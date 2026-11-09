-- Enable versioned editing of existing reasoned-choice lessons; preserve compiled engines.
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
  -- Packaged evaluators remain immutable; reasonedChoice can migrate to the
  -- declarative authored evaluator in a new version without altering old sessions.
  IF previous.activity_id IS NOT NULL AND previous.evaluator_version NOT IN (3,4)
    AND previous.mechanism<>'reasonedChoice'
    AND (admin_content_mutate.payload->'config' IS DISTINCT FROM previous.config
      OR admin_content_mutate.payload->>'mechanism' IS DISTINCT FROM previous.mechanism)
    THEN RAISE EXCEPTION 'Packaged engine configuration is immutable' USING ERRCODE='22023'; END IF;
  IF previous.activity_id IS NULL OR previous.evaluator_version IN (3,4)
    OR (previous.mechanism='reasonedChoice' AND admin_content_mutate.payload->>'mechanism'='reasonedChoice') THEN
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
    VALUES(rid,'admin-'||rid::text,CASE WHEN string_to_array(base.min_app_version,'.')::int[]>=ARRAY[1,3,5] THEN base.min_app_version WHEN is_slides THEN '1.3.5' WHEN string_to_array(base.min_app_version,'.')::int[]>=ARRAY[1,3,3] THEN base.min_app_version ELSE '1.3.3' END,actor);
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
