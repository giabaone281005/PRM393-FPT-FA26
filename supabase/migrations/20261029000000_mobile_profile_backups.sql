-- Personal offline snapshots, not server-verified learning records or XP.
-- Generated with `supabase migration new`; timestamp placed after retained
-- legacy files through 20261028000000, as required by repository rules.
CREATE TABLE IF NOT EXISTS public.mobile_profile_backups (
  owner_user_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  profile_key text NOT NULL CHECK (length(profile_key) BETWEEN 1 AND 128),
  revision bigint NOT NULL DEFAULT 1 CHECK (revision > 0),
  payload jsonb NOT NULL CHECK (
    jsonb_typeof(payload) = 'object'
    AND octet_length(payload::text) <= 1048576
    AND payload->>'version' = '3'
    AND jsonb_typeof(payload->'profile') = 'object'
    AND jsonb_typeof(payload->'learning') = 'object'
    AND payload->'profile'->>'id' = profile_key
    AND length(btrim(payload->'profile'->>'name')) BETWEEN 1 AND 40
  ),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (owner_user_id, profile_key)
);
ALTER TABLE public.mobile_profile_backups ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.mobile_profile_backups FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.mobile_profile_backups TO authenticated;
GRANT ALL ON public.mobile_profile_backups TO service_role;
DROP POLICY IF EXISTS owner_read ON public.mobile_profile_backups;
CREATE POLICY owner_read ON public.mobile_profile_backups FOR SELECT TO authenticated
USING (owner_user_id = (SELECT auth.uid()) AND private.has_role('user'));

CREATE OR REPLACE FUNCTION private.save_mobile_backup(
  expected_owner uuid, profile_key text, expected_revision bigint, backup_payload jsonb
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
  actor uuid := auth.uid();
  saved public.mobile_profile_backups;
BEGIN
  IF actor IS NULL OR actor IS DISTINCT FROM expected_owner
    OR NOT private.has_role('user')
    OR NOT EXISTS (SELECT 1 FROM public.accounts a WHERE a.id = actor AND a.deleted_at IS NULL)
  THEN RAISE EXCEPTION 'Mobile backup access denied' USING ERRCODE = '42501'; END IF;
  IF expected_revision IS NULL OR expected_revision < 0 OR profile_key IS NULL
    OR length(profile_key) NOT BETWEEN 1 AND 128
    OR backup_payload IS NULL
    OR jsonb_typeof(backup_payload) IS DISTINCT FROM 'object'
    OR octet_length(backup_payload::text) > 1048576
    OR backup_payload->>'version' IS DISTINCT FROM '3'
    OR jsonb_typeof(backup_payload->'profile') IS DISTINCT FROM 'object'
    OR jsonb_typeof(backup_payload->'learning') IS DISTINCT FROM 'object'
    OR backup_payload->'profile'->>'id' IS DISTINCT FROM profile_key
    OR coalesce(length(btrim(backup_payload->'profile'->>'name')),0) NOT BETWEEN 1 AND 40
  THEN RAISE EXCEPTION 'Invalid mobile backup' USING ERRCODE = '22023'; END IF;

  -- Serialize requests per account, including the first insert and quota check.
  PERFORM pg_advisory_xact_lock(hashtextextended(actor::text, 93417));
  SELECT b.* INTO saved FROM public.mobile_profile_backups b
  WHERE b.owner_user_id = actor AND b.profile_key = save_mobile_backup.profile_key FOR UPDATE;
  IF NOT FOUND THEN
    IF expected_revision <> 0 THEN
      RAISE EXCEPTION 'Backup revision conflict' USING ERRCODE = '40001';
    END IF;
    IF (SELECT count(*) FROM public.mobile_profile_backups b WHERE b.owner_user_id = actor) >= 100 THEN
      RAISE EXCEPTION 'Backup profile quota reached' USING ERRCODE = '22023';
    END IF;
    INSERT INTO public.mobile_profile_backups(owner_user_id,profile_key,payload)
    VALUES(actor,profile_key,backup_payload) RETURNING * INTO saved;
  ELSIF saved.payload = backup_payload THEN
    -- A retry after a lost response returns the same receipt.
    NULL;
  ELSIF saved.revision <> expected_revision THEN
    RAISE EXCEPTION 'Backup revision conflict' USING ERRCODE = '40001';
  ELSE
    UPDATE public.mobile_profile_backups b SET payload = backup_payload,
      revision = b.revision + 1, updated_at = now()
    WHERE b.owner_user_id = actor AND b.profile_key = save_mobile_backup.profile_key
    RETURNING b.* INTO saved;
  END IF;
  RETURN to_jsonb(saved);
END $$;
REVOKE ALL ON FUNCTION private.save_mobile_backup(uuid,text,bigint,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.save_mobile_backup(uuid,text,bigint,jsonb) TO authenticated;

CREATE OR REPLACE FUNCTION public.save_mobile_backup(
  expected_owner uuid, profile_key text, expected_revision bigint, backup_payload jsonb
) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$
  SELECT private.save_mobile_backup(expected_owner,profile_key,expected_revision,backup_payload)
$$;
REVOKE ALL ON FUNCTION public.save_mobile_backup(uuid,text,bigint,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_mobile_backup(uuid,text,bigint,jsonb) TO authenticated;
COMMENT ON TABLE public.mobile_profile_backups IS
  'Unverified personal offline snapshots; must never grant xp_ledger rewards or verified completions.';
NOTIFY pgrst, 'reload schema';
