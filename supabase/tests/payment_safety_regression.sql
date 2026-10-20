-- Run with a privileged SQL connection against STAGING after all migrations.
-- All fixtures roll back. This is not a production-data cleanup script.
BEGIN;
CREATE TEMP TABLE commerce_test_order(id uuid);
GRANT ALL ON commerce_test_order TO authenticated,service_role;
CREATE FUNCTION pg_temp.assert_true(ok boolean,message text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: %',message; END IF; END $$;
INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data) VALUES
('11111111-1111-4111-8111-111111111111','commerce-a@example.invalid',now(),'{}','{}'),
('22222222-2222-4222-8222-222222222222','commerce-b@example.invalid',now(),'{}','{}');
INSERT INTO public.parents(id,email) VALUES
('11111111-1111-4111-8111-111111111111','commerce-a@example.invalid'),
('22222222-2222-4222-8222-222222222222','commerce-b@example.invalid')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.kid_profiles(id,parent_id,nickname,grade) VALUES
('33333333-3333-4333-8333-333333333333','11111111-1111-4111-8111-111111111111','Commerce test A',1),
('44444444-4444-4444-8444-444444444444','22222222-2222-4222-8222-222222222222','Commerce test B',1);
INSERT INTO public.plan_prices(id,plan_id,label,duration_months,amount_vnd,published)
SELECT '55555555-5555-4555-8555-555555555555',id,'Test month',1,99000,true
FROM public.learning_plans WHERE code='plus';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.kid_profiles),'parent sees only own kid');
SELECT pg_temp.assert_true(NOT has_function_privilege('authenticated','public.settle_vnpay_order(uuid,text,bigint,text,text)','EXECUTE'),'client cannot settle payments');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.learning_orders','UPDATE'),'client cannot mark order paid');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.questions','SELECT'),'raw paid payload is private');
SELECT pg_temp.assert_true(NOT public.has_parent_pin(),'new family must configure PIN');
SELECT pg_temp.assert_true(public.set_parent_pin('','8426'),'initial PIN saves');
SELECT pg_temp.assert_true(public.verify_parent_pin('8426'),'PIN verifies');
SELECT pg_temp.assert_true(NOT public.verify_parent_pin('0000'),'incorrect PIN rejected');
INSERT INTO commerce_test_order SELECT (public.create_learning_order(
'55555555-5555-4555-8555-555555555555','66666666-6666-4666-8666-666666666666',public.unlock_parent('8426'))->>'id')::uuid;
SELECT pg_temp.assert_true((public.create_learning_order('55555555-5555-4555-8555-555555555555',
'66666666-6666-4666-8666-666666666666',public.unlock_parent('8426'))->>'id')::uuid=(SELECT id FROM commerce_test_order),'checkout retry reuses order');
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.learning_orders),'other parent cannot read order');
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT pg_temp.assert_true(public.settle_vnpay_order((SELECT id FROM commerce_test_order),'987654321',1,'00','00')='04','wrong amount rejected');
SELECT pg_temp.assert_true(public.settle_vnpay_order((SELECT id FROM commerce_test_order),'987654321',99000,'00','00')='00','verified success settles');
SELECT pg_temp.assert_true(public.settle_vnpay_order((SELECT id FROM commerce_test_order),'987654321',99000,'00','00')='02','duplicate IPN acknowledged without second reward');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.learning_payments WHERE order_id=(SELECT id FROM commerce_test_order)),'exactly one payment');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.subscription_periods WHERE parent_id='11111111-1111-4111-8111-111111111111' AND source='vnpay'),'exactly one paid period');
RESET ROLE;
DO $$ BEGIN
 BEGIN
 UPDATE public.plan_prices SET amount_vnd=1000 WHERE id='55555555-5555-4555-8555-555555555555';
 RAISE EXCEPTION 'test failure: purchased price was mutable';
 EXCEPTION WHEN raise_exception THEN
 IF SQLERRM NOT LIKE 'Giá đã có đơn hàng%' THEN RAISE; END IF;
 END;
END $$;

-- Fixtures only; no provider calls, no real money. All changes roll back.
CREATE TEMP TABLE checkout_test_orders(k text PRIMARY KEY,id uuid);
GRANT ALL ON checkout_test_orders TO authenticated,service_role;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT pg_temp.assert_true(NOT has_function_privilege('authenticated','public.reserve_learning_checkout(uuid,uuid,text,text)','EXECUTE'),'client cannot reserve provider attempt');
SELECT pg_temp.assert_true(NOT has_function_privilege('anon','public.save_learning_checkout(uuid,text,jsonb)','EXECUTE'),'anonymous cannot change checkout');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.learning_checkout_attempts','INSERT'),'client cannot forge provider');
INSERT INTO checkout_test_orders SELECT 'retain',(public.create_learning_order('55555555-5555-4555-8555-555555555555','76666666-6666-4666-8666-666666666666',public.unlock_parent('8426'))->>'id')::uuid;
INSERT INTO checkout_test_orders SELECT 'purge',(public.create_learning_order('55555555-5555-4555-8555-555555555555','86666666-6666-4666-8666-666666666666',public.unlock_parent('8426'))->>'id')::uuid;
INSERT INTO checkout_test_orders SELECT 'momo',(public.create_learning_order('55555555-5555-4555-8555-555555555555','96666666-6666-4666-8666-666666666666',public.unlock_parent('8426'))->>'id')::uuid;
INSERT INTO checkout_test_orders SELECT 'vnpay',(public.create_learning_order('55555555-5555-4555-8555-555555555555','a6666666-6666-4666-8666-666666666666',public.unlock_parent('8426'))->>'id')::uuid;
RESET ROLE;
INSERT INTO public.payment_events(order_id,provider,external_event_id,response_code)
SELECT id,'vnpay','retention-evidence','99' FROM checkout_test_orders WHERE k='retain';
UPDATE public.learning_orders SET created_at=now()-interval '2 hours',expires_at=now()-interval '1 hour' WHERE id=(SELECT id FROM checkout_test_orders WHERE k='purge');
SET LOCAL ROLE authenticated;
SELECT public.lock_parent();
SELECT pg_temp.assert_true(public.discard_unpaid_order((SELECT id FROM checkout_test_orders WHERE k='retain')),'compatibility discard ends waiting');
SELECT pg_temp.assert_true((SELECT status='expired' FROM public.learning_orders WHERE id=(SELECT id FROM checkout_test_orders WHERE k='retain')),'discard retains order');
SELECT public.purge_my_unpaid_orders();
SELECT pg_temp.assert_true((SELECT status='expired' FROM public.learning_orders WHERE id=(SELECT id FROM checkout_test_orders WHERE k='purge')),'purge expires rather than deletes');
RESET ROLE;
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.payment_events WHERE external_event_id='retention-evidence'),'discard retains provider evidence');
SET LOCAL ROLE service_role;
SELECT pg_temp.assert_true(public.settle_vnpay_order((SELECT id FROM checkout_test_orders WHERE k='retain'),'late-retained',99000,'00','00')='00','late callback settles retained order');
SELECT pg_temp.assert_true(public.settle_vnpay_order((SELECT id FROM checkout_test_orders WHERE k='purge'),'late-purged',99000,'00','00')='00','late callback settles after purge');
SELECT pg_temp.assert_true(public.reserve_learning_checkout((SELECT id FROM checkout_test_orders WHERE k='momo'),'11111111-1111-4111-8111-111111111111','momo','sandbox')->>'gateway_order_id' = replace((SELECT id::text FROM checkout_test_orders WHERE k='momo'),'-',''),'provider ID derives from persisted order');
SELECT pg_temp.assert_true(public.reserve_learning_checkout((SELECT id FROM checkout_test_orders WHERE k='momo'),'11111111-1111-4111-8111-111111111111','momo','sandbox')->>'gateway_order_id' = replace((SELECT id::text FROM checkout_test_orders WHERE k='momo'),'-',''),'retry reuses same provider ID');
DO $$ BEGIN
  BEGIN
    PERFORM public.reserve_learning_checkout((SELECT id FROM checkout_test_orders WHERE k='momo'),'11111111-1111-4111-8111-111111111111','vnpay','sandbox');
    RAISE EXCEPTION 'test failure: provider changed';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'Đơn đã có kênh thanh toán%' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.reserve_learning_checkout((SELECT id FROM checkout_test_orders WHERE k='momo'),'22222222-2222-4222-8222-222222222222','momo','sandbox');
    RAISE EXCEPTION 'test failure: other parent reserved';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'Đơn đã xử lý hoặc hết hạn%' THEN RAISE; END IF;
  END;
END $$;
SELECT pg_temp.assert_true(public.save_learning_checkout((SELECT id FROM checkout_test_orders WHERE k='momo'),replace((SELECT id::text FROM checkout_test_orders WHERE k='momo'),'-',''),'{"payUrl":"https://test-payment.momo.vn/one"}') ->> 'payUrl'='https://test-payment.momo.vn/one','first checkout cached');
SELECT pg_temp.assert_true(public.save_learning_checkout((SELECT id FROM checkout_test_orders WHERE k='momo'),replace((SELECT id::text FROM checkout_test_orders WHERE k='momo'),'-',''),'{"payUrl":"https://test-payment.momo.vn/two"}') ->> 'payUrl'='https://test-payment.momo.vn/one','retry keeps first checkout');
SELECT pg_temp.assert_true(public.settle_vnpay_order((SELECT id FROM checkout_test_orders WHERE k='momo'),'wrong-provider',99000,'00','00')='04','VNPay cannot settle MoMo attempt');
SELECT pg_temp.assert_true(public.settle_momo_order((SELECT id FROM checkout_test_orders WHERE k='momo'),'momo-first',1,0)='BAD_AMOUNT','MoMo amount verified');
SELECT pg_temp.assert_true(public.settle_momo_order((SELECT id FROM checkout_test_orders WHERE k='momo'),'momo-first',99000,0)='OK','first success settles');
SELECT pg_temp.assert_true(public.settle_momo_order((SELECT id FROM checkout_test_orders WHERE k='momo'),'momo-first',99000,0)='OK','same transaction is idempotent');
SELECT pg_temp.assert_true(public.settle_momo_order((SELECT id FROM checkout_test_orders WHERE k='momo'),'momo-extra',99000,0)='REVIEW','different transaction requires review');
SELECT pg_temp.assert_true(public.settle_momo_order((SELECT id FROM checkout_test_orders WHERE k='momo'),'momo-extra',99000,0)='REVIEW','extra callback retries remain review');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.learning_payments WHERE order_id=(SELECT id FROM checkout_test_orders WHERE k='momo')),'only one entitlement payment');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.subscription_periods WHERE payment_id IN (SELECT id FROM public.learning_payments WHERE order_id=(SELECT id FROM checkout_test_orders WHERE k='momo'))),'no extra Plus period');
SELECT public.reserve_learning_checkout((SELECT id FROM checkout_test_orders WHERE k='vnpay'),'11111111-1111-4111-8111-111111111111','vnpay','sandbox');
SELECT pg_temp.assert_true(public.settle_momo_order((SELECT id FROM checkout_test_orders WHERE k='vnpay'),'wrong-provider',99000,0)='BAD_PROVIDER','MoMo cannot settle VNPay attempt');
RESET ROLE;
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.payment_events WHERE order_id=(SELECT id FROM checkout_test_orders WHERE k='momo') AND response_code='REVIEW_DUPLICATE'),'extra transaction evidence retained once');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.admin_audit_logs WHERE target_id=(SELECT id::text FROM checkout_test_orders WHERE k='momo') AND action='PAYMENT_REVIEW' AND details->>'transaction'='momo-extra'),'operator can find extra transaction');
SET LOCAL ROLE authenticated;
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.learning_checkout_attempts),'owner sees attempts');
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.learning_checkout_attempts),'other family cannot read attempts');
SELECT pg_temp.assert_true(NOT public.discard_unpaid_order((SELECT id FROM checkout_test_orders WHERE k='vnpay')),'other family cannot expire order');
DO $$ BEGIN
  BEGIN
    PERFORM private.purge_unpaid_orders('11111111-1111-4111-8111-111111111111');
    RAISE EXCEPTION 'test failure: cross-family purge';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'Chỉ được xử lý đơn của chính mình%' THEN RAISE; END IF;
  END;
END $$;
RESET ROLE;
SELECT 'payment safety regression passed' AS result;
ROLLBACK;
