-- Render with tools/prepare_studio_sync_smoke.py, then run the generated SQL.
-- Every fixture account, release, learning session and XP record rolls back.
BEGIN;
DO $setup$
DECLARE actor uuid:=gen_random_uuid(); learner uuid:=gen_random_uuid();
BEGIN
 INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
 (actor,'qa-studio-admin-'||actor||'@example.invalid','{}'),
 (learner,'qa-studio-user-'||learner||'@example.invalid','{}');
 UPDATE private.account_access SET role='admin' WHERE user_id=actor;
 PERFORM set_config('qa.actor',actor::text,true);
 PERFORM set_config('qa.learner',learner::text,true);
 PERFORM set_config('qa.topic','qa-sync-'||replace(actor::text,'-',''),true);
 PERFORM set_config('request.jwt.claim.sub',actor::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
END $setup$;
SET LOCAL ROLE authenticated;
DO $test$
DECLARE fixtures jsonb:=$fixtures$__STUDIO_ENGINE_FIXTURES__$fixtures$;
 topic text:=current_setting('qa.topic'); body jsonb; cfg jsonb; result jsonb;
 rid uuid; pid uuid:=gen_random_uuid(); sid uuid:=gen_random_uuid(); op uuid;
 part jsonb; slides jsonb; solution jsonb; catalogue jsonb; group_index integer;
 lesson text; icons text[]:=ARRAY['cube','headphones','robot'];
BEGIN
 PERFORM public.admin_learning_mutate(gen_random_uuid(),'topic.save',jsonb_build_object(
   'id',topic,'title','QA Studio sync','subject','QA','status','active','sort_order',10000,'icon_key','functions'));
 FOR group_index IN 0..2 LOOP
  SELECT jsonb_agg(jsonb_build_object('id','qa-slide-'||ord,'engine',f->>'engine',
    'locked',true,'title','QA '||(f->>'engine'),'prompt','Complete the interaction.',
    'hint','Use the displayed controls.','explanation','The target is satisfied.','config',f->'config') ORDER BY ord)
    INTO slides FROM jsonb_array_elements(fixtures) WITH ORDINALITY a(f,ord)
    WHERE ord>group_index*12 AND ord<=group_index*12+12;
  cfg:=jsonb_build_object('schema_version',1,'lesson_icon',icons[group_index+1],'slides',slides);
  body:=jsonb_build_object('id',topic||'-'||group_index,'topic_id',topic,'title','QA engines '||group_index,
   'stage','QA','prompt','Verify published Studio content.','hint','Use each control.',
   'explanation','All engines and icon metadata round-trip.','sort_order',group_index,
   'status','active','mechanism','slideLesson','config',cfg,'revision',0);
  op:=gen_random_uuid();
  result:=public.admin_builder_save(op,body);
  IF public.admin_builder_save(op,body) IS DISTINCT FROM result THEN RAISE EXCEPTION 'Draft retry differs'; END IF;
  op:=gen_random_uuid();
  body:=body||jsonb_build_object('builder_revision',(result->>'revision')::int);
  result:=public.admin_content_mutate(op,body);
  IF public.admin_content_mutate(op,body) IS DISTINCT FROM result THEN RAISE EXCEPTION 'Publication retry differs'; END IF;
  rid:=(result->>'release_id')::uuid;
 END LOOP;
 PERFORM set_config('request.jwt.claim.sub',current_setting('qa.learner'),true);
 catalogue:=public.learning_catalog('1.3.8');
 IF (SELECT count(*) FROM jsonb_array_elements(catalogue->'activities') a WHERE a->>'topic_id'=topic)<>3 THEN RAISE EXCEPTION 'Missing published lessons'; END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.6')->'activities') a WHERE a->>'topic_id'=topic) THEN RAISE EXCEPTION 'New engines exposed to old app'; END IF;
 PERFORM public.learning_mutate(gen_random_uuid(),'profile.create',jsonb_build_object('id',pid,'name','QA sync','daily_minutes',10,'interest_topic_ids','[]'::jsonb));
 PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',sid,'profile_id',pid,'topic_id',topic,'release_id',rid));
 FOR group_index IN 0..2 LOOP
  lesson:=topic||'-'||group_index;
  SELECT a INTO part FROM jsonb_array_elements(catalogue->'activities') a WHERE a->>'activity_id'=lesson;
  IF part#>>'{config,lesson_icon}' IS DISTINCT FROM icons[group_index+1] THEN RAISE EXCEPTION 'Lesson icon lost'; END IF;
  SELECT jsonb_build_object('index',least(11,jsonb_array_length(part#>'{config,slides}')-1),
   'slides',jsonb_agg(f->'correct' ORDER BY ord)) INTO solution
   FROM jsonb_array_elements(fixtures) WITH ORDINALITY a(f,ord)
   WHERE ord>group_index*12 AND ord<=group_index*12+12;
  body:=jsonb_build_object('session_id',sid,'activity_id',lesson,'content_version',1,'state','{}'::jsonb);
  result:=public.authored_attempt(gen_random_uuid(),body);
  IF coalesce((result#>>'{result,attempt,is_correct}')::boolean,true) THEN RAISE EXCEPTION 'Incomplete state accepted'; END IF;
  result:=public.authored_attempt(gen_random_uuid(),body||jsonb_build_object('state',solution));
  IF NOT coalesce((result#>>'{result,attempt,is_correct}')::boolean,false) THEN RAISE EXCEPTION 'Engine solution rejected: %',lesson; END IF;
 END LOOP;
 op:=gen_random_uuid();
 result:=public.learning_mutate(op,'session.complete',jsonb_build_object('session_id',sid));
 IF (result#>>'{result,xp_awarded}')::int<>30 THEN RAISE EXCEPTION 'Incorrect reward'; END IF;
 IF public.learning_mutate(op,'session.complete',jsonb_build_object('session_id',sid)) IS DISTINCT FROM result THEN RAISE EXCEPTION 'Completion retry differs'; END IF;
 BEGIN
  PERFORM public.admin_content_mutate(gen_random_uuid(),body);
  RAISE EXCEPTION 'Learner published content';
 EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN
  UPDATE public.lesson_builder_drafts SET status='published' WHERE id=topic||'-0';
  RAISE EXCEPTION 'Learner bypassed RPC';
 EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $test$;
RESET ROLE;
SELECT 'PASS: 33 engines, 3 lesson icons, draft/publication/completion retries, catalogue gating, canonical 30 XP and learner write denial; rollback' result;
ROLLBACK;
