-- Private delivery through short-lived signed URLs; no public object buckets.
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
VALUES('learning-assets','learning-assets',false,2097152,ARRAY['image/png','image/jpeg','image/webp']),
      ('user-avatars','user-avatars',false,2097152,ARRAY['image/png','image/jpeg','image/webp'])
ON CONFLICT(id) DO NOTHING;

CREATE OR REPLACE FUNCTION private.register_learning_asset(actor uuid,asset_data jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE wanted_bucket text; role_name text; asset public.assets; object storage.objects;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN RAISE EXCEPTION 'Server only' USING ERRCODE='42501'; END IF;
  SELECT role INTO role_name FROM private.account_access WHERE user_id=actor AND status='active';
  IF role_name IS NULL OR NOT EXISTS(SELECT 1 FROM public.accounts WHERE id=actor AND deleted_at IS NULL)
  THEN RAISE EXCEPTION 'Account access denied' USING ERRCODE='42501'; END IF;
  wanted_bucket := CASE WHEN role_name='admin' THEN 'learning-assets' ELSE 'user-avatars' END;
  IF asset_data->>'bucket_id' IS DISTINCT FROM wanted_bucket
    OR asset_data->>'sha256' IS NULL OR asset_data->>'sha256' !~ '^[0-9a-f]{64}$'
    OR asset_data->>'object_path' IS DISTINCT FROM actor::text||'/'||(asset_data->>'sha256')||
      (CASE asset_data->>'mime_type' WHEN 'image/png' THEN '.png' WHEN 'image/jpeg' THEN '.jpg' WHEN 'image/webp' THEN '.webp' ELSE '?' END)
    OR coalesce((asset_data->>'byte_size')::bigint,0) NOT BETWEEN 1 AND 2097152
    OR (asset_data->>'source_url' IS NOT NULL AND coalesce(length(asset_data->>'license'),0)=0)
  THEN RAISE EXCEPTION 'Invalid asset metadata' USING ERRCODE='22023'; END IF;
  SELECT * INTO object FROM storage.objects WHERE bucket_id=wanted_bucket AND name=asset_data->>'object_path';
  IF NOT FOUND OR (object.metadata->>'size')::bigint IS DISTINCT FROM (asset_data->>'byte_size')::bigint
    OR object.metadata->>'mimetype' IS DISTINCT FROM asset_data->>'mime_type'
  THEN RAISE EXCEPTION 'Stored asset does not match metadata' USING ERRCODE='22023'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(actor::text,750032));
  SELECT * INTO asset FROM public.assets WHERE bucket_id=wanted_bucket AND object_path=asset_data->>'object_path';
  IF FOUND THEN RETURN to_jsonb(asset); END IF;
  IF (SELECT count(*) FROM public.assets WHERE created_by=actor AND status='ready')>=
    (CASE WHEN role_name='admin' THEN 10000 ELSE 10 END)
  THEN RAISE EXCEPTION 'Asset limit reached' USING ERRCODE='22023'; END IF;
  INSERT INTO public.assets(owner_user_id,bucket_id,object_path,kind,mime_type,byte_size,sha256,
    source_url,license,attribution,status,created_by)
    VALUES(CASE WHEN role_name='user' THEN actor END,wanted_bucket,asset_data->>'object_path',
      CASE WHEN role_name='user' THEN 'avatar' ELSE 'image' END,asset_data->>'mime_type',
      (asset_data->>'byte_size')::bigint,asset_data->>'sha256',asset_data->>'source_url',asset_data->>'license',
      asset_data->>'attribution','ready',actor) RETURNING * INTO asset;
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,CASE WHEN role_name='admin' THEN 'admin' ELSE 'system' END,'asset.register','asset',asset.id::text,
      gen_random_uuid(),jsonb_build_object('bucket',wanted_bucket,'bytes',asset.byte_size));
  RETURN to_jsonb(asset);
END $$;
REVOKE ALL ON FUNCTION private.register_learning_asset(uuid,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.register_learning_asset(uuid,jsonb) TO service_role;
CREATE OR REPLACE FUNCTION public.register_learning_asset(actor uuid,asset_data jsonb)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.register_learning_asset(actor,asset_data) $$;
REVOKE ALL ON FUNCTION public.register_learning_asset(uuid,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.register_learning_asset(uuid,jsonb) TO service_role;

-- Bind the complete pedagogical content to the shipped implementation, rather
-- than allowing an admin to change the question under an old evaluator ID.
CREATE OR REPLACE FUNCTION private.supported_activity(av public.activity_versions)
RETURNS boolean LANGUAGE sql STABLE SET search_path='' AS $$
  SELECT EXISTS(SELECT 1 FROM private.evaluator_versions ev
    WHERE ev.mechanism=av.mechanism AND ev.version=av.evaluator_version AND ev.status IN ('active','retired')
      AND ev.input_schema->'activities' @> jsonb_build_array(jsonb_build_object(
        'id',av.activity_id,'content_version',av.content_version,'title',av.title,'stage',av.stage,
        'prompt',av.prompt,'hint_levels',av.hint_levels,'explanation',av.explanation,
        'mechanism',av.mechanism,'mechanism_version',av.mechanism_version,'evaluator_version',av.evaluator_version,
        'config',av.config,'initial_state',av.initial_state,'skill_ids',to_jsonb(av.skill_ids))))
$$;
REVOKE ALL ON FUNCTION private.supported_activity(public.activity_versions) FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION private.guard_release_publish() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
  IF TG_OP='DELETE' THEN
    IF OLD.status<>'draft' THEN RAISE EXCEPTION 'Release history cannot be deleted'; END IF;
    RETURN OLD;
  END IF;
  IF TG_OP='UPDATE' AND OLD.status<>'draft' AND
    (to_jsonb(NEW)-'status' IS DISTINCT FROM to_jsonb(OLD)-'status' OR NEW.status='draft')
  THEN RAISE EXCEPTION 'Published release metadata is immutable'; END IF;
  IF NEW.status='published' THEN
    IF NOT EXISTS(SELECT 1 FROM public.release_activities WHERE release_id=NEW.id)
      OR EXISTS(SELECT 1 FROM public.release_activities ra JOIN public.activity_versions av
        ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
        JOIN private.evaluator_versions ev ON ev.mechanism=av.mechanism AND ev.version=av.evaluator_version
        WHERE ra.release_id=NEW.id AND (av.status<>'published' OR ev.status<>'active' OR NOT private.supported_activity(av)))
      OR EXISTS(SELECT 1 FROM public.activity_assets aa JOIN public.assets a ON a.id=aa.asset_id
        JOIN public.release_activities ra ON ra.activity_id=aa.activity_id AND ra.content_version=aa.content_version
        WHERE ra.release_id=NEW.id AND aa.required AND (a.status<>'ready' OR a.bucket_id<>'learning-assets'))
    THEN RAISE EXCEPTION 'Cannot publish without verified backend evaluator coverage' USING ERRCODE='22023'; END IF;
  END IF;
  RETURN NEW;
END $$;

-- A bounded page may split a transaction's revision: always continue using both
-- revision and index, and retain the same high-water mark until has_more=false.
CREATE OR REPLACE FUNCTION private.learning_changes(
  after_revision bigint DEFAULT 0,after_index integer DEFAULT -1,until_revision bigint DEFAULT NULL,page_size integer DEFAULT 100
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor(); head private.sync_heads; items jsonb; high bigint;
  next_rev bigint; next_idx integer;
BEGIN
  SELECT * INTO head FROM private.sync_heads WHERE owner_user_id=actor;
  high := coalesce(until_revision,head.revision,0);
  IF after_revision IS NULL OR after_index IS NULL OR page_size IS NULL
    OR page_size NOT BETWEEN 1 AND 200 OR after_index< -1 OR after_revision<0
    OR high>coalesce(head.revision,0) OR high<after_revision
    OR after_revision<coalesce(head.min_available_revision,0)
  THEN RAISE EXCEPTION 'Invalid or expired sync cursor' USING ERRCODE='22023'; END IF;
  SELECT coalesce(jsonb_agg(jsonb_build_object('revision',x.revision::text,'index',x.change_index,
    'entity',x.entity_type,'id',x.entity_id,'action',x.action,'payload',
      x.payload||CASE WHEN x.payload ? 'revision' THEN jsonb_build_object('revision',x.payload->>'revision') ELSE '{}'::jsonb END
      ||CASE WHEN x.payload ? 'base_revision' THEN jsonb_build_object('base_revision',x.payload->>'base_revision') ELSE '{}'::jsonb END
    ) ORDER BY x.revision,x.change_index),'[]') INTO items FROM (
      SELECT y.*,sum(octet_length(coalesce(y.payload::text,''))+512) OVER(ORDER BY revision,change_index) page_bytes
      FROM (SELECT * FROM private.sync_changes WHERE owner_user_id=actor
        AND (revision,change_index)>(after_revision,after_index) AND revision<=high
        ORDER BY revision,change_index LIMIT page_size) y
    ) x WHERE page_bytes<=1048576;
  next_rev := coalesce((items->-1->>'revision')::bigint,after_revision);
  next_idx := coalesce((items->-1->>'index')::int,after_index);
  RETURN jsonb_build_object('changes',items,'high_water',high::text,
    'has_more',EXISTS(SELECT 1 FROM private.sync_changes WHERE owner_user_id=actor AND revision<=high
      AND (revision,change_index)>(next_rev,next_idx)),
    'next_revision',next_rev::text,'next_index',next_idx);
END $$;
REVOKE ALL ON FUNCTION private.learning_changes(bigint,integer,bigint,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.learning_changes(bigint,integer,bigint,integer) TO authenticated;
NOTIFY pgrst,'reload schema';
