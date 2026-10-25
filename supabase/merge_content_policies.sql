
DO $policy_merge$
DECLARE r record; p record; combined text;
BEGIN
 FOR r IN SELECT polrelid FROM pg_policy WHERE polcmd='r' AND polrelid IN (
 SELECT oid FROM pg_class WHERE relnamespace='public'::regnamespace
 ) GROUP BY polrelid HAVING count(*)>1
 LOOP
  SELECT string_agg('('||pg_get_expr(polqual,polrelid)||')',' OR ') INTO combined
  FROM pg_policy WHERE polrelid=r.polrelid AND polcmd='r';
  FOR p IN SELECT polname FROM pg_policy WHERE polrelid=r.polrelid AND polcmd='r' LOOP
   EXECUTE format('DROP POLICY %I ON %s',p.polname,r.polrelid::regclass);
  END LOOP;
  EXECUTE format('CREATE POLICY content_read ON %s FOR SELECT TO authenticated USING (%s)',
    r.polrelid::regclass,combined);
 END LOOP;
END $policy_merge$;
