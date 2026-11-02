-- Keep legacy snapshots intact. Pin exactly one primary learning snapshot per account.
CREATE TABLE IF NOT EXISTS private.account_learning_roots (
  owner_user_id uuid PRIMARY KEY REFERENCES public.accounts(id) ON DELETE CASCADE,
  profile_key text NOT NULL CHECK(length(profile_key) BETWEEN 1 AND 128)
);
ALTER TABLE private.account_learning_roots ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.account_learning_roots FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION private.account_learning_key(expected_owner uuid)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE actor uuid := private.learning_actor('user'); result text;
BEGIN
  IF actor IS DISTINCT FROM expected_owner THEN RAISE EXCEPTION 'Account access denied' USING ERRCODE='42501'; END IF;
  PERFORM pg_advisory_xact_lock(hashtextextended(actor::text,93417));
  SELECT profile_key INTO result FROM private.account_learning_roots WHERE owner_user_id=actor;
  IF result IS NULL THEN
    SELECT profile_key INTO result FROM public.mobile_profile_backups WHERE owner_user_id=actor ORDER BY updated_at DESC,profile_key LIMIT 1;
    result := coalesce(result,'account-'||actor::text);
    INSERT INTO private.account_learning_roots(owner_user_id,profile_key) VALUES(actor,result)
      ON CONFLICT(owner_user_id) DO NOTHING;
  END IF;
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.account_learning_key(uuid) FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION private.load_account_progress(expected_owner uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE key text := private.account_learning_key(expected_owner); result jsonb;
BEGIN
  SELECT to_jsonb(b) INTO result FROM public.mobile_profile_backups b
    WHERE owner_user_id=expected_owner AND profile_key=key;
  RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.load_account_progress(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.load_account_progress(uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.load_account_progress(expected_owner uuid)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.load_account_progress(expected_owner) $$;
REVOKE ALL ON FUNCTION public.load_account_progress(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.load_account_progress(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION private.save_account_progress(expected_owner uuid,expected_revision bigint,backup_payload jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE key text := private.account_learning_key(expected_owner);
BEGIN
  RETURN private.save_mobile_backup(expected_owner,key,expected_revision,
    jsonb_set(backup_payload,'{profile,id}',to_jsonb(key)));
EXCEPTION WHEN serialization_failure THEN
  RAISE EXCEPTION 'Account progress revision conflict' USING ERRCODE='PT409';
END $$;
REVOKE ALL ON FUNCTION private.save_account_progress(uuid,bigint,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.save_account_progress(uuid,bigint,jsonb) TO authenticated;
CREATE OR REPLACE FUNCTION public.save_account_progress(expected_owner uuid,expected_revision bigint,backup_payload jsonb)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.save_account_progress(expected_owner,expected_revision,backup_payload)
$$;
REVOKE ALL ON FUNCTION public.save_account_progress(uuid,bigint,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_account_progress(uuid,bigint,jsonb) TO authenticated;
