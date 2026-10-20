-- Development only; all fixture users/content/answers roll back.
BEGIN;
CREATE FUNCTION pg_temp.assert_true(ok boolean,msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: %',msg; END IF; END $$;
CREATE TEMP TABLE history_context(k text PRIMARY KEY,v jsonb);
GRANT ALL ON history_context TO authenticated;
INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data) VALUES
('a6666666-1111-4111-8111-111111111111','history-a@example.invalid',now(),'{}','{}'),
('b6666666-1111-4111-8111-111111111111','history-b@example.invalid',now(),'{}','{}');
INSERT INTO public.parents(id,email) SELECT id,email FROM auth.users WHERE id IN
('a6666666-1111-4111-8111-111111111111','b6666666-1111-4111-8111-111111111111') ON CONFLICT DO NOTHING;
INSERT INTO public.subscriptions(parent_id) VALUES('a6666666-1111-4111-8111-111111111111') ON CONFLICT DO NOTHING;
INSERT INTO public.kid_profiles(id,parent_id,nickname,grade) VALUES
('c6666666-1111-4111-8111-111111111111','a6666666-1111-4111-8111-111111111111','History QA',1);
UPDATE public.parents SET active_kid_id='c6666666-1111-4111-8111-111111111111' WHERE id='a6666666-1111-4111-8111-111111111111';
INSERT INTO public.topics(id,grade,topic_number,title) VALUES('d6666666-1111-4111-8111-111111111111',1,9998,'History QA');
INSERT INTO public.lessons(id,topic_id,lesson_number,title,theory,access_tier,order_index) VALUES
('e6666666-1111-4111-8111-111111111111','d6666666-1111-4111-8111-111111111111',1,'History lesson','Phép cộng','basic',1);
INSERT INTO public.questions(id,lesson_id,question_type,prompt,payload,order_index,socratic_hints) VALUES
('f6666666-1111-4111-8111-111111111111','e6666666-1111-4111-8111-111111111111','word_problem','3 + 2 = ?',
'{"correctAnswer":5,"options":[3,4,5,6]}',1,'[{"hint_text":"Đếm thêm hai từ ba."}]');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a6666666-1111-4111-8111-111111111111',true);
INSERT INTO history_context VALUES('lesson',public.start_learning_session('c6666666-1111-4111-8111-111111111111','e6666666-1111-4111-8111-111111111111','lesson',gen_random_uuid()));
SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson'),'f6666666-1111-4111-8111-111111111111','4',gen_random_uuid(),1);
INSERT INTO history_context VALUES('practice',public.start_learning_session('c6666666-1111-4111-8111-111111111111',NULL,'practice',gen_random_uuid()));
SELECT pg_temp.assert_true(jsonb_array_length(public.learning_session_history('c6666666-1111-4111-8111-111111111111'))=2,'timeline includes lesson and practice');
SELECT pg_temp.assert_true(jsonb_array_length(public.learning_session_history('c6666666-1111-4111-8111-111111111111','lesson','unfinished',0))=1,'kind and unfinished filters');
SELECT pg_temp.assert_true(jsonb_array_length(public.learning_session_history('c6666666-1111-4111-8111-111111111111',NULL,NULL,1))=0,'pagination');
SELECT pg_temp.assert_true((public.resume_learning_session((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson'))->>'id')=(SELECT v->>'id' FROM history_context WHERE k='lesson'),'resume exact earlier session');
SELECT pg_temp.assert_true((SELECT status='paused' FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM history_context WHERE k='practice')),'other active session pauses');
SELECT pg_temp.assert_true(public.learning_session_review((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson'))->'attempts'->0->>'answer'='4','review preserves submitted answer');
SELECT pg_temp.assert_true(position('correctAnswer' IN public.learning_session_review((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson'))::text)=0,'review never leaks answer key');
SELECT public.answer_learning_session((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson'),'f6666666-1111-4111-8111-111111111111','5',gen_random_uuid(),0);
SELECT public.finish_learning_session((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson'));
SELECT pg_temp.assert_true(jsonb_array_length(public.learning_session_review((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson'))->'attempts')=2,'all attempts retained');
SELECT pg_temp.assert_true((public.learning_session_history('c6666666-1111-4111-8111-111111111111','lesson','completed',0)->0->>'accuracy_percent')::int=50,'server score matches two attempts');
SELECT set_config('request.jwt.claim.sub','b6666666-1111-4111-8111-111111111111',true);
DO $$ BEGIN
  BEGIN PERFORM public.learning_session_history('c6666666-1111-4111-8111-111111111111'); RAISE EXCEPTION 'history leaked';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE '%Không có quyền%' THEN RAISE; END IF; END;
  BEGIN PERFORM public.learning_session_review((SELECT (v->>'id')::uuid FROM history_context WHERE k='lesson')); RAISE EXCEPTION 'review leaked';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE '%Không có quyền%' THEN RAISE; END IF; END;
END $$;
RESET ROLE;
SELECT pg_temp.assert_true(NOT has_function_privilege('anon','public.learning_session_history(uuid,text,text,integer)','EXECUTE'),'anonymous denied');
SELECT 'learning history regression passed' AS result;
ROLLBACK;
