-- Declarative slide engines, independent drafts, and immutable publication.
CREATE OR REPLACE FUNCTION private.slide_text(v jsonb, maximum integer, allow_empty boolean DEFAULT false)
RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT coalesce(jsonb_typeof(v)='string' AND length(v#>>'{}')<=maximum AND (allow_empty OR length(btrim(v#>>'{}'))>0),false)
$$;
CREATE OR REPLACE FUNCTION private.slide_integer(v jsonb, minimum integer, maximum integer)
RETURNS boolean LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT CASE WHEN jsonb_typeof(v)='number' AND v#>>'{}' ~ '^-?\d+$'
   THEN (v#>>'{}')::numeric BETWEEN minimum AND maximum ELSE false END
$$;
REVOKE ALL ON FUNCTION private.slide_text(jsonb,integer,boolean),private.slide_integer(jsonb,integer,integer) FROM PUBLIC,anon,authenticated;

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
   ELSE RETURN false;
   END CASE;
 END LOOP;
 RETURN interactive;
EXCEPTION WHEN OTHERS THEN RETURN false;
END $$;
REVOKE ALL ON FUNCTION private.valid_slide_lesson(jsonb) FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION private.initial_slide_state(c jsonb) RETURNS jsonb
LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT jsonb_build_object('index',0,'slides',(SELECT jsonb_agg(CASE s->>'engine'
   WHEN 'story' THEN '{"ack":false}'::jsonb WHEN 'quiz' THEN '{"answer":-1}'::jsonb
   WHEN 'pairs' THEN jsonb_build_object('values',(SELECT jsonb_agg(-1) FROM jsonb_array_elements(s#>'{config,pairs}')))
   WHEN 'graph' THEN jsonb_build_object('a',s#>'{config,start_a}','b',s#>'{config,start_b}') END ORDER BY n)
   FROM jsonb_array_elements(c->'slides') WITH ORDINALITY t(s,n)))
$$;
REVOKE ALL ON FUNCTION private.initial_slide_state(jsonb) FROM PUBLIC,anon,authenticated;

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
   ELSE RETURN false;
   END CASE;
 END LOOP;
 RETURN true;
EXCEPTION WHEN OTHERS THEN RETURN false;
END $$;
REVOKE ALL ON FUNCTION private.evaluate_slide_lesson(jsonb,jsonb) FROM PUBLIC,anon,authenticated;
INSERT INTO private.evaluator_versions(mechanism,version,handler_key,implementation_hash,input_schema,status)
VALUES('slideLesson',4,'postgres:slide-engines-v1',encode(extensions.digest('slide-engines-v1:story-quiz-pairs-linear','sha256'),'hex'),
 '{"kind":"slide-engines-v1"}','active') ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS public.lesson_builder_drafts (
 id text PRIMARY KEY CHECK(id ~ '^[a-z][a-z0-9-]{0,79}$'), topic_id text NOT NULL REFERENCES public.topics(id),
 payload jsonb NOT NULL CHECK(jsonb_typeof(payload)='object'), revision integer NOT NULL DEFAULT 1,
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','published')),
 updated_by uuid REFERENCES public.accounts(id) ON DELETE SET NULL, updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.lesson_builder_drafts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.lesson_builder_drafts FROM anon,authenticated;
GRANT SELECT ON public.lesson_builder_drafts TO authenticated;
DROP POLICY IF EXISTS admin_read ON public.lesson_builder_drafts;
CREATE POLICY admin_read ON public.lesson_builder_drafts FOR SELECT TO authenticated USING(private.has_role('admin'));
CREATE OR REPLACE FUNCTION private.admin_builder_read(topic text) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); rows jsonb;
BEGIN
 SELECT coalesce(jsonb_agg(d.payload||jsonb_build_object('draft_revision',d.revision,'builder_status',d.status,
   'content_revision',coalesce(e.revision,0)) ORDER BY d.updated_at DESC),'[]') INTO rows
   FROM public.lesson_builder_drafts d LEFT JOIN public.lesson_edits e ON e.activity_id=d.id WHERE d.topic_id=topic;
 RETURN jsonb_build_object('items',rows,'total',jsonb_array_length(rows));
END $$;
REVOKE ALL ON FUNCTION private.admin_builder_read(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_builder_read(text) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_builder_read(topic text) RETURNS jsonb LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_builder_read(topic) $$;
REVOKE ALL ON FUNCTION public.admin_builder_read(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_builder_read(text) TO authenticated;
CREATE OR REPLACE FUNCTION private.admin_builder_save(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); old public.lesson_builder_drafts; audit private.admin_audit_logs; result jsonb;
 digest text := encode(extensions.digest(payload::text,'sha256'),'hex');
BEGIN
 IF operation_id IS NULL OR jsonb_typeof(payload) IS DISTINCT FROM 'object' OR octet_length(payload::text)>180000
   OR NOT coalesce(payload->>'id' ~ '^[a-z][a-z0-9-]{0,79}$',false) OR NOT payload ? 'revision'
   THEN RAISE EXCEPTION 'Invalid builder draft' USING ERRCODE='22023'; END IF;
 PERFORM pg_advisory_xact_lock(750040);
 SELECT * INTO audit FROM private.admin_audit_logs WHERE actor_user_id=actor AND request_id=operation_id;
 IF FOUND THEN
   IF audit.action<>'lesson.draft' OR audit.summary->>'request_hash' IS DISTINCT FROM digest THEN RAISE EXCEPTION 'Operation mismatch' USING ERRCODE='22023'; END IF;
   RETURN audit.summary->'response';
 END IF;
 SELECT * INTO old FROM public.lesson_builder_drafts WHERE id=payload->>'id';
 IF coalesce(old.revision,0) IS DISTINCT FROM (payload->>'revision')::int THEN RAISE EXCEPTION 'Draft revision conflict' USING ERRCODE='PT409'; END IF;
 IF old.id IS NOT NULL AND old.topic_id IS DISTINCT FROM payload->>'topic_id' THEN RAISE EXCEPTION 'Draft topic cannot change' USING ERRCODE='22023'; END IF;
 INSERT INTO public.lesson_builder_drafts(id,topic_id,payload,updated_by) VALUES(payload->>'id',payload->>'topic_id',payload,actor)
   ON CONFLICT(id) DO UPDATE SET payload=excluded.payload,revision=lesson_builder_drafts.revision+1,status='draft',updated_by=actor,updated_at=now();
 result := jsonb_build_object('id',payload->>'id','revision',coalesce(old.revision,0)+1);
 INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
   VALUES(actor,'admin','lesson.draft','activity',payload->>'id',operation_id,jsonb_build_object('request_hash',digest,'response',result));
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.admin_builder_save(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_builder_save(uuid,jsonb) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_builder_save(operation_id uuid,payload jsonb) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_builder_save(operation_id,payload) $$;
REVOKE ALL ON FUNCTION public.admin_builder_save(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_builder_save(uuid,jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION private.supported_activity(av public.activity_versions)
RETURNS boolean LANGUAGE sql STABLE SET search_path='' AS $$
  SELECT CASE WHEN av.evaluator_version=4 THEN av.mechanism='slideLesson' AND av.mechanism_version=1
    AND private.valid_slide_lesson(av.config) AND av.initial_state=private.initial_slide_state(av.config)
  WHEN av.evaluator_version=3 THEN av.mechanism='reasonedChoice'
    AND av.mechanism_version=1 AND private.valid_authored_choice(av.config)
    AND av.initial_state='{"answer":-1,"reason":-1}'::jsonb
  ELSE EXISTS(SELECT 1 FROM private.evaluator_versions ev
    WHERE ev.mechanism=av.mechanism AND ev.version=av.evaluator_version AND ev.status IN ('active','retired')
      AND ev.input_schema->'activities' @> jsonb_build_array(jsonb_build_object(
        'id',av.activity_id,'content_version',av.content_version,'title',av.title,'stage',av.stage,
        'prompt',av.prompt,'hint_levels',av.hint_levels,'explanation',av.explanation,
        'mechanism',av.mechanism,'mechanism_version',av.mechanism_version,'evaluator_version',av.evaluator_version,
        'config',av.config,'initial_state',av.initial_state,'skill_ids',to_jsonb(av.skill_ids)))) END
$$;

CREATE OR REPLACE FUNCTION private.admin_content_mutate(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); item public.activities; previous public.activity_versions;
  edit public.lesson_edits; op private.admin_audit_logs; base public.content_releases;
  rid uuid := gen_random_uuid(); version_number integer; result jsonb; manifest jsonb; is_slides boolean;
  request_hash text := encode(extensions.digest(payload::text,'sha256'),'hex');
BEGIN
  IF operation_id IS NULL OR jsonb_typeof(payload) IS DISTINCT FROM 'object' OR octet_length(payload::text)>100000
    THEN RAISE EXCEPTION 'Invalid content' USING ERRCODE='22023'; END IF;
  -- Serialize catalog publication globally so simultaneous admins cannot lose changes.
  PERFORM pg_advisory_xact_lock(750040);
  SELECT * INTO op FROM private.admin_audit_logs WHERE actor_user_id=actor AND request_id=operation_id;
  IF FOUND THEN
    IF op.action<>'lesson.save' OR op.summary->>'request_hash' IS DISTINCT FROM request_hash THEN
      RAISE EXCEPTION 'Operation mismatch' USING ERRCODE='22023'; END IF;
    RETURN op.summary->'response';
  END IF;
  IF payload->>'id' !~ '^[a-z][a-z0-9-]{0,79}$' OR payload->>'id' IS NULL
    OR NOT EXISTS(SELECT 1 FROM public.topics WHERE id=payload->>'topic_id')
    OR payload->>'status' IS NULL OR payload->>'status' NOT IN ('active','archived')
    THEN RAISE EXCEPTION 'Invalid lesson metadata' USING ERRCODE='22023'; END IF;
  SELECT * INTO item FROM public.activities WHERE id=payload->>'id';
  IF FOUND AND item.topic_id IS DISTINCT FROM payload->>'topic_id' THEN
    RAISE EXCEPTION 'Activity topic cannot change' USING ERRCODE='22023'; END IF;
  SELECT * INTO edit FROM public.lesson_edits WHERE activity_id=payload->>'id';
  IF coalesce(edit.revision,0) IS DISTINCT FROM (payload->>'revision')::int OR NOT payload ? 'revision' THEN
    RAISE EXCEPTION 'Content revision conflict' USING ERRCODE='PT409'; END IF;
  SELECT * INTO previous FROM public.activity_versions WHERE activity_id=payload->>'id' ORDER BY content_version DESC LIMIT 1;
  is_slides := coalesce(payload->>'mechanism',previous.mechanism,'reasonedChoice')='slideLesson';
  IF is_slides AND EXISTS(SELECT 1 FROM public.lesson_builder_drafts WHERE id=payload->>'id'
    AND revision IS DISTINCT FROM (payload->>'builder_revision')::int)
    THEN RAISE EXCEPTION 'Builder revision conflict' USING ERRCODE='PT409'; END IF;
  IF previous.activity_id IS NULL OR previous.evaluator_version IN (3,4) THEN
    IF (is_slides AND NOT private.valid_slide_lesson(payload->'config'))
      OR (NOT is_slides AND NOT private.valid_authored_choice(payload->'config')) THEN
      RAISE EXCEPTION 'Invalid engine configuration' USING ERRCODE='22023'; END IF;
    INSERT INTO public.activities(id,topic_id,status,created_by)
      VALUES(payload->>'id',payload->>'topic_id','active',actor) ON CONFLICT DO NOTHING;
    version_number := coalesce(previous.content_version,0)+1;
    INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,
      mechanism,mechanism_version,evaluator_version,config,initial_state,status,published_at,created_by)
      VALUES(payload->>'id',version_number,payload->>'title',payload->>'stage',payload->>'prompt',
        jsonb_build_array(payload->>'hint'),payload->>'explanation',CASE WHEN is_slides THEN 'slideLesson' ELSE 'reasonedChoice' END,1,
        CASE WHEN is_slides THEN 4 ELSE 3 END,payload->'config',
        CASE WHEN is_slides THEN private.initial_slide_state(payload->'config') ELSE '{"answer":-1,"reason":-1}'::jsonb END,'draft',NULL,actor);
    UPDATE public.activity_versions SET status='published',published_at=now()
      WHERE activity_id=payload->>'id' AND content_version=version_number;
  END IF;
  INSERT INTO public.lesson_edits(activity_id,title,stage,prompt,hint,explanation,status,sort_order)
    VALUES(payload->>'id',payload->>'title',payload->>'stage',payload->>'prompt',payload->>'hint',
      payload->>'explanation',payload->>'status',(payload->>'sort_order')::int)
    ON CONFLICT(activity_id) DO UPDATE SET title=excluded.title,stage=excluded.stage,prompt=excluded.prompt,
      hint=excluded.hint,explanation=excluded.explanation,status=excluded.status,sort_order=excluded.sort_order,
      revision=lesson_edits.revision+1,updated_at=now();
  SELECT * INTO base FROM public.content_releases WHERE status='published' ORDER BY published_at DESC,id DESC LIMIT 1;
  INSERT INTO public.content_releases(id,version_label,min_app_version,created_by)
    VALUES(rid,'admin-'||rid::text,CASE WHEN is_slides OR base.min_app_version='1.3.4' THEN '1.3.4' ELSE '1.3.3' END,actor);
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
  UPDATE public.lesson_builder_drafts SET status='published' WHERE id=payload->>'id';
  result := jsonb_build_object('release_id',rid,'id',payload->>'id','revision',coalesce(edit.revision,0)+1);
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,'admin','lesson.save','activity',payload->>'id',operation_id,
      jsonb_build_object('request_hash',request_hash,'response',result));
  RETURN result;
END $$;

CREATE OR REPLACE FUNCTION private.authored_attempt(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor(); av public.activity_versions; correct boolean; evaluation jsonb;
BEGIN
  SELECT * INTO av FROM public.activity_versions WHERE activity_id=payload->>'activity_id'
    AND content_version=(payload->>'content_version')::int AND evaluator_version IN (3,4) AND status='published';
  IF NOT FOUND OR NOT private.supported_activity(av) OR jsonb_typeof(payload->'state') IS DISTINCT FROM 'object'
    THEN RAISE EXCEPTION 'Unsupported authored activity' USING ERRCODE='22023'; END IF;
  correct := CASE WHEN av.evaluator_version=4 THEN private.evaluate_slide_lesson(av.config,payload->'state') ELSE coalesce(payload->'state'->'answer'=av.config->'answer' AND payload->'state'->'reason'=av.config->'reason',false) END;
  evaluation := jsonb_build_object('mechanism',av.mechanism,'evaluator_version',av.evaluator_version,'config',av.config,
    'initial_state',av.initial_state,'is_correct',correct,'misconception_codes','[]'::jsonb,
    'satisfied_constraints','[]'::jsonb,'feedback_key',CASE WHEN correct THEN 'correct' ELSE 'try-again' END,
    'implementation_hash',encode(extensions.digest(CASE WHEN av.evaluator_version=4 THEN 'slide-engines-v1:story-quiz-pairs-linear' ELSE 'authored-choice-v1:integer-answer-and-reason' END,'sha256'),'hex'));
  -- Actor, ownership, pinned release, retries, completions and XP use the canonical authority.
  RETURN private.learning_wire(private.learning_apply(actor,operation_id,'attempt.submit',payload,evaluation));
END $$;
NOTIFY pgrst,'reload schema';
