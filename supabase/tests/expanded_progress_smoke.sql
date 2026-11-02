-- Exercise new activity state through the deployed account snapshot RPC.
-- The generated fixture and every write are rolled back.
BEGIN;
DO $$
DECLARE actor uuid := gen_random_uuid();
BEGIN
  INSERT INTO auth.users(id,email,raw_user_meta_data)
    VALUES(actor,'curriculum-'||actor||'@example.invalid','{}');
  PERFORM set_config('test.curriculum_actor',actor::text,true);
  PERFORM set_config('request.jwt.claim.sub',actor::text,true);
END $$;
SET LOCAL ROLE authenticated;
DO $$
DECLARE actor uuid := current_setting('test.curriculum_actor')::uuid;
  payload jsonb := '{"version":3,"profile":{"id":"local-learning-id","name":"Curriculum fixture"},"learning":{"drafts":{"english":{"version":3,"step":3,"activeActivityId":"english-introduce","states":{"english-introduce":{"response":"Hello my name is Alex"}},"touched":["english-introduce"],"checked":[]},"biology":{"step":4,"states":{"biology-growth":{"x":2,"y":3,"prediction":6,"observed":[2,3,6],"trials":[[2,3,6]]}}},"finance":{"step":4,"states":{"finance-budget":{"values":[6,3,1]}}}}}}';
  saved jsonb; loaded jsonb;
BEGIN
  saved := public.save_account_progress(actor,0,payload);
  loaded := public.load_account_progress(actor);
  IF loaded->'payload' <> saved->'payload' THEN RAISE EXCEPTION 'Round-trip state differs'; END IF;
  IF loaded#>>'{payload,learning,drafts,english,states,english-introduce,response}' <> 'Hello my name is Alex' THEN
    RAISE EXCEPTION 'Language response missing';
  END IF;
  IF loaded#>'{payload,learning,drafts,biology,states,biology-growth,observed}' <> '[2,3,6]'::jsonb THEN
    RAISE EXCEPTION 'Model observation missing';
  END IF;
  IF loaded#>'{payload,learning,drafts,finance,states,finance-budget,values}' <> '[6,3,1]'::jsonb THEN
    RAISE EXCEPTION 'Resource allocation missing';
  END IF;
  IF (public.save_account_progress(actor,0,payload)->>'revision')::bigint <> (saved->>'revision')::bigint THEN
    RAISE EXCEPTION 'Idempotent retry changed revision';
  END IF;
END $$;
RESET ROLE;
ROLLBACK;
