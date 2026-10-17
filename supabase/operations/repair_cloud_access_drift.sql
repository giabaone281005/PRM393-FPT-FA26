-- Repair observed Cloud drift without deleting application or Auth data.
SET lock_timeout='5s';
SET statement_timeout='30s';
REVOKE SELECT ON public.questions, public.lessons FROM PUBLIC,anon,authenticated;
DO $$ DECLARE r record; BEGIN
 FOR r IN SELECT table_name,column_name FROM information_schema.columns
 WHERE table_schema='public' AND table_name IN ('questions','lessons')
 LOOP EXECUTE format('REVOKE SELECT (%I) ON public.%I FROM PUBLIC,anon,authenticated',r.column_name,r.table_name); END LOOP;
END $$;
REVOKE SELECT,INSERT,UPDATE ON public.parents FROM PUBLIC,anon,authenticated;
DO $$ DECLARE r record; BEGIN
 FOR r IN SELECT column_name FROM information_schema.columns WHERE table_schema='public' AND table_name='parents'
 LOOP EXECUTE format('REVOKE SELECT (%1$I),INSERT (%1$I),UPDATE (%1$I) ON public.parents FROM PUBLIC,anon,authenticated',r.column_name); END LOOP;
END $$;
GRANT SELECT(id,email,created_at,updated_at,active_kid_id) ON public.parents TO authenticated;
ALTER FUNCTION public.set_updated_at() SET search_path='';
ALTER FUNCTION public.get_lessons_by_grade(integer) SET search_path='';
ALTER FUNCTION public.activate_plus(uuid,integer) SET search_path='';
ALTER FUNCTION public.purchase_item(uuid,text) SET search_path='';
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC,anon,authenticated;
REVOKE EXECUTE ON FUNCTION public.get_lessons_by_grade(integer),public.admin_confirm_order(text),public.create_order(text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.admin_confirm_order(text),public.create_order(text,text) TO service_role;
REVOKE EXECUTE ON FUNCTION public.admin_dashboard_stats(),public.get_my_subscription(),public.is_premium() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_dashboard_stats(),public.get_my_subscription(),public.is_premium() TO authenticated,service_role;
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.parents'::regclass AND contype='f' AND confrelid='auth.users'::regclass) THEN
 ALTER TABLE public.parents ADD CONSTRAINT parents_auth_user_fk FOREIGN KEY(id) REFERENCES auth.users(id) NOT VALID;
 END IF;
END $$;
ALTER TABLE public.parents VALIDATE CONSTRAINT parents_auth_user_fk;
NOTIFY pgrst,'reload schema';
