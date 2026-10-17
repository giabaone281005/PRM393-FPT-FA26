-- READ ONLY. Run after reconnecting Dashboard if a migration response was lost.
-- Works before or after the new migrations. Never reruns DDL.
SELECT '20261018 commerce' AS migration,
 (to_regclass('public.learning_orders') IS NOT NULL
 AND to_regclass('public.learning_plans') IS NOT NULL
 AND to_regclass('public.plan_prices') IS NOT NULL
 AND to_regclass('public.learning_payments') IS NOT NULL
 AND to_regclass('public.payment_events') IS NOT NULL
 AND to_regclass('public.subscription_periods') IS NOT NULL
 AND to_regprocedure('public.settle_vnpay_order(uuid,text,bigint,text,text)') IS NOT NULL
 AND to_regprocedure('public.has_parent_pin()') IS NOT NULL
 AND to_regprocedure('public.complete_kid_lesson(uuid,uuid,integer,integer)') IS NOT NULL) AS objects_present
UNION ALL SELECT '20261019 verified sessions',
 to_regprocedure('public.create_learning_order(uuid,uuid,text)') IS NOT NULL
 AND to_regprocedure('public.answer_learning_session(uuid,text,jsonb,uuid,integer)') IS NOT NULL
UNION ALL SELECT '20261020 content/economy',
 to_regprocedure('public.set_user_role(uuid,public.app_role,boolean,text)') IS NOT NULL
 AND to_regclass('public.lesson_versions') IS NOT NULL
UNION ALL SELECT '20261021 payment/AI/support',
 to_regprocedure('public.resolve_support(uuid,text)') IS NOT NULL
 AND to_regclass('public.refund_requests') IS NOT NULL;

-- Confirm signatures if a previous version of a new file was run during development.
SELECT n.nspname,p.proname,pg_get_function_identity_arguments(p.oid)
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname IN ('create_learning_order','answer_learning_session','resolve_support')
ORDER BY 2,3;
-- These markers assume each provided migration was run as one complete transaction.
-- Partial selections/manual edits require checking the actual object definitions.
