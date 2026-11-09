-- Additive Tinkercad Studio contract; legacy releases and user records are retained.
CREATE OR REPLACE FUNCTION private.studio_strings(v jsonb, minimum integer DEFAULT 2, maximum integer DEFAULT 8)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
BEGIN
 RETURN jsonb_typeof(v)='array' AND jsonb_array_length(v) BETWEEN minimum AND maximum
   AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(v) x WHERE NOT private.slide_text(x,1000));
EXCEPTION WHEN OTHERS THEN RETURN false; END $$;
CREATE OR REPLACE FUNCTION private.studio_numbers(v jsonb, minimum integer, maximum integer)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
BEGIN
 RETURN coalesce(jsonb_typeof(v)='array' AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(v) x WHERE NOT private.slide_integer(x,minimum,maximum)),false);
EXCEPTION WHEN OTHERS THEN RETURN false; END $$;
CREATE OR REPLACE FUNCTION private.valid_extended_slide(engine text,c jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE a jsonb := c->'answer_values'; n integer;
BEGIN
 CASE engine
 WHEN 'solid3D' THEN RETURN private.slide_integer(c->'target_volume',1,125) AND EXISTS(SELECT 1 FROM generate_series(1,5) w,generate_series(1,5) h,generate_series(1,5) d WHERE w*h*d=(c->>'target_volume')::int);
 WHEN 'polygonVertices' THEN RETURN private.slide_integer(c->'target_area',1,16) AND EXISTS(SELECT 1 FROM generate_series(1,4) w,generate_series(1,4) h WHERE w*h=(c->>'target_area')::int);
 WHEN 'balanceScale' THEN RETURN private.slide_integer(c->'target_weight',0,10);
 WHEN 'robotRoute' THEN RETURN private.slide_integer(c->'max_commands',6,32);
 WHEN 'loopBuilder' THEN RETURN private.slide_integer(c->'target_repeat',1,4) AND jsonb_typeof(c->'target_body')='array' AND jsonb_array_length(c->'target_body')=2 AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(c->'target_body') x WHERE x NOT IN ('"R"','"D"','"L"','"U"'));
 WHEN 'globe3D' THEN RETURN private.slide_integer(c->'target_latitude',-90,90) AND private.slide_integer(c->'target_longitude',-180,180) AND (c->>'target_latitude')::int%15=0 AND (c->>'target_longitude')::int%15=0;
 WHEN 'causalLab','causalExperiment' THEN RETURN private.slide_integer(c->'target_product',0,9) AND private.studio_strings(c->'axes',2,2) AND EXISTS(SELECT 1 FROM generate_series(0,3) x,generate_series(0,3) y WHERE x*y=(c->>'target_product')::int);
 WHEN 'symmetryMirror','tangramRotate','strata3D' THEN RETURN true;
 WHEN 'resourceBudget' THEN RETURN private.studio_strings(c->'items',2,6) AND private.studio_numbers(c->'minima',0,10) AND jsonb_array_length(c->'minima')=jsonb_array_length(c->'items') AND (SELECT sum((x#>>'{}')::int) FROM jsonb_array_elements(c->'minima') x)<=10;
 WHEN 'sequenceTiles','evidenceBoard','categorySort','clozeBank','matchPairs' THEN
   IF NOT private.studio_strings(c->'items') OR NOT private.studio_numbers(a,0,7) THEN RETURN false; END IF;
   n:=jsonb_array_length(c->'items');
   IF engine IN ('sequenceTiles','evidenceBoard') THEN
     RETURN jsonb_array_length(a) BETWEEN 1 AND n AND (engine<>'sequenceTiles' OR jsonb_array_length(a)=n)
       AND (SELECT count(DISTINCT x) FROM jsonb_array_elements(a) x)=jsonb_array_length(a)
       AND private.studio_numbers(a,0,n-1);
   END IF;
   RETURN private.studio_strings(c->'choices') AND jsonb_array_length(a)=n AND private.studio_numbers(a,0,jsonb_array_length(c->'choices')-1)
     AND (engine<>'matchPairs' OR (SELECT count(DISTINCT x) FROM jsonb_array_elements(a) x)=n);
 ELSE RETURN false;
 END CASE;
EXCEPTION WHEN OTHERS THEN RETURN false; END $$;
CREATE OR REPLACE FUNCTION private.initial_extended_slide(engine text,c jsonb)
RETURNS jsonb LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT CASE engine
 WHEN 'solid3D' THEN '{"width":2,"height":2,"depth":2}'::jsonb
 WHEN 'polygonVertices' THEN '{"points":[[0,0],[4,0],[4,4],[0,4]]}'::jsonb
 WHEN 'symmetryMirror' THEN '{"cells":[]}'::jsonb
 WHEN 'tangramRotate' THEN '{"turns":[1,1],"placed":[false,false]}'::jsonb
 WHEN 'robotRoute' THEN '{"commands":[]}'::jsonb
 WHEN 'loopBuilder' THEN '{"body":["D","R"],"repeat":1}'::jsonb
 WHEN 'balanceScale' THEN '{"weight":0}'::jsonb
 WHEN 'causalLab' THEN '{"x":0,"y":0,"prediction":-1,"trials":[],"observed":[]}'::jsonb
 WHEN 'causalExperiment' THEN '{"x":0,"y":0,"prediction":-1,"trials":[],"observed":[]}'::jsonb
 WHEN 'globe3D' THEN '{"latitude":0,"longitude":0}'::jsonb
 WHEN 'strata3D' THEN '{"layers":[30,10,20]}'::jsonb
 WHEN 'evidenceBoard' THEN '{"selected":[]}'::jsonb
 WHEN 'sequenceTiles' THEN jsonb_build_object('values',(SELECT jsonb_agg(i ORDER BY i DESC) FROM generate_series(0,jsonb_array_length(c->'items')-1) i))
 ELSE jsonb_build_object('values',(SELECT jsonb_agg(CASE WHEN engine='resourceBudget' THEN 0 ELSE -1 END) FROM jsonb_array_elements(c->'items'))) END
$$;
CREATE OR REPLACE FUNCTION private.evaluate_extended_slide(engine text,c jsonb,s jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE p jsonb; cmd jsonb; x integer:=0; y integer:=0; i integer; a jsonb; b jsonb;
BEGIN
 IF jsonb_typeof(s) IS DISTINCT FROM 'object' THEN RETURN false; END IF;
 CASE engine
 WHEN 'solid3D' THEN RETURN private.slide_integer(s->'width',1,5) AND private.slide_integer(s->'height',1,5) AND private.slide_integer(s->'depth',1,5) AND (s->>'width')::int*(s->>'height')::int*(s->>'depth')::int=(c->>'target_volume')::int;
 WHEN 'balanceScale' THEN RETURN private.slide_integer(s->'weight',0,10) AND s->'weight'=c->'target_weight';
 WHEN 'polygonVertices' THEN
   p:=s->'points';
   IF jsonb_typeof(p) IS DISTINCT FROM 'array' OR jsonb_array_length(p)<>4 THEN RETURN false; END IF;
   FOR a IN SELECT value FROM jsonb_array_elements(p) LOOP IF NOT private.studio_numbers(a,0,4) OR jsonb_array_length(a)<>2 THEN RETURN false; END IF; END LOOP;
   RETURN p#>'{0,1}'=p#>'{1,1}' AND p#>'{1,0}'=p#>'{2,0}' AND p#>'{2,1}'=p#>'{3,1}' AND p#>'{3,0}'=p#>'{0,0}'
     AND abs(((p#>>'{1,0}')::int-(p#>>'{0,0}')::int)*((p#>>'{3,1}')::int-(p#>>'{0,1}')::int))=(c->>'target_area')::int;
 WHEN 'symmetryMirror' THEN RETURN private.studio_numbers(s->'cells',0,35) AND jsonb_array_length(s->'cells')=3 AND s->'cells' @> '[11,16,23]'::jsonb;
 WHEN 'tangramRotate' THEN RETURN private.studio_numbers(s->'turns',0,3) AND jsonb_array_length(s->'turns')=2 AND abs((s#>>'{turns,0}')::int-(s#>>'{turns,1}')::int)=2 AND s->'placed'='[true,true]'::jsonb;
 WHEN 'strata3D' THEN RETURN private.studio_numbers(s->'layers',10,30) AND s->'layers'='[10,20,30]'::jsonb;
 WHEN 'globe3D' THEN RETURN private.slide_integer(s->'latitude',-90,90) AND private.slide_integer(s->'longitude',-180,180) AND s->'latitude'=c->'target_latitude' AND s->'longitude'=c->'target_longitude';
 WHEN 'loopBuilder' THEN RETURN private.slide_integer(s->'repeat',1,4) AND s->'repeat'=c->'target_repeat' AND s->'body'=c->'target_body';
 WHEN 'robotRoute' THEN
   IF jsonb_typeof(s->'commands') IS DISTINCT FROM 'array' OR jsonb_array_length(s->'commands')>(c->>'max_commands')::int THEN RETURN false; END IF;
   FOR cmd IN SELECT value FROM jsonb_array_elements(s->'commands') LOOP
     CASE cmd WHEN '"R"' THEN x:=x+1; WHEN '"L"' THEN x:=x-1; WHEN '"D"' THEN y:=y+1; WHEN '"U"' THEN y:=y-1; ELSE RETURN false; END CASE;
     IF x<0 OR x>3 OR y<0 OR y>3 OR (x=1 AND y=1) THEN RETURN false; END IF;
   END LOOP;
   RETURN x=3 AND y=3;
 WHEN 'causalLab','causalExperiment' THEN RETURN private.slide_integer(s->'x',0,3) AND private.slide_integer(s->'y',0,3) AND private.slide_integer(s->'prediction',0,9) AND private.studio_numbers(s->'observed',0,9)
   AND (s->>'x')::int*(s->>'y')::int=(c->>'target_product')::int AND s->'prediction'=c->'target_product' AND s->'observed'=jsonb_build_array(s->'x',s->'y',c->'target_product');
 WHEN 'resourceBudget' THEN
   a:=s->'values';
   IF NOT private.studio_numbers(a,0,10) OR jsonb_array_length(a)<>jsonb_array_length(c->'items') OR (SELECT sum((v#>>'{}')::int) FROM jsonb_array_elements(a) v)<>10 THEN RETURN false; END IF;
   FOR i IN 0..jsonb_array_length(a)-1 LOOP IF (a->>i)::int<(c->'minima'->>i)::int THEN RETURN false; END IF; END LOOP;
   RETURN true;
 WHEN 'evidenceBoard' THEN
   IF NOT private.studio_numbers(s->'selected',0,7) THEN RETURN false; END IF;
   SELECT jsonb_agg(v ORDER BY v) INTO a FROM jsonb_array_elements(s->'selected') v;
   SELECT jsonb_agg(v ORDER BY v) INTO b FROM jsonb_array_elements(c->'answer_values') v;
   RETURN a=b;
 WHEN 'sequenceTiles','categorySort','clozeBank','matchPairs' THEN RETURN private.studio_numbers(s->'values',0,7) AND s->'values'=c->'answer_values';
 ELSE RETURN false;
 END CASE;
EXCEPTION WHEN OTHERS THEN RETURN false; END $$;
REVOKE ALL ON FUNCTION private.studio_strings(jsonb,integer,integer),private.studio_numbers(jsonb,integer,integer),private.valid_extended_slide(text,jsonb),private.initial_extended_slide(text,jsonb),private.evaluate_extended_slide(text,jsonb,jsonb) FROM PUBLIC,anon,authenticated;

-- Aggregate progress, authorized by the same server-side Admin gate as the dashboard.
CREATE OR REPLACE FUNCTION private.admin_studio_progress(account_id uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid:=private.learning_actor('admin');
BEGIN
 IF account_id IS NULL OR NOT EXISTS(SELECT 1 FROM public.accounts a WHERE a.id=account_id AND a.deleted_at IS NULL) THEN
   RAISE EXCEPTION 'Account unavailable' USING ERRCODE='22023'; END IF;
 RETURN jsonb_build_object(
   'profiles',(SELECT count(*) FROM public.learner_profiles p WHERE p.owner_user_id=account_id AND p.deleted_at IS NULL),
   'sessions',(SELECT count(*) FROM public.learning_sessions s WHERE s.owner_user_id=account_id),
   'verified_completions',(SELECT count(*) FROM public.topic_completions c WHERE c.owner_user_id=account_id AND c.source='verified'),
   'verified_xp',(SELECT coalesce(sum(x.delta),0) FROM public.xp_ledger x WHERE x.owner_user_id=account_id AND x.source='first_completion'));
END $$;
REVOKE ALL ON FUNCTION private.admin_studio_progress(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_studio_progress(uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_studio_progress(account_id uuid) RETURNS jsonb
LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_studio_progress(account_id) $$;
REVOKE ALL ON FUNCTION public.admin_studio_progress(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_studio_progress(uuid) TO authenticated;

-- Public illustrations are stable URLs for immutable published content, never expiring signed URLs.
-- Private image buckets used by existing learning APIs remain unchanged.
INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
VALUES('lesson-assets','lesson-assets',true,5242880,ARRAY['image/png','image/jpeg','image/webp','image/gif','image/svg+xml'])
ON CONFLICT(id) DO NOTHING;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM storage.buckets WHERE id='lesson-assets' AND NOT public) THEN
   RAISE EXCEPTION 'lesson-assets already exists as private; reconcile its usage before exposing illustrations';
 END IF;
END $$;
DROP POLICY IF EXISTS studio_asset_insert ON storage.objects;
CREATE POLICY studio_asset_insert ON storage.objects FOR INSERT TO authenticated
WITH CHECK(bucket_id='lesson-assets' AND private.has_role('admin') AND (storage.foldername(name))[1]=(SELECT auth.uid())::text);
DROP POLICY IF EXISTS studio_asset_admin_read ON storage.objects;
CREATE POLICY studio_asset_admin_read ON storage.objects FOR SELECT TO authenticated
USING(bucket_id='lesson-assets' AND private.has_role('admin'));
-- No UPDATE/DELETE policy: uploads use unique paths, preserving published asset URLs.

NOTIFY pgrst,'reload schema';



CREATE OR REPLACE FUNCTION private.valid_slide_lesson(c jsonb) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE s jsonb; cfg jsonb; p jsonb; k text; ids text[] := '{}'; interactive boolean := false;
BEGIN
 IF c->'schema_version' IS DISTINCT FROM '1'::jsonb OR jsonb_typeof(c->'slides') IS DISTINCT FROM 'array'
   OR jsonb_array_length(c->'slides') NOT BETWEEN 1 AND 12 THEN RETURN false; END IF;
 FOR s IN SELECT value FROM jsonb_array_elements(c->'slides') LOOP
   IF NOT private.slide_text(s->'id',80) OR s->>'id' !~ '^[a-z][a-z0-9-]*$' OR s->>'id'=ANY(ids)
     OR NOT private.slide_text(s->'title',160) OR NOT private.slide_text(s->'prompt',10000,s->>'engine'='story')
     OR NOT private.slide_text(s->'hint',3000,true) OR NOT private.slide_text(s->'explanation',10000,true)
     OR jsonb_typeof(s->'config') IS DISTINCT FROM 'object' THEN RETURN false; END IF;
   ids := array_append(ids,s->>'id'); cfg := s->'config';
   CASE s->>'engine'
   WHEN 'story' THEN
     IF NOT private.slide_text(cfg->'text',10000) OR NOT private.slide_text(cfg->'image_url',2000,true)
       OR NOT private.slide_text(cfg->'image_alt',500,true) THEN RETURN false; END IF;
     IF cfg->>'image_url'<>'' AND (cfg->>'image_url' !~ '^https://[^/@[:space:]]+(/[^[:space:]]*)?$'
       OR length(btrim(cfg->>'image_alt'))=0) THEN RETURN false; END IF;
   WHEN 'quiz' THEN
     interactive := true;
     IF jsonb_typeof(cfg->'choices') IS DISTINCT FROM 'array' OR jsonb_array_length(cfg->'choices') NOT BETWEEN 2 AND 8
       OR NOT private.slide_integer(cfg->'answer',0,jsonb_array_length(cfg->'choices')-1)
       OR EXISTS(SELECT 1 FROM jsonb_array_elements(cfg->'choices') x WHERE NOT private.slide_text(x,2000)) THEN RETURN false; END IF;
   WHEN 'pairs' THEN
     interactive := true;
     IF jsonb_typeof(cfg->'pairs') IS DISTINCT FROM 'array' OR jsonb_array_length(cfg->'pairs') NOT BETWEEN 2 AND 6 THEN RETURN false; END IF;
     FOR p IN SELECT value FROM jsonb_array_elements(cfg->'pairs') LOOP
       IF NOT private.slide_text(p->'left',1000) OR NOT private.slide_text(p->'right',1000) THEN RETURN false; END IF;
     END LOOP;
   WHEN 'graph' THEN
     interactive := true;
     FOREACH k IN ARRAY ARRAY['min_a','max_a','min_b','max_b','start_a','start_b','target_a','target_b'] LOOP
       IF NOT private.slide_integer(cfg->k,-10,10) THEN RETURN false; END IF;
     END LOOP;
     IF (cfg->>'min_a')::int>=(cfg->>'max_a')::int OR (cfg->>'min_b')::int>=(cfg->>'max_b')::int
       OR NOT private.slide_integer(cfg->'start_a',(cfg->>'min_a')::int,(cfg->>'max_a')::int)
       OR NOT private.slide_integer(cfg->'target_a',(cfg->>'min_a')::int,(cfg->>'max_a')::int)
       OR NOT private.slide_integer(cfg->'start_b',(cfg->>'min_b')::int,(cfg->>'max_b')::int)
       OR NOT private.slide_integer(cfg->'target_b',(cfg->>'min_b')::int,(cfg->>'max_b')::int) THEN RETURN false; END IF;
   ELSE IF NOT coalesce(private.valid_extended_slide(s->>'engine',cfg),false) THEN RETURN false; END IF; interactive:=true;
   END CASE;
 END LOOP;
 RETURN interactive;
EXCEPTION WHEN OTHERS THEN RETURN false;
END $$;

CREATE OR REPLACE FUNCTION private.initial_slide_state(c jsonb) RETURNS jsonb
LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT jsonb_build_object('index',0,'slides',(SELECT jsonb_agg(CASE s->>'engine'
   WHEN 'story' THEN '{"ack":false}'::jsonb WHEN 'quiz' THEN '{"answer":-1}'::jsonb
   WHEN 'pairs' THEN jsonb_build_object('values',(SELECT jsonb_agg(-1) FROM jsonb_array_elements(s#>'{config,pairs}')))
   WHEN 'graph' THEN jsonb_build_object('a',s#>'{config,start_a}','b',s#>'{config,start_b}') ELSE private.initial_extended_slide(s->>'engine',s->'config') END ORDER BY n)
   FROM jsonb_array_elements(c->'slides') WITH ORDINALITY t(s,n)))
$$;

CREATE OR REPLACE FUNCTION private.evaluate_slide_lesson(c jsonb, state jsonb) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
DECLARE s jsonb; cfg jsonb; answer jsonb; idx integer := 0; pair_index integer;
BEGIN
 IF NOT private.valid_slide_lesson(c) OR jsonb_typeof(state->'slides') IS DISTINCT FROM 'array'
   OR jsonb_array_length(state->'slides')<>jsonb_array_length(c->'slides') THEN RETURN false; END IF;
 FOR s IN SELECT value FROM jsonb_array_elements(c->'slides') LOOP
   cfg := s->'config'; answer := state->'slides'->idx; idx := idx+1;
   IF jsonb_typeof(answer) IS DISTINCT FROM 'object' THEN RETURN false; END IF;
   CASE s->>'engine'
   WHEN 'story' THEN IF answer->'ack' IS DISTINCT FROM 'true'::jsonb THEN RETURN false; END IF;
   WHEN 'quiz' THEN IF NOT private.slide_integer(answer->'answer',0,jsonb_array_length(cfg->'choices')-1)
     OR answer->'answer' IS DISTINCT FROM cfg->'answer' THEN RETURN false; END IF;
   WHEN 'pairs' THEN
     IF jsonb_typeof(answer->'values') IS DISTINCT FROM 'array' OR jsonb_array_length(answer->'values')<>jsonb_array_length(cfg->'pairs') THEN RETURN false; END IF;
     FOR pair_index IN 0..jsonb_array_length(cfg->'pairs')-1 LOOP
       IF NOT private.slide_integer(answer->'values'->pair_index,0,jsonb_array_length(cfg->'pairs')-1)
         OR answer->'values'->pair_index IS DISTINCT FROM to_jsonb(pair_index) THEN RETURN false; END IF;
     END LOOP;
   WHEN 'graph' THEN IF NOT private.slide_integer(answer->'a',-10,10) OR NOT private.slide_integer(answer->'b',-10,10)
     OR answer->'a' IS DISTINCT FROM cfg->'target_a' OR answer->'b' IS DISTINCT FROM cfg->'target_b' THEN RETURN false; END IF;
   ELSE IF NOT coalesce(private.evaluate_extended_slide(s->>'engine',cfg,answer),false) THEN RETURN false; END IF;
   END CASE;
 END LOOP;
 RETURN true;
EXCEPTION WHEN OTHERS THEN RETURN false;
END $$;

CREATE OR REPLACE FUNCTION private.admin_content_mutate(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); item public.activities; previous public.activity_versions;
  edit public.lesson_edits; op private.admin_audit_logs; base public.content_releases;
  rid uuid := gen_random_uuid(); version_number integer; result jsonb; manifest jsonb; is_slides boolean;
  request_hash text := encode(extensions.digest(admin_content_mutate.payload::text,'sha256'),'hex');
BEGIN
  IF operation_id IS NULL OR jsonb_typeof(admin_content_mutate.payload) IS DISTINCT FROM 'object' OR octet_length(admin_content_mutate.payload::text)>100000
    THEN RAISE EXCEPTION 'Invalid content' USING ERRCODE='22023'; END IF;
  -- Serialize catalog publication globally so simultaneous admins cannot lose changes.
  PERFORM pg_advisory_xact_lock(750040);
  SELECT * INTO op FROM private.admin_audit_logs WHERE actor_user_id=actor AND request_id=operation_id;
  IF FOUND THEN
    IF op.action<>'lesson.save' OR op.summary->>'request_hash' IS DISTINCT FROM request_hash THEN
      RAISE EXCEPTION 'Operation mismatch' USING ERRCODE='22023'; END IF;
    RETURN op.summary->'response';
  END IF;
  IF admin_content_mutate.payload->>'id' !~ '^[a-z][a-z0-9-]{0,79}$' OR admin_content_mutate.payload->>'id' IS NULL
    OR NOT EXISTS(SELECT 1 FROM public.topics WHERE id=admin_content_mutate.payload->>'topic_id')
    OR admin_content_mutate.payload->>'status' IS NULL OR admin_content_mutate.payload->>'status' NOT IN ('active','archived')
    THEN RAISE EXCEPTION 'Invalid lesson metadata' USING ERRCODE='22023'; END IF;
  SELECT * INTO item FROM public.activities WHERE id=admin_content_mutate.payload->>'id';
  IF FOUND AND item.topic_id IS DISTINCT FROM admin_content_mutate.payload->>'topic_id' THEN
    RAISE EXCEPTION 'Activity topic cannot change' USING ERRCODE='22023'; END IF;
  SELECT * INTO edit FROM public.lesson_edits WHERE activity_id=admin_content_mutate.payload->>'id';
  IF coalesce(edit.revision,0) IS DISTINCT FROM (admin_content_mutate.payload->>'revision')::int OR NOT admin_content_mutate.payload ? 'revision' THEN
    RAISE EXCEPTION 'Content revision conflict' USING ERRCODE='PT409'; END IF;
  SELECT * INTO previous FROM public.activity_versions WHERE activity_id=admin_content_mutate.payload->>'id' ORDER BY content_version DESC LIMIT 1;
  is_slides := coalesce(admin_content_mutate.payload->>'mechanism',previous.mechanism,'reasonedChoice')='slideLesson';
  IF is_slides AND EXISTS(SELECT 1 FROM public.lesson_builder_drafts WHERE id=admin_content_mutate.payload->>'id'
    AND revision IS DISTINCT FROM (admin_content_mutate.payload->>'builder_revision')::int)
    THEN RAISE EXCEPTION 'Builder revision conflict' USING ERRCODE='PT409'; END IF;
  IF previous.activity_id IS NULL OR previous.evaluator_version IN (3,4) THEN
    IF (is_slides AND NOT private.valid_slide_lesson(admin_content_mutate.payload->'config'))
      OR (NOT is_slides AND NOT private.valid_authored_choice(admin_content_mutate.payload->'config')) THEN
      RAISE EXCEPTION 'Invalid engine configuration' USING ERRCODE='22023'; END IF;
    INSERT INTO public.activities(id,topic_id,status,created_by)
      VALUES(admin_content_mutate.payload->>'id',admin_content_mutate.payload->>'topic_id','active',actor) ON CONFLICT DO NOTHING;
    version_number := coalesce(previous.content_version,0)+1;
    INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,
      mechanism,mechanism_version,evaluator_version,config,initial_state,status,published_at,created_by)
      VALUES(admin_content_mutate.payload->>'id',version_number,admin_content_mutate.payload->>'title',admin_content_mutate.payload->>'stage',admin_content_mutate.payload->>'prompt',
        jsonb_build_array(admin_content_mutate.payload->>'hint'),admin_content_mutate.payload->>'explanation',CASE WHEN is_slides THEN 'slideLesson' ELSE 'reasonedChoice' END,1,
        CASE WHEN is_slides THEN 4 ELSE 3 END,admin_content_mutate.payload->'config',
        CASE WHEN is_slides THEN private.initial_slide_state(admin_content_mutate.payload->'config') ELSE '{"answer":-1,"reason":-1}'::jsonb END,'draft',NULL,actor);
    UPDATE public.activity_versions SET status='published',published_at=now()
      WHERE activity_id=admin_content_mutate.payload->>'id' AND content_version=version_number;
  END IF;
  INSERT INTO public.lesson_edits(activity_id,title,stage,prompt,hint,explanation,status,sort_order)
    VALUES(admin_content_mutate.payload->>'id',admin_content_mutate.payload->>'title',admin_content_mutate.payload->>'stage',admin_content_mutate.payload->>'prompt',admin_content_mutate.payload->>'hint',
      admin_content_mutate.payload->>'explanation',admin_content_mutate.payload->>'status',(admin_content_mutate.payload->>'sort_order')::int)
    ON CONFLICT(activity_id) DO UPDATE SET title=excluded.title,stage=excluded.stage,prompt=excluded.prompt,
      hint=excluded.hint,explanation=excluded.explanation,status=excluded.status,sort_order=excluded.sort_order,
      revision=lesson_edits.revision+1,updated_at=now();
  SELECT * INTO base FROM public.content_releases WHERE status='published' ORDER BY published_at DESC,id DESC LIMIT 1;
  INSERT INTO public.content_releases(id,version_label,min_app_version,created_by)
    VALUES(rid,'admin-'||rid::text,CASE WHEN is_slides OR string_to_array(base.min_app_version,'.')::int[]>=ARRAY[1,3,5] THEN '1.3.5' ELSE coalesce(base.min_app_version,'1.3.3') END,actor);
  INSERT INTO public.release_activities(release_id,activity_id,content_version,topic_id,position,required)
    SELECT rid,a.id,v.content_version,a.topic_id,
      (row_number() OVER(PARTITION BY a.topic_id ORDER BY coalesce(e.sort_order,ra.position,0),a.id)-1)::int,true
    FROM public.activities a
    JOIN LATERAL (SELECT * FROM public.activity_versions x WHERE x.activity_id=a.id AND x.status='published'
      ORDER BY content_version DESC LIMIT 1) v ON true
    LEFT JOIN public.lesson_edits e ON e.activity_id=a.id
    LEFT JOIN public.release_activities ra ON ra.release_id=base.id AND ra.activity_id=a.id
    WHERE coalesce(e.status,'active')='active' AND (ra.activity_id IS NOT NULL OR v.evaluator_version IN (3,4) OR e.status='active');
  SELECT jsonb_agg(to_jsonb(ra) ORDER BY topic_id,position) INTO manifest FROM public.release_activities ra WHERE release_id=rid;
  UPDATE public.content_releases SET status='published',published_at=clock_timestamp(),
    manifest_hash=encode(extensions.digest(manifest::text,'sha256'),'hex') WHERE id=rid;
  UPDATE public.lesson_builder_drafts SET status='published' WHERE id=admin_content_mutate.payload->>'id';
  result := jsonb_build_object('release_id',rid,'id',admin_content_mutate.payload->>'id','revision',coalesce(edit.revision,0)+1);
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,'admin','lesson.save','activity',admin_content_mutate.payload->>'id',operation_id,
      jsonb_build_object('request_hash',request_hash,'response',result));
  RETURN result;
END $$;
NOTIFY pgrst,'reload schema';
