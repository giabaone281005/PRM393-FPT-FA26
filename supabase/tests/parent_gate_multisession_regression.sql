BEGIN;
CREATE OR REPLACE FUNCTION pg_temp.assert_true(ok boolean,msg text)
RETURNS void LANGUAGE plpgsql AS $$ BEGIN
  IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: %',msg; END IF;
END $$;
INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data)
VALUES('a7777777-1111-4111-8111-111111111111','pin-session-qa@example.invalid',now(),'{}','{}');
INSERT INTO public.parents(id,email) VALUES('a7777777-1111-4111-8111-111111111111',
  'pin-session-qa@example.invalid') ON CONFLICT DO NOTHING;
CREATE TEMP TABLE pin_context(k text PRIMARY KEY,v text);
GRANT ALL ON pin_context TO authenticated;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a7777777-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{"sub":"a7777777-1111-4111-8111-111111111111","session_id":"pin-a"}',true);
SELECT pg_temp.assert_true(public.set_parent_pin('','8426'),'set initial PIN');
INSERT INTO pin_context VALUES('a',public.unlock_parent('8426'));
SELECT set_config('request.jwt.claims','{"sub":"a7777777-1111-4111-8111-111111111111","session_id":"pin-b"}',true);
INSERT INTO pin_context VALUES('b',public.unlock_parent('8426'));
SELECT pg_temp.assert_true(public.parent_authorized((SELECT v FROM pin_context WHERE k='b')),'second session unlocked');
SELECT pg_temp.assert_true(NOT public.parent_authorized((SELECT v FROM pin_context WHERE k='a')),'session B cannot steal session A token');
SELECT set_config('request.jwt.claims','{"sub":"a7777777-1111-4111-8111-111111111111","session_id":"pin-a"}',true);
SELECT pg_temp.assert_true(public.parent_authorized((SELECT v FROM pin_context WHERE k='a')),'session B did not revoke session A');
SELECT public.lock_parent();
SELECT pg_temp.assert_true(NOT public.parent_authorized((SELECT v FROM pin_context WHERE k='a')),'locking session A revokes A');
SELECT set_config('request.jwt.claims','{"sub":"a7777777-1111-4111-8111-111111111111","session_id":"pin-b"}',true);
SELECT pg_temp.assert_true(public.parent_authorized((SELECT v FROM pin_context WHERE k='b')),'locking A preserves B');
SELECT pg_temp.assert_true(public.set_parent_pin('8426','9638'),'change PIN');
SELECT pg_temp.assert_true(NOT public.parent_authorized((SELECT v FROM pin_context WHERE k='b')),'PIN change revokes old unlocks');
SELECT pg_temp.assert_true(public.unlock_parent('8426') IS NULL,'old PIN rejected');
SELECT pg_temp.assert_true(public.parent_authorized(public.unlock_parent('9638')),'new PIN unlocks');
SELECT 'parent gate multisession regression passed' AS result;
ROLLBACK;
