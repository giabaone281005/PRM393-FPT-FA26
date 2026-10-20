BEGIN;

-- Compatibility APIs retain orders, support links and provider evidence.
-- A late verified callback can still settle an expired order.
CREATE OR REPLACE FUNCTION private.discard_unpaid_order(p_order uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE o public.learning_orders;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Cần đăng nhập'; END IF;
  SELECT * INTO o FROM public.learning_orders
  WHERE id = p_order AND parent_id = auth.uid() FOR UPDATE;
  IF NOT FOUND OR o.status NOT IN ('pending','failed','expired') THEN RETURN false; END IF;
  IF EXISTS (SELECT 1 FROM public.learning_payments WHERE order_id=o.id) THEN RETURN false; END IF;
  UPDATE public.learning_orders SET status='expired', expires_at=least(expires_at,now()) WHERE id=o.id;
  RETURN true;
END $$;

CREATE OR REPLACE FUNCTION public.discard_unpaid_order(p_order uuid)
RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.discard_unpaid_order(p_order); $$;
REVOKE ALL ON FUNCTION private.discard_unpaid_order(uuid),public.discard_unpaid_order(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.discard_unpaid_order(uuid),public.discard_unpaid_order(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION private.purge_unpaid_orders(p_parent uuid, p_grace interval DEFAULT interval '30 minutes')
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE n integer;
BEGIN
  IF auth.uid() IS NOT NULL AND p_parent IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Chỉ được xử lý đơn của chính mình';
  END IF;
  IF auth.uid() IS NULL AND coalesce(auth.role(),'') <> 'service_role' THEN RETURN 0; END IF;
  UPDATE public.learning_orders o SET status='expired'
  WHERE o.status='pending' AND (p_parent IS NULL OR o.parent_id=p_parent)
    AND o.expires_at < now() AND o.created_at < now()-greatest(p_grace,interval '0 seconds')
    AND NOT EXISTS (SELECT 1 FROM public.learning_payments p WHERE p.order_id=o.id);
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN n;
END $$;

CREATE OR REPLACE FUNCTION public.purge_my_unpaid_orders()
RETURNS integer LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT CASE WHEN auth.uid() IS NULL THEN 0 ELSE private.purge_unpaid_orders(auth.uid()) END; $$;
REVOKE ALL ON FUNCTION private.purge_unpaid_orders(uuid,interval),public.purge_my_unpaid_orders() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.purge_unpaid_orders(uuid,interval) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.purge_my_unpaid_orders() TO authenticated;

CREATE TABLE IF NOT EXISTS public.learning_checkout_attempts (
  order_id uuid PRIMARY KEY REFERENCES public.learning_orders(id),
  provider text NOT NULL CHECK (provider IN ('momo','vnpay')),
  environment text NOT NULL CHECK (environment IN ('sandbox','live')),
  gateway_order_id text NOT NULL UNIQUE,
  checkout_response jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.learning_checkout_attempts ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.learning_checkout_attempts FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.learning_checkout_attempts TO authenticated;
GRANT ALL ON public.learning_checkout_attempts TO service_role;
DROP POLICY IF EXISTS checkout_attempt_read ON public.learning_checkout_attempts;
CREATE POLICY checkout_attempt_read ON public.learning_checkout_attempts FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.learning_orders o
  WHERE o.id=order_id AND (o.parent_id=(SELECT auth.uid()) OR (SELECT public.is_admin()))));

CREATE OR REPLACE FUNCTION private.reserve_learning_checkout(p_order uuid,p_parent uuid,p_provider text,p_environment text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE o public.learning_orders; a public.learning_checkout_attempts;
BEGIN
  IF p_provider NOT IN ('momo','vnpay') OR p_environment NOT IN ('sandbox','live') THEN
    RAISE EXCEPTION 'Kênh thanh toán không hợp lệ';
  END IF;
  SELECT * INTO o FROM public.learning_orders WHERE id=p_order AND parent_id=p_parent FOR UPDATE;
  IF NOT FOUND OR o.status<>'pending' OR o.expires_at<=now() THEN RAISE EXCEPTION 'Đơn đã xử lý hoặc hết hạn'; END IF;
  INSERT INTO public.learning_checkout_attempts(order_id,provider,environment,gateway_order_id)
  VALUES(o.id,p_provider,p_environment,replace(o.id::text,'-','')) ON CONFLICT(order_id) DO NOTHING;
  SELECT * INTO a FROM public.learning_checkout_attempts WHERE order_id=o.id;
  IF a.provider<>p_provider OR a.environment<>p_environment THEN
    RAISE EXCEPTION 'Đơn đã có kênh thanh toán. Kiểm tra đơn hiện tại trước khi mua lại';
  END IF;
  RETURN to_jsonb(a);
END $$;
CREATE OR REPLACE FUNCTION public.reserve_learning_checkout(p_order uuid,p_parent uuid,p_provider text,p_environment text)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.reserve_learning_checkout(p_order,p_parent,p_provider,p_environment); $$;
REVOKE ALL ON FUNCTION private.reserve_learning_checkout(uuid,uuid,text,text),public.reserve_learning_checkout(uuid,uuid,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.reserve_learning_checkout(uuid,uuid,text,text),public.reserve_learning_checkout(uuid,uuid,text,text) TO service_role;

CREATE OR REPLACE FUNCTION private.save_learning_checkout(p_order uuid,p_gateway text,p_response jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE a public.learning_checkout_attempts;
BEGIN
  UPDATE public.learning_checkout_attempts SET checkout_response=coalesce(checkout_response,p_response)
  WHERE order_id=p_order AND gateway_order_id=p_gateway RETURNING * INTO a;
  IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy lượt thanh toán'; END IF;
  RETURN a.checkout_response;
END $$;
CREATE OR REPLACE FUNCTION public.save_learning_checkout(p_order uuid,p_gateway text,p_response jsonb)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.save_learning_checkout(p_order,p_gateway,p_response); $$;
REVOKE ALL ON FUNCTION private.save_learning_checkout(uuid,text,jsonb),public.save_learning_checkout(uuid,text,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.save_learning_checkout(uuid,text,jsonb),public.save_learning_checkout(uuid,text,jsonb) TO service_role;


CREATE OR REPLACE FUNCTION private.settle_momo_order(p_order uuid, p_transaction text, p_amount bigint, p_result integer)
    RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE
o public.learning_orders; payment_id uuid;
  start_time timestamptz; end_time timestamptz; old_tier public.subscription_tier; event_id uuid;
BEGIN
SELECT * INTO o FROM public.learning_orders WHERE id = p_order FOR UPDATE;
IF NOT FOUND THEN RETURN 'NOT_FOUND'; END IF;
  IF o.amount_vnd <> p_amount THEN RETURN 'BAD_AMOUNT'; END IF;
  IF EXISTS (SELECT 1 FROM public.learning_checkout_attempts a WHERE a.order_id=o.id AND a.provider<>'momo') THEN RETURN 'BAD_PROVIDER'; END IF;
  IF o.status IN ('paid','refunded') THEN
    IF p_result<>0 THEN RETURN 'OK'; END IF;
    IF nullif(p_transaction,'') IS NULL OR p_transaction='0' THEN RETURN 'RETRY'; END IF;
    IF EXISTS (SELECT 1 FROM public.learning_payments WHERE order_id=o.id AND provider='momo' AND external_transaction_id=p_transaction) THEN RETURN 'OK'; END IF;
    INSERT INTO public.payment_events(order_id,provider,external_event_id,response_code)
    VALUES(o.id,'momo',o.id::text||':'||p_transaction||':duplicate','REVIEW_DUPLICATE')
    ON CONFLICT(provider,external_event_id) DO NOTHING RETURNING id INTO event_id;
    IF event_id IS NOT NULL THEN
      INSERT INTO public.admin_audit_logs(action,target_type,target_id,details)
      VALUES('PAYMENT_REVIEW','learning_orders',o.id::text,
        jsonb_build_object('provider','momo','transaction',p_transaction,'amount_vnd',p_amount,'reason','additional_successful_transaction'));
    END IF;
    RETURN 'REVIEW';
  END IF;

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

CREATE OR REPLACE FUNCTION private.settle_vnpay_order(p_order uuid,p_transaction text,p_amount bigint,p_code text,p_transaction_status text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE o public.learning_orders; payment_id uuid; start_time timestamptz; end_time timestamptz; old_tier public.subscription_tier;
BEGIN
 SELECT * INTO o FROM public.learning_orders WHERE id=p_order FOR UPDATE;
 IF NOT FOUND THEN RETURN '01'; END IF;
 IF o.amount_vnd<>p_amount THEN RETURN '04'; END IF;
 IF EXISTS (SELECT 1 FROM public.learning_checkout_attempts a WHERE a.order_id=o.id AND a.provider<>'vnpay') THEN RETURN '04'; END IF;
 IF o.status='paid' THEN RETURN '02'; END IF;
 IF o.status NOT IN ('pending','expired','failed') THEN RETURN '02'; END IF;
 IF o.status='failed' AND (p_code<>'00' OR p_transaction_status<>'00') THEN RETURN '02'; END IF;
 INSERT INTO public.payment_events(order_id,provider,external_event_id,response_code)
 VALUES(o.id,'vnpay',o.id::text||':'||p_transaction||':'||p_code||':'||p_transaction_status,p_code)
 ON CONFLICT(provider,external_event_id) DO NOTHING;
 IF p_code<>'00' OR p_transaction_status<>'00' THEN
 UPDATE public.learning_orders SET status='failed' WHERE id=o.id;
 RETURN '00';
 END IF;
 IF nullif(p_transaction,'') IS NULL OR p_transaction='0' THEN RETURN '99'; END IF;
 PERFORM 1 FROM public.parents WHERE id=o.parent_id FOR UPDATE;
 SELECT tier INTO old_tier FROM public.subscriptions WHERE parent_id=o.parent_id;
 SELECT CASE WHEN tier='plus' AND status='active' THEN greatest(now(),expires_at) ELSE now() END
 INTO start_time FROM public.subscriptions WHERE parent_id=o.parent_id;
 start_time:=coalesce(start_time,now());
 -- Existing perpetual rights stay perpetual even if granted during a pending checkout.
 IF EXISTS(SELECT 1 FROM public.subscriptions WHERE parent_id=o.parent_id AND tier='plus' AND status='active' AND expires_at IS NULL)
 THEN end_time:=NULL; ELSE end_time:=start_time+make_interval(months=>(o.snapshot->>'duration_months')::integer); END IF;
 INSERT INTO public.learning_payments(order_id,provider,external_transaction_id,amount_vnd)
 VALUES(o.id,'vnpay',p_transaction,p_amount) RETURNING id INTO payment_id;
 INSERT INTO public.subscription_periods(parent_id,payment_id,source,starts_at,ends_at,snapshot)
 VALUES(o.parent_id,payment_id,'vnpay',start_time,end_time,o.snapshot);
 INSERT INTO public.subscriptions(parent_id,tier,status,max_kids,start_date,expires_at,notes)
 VALUES(o.parent_id,'plus','active',(o.snapshot->>'max_kids')::integer,now(),end_time,'VNPay '||o.id)
 ON CONFLICT(parent_id) DO UPDATE SET tier='plus',status='active',max_kids=EXCLUDED.max_kids,
 expires_at=EXCLUDED.expires_at,updated_at=now(),notes=EXCLUDED.notes;
 INSERT INTO public.subscription_logs(parent_id,action,old_tier,new_tier,reason)
 VALUES(o.parent_id,'PURCHASE',old_tier,'plus','VNPay order '||o.id);
 UPDATE public.learning_orders SET status='paid',paid_at=now() WHERE id=o.id;
 RETURN '00';
END $$;

COMMIT;
