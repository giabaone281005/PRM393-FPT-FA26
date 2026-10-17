-- READ ONLY. Run AFTER new migrations on the Cloud schema diagnosed by the user.
-- Requires the legacy orders/payments tables to already exist.
BEGIN READ ONLY;
DO $$ BEGIN
IF (to_regclass('public.orders') IS NOT NULL AND to_regclass('public.payments') IS NOT NULL) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: legacy tables retained';END IF;
IF (to_regclass('public.learning_orders') IS NOT NULL AND to_regclass('public.learning_payments') IS NOT NULL) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: new commerce tables exist independently';END IF;
IF (to_regclass('public.orders')<>to_regclass('public.learning_orders') AND to_regclass('public.payments')<>to_regclass('public.learning_payments')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: legacy and new relations are distinct';END IF;
IF (EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='order_code' AND is_nullable='NO')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: legacy order_code retained';END IF;
IF (EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='orders' AND column_name='plan_id' AND is_nullable='NO')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: legacy plan_id retained';END IF;
IF (EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='payments' AND column_name='order_id' AND data_type='text')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: legacy payment order_id remains text';END IF;
IF (EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='learning_payments' AND column_name='order_id' AND data_type='uuid')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: new verified payment order_id is UUID';END IF;
IF (EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.orders'::regclass AND confrelid=to_regclass('public.subscription_plans') AND contype='f')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: legacy subscription_plans reference retained';END IF;
IF (EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.learning_payments'::regclass AND confrelid='public.learning_orders'::regclass AND contype='f')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: new payments reference new orders';END IF;
IF (EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.payment_events'::regclass AND confrelid='public.learning_orders'::regclass AND contype='f')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: new provider events cannot reference legacy orders';END IF;
IF (EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.subscription_periods'::regclass AND confrelid='public.learning_payments'::regclass AND contype='f')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: new entitlement periods use verified learning payments';END IF;
IF (NOT has_function_privilege('authenticated','private.legacy_commerce_history(uuid)','EXECUTE')) IS DISTINCT FROM true THEN RAISE EXCEPTION 'Assertion failed: legacy financial history helper cannot be called directly';END IF;
END $$;
SELECT 'legacy commerce compatibility passed' AS result;
ROLLBACK;
