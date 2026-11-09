-- Template: tools/prepare_curriculum_replace.py embeds the versioned JSON fixture.
DO $setup$
DECLARE learner uuid:=gen_random_uuid();
BEGIN
 INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES(learner,'qa-curriculum-'||learner||'@example.invalid','{}');
 PERFORM set_config('test.learner',learner::text,true);
 PERFORM set_config('request.jwt.claim.sub',learner::text,true);
END $setup$;
SET LOCAL ROLE authenticated;
DO $qa$
DECLARE data jsonb:=$curriculum$__CURRICULUM_JSON__$curriculum$; pid uuid:=gen_random_uuid(); sid uuid; rid uuid:=current_setting('curriculum.release')::uuid; t jsonb; lesson jsonb; solution jsonb; result jsonb; body jsonb;
BEGIN
 IF jsonb_array_length(public.learning_catalog('1.3.7')->'topics')<>3 OR jsonb_array_length(public.learning_catalog('1.3.7')->'activities')<>10 THEN RAISE EXCEPTION 'Learner catalog differs'; END IF;
 IF EXISTS(SELECT 1 FROM jsonb_array_elements(public.learning_catalog('1.3.6')->'activities') x WHERE x->>'activity_id' LIKE 'studio-%') THEN RAISE EXCEPTION 'New language exposed to old app'; END IF;
 PERFORM public.learning_mutate(gen_random_uuid(),'profile.create',jsonb_build_object('id',pid,'name','QA curriculum','daily_minutes',10,'interest_topic_ids','[]'::jsonb));
 FOR t IN SELECT value FROM jsonb_array_elements(data->'topics') LOOP
  sid:=gen_random_uuid();
  PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',sid,'profile_id',pid,'topic_id',t->>'id','release_id',rid));
  FOR lesson IN SELECT value FROM jsonb_array_elements(data->'lessons') x WHERE x->>'topic_id'=t->>'id' LOOP
   SELECT jsonb_build_object('index',5,'slides',jsonb_agg(data->'solutions'->(lesson->>'id')->(x->>'id') ORDER BY ord)) INTO solution FROM jsonb_array_elements(lesson#>'{config,slides}') WITH ORDINALITY a(x,ord);
   body:=jsonb_build_object('session_id',sid,'activity_id',lesson->>'id','content_version',1,'state','{}'::jsonb);
   result:=public.authored_attempt(gen_random_uuid(),body);
   IF coalesce((result#>>'{result,attempt,is_correct}')::boolean,true) THEN RAISE EXCEPTION 'Incomplete state accepted'; END IF;
   result:=public.authored_attempt(gen_random_uuid(),body||jsonb_build_object('state',solution));
   IF NOT coalesce((result#>>'{result,attempt,is_correct}')::boolean,false) THEN RAISE EXCEPTION 'Solution rejected: %',lesson->>'id'; END IF;
  END LOOP;
  result:=public.learning_mutate(gen_random_uuid(),'session.complete',jsonb_build_object('session_id',sid));
  IF (result#>>'{result,xp_awarded}')::int<>30 THEN RAISE EXCEPTION 'Completion reward differs'; END IF;
 END LOOP;
 BEGIN PERFORM public.admin_content_mutate(gen_random_uuid(),data->'lessons'->0); RAISE EXCEPTION 'Learner authored content'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $qa$;
RESET ROLE;
SELECT 'PASS: 3-topic catalog, version gating, 10 correct + 10 rejected attempts, 3 completions / 90 XP and Admin denial; all rolled back' result;
