-- Execute in STAGING SQL Editor as postgres AFTER migrations 18,19,20,21.
-- Fixtures and every mutation are rolled back. Any failed assertion aborts this transaction.
BEGIN;
CREATE FUNCTION pg_temp.assert_true(ok boolean,msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: %',msg;END IF;END $$;
CREATE FUNCTION pg_temp.expect_error(statement text,fragment text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE caught boolean:=false;BEGIN
 BEGIN EXECUTE statement;EXCEPTION WHEN OTHERS THEN
 IF position(fragment IN SQLERRM)=0 THEN RAISE;END IF;caught:=true;END;
 IF NOT caught THEN RAISE EXCEPTION 'Expected rejection: %',statement;END IF;
END $$;
CREATE TEMP TABLE test_context(k text PRIMARY KEY,v jsonb);
SELECT pg_temp.assert_true(private.answer_equal('0,5','1/2') AND private.answer_equal('8.0','8'),'equivalent numeric answers are accepted');
SELECT pg_temp.assert_true(NOT private.answer_equal('1/0','1') AND NOT private.answer_equal('2/3','1/2'),'invalid or unequal fractions rejected');
GRANT ALL ON test_context TO authenticated,service_role;
INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data) VALUES
('a1111111-1111-4111-8111-111111111111','role-a@example.invalid',now(),'{}','{}'),
('b2222222-2222-4222-8222-222222222222','role-b@example.invalid',now(),'{}','{}'),
('c3333333-3333-4333-8333-333333333333','role-admin@example.invalid',now(),'{}','{}'),
('d4444444-4444-4444-8444-444444444444','role-editor@example.invalid',now(),'{}','{}');
-- Auth insert trigger may already have created these parent rows.
INSERT INTO public.parents(id,email) SELECT id,email FROM auth.users WHERE email IN ('role-a@example.invalid','role-b@example.invalid','role-admin@example.invalid','role-editor@example.invalid')
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.subscriptions(parent_id) SELECT id FROM public.parents WHERE email IN ('role-a@example.invalid','role-b@example.invalid','role-admin@example.invalid','role-editor@example.invalid');
INSERT INTO public.user_roles(user_id,role) VALUES ('c3333333-3333-4333-8333-333333333333','admin'),('d4444444-4444-4444-8444-444444444444','moderator');
INSERT INTO public.kid_profiles(id,parent_id,nickname,grade) VALUES
('e5555555-5555-4555-8555-555555555555','a1111111-1111-4111-8111-111111111111','Test A',1),
('f6666666-6666-4666-8666-666666666666','b2222222-2222-4222-8222-222222222222','Test B',1);
UPDATE public.parents SET active_kid_id='e5555555-5555-4555-8555-555555555555' WHERE id='a1111111-1111-4111-8111-111111111111';
UPDATE public.parents SET active_kid_id='f6666666-6666-4666-8666-666666666666' WHERE id='b2222222-2222-4222-8222-222222222222';
INSERT INTO public.topics(id,grade,topic_number,title) VALUES('11111111-aaaa-4111-8111-111111111111',1,9999,'Regression topic');
INSERT INTO public.lessons(id,topic_id,lesson_number,title,theory,access_tier,order_index,star_reward,xp_reward) VALUES
('22222222-aaaa-4222-8222-222222222222','11111111-aaaa-4111-8111-111111111111',1,'Regression lesson','Lý thuyết kiểm thử phép cộng.','basic',1,3,30);
INSERT INTO public.questions(id,lesson_id,question_type,prompt,payload,order_index,skill_id) VALUES
('33333333-aaaa-4333-8333-333333333333','22222222-aaaa-4222-8222-222222222222','word_problem','3 + 2 = ?', '{"correctAnswer":5,"options":[3,4,5,6]}',1,'operations');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a1111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"a1111111-1111-4111-8111-111111111111","session_id":"session-a"}',true);
SELECT public.ensure_family();
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.kid_profiles),'RLS isolates families');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.kid_profiles','UPDATE'),'no client heart/star write');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.question_attempts','INSERT'),'no client answer forgery');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.kid_inventory','INSERT'),'no client free inventory');
SELECT pg_temp.assert_true(NOT has_function_privilege('authenticated','private.session_public(uuid)','EXECUTE'),'internal payload helper is private');
SELECT pg_temp.assert_true(NOT has_function_privilege('authenticated','public.complete_kid_lesson(uuid,uuid,integer,integer)','EXECUTE'),'legacy trust-client completion disabled');
SELECT pg_temp.assert_true(NOT public.parent_authorized('forged'),'forged parent token rejected');
SELECT pg_temp.assert_true(public.set_parent_pin('','8426'),'set PIN');
INSERT INTO test_context VALUES('proof',to_jsonb(public.unlock_parent('8426')));
SELECT pg_temp.assert_true(public.parent_authorized((SELECT v#>>'{}' FROM test_context WHERE k='proof')),'valid parent token');
SELECT set_config('request.jwt.claims','{"sub":"a1111111-1111-4111-8111-111111111111","session_id":"another-device"}',true);
SELECT pg_temp.assert_true(NOT public.parent_authorized((SELECT v#>>'{}' FROM test_context WHERE k='proof')),'token bound to auth session');
SELECT set_config('request.jwt.claims','{"sub":"a1111111-1111-4111-8111-111111111111","session_id":"session-a"}',true);
SELECT pg_temp.expect_error($q$SELECT public.manage_kid(NULL,'Unauthorized',1,false,'forged')$q$,'Cần mở cổng phụ huynh');
SELECT pg_temp.expect_error($q$SELECT public.manage_kid(NULL,'Extra Basic kid',1,false,(SELECT v#>>'{}' FROM test_context WHERE k='proof'))$q$,'Đã đạt');
INSERT INTO test_context VALUES('session',public.start_learning_session('e5555555-5555-4555-8555-555555555555','22222222-aaaa-4222-8222-222222222222','lesson','44444444-aaaa-4444-8444-444444444444'));
SELECT pg_temp.assert_true((SELECT v->'questions'->0->'payload'->'correctAnswer' IS NULL FROM test_context WHERE k='session'),'answer not leaked in session payload');
SELECT pg_temp.assert_true((public.start_learning_session('e5555555-5555-4555-8555-555555555555','22222222-aaaa-4222-8222-222222222222','lesson','44444444-aaaa-4444-8444-444444444444')->>'id')=(SELECT v->>'id' FROM test_context WHERE k='session'),'start is idempotent');
SELECT pg_temp.expect_error($q$SELECT public.finish_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'))$q$,'Chưa hoàn thành câu hỏi');
SELECT pg_temp.expect_error($q$SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'),'wrong-question','5','55555555-aaaa-4555-8555-555555555555',0)$q$,'Câu hỏi đã thay đổi');
SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'),'33333333-aaaa-4333-8333-333333333333','99','55555555-aaaa-4555-8555-555555555555',0);
SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'),'33333333-aaaa-4333-8333-333333333333','99','55555555-aaaa-4555-8555-555555555555',0);
SELECT pg_temp.assert_true((SELECT current_hearts=4 FROM public.kid_profiles WHERE id='e5555555-5555-4555-8555-555555555555'),'retry loses exactly one heart');
SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'),'33333333-aaaa-4333-8333-333333333333','5','66666666-aaaa-4666-8666-666666666666',1);
SELECT pg_temp.assert_true((SELECT count(*) FILTER (WHERE a.is_correct)=1 AND count(*) FILTER (WHERE NOT a.is_correct)=1 FROM public.question_attempts a JOIN public.study_sessions s ON s.id=a.session_id WHERE s.kid_id='e5555555-5555-4555-8555-555555555555'),'progress reads exact server-graded attempt counts');
SELECT public.finish_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'));
SELECT public.finish_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'));
SELECT pg_temp.assert_true((SELECT energy_stars=3 FROM public.kid_profiles WHERE id='e5555555-5555-4555-8555-555555555555'),'duplicate finish rewards only once');
SELECT pg_temp.assert_true((SELECT accuracy_percent=50 AND attempts_count=1 FROM public.kid_progress WHERE kid_id='e5555555-5555-4555-8555-555555555555' AND lesson_id='22222222-aaaa-4222-8222-222222222222'),'accuracy uses actual attempts');
SELECT pg_temp.assert_true(NOT public.submit_learning_essay((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'),'5','short'),'completed session cannot change essay');
SELECT public.buy_equip_item('e5555555-5555-4555-8555-555555555555','hat_detective',true);
SELECT public.buy_equip_item('e5555555-5555-4555-8555-555555555555','hat_detective',false);
SELECT pg_temp.assert_true((SELECT energy_stars=3 FROM public.kid_profiles WHERE id='e5555555-5555-4555-8555-555555555555'),'re-equipping owned item is free');
SELECT pg_temp.expect_error($q$SELECT public.buy_equip_item('e5555555-5555-4555-8555-555555555555','hat_wizard',true)$q$,'chưa đủ sao');
INSERT INTO test_context VALUES('practice',public.start_learning_session('e5555555-5555-4555-8555-555555555555',NULL,'practice','77777777-aaaa-4777-8777-777777777777'));
RESET ROLE;
CREATE TEMP TABLE practice_answers AS SELECT q,private.question_expected(q) AS expected FROM private.session_payloads p CROSS JOIN LATERAL jsonb_array_elements(p.content->'questions') q WHERE session_id=(SELECT (v->>'id')::uuid FROM test_context WHERE k='practice');
GRANT SELECT ON practice_answers TO authenticated;
UPDATE public.study_sessions SET last_heartbeat_at=clock_timestamp()-interval '20 seconds' WHERE id=(SELECT (v->>'id')::uuid FROM test_context WHERE k='practice');
SET LOCAL ROLE authenticated;
SELECT public.heartbeat_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='practice'),true,'{"tab":"quiz"}');
SELECT pg_temp.assert_true((SELECT duration_seconds>=19 FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM test_context WHERE k='practice')),'foreground heartbeat charges elapsed seconds');
DO $$ DECLARE row record;BEGIN FOR row IN SELECT * FROM practice_answers LOOP
 PERFORM public.answer_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='practice'),row.q->>'id',to_jsonb(row.expected),gen_random_uuid(),0);END LOOP;END $$;
SELECT public.finish_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='practice'));
SELECT public.finish_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='practice'));
SELECT pg_temp.assert_true((SELECT current_hearts=5 AND energy_stars=3 FROM public.kid_profiles WHERE id='e5555555-5555-4555-8555-555555555555'),'practice restores hearts without farmed stars');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.practice_garden_logs WHERE session_id=(SELECT (v->>'id')::uuid FROM test_context WHERE k='practice')),'one recovery log per session');
SELECT set_config('request.jwt.claim.sub','b2222222-2222-4222-8222-222222222222',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.question_attempts a JOIN public.study_sessions s ON s.id=a.session_id WHERE s.kid_id='e5555555-5555-4555-8555-555555555555'),'progress query cannot read another family attempts');
SELECT pg_temp.expect_error($q$SELECT public.heartbeat_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='practice'),true,'{}')$q$,'Không có quyền');
SELECT set_config('request.jwt.claim.sub','d4444444-4444-4444-8444-444444444444',true);
SELECT pg_temp.assert_true(public.is_staff() AND NOT public.is_admin(),'moderator has content role only');
SELECT public.staff_curriculum(1);
SELECT pg_temp.expect_error('SELECT public.admin_dashboard()','Cần quyền admin');
SELECT pg_temp.expect_error($q$SELECT public.admin_upgrade_subscription('a1111111-1111-4111-8111-111111111111','plus',30,'forged moderator grant')$q$,'Chỉ admin');
RESET ROLE;
SELECT pg_temp.assert_true(NOT EXISTS(SELECT 1 FROM public.tournament_members GROUP BY tournament_id HAVING count(*)>30),'groups have at most 30 members');
SELECT pg_temp.assert_true(NOT has_table_privilege('anon','public.questions','SELECT'),'anonymous cannot read paid answers');
SELECT pg_temp.assert_true(NOT has_function_privilege('authenticated','public.claim_ai(uuid,uuid,uuid,text)','EXECUTE'),'AI quota cannot be claimed directly');
SELECT pg_temp.assert_true(NOT has_function_privilege('authenticated','public.finish_refund(uuid,text,text,text)','EXECUTE'),'clients cannot confirm refunds');
SELECT 'role + learning regression passed' AS result;
ROLLBACK;
