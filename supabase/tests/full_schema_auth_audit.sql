-- READ ONLY. Run as postgres in Supabase SQL Editor; returns metadata, no user rows.
-- Works even when application migrations are missing or partially installed.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '30s';
WITH expected(name) AS (
 SELECT unnest(ARRAY[
 'private.ai_requests','private.parent_unlocks','private.session_payloads',
 'public.admin_audit_logs','public.admins','public.ai_settings','public.kid_equipment',
 'public.kid_inventory','public.kid_profiles','public.kid_progress','public.kid_streaks',
 'public.learning_orders','public.learning_payments','public.learning_plans',
 'public.lesson_drafts','public.lesson_versions','public.lessons','public.mascot_items',
 'public.notifications','public.parents','public.payment_events','public.plan_prices',
 'public.practice_garden_logs','public.question_attempts','public.questions',
 'public.refund_requests','public.skills','public.study_daily_usage','public.study_sessions',
 'public.subscription_logs','public.subscription_periods','public.subscriptions',
 'public.support_requests','public.topics','public.tournament_members','public.tournaments',
 'public.user_roles'])
), app_relations AS (
 SELECT c.*, n.nspname FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
 WHERE n.nspname IN ('public','private') AND c.relkind IN ('r','p','v','m')
), app_functions AS (
 SELECT p.*,n.nspname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname IN ('public','private') AND p.prokind='f'
)
SELECT jsonb_pretty(jsonb_build_object(
 'database',jsonb_build_object('version',version(),'database',current_database(),
   'migration_history_present',to_regclass('supabase_migrations.schema_migrations') IS NOT NULL),
 'expected_tables',(SELECT jsonb_agg(jsonb_build_object('name',name,
   'exists',to_regclass(name) IS NOT NULL) ORDER BY name) FROM expected),
 'relations',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',nspname,'name',relname,
   'kind',relkind,'rls',relrowsecurity,'options',reloptions,
   'expected',EXISTS(SELECT 1 FROM expected WHERE name=nspname||'.'||relname),
   'anon_select',has_table_privilege('anon',oid,'SELECT'),
   'authenticated_select',has_table_privilege('authenticated',oid,'SELECT'),
   'authenticated_insert',has_table_privilege('authenticated',oid,'INSERT'),
   'authenticated_update',has_table_privilege('authenticated',oid,'UPDATE'),
   'authenticated_delete',has_table_privilege('authenticated',oid,'DELETE'))
   ORDER BY nspname,relname),'[]') FROM app_relations),
 'columns',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',r.nspname,'table',r.relname,
   'column',a.attname,'type',format_type(a.atttypid,a.atttypmod),'not_null',a.attnotnull,
   'default',pg_get_expr(d.adbin,d.adrelid)) ORDER BY r.nspname,r.relname,a.attnum),'[]')
   FROM app_relations r JOIN pg_attribute a ON a.attrelid=r.oid AND a.attnum>0 AND NOT a.attisdropped
   LEFT JOIN pg_attrdef d ON d.adrelid=r.oid AND d.adnum=a.attnum),
 'foreign_keys',(SELECT coalesce(jsonb_agg(jsonb_build_object('name',c.conname,
   'table',c.conrelid::regclass::text,'references',c.confrelid::regclass::text,
   'definition',pg_get_constraintdef(c.oid),'validated',c.convalidated,
   'delete_action',CASE c.confdeltype WHEN 'a' THEN 'NO ACTION' WHEN 'r' THEN 'RESTRICT'
     WHEN 'c' THEN 'CASCADE' WHEN 'n' THEN 'SET NULL' WHEN 'd' THEN 'SET DEFAULT' END)
   ORDER BY c.conrelid::regclass::text,c.conname),'[]') FROM pg_constraint c
   WHERE c.contype='f' AND (c.conrelid IN (SELECT oid FROM app_relations)
     OR c.confrelid=to_regclass('auth.users'))),
 'auth_triggers',(SELECT coalesce(jsonb_agg(jsonb_build_object('name',t.tgname,
   'enabled',t.tgenabled,'definition',pg_get_triggerdef(t.oid),
   'function',p.oid::regprocedure::text,'security_definer',p.prosecdef,
   'owner',pg_get_userbyid(p.proowner),'settings',p.proconfig,
   'body',pg_get_functiondef(p.oid)) ORDER BY t.tgname),'[]')
   FROM pg_trigger t JOIN pg_proc p ON p.oid=t.tgfoid
   WHERE t.tgrelid=to_regclass('auth.users') AND NOT t.tgisinternal),
 'application_triggers',(SELECT coalesce(jsonb_agg(jsonb_build_object(
   'table',t.tgrelid::regclass::text,'name',t.tgname,'enabled',t.tgenabled,
   'definition',pg_get_triggerdef(t.oid)) ORDER BY t.tgrelid::regclass::text,t.tgname),'[]')
   FROM pg_trigger t WHERE t.tgrelid IN (SELECT oid FROM app_relations) AND NOT t.tgisinternal),
 'functions',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',nspname,'name',proname,
   'arguments',pg_get_function_identity_arguments(oid),'returns',pg_get_function_result(oid),
   'owner',pg_get_userbyid(proowner),'security_definer',prosecdef,'settings',proconfig,
   'anon_execute',has_function_privilege('anon',oid,'EXECUTE'),
   'authenticated_execute',has_function_privilege('authenticated',oid,'EXECUTE'),
   'service_execute',has_function_privilege('service_role',oid,'EXECUTE'))
   ORDER BY nspname,proname,oid),'[]') FROM app_functions),
 'policies',(SELECT coalesce(jsonb_agg(jsonb_build_object('schema',schemaname,
   'table',tablename,'name',policyname,'command',cmd,'roles',roles,
   'using',qual,'check',with_check) ORDER BY schemaname,tablename,policyname),'[]')
   FROM pg_policies WHERE schemaname IN ('public','private')),
 'extensions',(SELECT jsonb_agg(jsonb_build_object('name',e.extname,'schema',n.nspname,
   'version',e.extversion) ORDER BY e.extname) FROM pg_extension e
   JOIN pg_namespace n ON n.oid=e.extnamespace),
 'storage_objects_owned',jsonb_build_object('table_present',to_regclass('storage.objects') IS NOT NULL,
   'note','Check Storage-owned files before deleting an Auth user; no file data is read here.'),
 'notes',jsonb_build_array(
   'NO ACTION / RESTRICT references can block deleting Auth users or their parents/kids.',
   'A table not in expected_tables is a review candidate, not proof it is unused.',
   'Auth SMTP, redirect URLs and Auth logs require Dashboard or Management API access.',
   'Do not grant anon access to fix authenticated app errors.'
 )
)) AS full_schema_auth_audit;
ROLLBACK;
