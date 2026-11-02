-- Run against the current Matlingo schema. Every fixture and mutation rolls back.
BEGIN;
DO $$
DECLARE a uuid := gen_random_uuid(); b uuid := gen_random_uuid();
BEGIN
  PERFORM set_config('test.admin',a::text,true);
  PERFORM set_config('test.user',b::text,true);
  PERFORM set_config('test.topic','qa-admin-'||replace(gen_random_uuid()::text,'-',''),true);
  INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
    (a,'admin-dashboard-'||a||'@example.invalid','{}'),
    (b,'user-dashboard-'||b||'@example.invalid','{}');
  UPDATE private.account_access SET role='admin' WHERE user_id=a;
  PERFORM set_config('request.jwt.claim.sub',a::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE result jsonb; op uuid := gen_random_uuid(); payload jsonb;
BEGIN
  result := public.admin_dashboard_read('overview');
  IF NOT (result ? 'users' AND result ? 'topics') THEN RAISE EXCEPTION 'Overview missing'; END IF;
  result := public.admin_dashboard_read('accounts',current_setting('test.user'),0,25);
  IF (result->>'total')::int<>1 OR result->'items'->0->>'email' IS NULL THEN RAISE EXCEPTION 'Account search failed'; END IF;
  result := public.admin_dashboard_read('accounts','',100000,25);
  IF jsonb_array_length(result->'items')<>0 THEN RAISE EXCEPTION 'Pagination failed'; END IF;
  BEGIN
    PERFORM public.admin_dashboard_read('accounts','',0,101);
    RAISE EXCEPTION 'Unbounded page accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  payload := jsonb_build_object('id',current_setting('test.topic'),'title','QA Dashboard','subject','QA','icon_key','menu_book_outlined','sort_order',1,'status','draft');
  result := public.admin_learning_mutate(op,'topic.save',payload);
  IF result<>public.admin_learning_mutate(op,'topic.save',payload) THEN RAISE EXCEPTION 'Admin retry failed'; END IF;
  result := public.admin_dashboard_read('topics',current_setting('test.topic'),0,25);
  IF (result->>'total')::int<>1 OR result->'items'->0->>'status'<>'draft' THEN RAISE EXCEPTION 'Topic search failed'; END IF;
  PERFORM public.admin_learning_mutate(gen_random_uuid(),'topic.save',payload||'{"title":"QA Updated","status":"archived"}');
  PERFORM public.admin_learning_mutate(gen_random_uuid(),'account.status',jsonb_build_object('id',current_setting('test.user'),'status','suspended'));
  result := public.admin_dashboard_read('accounts',current_setting('test.user'),0,25);
  IF result->'items'->0->>'status'<>'suspended' THEN RAISE EXCEPTION 'Suspend failed'; END IF;
  PERFORM public.admin_learning_mutate(gen_random_uuid(),'account.status',jsonb_build_object('id',current_setting('test.user'),'status','active'));
END $$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub',current_setting('test.user'),true) IS NOT NULL AS switched_to_user;
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  BEGIN
    PERFORM public.admin_dashboard_read('accounts'); RAISE EXCEPTION 'User read admin data';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.admin_learning_mutate(gen_random_uuid(),'account.status',jsonb_build_object('id',current_setting('test.user'),'status','suspended'));
    RAISE EXCEPTION 'User mutated admin data';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
UPDATE private.account_access SET status='suspended' WHERE user_id=current_setting('test.admin')::uuid;
SELECT set_config('request.jwt.claim.sub',current_setting('test.admin'),true) IS NOT NULL AS switched_to_suspended_admin;
SET LOCAL ROLE authenticated;
DO $$ BEGIN
  BEGIN PERFORM public.admin_dashboard_read('overview'); RAISE EXCEPTION 'Suspended admin read data';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
  IF has_function_privilege(current_user,'public.admin_dashboard_read(text,text,integer,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous admin read privilege'; END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
  IF NOT EXISTS(SELECT 1 FROM pg_policies WHERE schemaname='realtime' AND tablename='messages' AND policyname='matlingo_admin_receive') THEN
    RAISE EXCEPTION 'Realtime policy missing'; END IF;
  IF (SELECT count(*) FROM pg_trigger WHERE tgname='admin_dashboard_changed')<>6 THEN
    RAISE EXCEPTION 'Realtime triggers missing'; END IF;
END $$;
SELECT 'Admin read/search/pagination, CRUD, authority and realtime schema checks passed' AS result;
ROLLBACK;
