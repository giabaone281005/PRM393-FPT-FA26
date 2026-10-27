-- Transactional integration tests: all Auth/application/Storage fixtures roll back.
BEGIN;
DO $$
DECLARE a uuid := gen_random_uuid(); b uuid := gen_random_uuid(); admin uuid := gen_random_uuid(); asset_id uuid;
BEGIN
  INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
    (a,'learning-a-'||a||'@example.invalid','{}'),
    (b,'learning-b-'||b||'@example.invalid','{}'),
    (admin,'learning-admin-'||admin||'@example.invalid','{}');
  UPDATE private.account_access SET role='admin' WHERE user_id=admin;
  PERFORM set_config('test.a',a::text,true);
  PERFORM set_config('test.b',b::text,true);
  PERFORM set_config('test.admin',admin::text,true);
  PERFORM set_config('test.profile',gen_random_uuid()::text,true);
  PERFORM set_config('test.session',gen_random_uuid()::text,true);
  PERFORM set_config('test.session2',gen_random_uuid()::text,true);
  PERFORM set_config('test.draft',gen_random_uuid()::text,true);
  INSERT INTO public.assets(bucket_id,object_path,kind,mime_type,byte_size,sha256,status,created_by)
    VALUES('learning-assets',admin::text||'/'||repeat('b',64)||'.png','image','image/png',12,repeat('b',64),'ready',admin)
    RETURNING id INTO asset_id;
  PERFORM set_config('test.asset',asset_id::text,true);
  PERFORM set_config('test.release',(SELECT id::text FROM public.content_releases WHERE version_label='frontend-baseline-2026-10-26'),true);
  PERFORM set_config('request.jwt.claim.sub',admin::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE result jsonb; op uuid := gen_random_uuid(); payload jsonb; av public.activity_versions;
BEGIN
  IF (SELECT status FROM public.content_releases WHERE id=current_setting('test.release')::uuid)='draft' THEN
    result := public.admin_learning_mutate(op,'release.publish',jsonb_build_object('id',current_setting('test.release')));
    IF result->>'status'<>'published' THEN RAISE EXCEPTION 'Admin publish failed'; END IF;
    IF public.admin_learning_mutate(op,'release.publish',jsonb_build_object('id',current_setting('test.release')))<>result
      THEN RAISE EXCEPTION 'Admin receipt retry failed'; END IF;
  END IF;
  op := gen_random_uuid();
  payload := jsonb_build_object('id','smoke-topic-'||op,'title','Smoke topic','subject','Test','icon_key','hub_outlined');
  result := public.admin_learning_mutate(op,'topic.save',payload);
  IF result<>public.admin_learning_mutate(op,'topic.save',payload) THEN RAISE EXCEPTION 'Admin request-hash retry failed'; END IF;
  BEGIN
    PERFORM public.admin_learning_mutate(op,'topic.save',payload||'{"title":"Changed"}');
    RAISE EXCEPTION 'Admin request ID reused with new payload';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  SELECT * INTO av FROM public.activity_versions WHERE activity_id='logic-balance' AND content_version=1;
  payload := to_jsonb(av)||jsonb_build_object('id','logic-balance','topic_id','logic','content_version',2);
  result := public.admin_learning_mutate(gen_random_uuid(),'activity.save',payload);
  IF result->>'status'<>'draft' THEN RAISE EXCEPTION 'New activity version is not draft'; END IF;
  op := gen_random_uuid();
  payload := jsonb_build_object('activity_id','logic-balance','content_version',2,'slot','cover','asset_id',current_setting('test.asset'),'required',true);
  result := public.admin_link_learning_asset(op,payload);
  IF result<>public.admin_link_learning_asset(op,payload) THEN RAISE EXCEPTION 'Asset attachment retry failed'; END IF;
  BEGIN
    PERFORM public.admin_link_learning_asset(gen_random_uuid(),payload||'{"content_version":1}');
    RAISE EXCEPTION 'Published attachment modified';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  op := gen_random_uuid();
  result := public.admin_learning_mutate(gen_random_uuid(),'release.create',jsonb_build_object('id',op,
    'version_label','unsupported-smoke-'||op,'min_app_version','1.3.0','activities',jsonb_build_array(
      jsonb_build_object('activity_id','logic-balance','content_version',2,'topic_id','logic','position',0,'required',true))));
  BEGIN
    PERFORM public.admin_learning_mutate(gen_random_uuid(),'release.publish',jsonb_build_object('id',op));
    RAISE EXCEPTION 'Unsupported evaluator content version published';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN
    PERFORM public.learning_mutate(gen_random_uuid(),'profile.create','{}');
    RAISE EXCEPTION 'Admin accessed learner mutation';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT set_config('request.jwt.claim.sub',current_setting('test.a'),true) IS NOT NULL AS learner_identity;
DO $$
DECLARE receipt jsonb; repeat_receipt jsonb; op uuid := gen_random_uuid(); payload jsonb; page jsonb;
BEGIN
  payload := jsonb_build_object('id',current_setting('test.profile'),'name','Smoke learner','daily_minutes',10,
    'interest_topic_ids',jsonb_build_array('logic'),'onboarded',true);
  receipt := public.learning_mutate(op,'profile.create',payload);
  IF jsonb_typeof(receipt->'result'->'revision')<>'string' THEN RAISE EXCEPTION 'Profile revision lost precision'; END IF;
  repeat_receipt := public.learning_mutate(op,'profile.create',payload);
  IF receipt<>repeat_receipt OR receipt->>'revision'<>'1' THEN RAISE EXCEPTION 'Mutation retry failed'; END IF;
  BEGIN
    PERFORM public.learning_mutate(op,'profile.create',payload||'{"name":"changed"}');
    RAISE EXCEPTION 'ID reused with new payload';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN
    PERFORM public.learning_mutate(gen_random_uuid(),'profile.update',payload||'{"expected_revision":99}');
    RAISE EXCEPTION 'Stale profile overwritten';
  EXCEPTION WHEN SQLSTATE 'PT409' THEN NULL; END;
  BEGIN
    PERFORM public.admin_learning_read(); RAISE EXCEPTION 'User read admin API';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.record_learning_attempt(current_setting('test.a')::uuid,gen_random_uuid(),'{}','{"is_correct":true}');
    RAISE EXCEPTION 'Client forged evaluator output';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    INSERT INTO public.xp_ledger(profile_id,owner_user_id,reward_key,topic_id,completion_id,source)
      VALUES(current_setting('test.profile')::uuid,current_setting('test.a')::uuid,'x','logic',gen_random_uuid(),'first_completion');
    RAISE EXCEPTION 'Direct client XP write accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  receipt := public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',current_setting('test.session'),
    'profile_id',current_setting('test.profile'),'release_id',current_setting('test.release'),'topic_id','logic'));
  IF receipt->'result'->'session'->>'status'<>'in_progress' THEN RAISE EXCEPTION 'Session start failed'; END IF;
  PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',current_setting('test.session2'),
    'profile_id',current_setting('test.profile'),'release_id',current_setting('test.release'),'topic_id','logic'));
  BEGIN
    PERFORM public.learning_mutate(gen_random_uuid(),'session.complete',jsonb_build_object('session_id',current_setting('test.session')));
    RAISE EXCEPTION 'Unsolved session completed';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  payload := jsonb_build_object('id',current_setting('test.draft'),'session_id',current_setting('test.session'),
    'activity_id','logic-balance','expected_revision',0,'snapshot','{"blocks":1}'::jsonb);
  receipt := public.learning_mutate(gen_random_uuid(),'draft.save',payload);
  BEGIN
    PERFORM public.learning_mutate(gen_random_uuid(),'draft.save',payload||'{"snapshot":{"blocks":2}}');
    RAISE EXCEPTION 'Stale draft overwritten';
  EXCEPTION WHEN SQLSTATE 'PT409' THEN NULL; END;
  receipt := public.learning_mutate(gen_random_uuid(),'event.record',jsonb_build_object('session_id',current_setting('test.session'),
    'activity_id','logic-balance','event_type','active_time','active_ms',5000));
  page := public.learning_changes(0,-1,NULL,1);
  IF NOT (page->>'has_more')::boolean OR jsonb_array_length(page->'changes')<>1 THEN RAISE EXCEPTION 'Sync page failed'; END IF;
  PERFORM set_config('test.high_water',page->>'high_water',true);
  IF public.learning_catalog('1.3.0')->'release'->>'status'<>'published' THEN RAISE EXCEPTION 'Catalog unavailable'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub',current_setting('test.b'),true) IS NOT NULL AS different_learner;
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM public.learner_profiles WHERE id=current_setting('test.profile')::uuid)
    OR jsonb_array_length(public.learning_changes()->'changes')<>0 THEN RAISE EXCEPTION 'Cross-account data leaked'; END IF;
  BEGIN
    PERFORM public.learning_progress(current_setting('test.profile')::uuid); RAISE EXCEPTION 'Cross-account report exposed';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.learning_mutate(gen_random_uuid(),'session.abandon',jsonb_build_object('session_id',current_setting('test.session')));
    RAISE EXCEPTION 'Cross-account session changed';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
-- The service-only route receives evaluator output generated from the compiled
-- evaluator in evaluator_solutions.json (also verified against Dart in CI).
INSERT INTO storage.objects(bucket_id,name,metadata) VALUES('user-avatars',
  current_setting('test.a')||'/'||repeat('a',64)||'.png','{"size":12,"mimetype":"image/png"}');
SELECT set_config('request.jwt.claim.role','service_role',true) IS NOT NULL AS server_identity;
SET LOCAL ROLE service_role;
DO $$
DECLARE states jsonb := '{"logic-balance":{"blocks":4},"logic-remove":{"pairs":3},"logic-gears":{"turns":2},"logic-invariant":{"pairs":5},"logic-hidden":{"blocks":6},"logic-counterexample":{"a":true,"b":false}}';
  item record; av public.activity_versions; ev private.evaluator_versions; payload jsonb; evaluation jsonb; receipt jsonb; op uuid; sid uuid;
BEGIN
  payload := jsonb_build_object('bucket_id','user-avatars','object_path',current_setting('test.a')||'/'||repeat('a',64)||'.png',
    'sha256',repeat('a',64),'mime_type','image/png','byte_size',12);
  receipt := public.register_learning_asset(current_setting('test.a')::uuid,payload);
  IF receipt->>'status'<>'ready' OR receipt<>public.register_learning_asset(current_setting('test.a')::uuid,payload)
    THEN RAISE EXCEPTION 'Asset registration/retry failed'; END IF;
  BEGIN
    PERFORM public.register_learning_asset(current_setting('test.a')::uuid,payload||'{"byte_size":13}');
    RAISE EXCEPTION 'Mismatched storage metadata accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  FOREACH sid IN ARRAY ARRAY[current_setting('test.session')::uuid,current_setting('test.session2')::uuid] LOOP
   FOR item IN SELECT key,value FROM jsonb_each(states) LOOP
    SELECT * INTO av FROM public.activity_versions WHERE activity_id=item.key AND content_version=1;
    SELECT * INTO ev FROM private.evaluator_versions WHERE mechanism=av.mechanism AND version=av.evaluator_version;
    payload := jsonb_build_object('session_id',sid,'activity_id',item.key,'content_version',1,'state',item.value);
    evaluation := jsonb_build_object('implementation_hash',ev.implementation_hash,'mechanism',av.mechanism,
      'evaluator_version',av.evaluator_version,'config',av.config,'initial_state',av.initial_state,
      'is_correct',true,'misconception_codes','[]'::jsonb,'satisfied_constraints','[]'::jsonb,'feedback_key','correct');
    op := gen_random_uuid();
    receipt := public.record_learning_attempt(current_setting('test.a')::uuid,op,payload,evaluation);
    IF receipt<>public.record_learning_attempt(current_setting('test.a')::uuid,op,payload,evaluation) THEN
      RAISE EXCEPTION 'Attempt retry changed'; END IF;
    BEGIN
      PERFORM public.record_learning_attempt(current_setting('test.a')::uuid,gen_random_uuid(),payload,
        evaluation||'{"implementation_hash":"wrong"}');
      RAISE EXCEPTION 'Unknown evaluator accepted';
    EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
   END LOOP;
  END LOOP;
END $$;
RESET ROLE;
SELECT set_config('request.jwt.claim.role','authenticated',true) IS NOT NULL AS user_role;
SELECT set_config('request.jwt.claim.sub',current_setting('test.a'),true) IS NOT NULL AS original_learner;
SET LOCAL ROLE authenticated;
DO $$
DECLARE receipt jsonb; op uuid := gen_random_uuid(); page jsonb; r bigint := 0; i int := -1; seen int := 0; n int; high bigint;
BEGIN
  receipt := public.learning_mutate(op,'session.complete',jsonb_build_object('session_id',current_setting('test.session')));
  IF receipt->'result'->>'xp_awarded'<>'30' OR receipt->'result'->'session'->>'status'<>'verified'
    THEN RAISE EXCEPTION 'Completion/XP failed'; END IF;
  IF receipt<>public.learning_mutate(op,'session.complete',jsonb_build_object('session_id',current_setting('test.session')))
    THEN RAISE EXCEPTION 'Completion retry changed'; END IF;
  receipt := public.learning_mutate(gen_random_uuid(),'session.complete',jsonb_build_object('session_id',current_setting('test.session2')));
  IF receipt->'result'->>'xp_awarded'<>'0' THEN RAISE EXCEPTION 'Second session awarded duplicate XP'; END IF;
  IF public.learning_progress(current_setting('test.profile')::uuid)->>'verified_xp'<>'30'
    OR (SELECT count(*) FROM public.xp_ledger WHERE profile_id=current_setting('test.profile')::uuid)<>1
    THEN RAISE EXCEPTION 'Duplicate reward'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.assets WHERE owner_user_id=current_setting('test.a')::uuid) THEN
    RAISE EXCEPTION 'Owner cannot read avatar'; END IF;
  LOOP
    page := public.learning_changes(r,i,high,1);
    high := (page->>'high_water')::bigint;
    seen := seen+jsonb_array_length(page->'changes');
    r := (page->>'next_revision')::bigint; i := (page->>'next_index')::int;
    EXIT WHEN NOT (page->>'has_more')::boolean;
    IF seen>100 THEN RAISE EXCEPTION 'Cursor stalled'; END IF;
  END LOOP;
  -- The completion transaction has three entities; one-row pages must retain all.
  IF seen<20 THEN RAISE EXCEPTION 'Sync missed rows: %',seen; END IF;
  PERFORM public.learning_mutate(gen_random_uuid(),'profile.delete',jsonb_build_object('id',current_setting('test.profile'),'expected_revision',1));
  BEGIN
    PERFORM public.learning_mutate(gen_random_uuid(),'session.start',jsonb_build_object('id',gen_random_uuid(),
      'profile_id',current_setting('test.profile'),'release_id',current_setting('test.release'),'topic_id','logic'));
    RAISE EXCEPTION 'Deleted profile resurrected';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
UPDATE private.account_access SET status='suspended' WHERE user_id=current_setting('test.a')::uuid;
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  BEGIN PERFORM public.learning_changes(); RAISE EXCEPTION 'Suspended user synced';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
  IF has_function_privilege(current_user,'public.learning_mutate(uuid,text,jsonb)','EXECUTE')
    OR has_function_privilege(current_user,'public.learning_changes(bigint,integer,bigint,integer)','EXECUTE')
    OR has_function_privilege(current_user,'public.record_learning_attempt(uuid,uuid,jsonb,jsonb)','EXECUTE')
    OR has_function_privilege(current_user,'public.admin_learning_mutate(uuid,text,jsonb)','EXECUTE')
  THEN RAISE EXCEPTION 'Anonymous API privilege exposed'; END IF;
END $$;
SELECT 'learning API ownership, evaluator authority, completion/XP, cursor, tombstone, admin and asset checks passed' AS result;
ROLLBACK;
