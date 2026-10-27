-- A version mismatch is an application conflict, not an engine serialization
-- failure. PostgREST 14 retries SQLSTATE 40001 indefinitely. Translate it before
-- it reaches the Data API while keeping all ownership/CAS checks unchanged.
-- https://supabase.com/kb/troubleshooting/high-cpu-and-infinite-transaction-retries-when-using-custom-error-codes-in-rpc-functions
CREATE OR REPLACE FUNCTION private.learning_mutate(operation_id uuid,operation_type text,payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
  IF operation_type='attempt.submit' THEN RAISE EXCEPTION 'Use server evaluator' USING ERRCODE='42501'; END IF;
  RETURN private.learning_wire(private.learning_apply(private.learning_actor(),operation_id,operation_type,payload));
EXCEPTION WHEN serialization_failure THEN
  RAISE EXCEPTION 'Learning revision conflict' USING ERRCODE='PT409';
END $$;
REVOKE ALL ON FUNCTION private.learning_mutate(uuid,text,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.learning_mutate(uuid,text,jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.save_mobile_backup(
  expected_owner uuid, profile_key text, expected_revision bigint, backup_payload jsonb
) RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
BEGIN
  RETURN private.save_mobile_backup(expected_owner,profile_key,expected_revision,backup_payload);
EXCEPTION WHEN serialization_failure THEN
  RAISE EXCEPTION 'Backup revision conflict' USING ERRCODE='PT409';
END $$;
REVOKE ALL ON FUNCTION public.save_mobile_backup(uuid,text,bigint,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_mobile_backup(uuid,text,bigint,jsonb) TO authenticated;
NOTIFY pgrst,'reload schema';
