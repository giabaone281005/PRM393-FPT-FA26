-- Additive CMS. Existing evaluator implementations and published versions stay immutable.
CREATE TABLE IF NOT EXISTS public.lesson_edits (
  activity_id text PRIMARY KEY REFERENCES public.activities(id),
  title text NOT NULL CHECK(length(btrim(title)) BETWEEN 1 AND 160),
  stage text NOT NULL, prompt text NOT NULL CHECK(length(btrim(prompt)) BETWEEN 1 AND 10000),
  hint text NOT NULL CHECK(length(hint) BETWEEN 1 AND 3000),
  explanation text NOT NULL CHECK(length(explanation) BETWEEN 1 AND 10000),
  status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','archived')),
  sort_order integer NOT NULL DEFAULT 0 CHECK(sort_order BETWEEN 0 AND 100000),
  revision integer NOT NULL DEFAULT 1,
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.lesson_edits ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.lesson_edits FROM anon,authenticated;
GRANT SELECT ON public.lesson_edits TO authenticated;
DROP POLICY IF EXISTS admin_read ON public.lesson_edits;
CREATE POLICY admin_read ON public.lesson_edits FOR SELECT TO authenticated USING(private.has_role('admin'));

INSERT INTO private.evaluator_versions(mechanism,version,handler_key,implementation_hash,input_schema,status)
VALUES('reasonedChoice',3,'postgres:authored-choice-v1',
 encode(extensions.digest('authored-choice-v1:integer-answer-and-reason','sha256'),'hex'),
 '{"kind":"authored-choice-v1"}','active') ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION private.valid_authored_choice(c jsonb) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
BEGIN
  IF jsonb_typeof(c) IS DISTINCT FROM 'object' OR jsonb_typeof(c->'choices') IS DISTINCT FROM 'array'
    OR jsonb_typeof(c->'reasons') IS DISTINCT FROM 'array' THEN RETURN false; END IF;
  IF jsonb_array_length(c->'choices') NOT BETWEEN 2 AND 8 OR jsonb_array_length(c->'reasons') NOT BETWEEN 2 AND 8
    OR c->>'answer' !~ '^\d+$' OR c->>'reason' !~ '^\d+$'
    OR NOT c ?& ARRAY['answer','reason'] THEN RETURN false; END IF;
  RETURN (c->>'answer')::int < jsonb_array_length(c->'choices')
    AND (c->>'reason')::int < jsonb_array_length(c->'reasons')
    AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements((c->'choices')||(c->'reasons')) x
      WHERE jsonb_typeof(x)<>'string' OR length(btrim(x#>>'{}')) NOT BETWEEN 1 AND 2000)
    AND length(coalesce(c->>'knowledge',''))<=10000 AND length(coalesce(c->>'source',''))<=2000;
EXCEPTION WHEN numeric_value_out_of_range THEN RETURN false;
END $$;
REVOKE ALL ON FUNCTION private.valid_authored_choice(jsonb) FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION private.supported_activity(av public.activity_versions)
RETURNS boolean LANGUAGE sql STABLE SET search_path='' AS $$
  SELECT CASE WHEN av.evaluator_version=3 THEN av.mechanism='reasonedChoice'
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

CREATE OR REPLACE FUNCTION private.admin_content_read(topic text) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); result jsonb;
BEGIN
  SELECT coalesce(jsonb_agg(to_jsonb(v)||jsonb_build_object('id',a.id,'topic_id',a.topic_id,
    'title',coalesce(e.title,v.title),'stage',coalesce(e.stage,v.stage),'prompt',coalesce(e.prompt,v.prompt),
    'hint_levels',CASE WHEN e.hint IS NOT NULL THEN jsonb_build_array(e.hint) ELSE v.hint_levels END,
    'explanation',coalesce(e.explanation,v.explanation),'editor_status',coalesce(e.status,'active'),
    'sort_order',coalesce(e.sort_order,ra.position,0),'revision',coalesce(e.revision,0))
    ORDER BY coalesce(e.sort_order,ra.position,0),a.id),'[]') INTO result
    FROM public.activities a
    JOIN LATERAL (SELECT * FROM public.activity_versions x WHERE x.activity_id=a.id ORDER BY content_version DESC LIMIT 1) v ON true
    LEFT JOIN public.lesson_edits e ON e.activity_id=a.id
    LEFT JOIN public.release_activities ra ON ra.activity_id=a.id AND ra.release_id=(
      SELECT id FROM public.content_releases WHERE status='published' ORDER BY published_at DESC,id DESC LIMIT 1)
    WHERE a.topic_id=topic;
  RETURN jsonb_build_object('items',result,'total',jsonb_array_length(result));
END $$;
REVOKE ALL ON FUNCTION private.admin_content_read(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_content_read(text) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_content_read(topic text) RETURNS jsonb
LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_content_read(topic) $$;
REVOKE ALL ON FUNCTION public.admin_content_read(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_content_read(text) TO authenticated;

CREATE OR REPLACE FUNCTION private.admin_content_mutate(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('admin'); item public.activities; previous public.activity_versions;
  edit public.lesson_edits; op private.admin_audit_logs; base public.content_releases;
  rid uuid := gen_random_uuid(); version_number integer; result jsonb; manifest jsonb;
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
  IF previous.activity_id IS NULL OR previous.evaluator_version=3 THEN
    IF NOT private.valid_authored_choice(payload->'config') THEN RAISE EXCEPTION 'Invalid choice configuration' USING ERRCODE='22023'; END IF;
    INSERT INTO public.activities(id,topic_id,status,created_by)
      VALUES(payload->>'id',payload->>'topic_id','active',actor) ON CONFLICT DO NOTHING;
    version_number := coalesce(previous.content_version,0)+1;
    INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,
      mechanism,mechanism_version,evaluator_version,config,initial_state,status,published_at,created_by)
      VALUES(payload->>'id',version_number,payload->>'title',payload->>'stage',payload->>'prompt',
        jsonb_build_array(payload->>'hint'),payload->>'explanation','reasonedChoice',1,3,payload->'config',
        '{"answer":-1,"reason":-1}','draft',NULL,actor);
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
    VALUES(rid,'admin-'||rid::text,'1.3.3',actor);
  INSERT INTO public.release_activities(release_id,activity_id,content_version,topic_id,position,required)
    SELECT rid,a.id,v.content_version,a.topic_id,
      (row_number() OVER(PARTITION BY a.topic_id ORDER BY coalesce(e.sort_order,ra.position,0),a.id)-1)::int,true
    FROM public.activities a
    JOIN LATERAL (SELECT * FROM public.activity_versions x WHERE x.activity_id=a.id AND x.status='published'
      ORDER BY content_version DESC LIMIT 1) v ON true
    LEFT JOIN public.lesson_edits e ON e.activity_id=a.id
    LEFT JOIN public.release_activities ra ON ra.release_id=base.id AND ra.activity_id=a.id
    WHERE coalesce(e.status,'active')='active' AND (ra.activity_id IS NOT NULL OR v.evaluator_version=3 OR e.status='active');
  SELECT jsonb_agg(to_jsonb(ra) ORDER BY topic_id,position) INTO manifest FROM public.release_activities ra WHERE release_id=rid;
  UPDATE public.content_releases SET status='published',published_at=clock_timestamp(),
    manifest_hash=encode(extensions.digest(manifest::text,'sha256'),'hex') WHERE id=rid;
  result := jsonb_build_object('release_id',rid,'id',payload->>'id','revision',coalesce(edit.revision,0)+1);
  INSERT INTO private.admin_audit_logs(actor_user_id,actor_kind,action,target_type,target_id,request_id,summary)
    VALUES(actor,'admin','lesson.save','activity',payload->>'id',operation_id,
      jsonb_build_object('request_hash',request_hash,'response',result));
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.admin_content_mutate(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_content_mutate(uuid,jsonb) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_content_mutate(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_content_mutate(operation_id,payload) $$;
REVOKE ALL ON FUNCTION public.admin_content_mutate(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_content_mutate(uuid,jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION private.authored_attempt(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor(); av public.activity_versions; correct boolean; evaluation jsonb;
BEGIN
  SELECT * INTO av FROM public.activity_versions WHERE activity_id=payload->>'activity_id'
    AND content_version=(payload->>'content_version')::int AND evaluator_version=3 AND status='published';
  IF NOT FOUND OR NOT private.supported_activity(av) OR jsonb_typeof(payload->'state') IS DISTINCT FROM 'object'
    THEN RAISE EXCEPTION 'Unsupported authored activity' USING ERRCODE='22023'; END IF;
  correct := coalesce(payload->'state'->'answer'=av.config->'answer' AND payload->'state'->'reason'=av.config->'reason',false);
  evaluation := jsonb_build_object('mechanism',av.mechanism,'evaluator_version',3,'config',av.config,
    'initial_state',av.initial_state,'is_correct',correct,'misconception_codes','[]'::jsonb,
    'satisfied_constraints','[]'::jsonb,'feedback_key',CASE WHEN correct THEN 'correct' ELSE 'try-again' END,
    'implementation_hash',encode(extensions.digest('authored-choice-v1:integer-answer-and-reason','sha256'),'hex'));
  -- Actor, ownership, pinned release, retries, completions and XP use the canonical authority.
  RETURN private.learning_wire(private.learning_apply(actor,operation_id,'attempt.submit',payload,evaluation));
END $$;
REVOKE ALL ON FUNCTION private.authored_attempt(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.authored_attempt(uuid,jsonb) TO authenticated;
CREATE OR REPLACE FUNCTION public.authored_attempt(operation_id uuid,payload jsonb) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.authored_attempt(operation_id,payload) $$;
REVOKE ALL ON FUNCTION public.authored_attempt(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.authored_attempt(uuid,jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION private.learning_catalog(app_version text) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor(); release public.content_releases; modern boolean;
BEGIN
  IF app_version IS NULL OR app_version !~ '^\d+\.\d+\.\d+$' THEN RAISE EXCEPTION 'Invalid app version' USING ERRCODE='22023'; END IF;
  modern := string_to_array(app_version,'.')::int[]>=ARRAY[1,3,3];
  SELECT * INTO release FROM public.content_releases r WHERE r.status='published'
    AND string_to_array(r.min_app_version,'.')::int[]<=string_to_array(app_version,'.')::int[]
    ORDER BY published_at DESC,id DESC LIMIT 1;
  RETURN jsonb_build_object('release',to_jsonb(release),
    'topics',(SELECT coalesce(jsonb_agg(to_jsonb(t) ORDER BY t.sort_order,t.id),'[]') FROM public.topics t
      WHERE EXISTS(SELECT 1 FROM public.release_activities ra WHERE ra.release_id=release.id AND ra.topic_id=t.id)),
    'activities',(SELECT coalesce(jsonb_agg(to_jsonb(av)||jsonb_build_object('topic_id',ra.topic_id,'position',ra.position,'required',ra.required)
      ||CASE WHEN modern AND e.activity_id IS NOT NULL THEN jsonb_build_object('title',e.title,'stage',e.stage,
        'prompt',e.prompt,'hint_levels',jsonb_build_array(e.hint),'explanation',e.explanation) ELSE '{}'::jsonb END
      ORDER BY ra.topic_id,ra.position),'[]') FROM public.release_activities ra
      JOIN public.activity_versions av ON av.activity_id=ra.activity_id AND av.content_version=ra.content_version
      LEFT JOIN public.lesson_edits e ON e.activity_id=av.activity_id WHERE ra.release_id=release.id));
END $$;

CREATE OR REPLACE FUNCTION private.notify_learning_catalog() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  PERFORM realtime.send('{"source":"catalog"}'::jsonb,'changed','matlingo:catalog',true);
  RETURN NULL;
END $$;
REVOKE ALL ON FUNCTION private.notify_learning_catalog() FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS learning_catalog_changed ON public.topics;
CREATE TRIGGER learning_catalog_changed AFTER INSERT OR UPDATE ON public.topics
  FOR EACH STATEMENT EXECUTE FUNCTION private.notify_learning_catalog();
DROP TRIGGER IF EXISTS learning_catalog_changed ON public.content_releases;
CREATE TRIGGER learning_catalog_changed AFTER INSERT OR UPDATE ON public.content_releases
  FOR EACH STATEMENT EXECUTE FUNCTION private.notify_learning_catalog();
DROP TRIGGER IF EXISTS admin_dashboard_changed ON public.lesson_edits;
CREATE TRIGGER admin_dashboard_changed AFTER INSERT OR UPDATE ON public.lesson_edits
  FOR EACH STATEMENT EXECUTE FUNCTION private.notify_admin_dashboard();
DROP POLICY IF EXISTS matlingo_catalog_receive ON realtime.messages;
CREATE POLICY matlingo_catalog_receive ON realtime.messages FOR SELECT TO authenticated
  USING(extension='broadcast' AND (SELECT realtime.topic())='matlingo:catalog'
    AND (private.has_role('user') OR private.has_role('admin')));
NOTIFY pgrst,'reload schema';
