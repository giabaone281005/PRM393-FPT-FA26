BEGIN;
CREATE INDEX IF NOT EXISTS parent_unlocks_parent_session_idx
ON private.parent_unlocks(parent_id,session_id);

CREATE OR REPLACE FUNCTION private.unlock_parent(p_pin text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE token text;
BEGIN
  IF auth.uid() IS NULL THEN RETURN NULL; END IF;
  PERFORM 1 FROM public.parents WHERE id=auth.uid() FOR UPDATE;
  IF NOT private.verify_parent_pin(p_pin) THEN RETURN NULL; END IF;
  DELETE FROM private.parent_unlocks WHERE parent_id=auth.uid()
    AND session_id=coalesce(auth.jwt()->>'session_id','');
  token:=encode(extensions.gen_random_bytes(32),'hex');
  INSERT INTO private.parent_unlocks(token_hash,parent_id,session_id,expires_at)
  VALUES(encode(extensions.digest(token,'sha256'),'hex'),auth.uid(),
    coalesce(auth.jwt()->>'session_id',''),now()+interval '15 minutes');
  RETURN token;
END $$;

CREATE OR REPLACE FUNCTION private.set_parent_pin(p_old text,p_new text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.parents;
BEGIN
  IF auth.uid() IS NULL OR p_new IS NULL OR p_new !~ '^[0-9]{4}$' OR p_new='1234' THEN
    RETURN false; END IF;
  SELECT * INTO p FROM public.parents WHERE id=auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RETURN false; END IF;
  IF p.parent_pin_hash<>'' AND NOT private.verify_parent_pin(p_old) THEN RETURN false; END IF;
  UPDATE public.parents SET parent_pin_hash=extensions.crypt(p_new,extensions.gen_salt('bf',10)),
    pin_failures=0,pin_locked_until=NULL WHERE id=p.id;
  -- Changing PIN revokes every existing unlock, including the current one.
  -- The client explicitly unlocks again using the new PIN after this succeeds.
  DELETE FROM private.parent_unlocks WHERE parent_id=auth.uid();
  RETURN true;
END $$;
REVOKE ALL ON FUNCTION private.unlock_parent(text),private.set_parent_pin(text,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.unlock_parent(text),private.set_parent_pin(text,text) TO authenticated;
COMMIT;
