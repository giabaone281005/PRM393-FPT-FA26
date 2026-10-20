-- Development only. Every fixture and mutation is rolled back.
BEGIN;
CREATE OR REPLACE FUNCTION pg_temp.assert_true(ok boolean,msg text)
RETURNS void LANGUAGE plpgsql AS $$ BEGIN
  IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: %',msg; END IF;
END $$;
CREATE OR REPLACE FUNCTION pg_temp.expect_error(statement text,fragment text)
RETURNS void LANGUAGE plpgsql AS $$ DECLARE caught boolean:=false; BEGIN
  BEGIN EXECUTE statement; EXCEPTION WHEN OTHERS THEN
    IF position(fragment IN SQLERRM)=0 THEN RAISE; END IF; caught:=true; END;
  IF NOT caught THEN RAISE EXCEPTION 'Expected rejection: %',statement; END IF;
END $$;
INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data) VALUES
('a9999999-1111-4111-8111-111111111111','demo-regression-a@example.invalid',now(),'{}','{}'),
('b9999999-1111-4111-8111-111111111111','demo-regression-b@example.invalid',now(),'{}','{}'),
('c9999999-1111-4111-8111-111111111111','demo-regression-admin@example.invalid',now(),'{}','{}');
INSERT INTO public.parents(id,email) SELECT id,email FROM auth.users
WHERE id IN ('a9999999-1111-4111-8111-111111111111','b9999999-1111-4111-8111-111111111111',
  'c9999999-1111-4111-8111-111111111111') ON CONFLICT(id) DO NOTHING;
INSERT INTO public.user_roles(user_id,role) VALUES('c9999999-1111-4111-8111-111111111111','admin');
UPDATE private.demo_payment_settings SET enabled=true,expires_at=now()+interval '1 day' WHERE id;
CREATE TEMP TABLE demo_context(k text PRIMARY KEY,v jsonb);
GRANT ALL ON demo_context TO authenticated;
INSERT INTO demo_context SELECT 'price',to_jsonb(p.id) FROM public.plan_prices p
JOIN public.learning_plans l ON l.id=p.plan_id
WHERE p.published AND l.published AND l.tier='plus' ORDER BY p.duration_months LIMIT 1;
SELECT pg_temp.assert_true(EXISTS(SELECT 1 FROM demo_context),'published price fixture exists');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a9999999-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"a9999999-1111-4111-8111-111111111111","session_id":"demo-regression-a"}',true);
SELECT public.ensure_family();
SELECT public.set_parent_pin('','8426');
INSERT INTO demo_context VALUES('token',to_jsonb(public.unlock_parent('8426')));
SELECT pg_temp.assert_true(public.demo_payment_available(),'demo availability uses server setting');
SELECT pg_temp.expect_error($q$SELECT public.create_demo_payment(
  (SELECT (v#>>'{}')::uuid FROM demo_context WHERE k='price'),
  'd9999999-1111-4111-8111-111111111111','forged')$q$,'Cần mở cổng');
INSERT INTO demo_context SELECT 'order',public.create_demo_payment(
  (SELECT (v#>>'{}')::uuid FROM demo_context WHERE k='price'),
  'd9999999-1111-4111-8111-111111111111',(SELECT v#>>'{}' FROM demo_context WHERE k='token'));
SELECT pg_temp.assert_true(public.create_demo_payment(
  (SELECT (v#>>'{}')::uuid FROM demo_context WHERE k='price'),
  'd9999999-1111-4111-8111-111111111111',(SELECT v#>>'{}' FROM demo_context WHERE k='token'))=
  (SELECT v FROM demo_context WHERE k='order'),'checkout retry reuses demo order');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.demo_payment_transactions),'own pending history persists');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.demo_payment_transactions','UPDATE'),
  'client cannot mark its own row paid');

-- A different auth session cannot reuse the unlocked PIN token.
SELECT set_config('request.jwt.claims','{"sub":"a9999999-1111-4111-8111-111111111111","session_id":"other-device"}',true);
SELECT pg_temp.expect_error($q$SELECT public.confirm_demo_payment(
  (SELECT (v->>'id')::uuid FROM demo_context WHERE k='order'),
  (SELECT v#>>'{}' FROM demo_context WHERE k='token'))$q$,'Cần mở cổng');
SELECT set_config('request.jwt.claims','{"sub":"a9999999-1111-4111-8111-111111111111","session_id":"demo-regression-a"}',true);
INSERT INTO demo_context SELECT 'paid',public.confirm_demo_payment(
  (SELECT (v->>'id')::uuid FROM demo_context WHERE k='order'),
  (SELECT v#>>'{}' FROM demo_context WHERE k='token'));
SELECT pg_temp.assert_true((SELECT v->>'status'='paid' AND v->>'external_transaction_id' LIKE 'DEMO-%'
  FROM demo_context WHERE k='paid'),'server confirms paid with explicit demo transaction id');
SELECT pg_temp.assert_true(public.confirm_demo_payment(
  (SELECT (v->>'id')::uuid FROM demo_context WHERE k='order'),
  (SELECT v#>>'{}' FROM demo_context WHERE k='token'))=(SELECT v FROM demo_context WHERE k='paid'),
  'confirmation retry is idempotent');
INSERT INTO demo_context SELECT 'expiry',to_jsonb(expires_at) FROM public.subscriptions WHERE parent_id=auth.uid();
SELECT pg_temp.assert_true((SELECT tier='plus' AND max_kids=3 AND notes LIKE 'DEMO %'
  FROM public.subscriptions WHERE parent_id=auth.uid()),'server persists Plus demo entitlement');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.subscription_periods
  WHERE parent_id=auth.uid() AND source='demo'),'exactly one demo period');
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.learning_orders WHERE parent_id=auth.uid()),
  'no fake merchant order');
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.learning_payments
  WHERE order_id=(SELECT (v->>'id')::uuid FROM demo_context WHERE k='order')),'no fake merchant payment');

SELECT set_config('request.jwt.claim.sub','b9999999-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"b9999999-1111-4111-8111-111111111111","session_id":"demo-regression-b"}',true);
SELECT public.ensure_family();
SELECT public.set_parent_pin('','8426');
INSERT INTO demo_context VALUES('token-b',to_jsonb(public.unlock_parent('8426')));
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.demo_payment_transactions),'other family cannot read demo history');
SELECT pg_temp.expect_error($q$SELECT public.confirm_demo_payment(
  (SELECT (v->>'id')::uuid FROM demo_context WHERE k='order'),
  (SELECT v#>>'{}' FROM demo_context WHERE k='token-b'))$q$,'Không tìm thấy');
SELECT set_config('request.jwt.claim.sub','c9999999-1111-4111-8111-111111111111',true);
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.demo_payment_transactions
  WHERE parent_id='a9999999-1111-4111-8111-111111111111'),'admin can read demo history');

RESET ROLE;
UPDATE private.demo_payment_settings SET enabled=false WHERE id;
SET LOCAL ROLE authenticated;
SELECT pg_temp.assert_true(NOT public.demo_payment_available(),'server can disable demo');
RESET ROLE;
SELECT pg_temp.assert_true(NOT has_function_privilege('anon','public.confirm_demo_payment(uuid,text)','EXECUTE'),
  'anonymous cannot confirm demo payment');
SELECT pg_temp.assert_true((SELECT count(*)=13 FROM pg_publication_tables
  WHERE pubname='supabase_realtime' AND tablename IN ('kid_profiles','subscriptions','kid_progress',
  'study_sessions','study_daily_usage','kid_equipment','notifications','support_requests',
  'learning_orders','plan_prices','lessons','user_roles','demo_payment_transactions')),
  'live sync tables are published');
SELECT 'demo payment regression passed' AS result;
ROLLBACK;
