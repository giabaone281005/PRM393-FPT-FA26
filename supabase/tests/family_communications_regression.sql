-- Development/staging only. Fixtures, RPC writes and notifications roll back.
BEGIN;
CREATE FUNCTION pg_temp.assert_true(ok boolean, message text)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF ok IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'Assertion failed: %', message;
  END IF;
END $$;

INSERT INTO auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data)
VALUES
  ('a8888888-1111-4111-8111-111111111111','communications-a@example.invalid',now(),'{}','{}'),
  ('b8888888-1111-4111-8111-111111111111','communications-b@example.invalid',now(),'{}','{}'),
  ('c8888888-1111-4111-8111-111111111111','communications-admin@example.invalid',now(),'{}','{}');
INSERT INTO public.parents(id,email)
SELECT id,email FROM auth.users WHERE id IN (
  'a8888888-1111-4111-8111-111111111111',
  'b8888888-1111-4111-8111-111111111111',
  'c8888888-1111-4111-8111-111111111111'
) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.user_roles(user_id,role)
VALUES ('c8888888-1111-4111-8111-111111111111','admin');
INSERT INTO public.notifications(id,parent_id,title,body,kind,dedupe_key)
VALUES
  ('d8888888-1111-4111-8111-111111111111','a8888888-1111-4111-8111-111111111111','A','Private A','support','communications-a'),
  ('e8888888-1111-4111-8111-111111111111','b8888888-1111-4111-8111-111111111111','B','Private B','support','communications-b');
CREATE TEMP TABLE communication_context(id uuid);
GRANT ALL ON communication_context TO authenticated;

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a8888888-1111-4111-8111-111111111111',true);
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.notifications),'family reads only its own notifications');
WITH changed AS (
  UPDATE public.notifications SET read_at=now()
  WHERE id='d8888888-1111-4111-8111-111111111111' RETURNING id
)
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM changed),'own notification read persists');
WITH changed AS (
  UPDATE public.notifications SET read_at=now()
  WHERE id='e8888888-1111-4111-8111-111111111111' RETURNING id
)
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM changed),'foreign notification cannot be marked read');
SELECT pg_temp.assert_true(NOT has_column_privilege('authenticated','public.notifications','body','UPDATE'),'clients cannot rewrite notification content');
SELECT pg_temp.assert_true(NOT has_table_privilege('authenticated','public.notifications','INSERT'),'clients cannot forge notifications');
SELECT public.set_parent_pin('','8426');
INSERT INTO communication_context
SELECT public.request_support(NULL,'Please inspect this learning issue',
  'f8888888-1111-4111-8111-111111111111',public.unlock_parent('8426'));
SELECT pg_temp.assert_true(public.request_support(NULL,'Please inspect this learning issue',
  'f8888888-1111-4111-8111-111111111111',public.unlock_parent('8426'))=
  (SELECT id FROM communication_context),'support retry reuses persisted request');
DO $$
BEGIN
  BEGIN
    PERFORM public.resolve_support((SELECT id FROM communication_context),'Forged parent response');
    RAISE EXCEPTION 'test failure: parent resolved support';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE '%Cần quyền admin%' THEN RAISE; END IF;
  END;
END $$;
SELECT set_config('request.jwt.claim.sub','b8888888-1111-4111-8111-111111111111',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.support_requests),'other family cannot read ticket');
SELECT set_config('request.jwt.claim.sub','c8888888-1111-4111-8111-111111111111',true);
SELECT public.resolve_support((SELECT id FROM communication_context),'Verified admin response');
SELECT public.resolve_support((SELECT id FROM communication_context),'Verified admin response');
SELECT set_config('request.jwt.claim.sub','a8888888-1111-4111-8111-111111111111',true);
SELECT pg_temp.assert_true((SELECT status='resolved' AND reply='Verified admin response'
  FROM public.support_requests WHERE id=(SELECT id FROM communication_context)),
  'reply persists for the requesting family');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.notifications
  WHERE dedupe_key='support:'||(SELECT id::text FROM communication_context)),
  'repeated admin reply creates exactly one notification');
RESET ROLE;
SELECT pg_temp.assert_true((SELECT read_at IS NULL FROM public.notifications
  WHERE id='e8888888-1111-4111-8111-111111111111'),'foreign read state is unchanged');
SELECT 'family communications regression passed' AS result;
ROLLBACK;
