BEGIN;
DO $$
DECLARE a uuid := gen_random_uuid(); b uuid := gen_random_uuid(); payload jsonb;
BEGIN
  PERFORM set_config('test.progress_a',a::text,true);
  PERFORM set_config('test.progress_b',b::text,true);
  INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
    (a,'progress-a-'||a||'@example.invalid','{}'),(b,'progress-b-'||b||'@example.invalid','{}');
  payload := jsonb_build_object('version',3,'profile',jsonb_build_object('id','legacy-a','name','Legacy'),'learning','{}'::jsonb);
  INSERT INTO public.mobile_profile_backups(owner_user_id,profile_key,payload,updated_at) VALUES(a,'legacy-a',payload,now());
  payload := jsonb_set(payload,'{profile,id}','"legacy-b"');
  INSERT INTO public.mobile_profile_backups(owner_user_id,profile_key,payload,updated_at) VALUES(a,'legacy-b',payload,now()-interval '1 day');
  PERFORM set_config('request.jwt.claim.sub',a::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE row jsonb; payload jsonb;
BEGIN
  row := public.load_account_progress(current_setting('test.progress_a')::uuid);
  IF row->>'profile_key'<>'legacy-a' THEN RAISE EXCEPTION 'Latest legacy progress not selected'; END IF;
  payload := jsonb_set(row->'payload','{profile,name}','"Updated primary"');
  row := public.save_account_progress(current_setting('test.progress_a')::uuid,1,payload);
  IF row->>'profile_key'<>'legacy-a' OR (row->>'revision')::int<>2 THEN RAISE EXCEPTION 'Primary changed'; END IF;
  IF row<>public.save_account_progress(current_setting('test.progress_a')::uuid,1,payload) THEN RAISE EXCEPTION 'Retry failed'; END IF;
  IF (SELECT count(*) FROM public.mobile_profile_backups WHERE owner_user_id=current_setting('test.progress_a')::uuid)<>2 THEN
    RAISE EXCEPTION 'Legacy data changed'; END IF;
  BEGIN
    PERFORM public.save_account_progress(current_setting('test.progress_a')::uuid,1,jsonb_set(payload,'{profile,name}','"Stale"'));
    RAISE EXCEPTION 'Stale state overwritten';
  EXCEPTION WHEN SQLSTATE 'PT409' THEN NULL; END;
  BEGIN
    PERFORM public.load_account_progress(current_setting('test.progress_b')::uuid);
    RAISE EXCEPTION 'Cross-account progress exposed';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
SELECT set_config('request.jwt.claim.sub',current_setting('test.progress_b'),true) IS NOT NULL AS second_user;
SET LOCAL ROLE authenticated;
DO $$
DECLARE row jsonb; payload jsonb;
BEGIN
  IF public.load_account_progress(current_setting('test.progress_b')::uuid) IS NOT NULL THEN RAISE EXCEPTION 'New account has progress'; END IF;
  payload := '{"version":3,"profile":{"id":"client-must-not-select-key","name":"New user"},"learning":{}}';
  row := public.save_account_progress(current_setting('test.progress_b')::uuid,0,payload);
  IF row->>'profile_key'<>'account-'||current_setting('test.progress_b') THEN RAISE EXCEPTION 'Wrong new primary key'; END IF;
  IF row->'payload'->'profile'->>'id'<>row->>'profile_key' THEN RAISE EXCEPTION 'Untrusted profile key accepted'; END IF;
  BEGIN
    SELECT count(*) INTO row FROM private.account_learning_roots;
    RAISE EXCEPTION 'Client read private primary mapping';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
  IF has_function_privilege(current_user,'public.load_account_progress(uuid)','EXECUTE')
    OR has_function_privilege(current_user,'public.save_account_progress(uuid,bigint,jsonb)','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous progress API exposed'; END IF;
END $$;
RESET ROLE;
SELECT 'Single account progress, legacy preservation, retries, conflicts and isolation passed' AS result;
ROLLBACK;
