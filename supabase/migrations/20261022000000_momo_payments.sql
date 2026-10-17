BEGIN;

-- Cho phép provider 'momo'
ALTER TABLE public.learning_payments    DROP CONSTRAINT IF EXISTS learning_payments_provider_check;
ALTER TABLE public.learning_payments    ADD  CONSTRAINT learning_payments_provider_check CHECK (provider IN ('vnpay','momo'));
ALTER TABLE public.payment_events       DROP CONSTRAINT IF EXISTS payment_events_provider_check;
ALTER TABLE public.payment_events       ADD  CONSTRAINT payment_events_provider_check CHECK (provider IN ('vnpay','momo'));
ALTER TABLE public.subscription_periods DROP CONSTRAINT IF EXISTS subscription_periods_source_check;
ALTER TABLE public.subscription_periods ADD  CONSTRAINT subscription_periods_source_check CHECK (source IN ('vnpay','momo','legacy_admin','admin'));

CREATE FUNCTION private.settle_momo_order(p_order uuid, p_transaction text, p_amount bigint, p_result integer)
    RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
o public.learning_orders; payment_id uuid;
  start_time timestamptz; end_time timestamptz; old_tier public.subscription_tier;
BEGIN
SELECT * INTO o FROM public.learning_orders WHERE id = p_order FOR UPDATE;
IF NOT FOUND THEN RETURN 'NOT_FOUND'; END IF;
  IF o.amount_vnd <> p_amount THEN RETURN 'BAD_AMOUNT'; END IF;
  IF o.status IN ('paid','refunded') THEN RETURN 'OK'; END IF;   -- IPN gửi lặp vẫn OK

INSERT INTO public.payment_events(order_id, provider, external_event_id, response_code)
VALUES (o.id, 'momo', o.id::text || ':' || p_transaction || ':' || p_result, p_result::text)
    ON CONFLICT (provider, external_event_id) DO NOTHING;

IF p_result <> 0 THEN
UPDATE public.learning_orders SET status = 'failed' WHERE id = o.id AND status = 'pending';
RETURN 'OK';
END IF;
  IF nullif(p_transaction,'') IS NULL OR p_transaction = '0' THEN RETURN 'RETRY'; END IF;

  PERFORM 1 FROM public.parents WHERE id = o.parent_id FOR UPDATE;
SELECT tier INTO old_tier FROM public.subscriptions WHERE parent_id = o.parent_id;
SELECT CASE WHEN tier='plus' AND status='active' THEN greatest(now(), expires_at) ELSE now() END
INTO start_time FROM public.subscriptions WHERE parent_id = o.parent_id;
start_time := coalesce(start_time, now());

  IF EXISTS (SELECT 1 FROM public.subscriptions
             WHERE parent_id = o.parent_id AND tier='plus' AND status='active' AND expires_at IS NULL)
  THEN end_time := NULL;
ELSE end_time := start_time + make_interval(months => (o.snapshot->>'duration_months')::integer);
END IF;

INSERT INTO public.learning_payments(order_id, provider, external_transaction_id, amount_vnd)
VALUES (o.id, 'momo', p_transaction, p_amount) RETURNING id INTO payment_id;

INSERT INTO public.subscription_periods(parent_id, payment_id, source, starts_at, ends_at, snapshot)
VALUES (o.parent_id, payment_id, 'momo', start_time, end_time, o.snapshot);

INSERT INTO public.subscriptions(parent_id, tier, status, max_kids, start_date, expires_at, notes)
VALUES (o.parent_id, 'plus', 'active', (o.snapshot->>'max_kids')::integer, now(), end_time, 'MoMo ' || o.id)
    ON CONFLICT (parent_id) DO UPDATE SET tier='plus', status='active', max_kids=EXCLUDED.max_kids,
                                   expires_at=EXCLUDED.expires_at, updated_at=now(), notes=EXCLUDED.notes;

INSERT INTO public.subscription_logs(parent_id, action, old_tier, new_tier, reason)
VALUES (o.parent_id, 'PURCHASE', old_tier, 'plus', 'MoMo order ' || o.id);

UPDATE public.learning_orders SET status = 'paid', paid_at = now() WHERE id = o.id;
RETURN 'OK';
END $$;

CREATE FUNCTION public.settle_momo_order(p_order uuid, p_transaction text, p_amount bigint, p_result integer)
    RETURNS text LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$
SELECT private.settle_momo_order(p_order, p_transaction, p_amount, p_result); $$;

REVOKE ALL ON FUNCTION private.settle_momo_order(uuid,text,bigint,integer) FROM PUBLIC;
GRANT  EXECUTE ON FUNCTION private.settle_momo_order(uuid,text,bigint,integer) TO service_role;
REVOKE ALL ON FUNCTION public.settle_momo_order(uuid,text,bigint,integer) FROM PUBLIC, anon, authenticated;
GRANT  EXECUTE ON FUNCTION public.settle_momo_order(uuid,text,bigint,integer) TO service_role;

COMMIT;