-- Run only against the Matlingo schema. Uses transaction-local test identities,
-- generates temporary backup keys, and rolls back every test row.
BEGIN;
DO $$
DECLARE ids uuid[] := ARRAY[gen_random_uuid(),gen_random_uuid()];
BEGIN
  INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
    (ids[1],'backup-smoke-'||ids[1]||'@example.invalid','{}'),
    (ids[2],'backup-smoke-'||ids[2]||'@example.invalid','{}');
  PERFORM set_config('test.owner_a',ids[1]::text,true);
  PERFORM set_config('test.owner_b',ids[2]::text,true);
  PERFORM set_config('test.profile_key','smoke-'||gen_random_uuid()::text,true);
  PERFORM set_config('request.jwt.claim.sub',ids[1]::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE
  actor uuid := current_setting('test.owner_a')::uuid;
  key text := current_setting('test.profile_key');
  payload jsonb;
  first_receipt jsonb;
  receipt jsonb;
BEGIN
  payload := jsonb_build_object('version',3,'profile',jsonb_build_object('id',key,'name','Smoke test'),'learning','{}'::jsonb);
  first_receipt := public.save_mobile_backup(actor,key,0,payload);
  IF (first_receipt->>'revision')::bigint <> 1 THEN RAISE EXCEPTION 'First revision failed'; END IF;
  receipt := public.save_mobile_backup(actor,key,0,payload);
  IF receipt <> first_receipt THEN RAISE EXCEPTION 'Retry was not idempotent'; END IF;
  payload := jsonb_set(payload,'{profile,name}','"Updated smoke test"');
  receipt := public.save_mobile_backup(actor,key,1,payload);
  IF (receipt->>'revision')::bigint <> 2 THEN RAISE EXCEPTION 'Update revision failed'; END IF;
  BEGIN
    PERFORM public.save_mobile_backup(actor,key,1,jsonb_set(payload,'{profile,name}','"Stale write"'));
    RAISE EXCEPTION 'Stale write accepted';
  EXCEPTION WHEN SQLSTATE 'PT409' THEN NULL; END;
  BEGIN
    PERFORM public.save_mobile_backup(current_setting('test.owner_b')::uuid,key,2,payload);
    RAISE EXCEPTION 'Wrong expected owner accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    PERFORM public.save_mobile_backup(actor,key,2,'{}'::jsonb);
    RAISE EXCEPTION 'Invalid payload accepted';
  EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
  BEGIN
    INSERT INTO public.mobile_profile_backups(owner_user_id,profile_key,payload) VALUES(actor,key||'-direct',payload);
    RAISE EXCEPTION 'Direct client write accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  IF NOT EXISTS (SELECT 1 FROM public.mobile_profile_backups WHERE profile_key=key) THEN RAISE EXCEPTION 'Owner cannot read saved backup'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub',current_setting('test.owner_b'),true) IS NOT NULL AS switched_test_identity;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.mobile_profile_backups WHERE profile_key=current_setting('test.profile_key')) THEN
    RAISE EXCEPTION 'Cross-account backup exposed';
  END IF;
END $$;
RESET ROLE;
UPDATE private.account_access SET status='suspended' WHERE user_id=current_setting('test.owner_a')::uuid;
SELECT set_config('request.jwt.claim.sub',current_setting('test.owner_a'),true) IS NOT NULL AS switched_test_identity;
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM public.mobile_profile_backups WHERE profile_key=current_setting('test.profile_key')) THEN RAISE EXCEPTION 'Suspended account can read'; END IF;
  BEGIN
    PERFORM public.save_mobile_backup(current_setting('test.owner_a')::uuid,current_setting('test.profile_key'),0,'{}'::jsonb);
    RAISE EXCEPTION 'Suspended account can save';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$
BEGIN
  IF has_table_privilege(current_user,'public.mobile_profile_backups','SELECT')
    OR has_function_privilege(current_user,'public.save_mobile_backup(uuid,text,bigint,jsonb)','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous backup access exposed';
  END IF;
END $$;
ROLLBACK;
