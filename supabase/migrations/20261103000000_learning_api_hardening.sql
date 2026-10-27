-- Keep bigint revisions exact in every canonical mutation response.
CREATE OR REPLACE FUNCTION private.learning_wire(value jsonb)
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE result jsonb; item record;
BEGIN
  IF jsonb_typeof(value)='object' THEN
    result := '{}';
    FOR item IN SELECT key,val FROM jsonb_each(value) AS t(key,val) LOOP
      result := result||jsonb_build_object(item.key,CASE WHEN item.key IN ('revision','base_revision','server_revision')
        AND jsonb_typeof(item.val)='number' THEN to_jsonb(item.val#>>'{}') ELSE private.learning_wire(item.val) END);
    END LOOP;
    RETURN result;
  ELSIF jsonb_typeof(value)='array' THEN
    SELECT coalesce(jsonb_agg(private.learning_wire(x.val) ORDER BY x.n),'[]') INTO result
      FROM jsonb_array_elements(value) WITH ORDINALITY x(val,n);
    RETURN result;
  END IF;
  RETURN value;
END $$;
REVOKE ALL ON FUNCTION private.learning_wire(jsonb) FROM PUBLIC,anon,authenticated;
CREATE OR REPLACE FUNCTION private.learning_mutate(operation_id uuid,operation_type text,payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  IF operation_type='attempt.submit' THEN RAISE EXCEPTION 'Use server evaluator' USING ERRCODE='42501'; END IF;
  RETURN private.learning_wire(private.learning_apply(private.learning_actor(),operation_id,operation_type,payload));
END $$;
CREATE OR REPLACE FUNCTION private.record_learning_attempt(owner_id uuid,operation_id uuid,payload jsonb,evaluation jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN RAISE EXCEPTION 'Server only' USING ERRCODE='42501'; END IF;
  RETURN private.learning_wire(private.learning_apply(owner_id,operation_id,'attempt.submit',payload,evaluation));
END $$;
CREATE INDEX IF NOT EXISTS audit_request_lookup ON private.admin_audit_logs(actor_user_id,request_id);

CREATE OR REPLACE FUNCTION private.guard_activity_asset() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
  IF TG_OP<>'INSERT' AND EXISTS(SELECT 1 FROM public.activity_versions WHERE activity_id=OLD.activity_id
    AND content_version=OLD.content_version AND status<>'draft') THEN
    RAISE EXCEPTION 'Published activity versions are immutable' USING ERRCODE='22023'; END IF;
  IF TG_OP<>'DELETE' AND EXISTS(SELECT 1 FROM public.activity_versions WHERE activity_id=NEW.activity_id
    AND content_version=NEW.content_version AND status<>'draft') THEN
    RAISE EXCEPTION 'Published activity versions are immutable' USING ERRCODE='22023'; END IF;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
  RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION private.guard_activity_asset() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS immutable_activity_assets ON public.activity_assets;
CREATE TRIGGER immutable_activity_assets BEFORE INSERT OR UPDATE OR DELETE ON public.activity_assets
  FOR EACH ROW EXECUTE FUNCTION private.guard_activity_asset();

CREATE OR REPLACE FUNCTION private.admin_link_learning_asset(operation_id uuid,payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); prior private.admin_audit_logs; result jsonb; hash text;
BEGIN
  IF operation_id IS NULL OR payload IS NULL OR jsonb_typeof(payload)<>'object'
    OR octet_length(payload::text)>8192 OR coalesce(length(payload->>'slot'),0) NOT BETWEEN 1 AND 64
  THEN RAISE EXCEPTION 'Invalid asset attachment' USING ERRCODE='22023'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(actor::text,750031));
  hash := encode(extensions.digest(convert_to(payload::text,'UTF8'),'sha256'),'hex');
  SELECT * INTO prior FROM private.admin_audit_logs WHERE actor_user_id=actor AND request_id=operation_id;
  IF FOUND THEN
    IF prior.action<>'asset.link' OR prior.summary->>'request_hash' IS DISTINCT FROM hash THEN
      RAISE EXCEPTION 'Operation ID reused with different payload' USING ERRCODE='22023'; END IF;
    RETURN prior.summary->'response'; END IF;
  PERFORM 1 FROM public.activity_versions WHERE activity_id=payload->>'activity_id'
    AND content_version=(payload->>'content_version')::int AND status='draft' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Draft activity unavailable' USING ERRCODE='22023'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.assets WHERE id=(payload->>'asset_id')::uuid
    AND bucket_id='learning-assets' AND status='ready' AND owner_user_id IS NULL)
  THEN RAISE EXCEPTION 'Content asset unavailable' USING ERRCODE='22023'; END IF;
  INSERT INTO public.activity_assets(activity_id,content_version,slot,asset_id,required)
    VALUES(payload->>'activity_id',(payload->>'content_version')::int,payload->>'slot',(payload->>'asset_id')::uuid,
      coalesce((payload->>'required')::boolean,false))
    ON CONFLICT(activity_id,content_version,slot) DO UPDATE SET asset_id=excluded.asset_id,required=excluded.required
    RETURNING to_jsonb(activity_assets) INTO result;
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,'admin','asset.link','activity',payload->>'activity_id',operation_id,
      jsonb_build_object('request_hash',hash,'response',result));
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.admin_link_learning_asset(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_link_learning_asset(uuid,jsonb) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_link_learning_asset(operation_id uuid,payload jsonb)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_link_learning_asset(operation_id,payload) $$;
REVOKE ALL ON FUNCTION public.admin_link_learning_asset(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_link_learning_asset(uuid,jsonb) TO authenticated;

-- Hash admin requests rather than retain arbitrary submitted fields in audit.
CREATE OR REPLACE FUNCTION private.admin_learning_mutate(operation_id uuid,operation_type text,payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); data jsonb := payload; result jsonb;
  audit private.admin_audit_logs; target text; manifest jsonb; release public.content_releases;
BEGIN
  IF operation_id IS NULL OR operation_type IS NULL OR data IS NULL OR jsonb_typeof(data)<>'object'
    OR octet_length(data::text)>300000 THEN RAISE EXCEPTION 'Invalid admin payload' USING ERRCODE='22023'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(actor::text,750031));
  SELECT * INTO audit FROM private.admin_audit_logs WHERE actor_user_id=actor AND request_id=operation_id;
  IF FOUND THEN
    IF coalesce(audit.summary->>'request_hash',encode(extensions.digest(convert_to((audit.summary->'request')::text,'UTF8'),'sha256'),'hex')) IS DISTINCT FROM encode(extensions.digest(convert_to(jsonb_build_object('operation_type',operation_type,'payload',data)::text,'UTF8'),'sha256'),'hex')
    THEN RAISE EXCEPTION 'Operation ID reused with different payload' USING ERRCODE='22023'; END IF;
    RETURN audit.summary->'response'; END IF;
  target := data->>'id';
  IF operation_type='account.status' THEN
    IF data->>'status' IS NULL OR data->>'status' NOT IN ('active','suspended') THEN
      RAISE EXCEPTION 'Invalid account status' USING ERRCODE='22023'; END IF;
    UPDATE private.account_access SET status=data->>'status' WHERE user_id=target::uuid AND role='user';
    IF NOT FOUND THEN RAISE EXCEPTION 'User account unavailable' USING ERRCODE='42501'; END IF;
    result := jsonb_build_object('id',target,'status',data->>'status');
  ELSIF operation_type='topic.save' THEN
    INSERT INTO public.topics(id,title,subtitle,subject,action_label,icon_key,sort_order,status,created_by)
      VALUES(target,data->>'title',coalesce(data->>'subtitle',''),data->>'subject',coalesce(data->>'action_label',''),
        data->>'icon_key',coalesce((data->>'sort_order')::int,0),coalesce(data->>'status','draft'),actor)
      ON CONFLICT(id) DO UPDATE SET title=excluded.title,subtitle=excluded.subtitle,subject=excluded.subject,
        action_label=excluded.action_label,icon_key=excluded.icon_key,sort_order=excluded.sort_order,status=excluded.status
      RETURNING to_jsonb(topics) INTO result;
  ELSIF operation_type='activity.save' THEN
    INSERT INTO public.activities(id,topic_id,created_by) VALUES(target,data->>'topic_id',actor) ON CONFLICT DO NOTHING;
    IF NOT EXISTS(SELECT 1 FROM public.activities WHERE id=target AND topic_id=data->>'topic_id') THEN
      RAISE EXCEPTION 'Activity topic cannot change' USING ERRCODE='22023'; END IF;
    INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,
      mechanism,mechanism_version,evaluator_version,config,initial_state,skill_ids,created_by)
      VALUES(target,(data->>'content_version')::int,data->>'title',data->>'stage',data->>'prompt',data->'hint_levels',
        data->>'explanation',data->>'mechanism',(data->>'mechanism_version')::int,(data->>'evaluator_version')::int,
        data->'config',data->'initial_state',ARRAY(SELECT jsonb_array_elements_text(coalesce(data->'skill_ids','[]'))),actor)
      ON CONFLICT(activity_id,content_version) DO UPDATE SET title=excluded.title,stage=excluded.stage,prompt=excluded.prompt,
        hint_levels=excluded.hint_levels,explanation=excluded.explanation,mechanism=excluded.mechanism,
        mechanism_version=excluded.mechanism_version,evaluator_version=excluded.evaluator_version,
        config=excluded.config,initial_state=excluded.initial_state,skill_ids=excluded.skill_ids
      RETURNING to_jsonb(activity_versions) INTO result;
  ELSIF operation_type='release.create' THEN
    IF data->>'min_app_version' IS NULL OR data->>'min_app_version' !~ '^\d+\.\d+\.\d+$'
      OR jsonb_typeof(data->'activities') IS DISTINCT FROM 'array'
      OR jsonb_array_length(data->'activities') NOT BETWEEN 1 AND 500
    THEN RAISE EXCEPTION 'Invalid release manifest' USING ERRCODE='22023'; END IF;
    INSERT INTO public.content_releases(id,version_label,min_app_version,created_by)
      VALUES(target::uuid,data->>'version_label',data->>'min_app_version',actor) RETURNING * INTO release;
    INSERT INTO public.release_activities(release_id,activity_id,content_version,topic_id,position,required)
      SELECT release.id,x->>'activity_id',(x->>'content_version')::int,x->>'topic_id',(x->>'position')::int,
        coalesce((x->>'required')::boolean,true) FROM jsonb_array_elements(data->'activities') x;
    result := to_jsonb(release);
  ELSIF operation_type='release.publish' THEN
    SELECT * INTO release FROM public.content_releases WHERE id=target::uuid AND status='draft' FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Draft release unavailable' USING ERRCODE='22023'; END IF;
    -- Only content whose evaluator/config has actually shipped may be published.
    IF EXISTS(SELECT 1 FROM public.release_activities ra JOIN public.activity_versions av
      ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
      JOIN private.evaluator_versions ev ON ev.mechanism=av.mechanism AND ev.version=av.evaluator_version
      WHERE ra.release_id=release.id AND (ev.status<>'active' OR NOT coalesce(ev.input_schema->'activities' @>
        jsonb_build_array(jsonb_build_object('id',av.activity_id,'content_version',av.content_version,
          'config',av.config,'initial_state',av.initial_state)),false)))
    THEN RAISE EXCEPTION 'Unsupported lesson version or invalid state' USING ERRCODE='22023'; END IF;
    UPDATE public.activity_versions av SET status='published',published_at=now()
      WHERE av.status='draft' AND EXISTS(SELECT 1 FROM public.release_activities ra
        WHERE ra.release_id=release.id AND ra.activity_id=av.activity_id AND ra.content_version=av.content_version);
    SELECT jsonb_agg(to_jsonb(ra) ORDER BY ra.topic_id,ra.position) INTO manifest
      FROM public.release_activities ra WHERE ra.release_id=release.id;
    UPDATE public.content_releases SET status='published',published_at=now(),
      manifest_hash=encode(extensions.digest(convert_to(manifest::text,'UTF8'),'sha256'),'hex')
      WHERE id=release.id RETURNING to_jsonb(content_releases) INTO result;
  ELSIF operation_type='release.retire' THEN
    UPDATE public.content_releases SET status='retired' WHERE id=target::uuid AND status='published'
      RETURNING to_jsonb(content_releases) INTO result;
    IF NOT FOUND THEN RAISE EXCEPTION 'Published release unavailable' USING ERRCODE='22023'; END IF;
  ELSE RAISE EXCEPTION 'Unknown admin operation' USING ERRCODE='22023'; END IF;
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,'admin',operation_type,split_part(operation_type,'.',1),target,operation_id,
      jsonb_build_object('request_hash',encode(extensions.digest(convert_to(jsonb_build_object('operation_type',operation_type,'payload',data)::text,'UTF8'),'sha256'),'hex'),'response',result));
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.admin_learning_mutate(uuid,text,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_learning_mutate(uuid,text,jsonb) TO authenticated;

NOTIFY pgrst,'reload schema';
