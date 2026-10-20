-- Privileged QA connection after migration 20261024000000. All fixtures roll back.
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
SELECT public.ensure_family();
INSERT INTO test_context VALUES('session',public.start_learning_session('e5555555-5555-4555-8555-555555555555','22222222-aaaa-4222-8222-222222222222','lesson',gen_random_uuid()));
SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'),'33333333-aaaa-4333-8333-333333333333','99',gen_random_uuid(),0);
SELECT pg_temp.assert_true(jsonb_array_length(public.wrong_answer_history('e5555555-5555-4555-8555-555555555555'))=1,'history derives from verified incorrect attempts');
SELECT pg_temp.assert_true(public.wrong_answer_history('e5555555-5555-4555-8555-555555555555')->0->'questionData'->'correctAnswer' IS NULL,'history does not disclose answer keys');
SELECT pg_temp.assert_true((public.wrong_answer_history('e5555555-5555-4555-8555-555555555555')->0->>'prompt')='3 + 2 = ?','history preserves question snapshot');
SELECT public.set_wrong_answer_review('e5555555-5555-4555-8555-555555555555','33333333-aaaa-4333-8333-333333333333','resolve');
SELECT public.set_wrong_answer_review('e5555555-5555-4555-8555-555555555555','33333333-aaaa-4333-8333-333333333333','resolve');
SELECT pg_temp.assert_true((SELECT resolved AND review_count=1 FROM public.learning_review_states WHERE kid_id='e5555555-5555-4555-8555-555555555555'),'retry is idempotent');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.question_attempts),'annotations do not create attempts');
SELECT pg_temp.assert_true((SELECT energy_stars=0 FROM public.kid_profiles WHERE id='e5555555-5555-4555-8555-555555555555'),'annotations do not award stars');
SELECT public.set_wrong_answer_review('e5555555-5555-4555-8555-555555555555',NULL,'hide_resolved');
SELECT pg_temp.assert_true(jsonb_array_length(public.wrong_answer_history('e5555555-5555-4555-8555-555555555555'))=0,'hide affects personal review list');
RESET ROLE;
UPDATE public.question_attempts SET answered_at=transaction_timestamp()-interval '1 second'
WHERE session_id=(SELECT (v->>'id')::uuid FROM test_context WHERE k='session');
SET LOCAL ROLE authenticated;
SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM test_context WHERE k='session'),'33333333-aaaa-4333-8333-333333333333','98',gen_random_uuid(),0);
SELECT pg_temp.assert_true(jsonb_array_length(public.wrong_answer_history('e5555555-5555-4555-8555-555555555555'))=1 AND NOT (public.wrong_answer_history('e5555555-5555-4555-8555-555555555555')->0->>'isResolved')::boolean,'a new incorrect attempt reopens the question');
SELECT pg_temp.expect_error($q$SELECT public.set_wrong_answer_review('e5555555-5555-4555-8555-555555555555',NULL,'unknown')$q$,'không hợp lệ');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.learning_review_states','INSERT'),'direct annotation writes denied');
SELECT pg_temp.assert_true(NOT has_function_privilege('anon','public.wrong_answer_history(uuid,uuid,integer)','EXECUTE'),'anonymous history denied');
SELECT set_config('request.jwt.claim.sub','b2222222-2222-4222-8222-222222222222',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.learning_review_states),'RLS isolates review markers');
SELECT pg_temp.expect_error($q$SELECT public.wrong_answer_history('e5555555-5555-4555-8555-555555555555')$q$,'Không có quyền');
SELECT pg_temp.expect_error($q$SELECT public.set_wrong_answer_review('e5555555-5555-4555-8555-555555555555',NULL,'hide_all')$q$,'Không có quyền');
RESET ROLE;
SELECT 'wrong answer review regression passed' AS result;
ROLLBACK;
