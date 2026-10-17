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
SELECT 'commerce regression passed' AS result;
ROLLBACK;
