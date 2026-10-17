-- STAGING only, privileged SQL connection. Database-only test: NO provider/network calls.
BEGIN;
CREATE FUNCTION pg_temp.assert_true(ok boolean,msg text) RETURNS void LANGUAGE plpgsql AS $$ BEGIN IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: %',msg;END IF;END $$;
CREATE TEMP TABLE operation_context(k text PRIMARY KEY,v jsonb);GRANT ALL ON operation_context TO authenticated,service_role;
INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data) VALUES
('a9999999-1111-4111-8111-111111111111','operation-parent@example.invalid',now(),'{}','{}'),
('b9999999-2222-4222-8222-222222222222','operation-admin@example.invalid',now(),'{}','{}'),
('c9999999-3333-4333-8333-333333333333','operation-editor@example.invalid',now(),'{}','{}');
-- Auth insert trigger may already have created these parent rows.
INSERT INTO public.parents(id,email) SELECT id,email FROM auth.users WHERE email IN ('operation-parent@example.invalid','operation-admin@example.invalid','operation-editor@example.invalid')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.subscriptions(parent_id) SELECT id FROM public.parents WHERE email IN ('operation-parent@example.invalid','operation-admin@example.invalid','operation-editor@example.invalid');
INSERT INTO public.user_roles(user_id,role) VALUES('b9999999-2222-4222-8222-222222222222','admin'),('c9999999-3333-4333-8333-333333333333','moderator');
INSERT INTO public.plan_prices(id,plan_id,label,duration_months,amount_vnd,published) SELECT 'd9999999-4444-4444-8444-444444444444',id,'Regression month',1,99000,true FROM public.learning_plans WHERE code='plus';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a9999999-1111-4111-8111-111111111111',true);
SELECT public.set_parent_pin('','8426');
INSERT INTO operation_context VALUES('order',public.create_learning_order('d9999999-4444-4444-8444-444444444444','e9999999-5555-4555-8555-555555555555',public.unlock_parent('8426')));
INSERT INTO operation_context VALUES('support',to_jsonb(public.request_support((SELECT (v->>'id')::uuid FROM operation_context WHERE k='order'),'Please check this payment','f9999999-6666-4666-8666-666666666666',public.unlock_parent('8426'))));
SELECT pg_temp.assert_true(public.request_support((SELECT (v->>'id')::uuid FROM operation_context WHERE k='order'),'Please check this payment','f9999999-6666-4666-8666-666666666666',public.unlock_parent('8426'))=(SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='support'),'support retries are idempotent');
RESET ROLE;SET LOCAL ROLE service_role;
SELECT pg_temp.assert_true(public.settle_vnpay_order((SELECT (v->>'id')::uuid FROM operation_context WHERE k='order'),'operation-payment',99000,'00','00')='00','settle payment');
RESET ROLE;SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','b9999999-2222-4222-8222-222222222222',true);
SELECT public.resolve_support((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='support'),'We have checked your payment.');
INSERT INTO operation_context VALUES('refund',to_jsonb(public.request_refund((SELECT (v->>'id')::uuid FROM operation_context WHERE k='order'),'Approved regression refund')));
SELECT pg_temp.assert_true(public.request_refund((SELECT (v->>'id')::uuid FROM operation_context WHERE k='order'),'Repeated request')=(SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='refund'),'one full refund per order');
RESET ROLE;SET LOCAL ROLE service_role;
SELECT pg_temp.assert_true(public.claim_refund((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='refund')) IS NOT NULL,'first claim succeeds');
SELECT pg_temp.assert_true(public.claim_refund((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='refund')) IS NULL,'repeat claim never sends twice');
SELECT public.finish_refund((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='refund'),'unknown',NULL,'NETWORK');
SELECT pg_temp.assert_true((SELECT tier='plus' FROM public.subscriptions WHERE parent_id='a9999999-1111-4111-8111-111111111111'),'uncertainty retains paid rights');
SELECT public.finish_refund((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='refund'),'succeeded','provider-refund','00');
SELECT public.finish_refund((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='refund'),'succeeded','provider-refund','00');
SELECT pg_temp.assert_true((SELECT status='refunded' FROM public.learning_orders WHERE id=(SELECT (v->>'id')::uuid FROM operation_context WHERE k='order')),'refund recorded');
SELECT pg_temp.assert_true((SELECT tier='basic' FROM public.subscriptions WHERE parent_id='a9999999-1111-4111-8111-111111111111'),'refunded-only rights revoked');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.notifications WHERE parent_id='a9999999-1111-4111-8111-111111111111' AND kind='refund'),'refund notification deduped');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.notifications WHERE parent_id='a9999999-1111-4111-8111-111111111111' AND kind='support'),'support reply creates a notification');
RESET ROLE;SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c9999999-3333-4333-8333-333333333333',true);
INSERT INTO operation_context VALUES('topic',to_jsonb(public.create_topic(1,'Regression editor topic')));
INSERT INTO operation_context VALUES('draft',to_jsonb(public.save_lesson_draft(NULL,jsonb_build_object('grade',1,'topic_id',(SELECT v#>>'{}' FROM operation_context WHERE k='topic'),'title','Editor regression','theory','Lý thuyết phép cộng dành cho kiểm thử.','access_tier','basic','questions',jsonb_build_array(jsonb_build_object('question_type','word_problem','prompt','3 + 2 = ?','payload','{"correctAnswer":5,"options":[3,4,5,6]}'::jsonb))))));
INSERT INTO operation_context VALUES('lesson',to_jsonb(public.publish_lesson((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='draft'))));
INSERT INTO operation_context VALUES('original',public.staff_lesson((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='lesson')));
UPDATE operation_context SET v=to_jsonb(public.save_lesson_draft((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='lesson'),(SELECT v||'{"title":"Editor revision"}' FROM operation_context WHERE k='original'))) WHERE k='draft';
SELECT public.publish_lesson((SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='draft'));
RESET ROLE;
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.lesson_versions WHERE lesson_id=(SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='lesson')),'both published versions retained');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.questions WHERE lesson_id=(SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='lesson') AND NOT is_active),'old question row retained for attempts');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.questions WHERE lesson_id=(SELECT (v#>>'{}')::uuid FROM operation_context WHERE k='lesson') AND is_active),'one current question version');
SELECT pg_temp.assert_true((SELECT count(*)>=2 FROM public.admin_audit_logs WHERE action='PUBLISH' AND target_id=(SELECT v#>>'{}' FROM operation_context WHERE k='lesson')),'publishes audited');
SELECT 'content + payment operations passed' AS result;
ROLLBACK;
