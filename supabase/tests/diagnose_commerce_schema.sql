-- READ ONLY. Run as postgres in SQL Editor on the SAME project that reported
-- "relation orders already exists". Returns one JSON cell, without customer rows.
SELECT jsonb_pretty(jsonb_build_object(
 'tables',(
   SELECT jsonb_agg(jsonb_build_object('name',name,'exists',to_regclass('public.'||name) IS NOT NULL) ORDER BY name)
   FROM unnest(ARRAY['learning_plans','plan_prices','orders','payments','learning_orders','learning_payments','payment_events','subscription_periods']) name
 ),
 'columns',(
   SELECT coalesce(jsonb_agg(jsonb_build_object('table',c.relname,'column',a.attname,
     'type',format_type(a.atttypid,a.atttypmod),'not_null',a.attnotnull,
     'default',pg_get_expr(d.adbin,d.adrelid)) ORDER BY c.relname,a.attnum),'[]'::jsonb)
   FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
   JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped
   LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum
   WHERE n.nspname='public' AND c.relname IN ('learning_plans','plan_prices','orders','payments','learning_orders','learning_payments','payment_events','subscription_periods')
 ),
 'constraints',(
   SELECT coalesce(jsonb_agg(jsonb_build_object('table',c.relname,'name',con.conname,
     'definition',pg_get_constraintdef(con.oid),'validated',con.convalidated) ORDER BY c.relname,con.conname),'[]'::jsonb)
   FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace
   WHERE n.nspname='public' AND c.relname IN ('learning_plans','plan_prices','orders','payments','learning_orders','learning_payments','payment_events','subscription_periods')
 ),
 'functions',(
   SELECT coalesce(jsonb_agg(jsonb_build_object('schema',n.nspname,'name',p.proname,
     'arguments',pg_get_function_identity_arguments(p.oid),'returns',pg_get_function_result(p.oid)) ORDER BY n.nspname,p.proname),'[]'::jsonb)
   FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
   WHERE n.nspname IN ('public','private') AND p.proname IN
     ('create_learning_order','claim_vnpay_check','settle_vnpay_order','has_parent_pin','verify_parent_pin','set_parent_pin','complete_kid_lesson','admin_upgrade_subscription')
 ),
 'indexes',(
   SELECT coalesce(jsonb_agg(jsonb_build_object('table',tablename,'name',indexname,'definition',indexdef) ORDER BY tablename,indexname),'[]'::jsonb)
   FROM pg_indexes WHERE schemaname='public' AND tablename IN ('learning_plans','plan_prices','orders','payments','learning_orders','learning_payments','payment_events','subscription_periods')
 ),
 'rls',(
   SELECT coalesce(jsonb_agg(jsonb_build_object('table',tablename,'enabled',rowsecurity) ORDER BY tablename),'[]'::jsonb)
   FROM pg_tables WHERE schemaname='public' AND tablename IN ('learning_plans','plan_prices','orders','payments','learning_orders','learning_payments','payment_events','subscription_periods')
 ),
 'policies',(
   SELECT coalesce(jsonb_agg(jsonb_build_object('table',tablename,'name',policyname,'command',cmd,
     'roles',roles,'using',qual,'check',with_check) ORDER BY tablename,policyname),'[]'::jsonb)
   FROM pg_policies WHERE schemaname='public' AND tablename IN ('learning_plans','plan_prices','orders','payments','learning_orders','learning_payments','payment_events','subscription_periods')
 )
)) AS commerce_schema_diagnostic;
