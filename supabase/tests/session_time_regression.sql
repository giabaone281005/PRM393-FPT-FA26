-- Privileged QA connection only. Fixtures and all time changes are rolled back.
BEGIN;
CREATE FUNCTION pg_temp.assert_true(ok boolean, msg text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: %',msg; END IF; END $$;
CREATE TEMP TABLE time_context(k text PRIMARY KEY, v jsonb);
GRANT ALL ON time_context TO authenticated;
INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data) VALUES
('a7777777-1111-4111-8111-111111111111','time-a@example.invalid',now(),'{}','{}'),
('b7777777-1111-4111-8111-111111111111','time-b@example.invalid',now(),'{}','{}');
INSERT INTO public.parents(id,email) SELECT id,email FROM auth.users
WHERE email IN ('time-a@example.invalid','time-b@example.invalid') ON CONFLICT(id) DO NOTHING;
INSERT INTO public.subscriptions(parent_id) VALUES('a7777777-1111-4111-8111-111111111111') ON CONFLICT(parent_id) DO NOTHING;
INSERT INTO public.kid_profiles(id,parent_id,nickname,grade) VALUES
('c7777777-1111-4111-8111-111111111111','a7777777-1111-4111-8111-111111111111','Time QA',1);
UPDATE public.parents SET active_kid_id='c7777777-1111-4111-8111-111111111111' WHERE id='a7777777-1111-4111-8111-111111111111';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a7777777-1111-4111-8111-111111111111',true);
SELECT public.ensure_family();
INSERT INTO time_context VALUES('session',public.start_learning_session('c7777777-1111-4111-8111-111111111111',NULL,'practice',gen_random_uuid()));
RESET ROLE;
UPDATE public.study_sessions SET last_heartbeat_at=clock_timestamp()-interval '10 seconds',last_active=true
WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session');
SET LOCAL ROLE authenticated;
SELECT public.heartbeat_learning_session((SELECT (v->>'id')::uuid FROM time_context WHERE k='session'),false,'{}');
SELECT pg_temp.assert_true((SELECT duration_seconds BETWEEN 10 AND 12 AND NOT last_active FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session')),'short session is flushed before 20 seconds');
INSERT INTO time_context SELECT 'paused_duration',to_jsonb(duration_seconds) FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session');
RESET ROLE;
UPDATE public.study_sessions SET last_heartbeat_at=clock_timestamp()-interval '30 seconds'
WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session');
SET LOCAL ROLE authenticated;
SELECT public.heartbeat_learning_session((SELECT (v->>'id')::uuid FROM time_context WHERE k='session'),true,'{}');
SELECT pg_temp.assert_true((SELECT duration_seconds=(SELECT (v#>>'{}')::integer FROM time_context WHERE k='paused_duration') FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session')),'background time is not charged on resume');
RESET ROLE;
UPDATE public.study_sessions SET last_heartbeat_at=clock_timestamp()-interval '60 seconds',last_active=true
WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session');
SET LOCAL ROLE authenticated;
SELECT public.heartbeat_learning_session((SELECT (v->>'id')::uuid FROM time_context WHERE k='session'),false,'{}');
SELECT pg_temp.assert_true((SELECT duration_seconds=(SELECT (v#>>'{}')::integer FROM time_context WHERE k='paused_duration') FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session')),'unconfirmed network gap is not invented');
SELECT pg_temp.assert_true((public.family_report()->'kids'->0->>'today_seconds')::integer=(SELECT duration_seconds FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session')),'dashboard total matches server-confirmed session time');
RESET ROLE;
UPDATE public.study_daily_usage SET total_seconds=1797 WHERE kid_id='c7777777-1111-4111-8111-111111111111' AND study_date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
UPDATE public.study_sessions SET last_heartbeat_at=clock_timestamp()-interval '20 seconds',last_active=true
WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session');
SET LOCAL ROLE authenticated;
SELECT public.heartbeat_learning_session((SELECT (v->>'id')::uuid FROM time_context WHERE k='session'),true,'{}');
SELECT pg_temp.assert_true((public.family_report()->'kids'->0->>'today_seconds')::integer=1800,'daily budget cannot be exceeded');
SELECT pg_temp.assert_true((SELECT duration_seconds=(SELECT (v#>>'{}')::integer FROM time_context WHERE k='paused_duration')+3 AND NOT last_active FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session')),'only remaining budget is charged');
SELECT set_config('request.jwt.claim.sub','b7777777-1111-4111-8111-111111111111',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.study_sessions WHERE id=(SELECT (v->>'id')::uuid FROM time_context WHERE k='session')),'another family cannot read session duration');
DO $$ BEGIN
 BEGIN
  PERFORM public.heartbeat_learning_session((SELECT (v->>'id')::uuid FROM time_context WHERE k='session'),true,'{}');
  RAISE EXCEPTION 'test failure: another family changed session';
 EXCEPTION WHEN raise_exception THEN
  IF SQLERRM NOT LIKE '%Không có quyền%' THEN RAISE; END IF;
 END;
END $$;
RESET ROLE;
SELECT 'session time regression passed' AS result;
ROLLBACK;
