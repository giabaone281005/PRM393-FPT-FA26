-- READ ONLY. Run before the four NEW migrations. Does not modify data.
BEGIN READ ONLY;
SELECT version();
SELECT extname,nspname AS extension_schema FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace WHERE extname='pgcrypto';
-- pgcrypto must be in extensions for the new PIN functions. Review any different schema.
SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;
SELECT p.id,p.email,(SELECT count(*) FROM public.kid_profiles k WHERE k.parent_id=p.id) AS kids
FROM public.parents p LEFT JOIN auth.users u ON u.id=p.id WHERE u.id IS NULL;
-- Orphan seed records are retained; the new NOT VALID FK prevents new orphans.
SELECT id,email FROM public.admins ORDER BY created_at;
SELECT user_id,role FROM public.user_roles ORDER BY role,user_id;
SELECT grade,week_code,count(*) AS members FROM public.tournaments t JOIN public.tournament_members m ON m.tournament_id=t.id GROUP BY grade,week_code HAVING count(*)>30;
SELECT id,nickname,energy_stars,screen_time_limit_minutes FROM public.kid_profiles WHERE energy_stars<0 OR screen_time_limit_minutes NOT BETWEEN 15 AND 120;
SELECT conname,pg_get_constraintdef(oid),convalidated FROM pg_constraint WHERE conrelid IN ('public.parents'::regclass,'public.kid_progress'::regclass,'public.tournaments'::regclass);
ROLLBACK;
