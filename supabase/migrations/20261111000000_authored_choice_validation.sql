-- Reject explicit JSON nulls and non-string optional text before publication.
CREATE OR REPLACE FUNCTION private.valid_authored_choice(c jsonb) RETURNS boolean
LANGUAGE plpgsql IMMUTABLE SET search_path='' AS $$
BEGIN
  IF jsonb_typeof(c) IS DISTINCT FROM 'object' OR jsonb_typeof(c->'choices') IS DISTINCT FROM 'array'
    OR jsonb_typeof(c->'reasons') IS DISTINCT FROM 'array' THEN RETURN false; END IF;
  IF jsonb_array_length(c->'choices') NOT BETWEEN 2 AND 8 OR jsonb_array_length(c->'reasons') NOT BETWEEN 2 AND 8
    OR coalesce(c->>'answer','') !~ '^\d+$' OR coalesce(c->>'reason','') !~ '^\d+$'
    OR jsonb_typeof(c->'answer') IS DISTINCT FROM 'number' OR jsonb_typeof(c->'reason') IS DISTINCT FROM 'number'
    OR (c ? 'knowledge' AND jsonb_typeof(c->'knowledge') IS DISTINCT FROM 'string')
    OR (c ? 'source' AND jsonb_typeof(c->'source') IS DISTINCT FROM 'string') THEN RETURN false; END IF;
  RETURN coalesce((c->>'answer')::int < jsonb_array_length(c->'choices')
    AND (c->>'reason')::int < jsonb_array_length(c->'reasons')
    AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements((c->'choices')||(c->'reasons')) x
      WHERE jsonb_typeof(x)<>'string' OR length(btrim(x#>>'{}')) NOT BETWEEN 1 AND 2000)
    AND length(coalesce(c->>'knowledge',''))<=10000 AND length(coalesce(c->>'source',''))<=2000,false);
EXCEPTION WHEN numeric_value_out_of_range THEN RETURN false;
END $$;
REVOKE ALL ON FUNCTION private.valid_authored_choice(jsonb) FROM PUBLIC,anon,authenticated;
NOTIFY pgrst,'reload schema';
