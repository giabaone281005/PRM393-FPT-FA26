BEGIN;

-- Separate demonstration ledger: never impersonate a merchant transaction.
CREATE TABLE IF NOT EXISTS private.demo_payment_settings (
  id boolean PRIMARY KEY DEFAULT true CHECK (id),
  enabled boolean NOT NULL DEFAULT false,
  expires_at timestamptz NOT NULL
);
ALTER TABLE private.demo_payment_settings ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.demo_payment_settings FROM PUBLIC, anon, authenticated;
INSERT INTO private.demo_payment_settings(id,enabled,expires_at)
VALUES(true,true,now()+interval '48 hours') ON CONFLICT(id) DO NOTHING;

CREATE TABLE IF NOT EXISTS public.demo_payment_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id uuid NOT NULL REFERENCES public.parents(id),
  plan_price_id uuid NOT NULL REFERENCES public.plan_prices(id),
  amount_vnd bigint NOT NULL CHECK(amount_vnd>0),
  currency text NOT NULL DEFAULT 'VND' CHECK(currency='VND'),
  snapshot jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','paid')),
  idempotency_key uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT now()+interval '15 minutes',
  paid_at timestamptz,
  external_transaction_id text UNIQUE,
  UNIQUE(parent_id,idempotency_key),
  CHECK((status='pending' AND paid_at IS NULL AND external_transaction_id IS NULL)
    OR (status='paid' AND paid_at IS NOT NULL AND external_transaction_id LIKE 'DEMO-%'))
);
CREATE INDEX IF NOT EXISTS demo_payment_parent_created_idx
ON public.demo_payment_transactions(parent_id,created_at DESC);
ALTER TABLE public.demo_payment_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS demo_payment_read ON public.demo_payment_transactions;
CREATE POLICY demo_payment_read ON public.demo_payment_transactions FOR SELECT
TO authenticated USING(parent_id=(SELECT auth.uid()) OR (SELECT public.is_admin()));
REVOKE ALL ON public.demo_payment_transactions FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.demo_payment_transactions TO authenticated;

ALTER TABLE public.subscription_periods DROP CONSTRAINT IF EXISTS subscription_periods_source_check;
ALTER TABLE public.subscription_periods ADD CONSTRAINT subscription_periods_source_check
CHECK(source IN ('vnpay','momo','trial','legacy_admin','admin','demo'));
CREATE UNIQUE INDEX IF NOT EXISTS subscription_period_demo_transaction_idx
ON public.subscription_periods((snapshot->>'demo_transaction_id')) WHERE source='demo';

CREATE OR REPLACE FUNCTION private.demo_payment_available()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
  SELECT auth.uid() IS NOT NULL AND EXISTS(SELECT 1 FROM private.demo_payment_settings
    WHERE id AND enabled AND expires_at>now());
$$;
CREATE OR REPLACE FUNCTION public.demo_payment_available()
RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.demo_payment_available();
$$;

CREATE OR REPLACE FUNCTION private.create_demo_payment(p_price uuid,p_key uuid,p_token text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE d public.demo_payment_transactions; price public.plan_prices; plan public.learning_plans;
BEGIN
  IF auth.uid() IS NULL OR NOT private.parent_authorized(p_token) THEN
    RAISE EXCEPTION 'Cần mở cổng phụ huynh'; END IF;
  IF NOT private.demo_payment_available() THEN RAISE EXCEPTION 'Thanh toán demo đang tắt'; END IF;
  IF p_key IS NULL THEN RAISE EXCEPTION 'Thiếu mã yêu cầu'; END IF;
  PERFORM 1 FROM public.parents WHERE id=auth.uid() FOR UPDATE;
  SELECT * INTO d FROM public.demo_payment_transactions
  WHERE parent_id=auth.uid() AND idempotency_key=p_key;
  IF FOUND THEN
    IF d.plan_price_id<>p_price THEN RAISE EXCEPTION 'Mã yêu cầu đã được dùng'; END IF;
    RETURN to_jsonb(d);
  END IF;
  SELECT * INTO price FROM public.plan_prices WHERE id=p_price AND published FOR SHARE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Gói chưa được mở bán'; END IF;
  SELECT * INTO plan FROM public.learning_plans WHERE id=price.plan_id AND published FOR SHARE;
  IF NOT FOUND OR plan.tier<>'plus' THEN RAISE EXCEPTION 'Gói không hợp lệ'; END IF;
  IF EXISTS(SELECT 1 FROM public.subscriptions WHERE parent_id=auth.uid()
    AND tier='plus' AND status='active' AND expires_at IS NULL) THEN
    RAISE EXCEPTION 'Gia đình đã có Plus không thời hạn'; END IF;
  INSERT INTO public.demo_payment_transactions(parent_id,plan_price_id,amount_vnd,idempotency_key,snapshot)
  VALUES(auth.uid(),p_price,price.amount_vnd,p_key,jsonb_build_object(
    'label',price.label,'name',plan.name,'duration_months',price.duration_months,
    'max_kids',plan.max_kids,'is_demo',true,'provider','demo')) RETURNING * INTO d;
  RETURN to_jsonb(d);
END $$;
CREATE OR REPLACE FUNCTION public.create_demo_payment(p_price uuid,p_key uuid,p_token text)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.create_demo_payment(p_price,p_key,p_token);
$$;

CREATE OR REPLACE FUNCTION private.confirm_demo_payment(p_transaction uuid,p_token text)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE d public.demo_payment_transactions; sub public.subscriptions;
  start_time timestamptz; end_time timestamptz;
BEGIN
  IF auth.uid() IS NULL OR NOT private.parent_authorized(p_token) THEN
    RAISE EXCEPTION 'Cần mở cổng phụ huynh'; END IF;
  PERFORM 1 FROM public.parents WHERE id=auth.uid() FOR UPDATE;
  SELECT * INTO d FROM public.demo_payment_transactions
  WHERE id=p_transaction AND parent_id=auth.uid() FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy giao dịch demo'; END IF;
  -- Retrying an already committed confirmation never adds another period.
  IF d.status='paid' THEN RETURN to_jsonb(d); END IF;
  IF NOT private.demo_payment_available() THEN RAISE EXCEPTION 'Thanh toán demo đang tắt'; END IF;
  IF d.expires_at<=now() THEN RAISE EXCEPTION 'Giao dịch demo đã hết hạn'; END IF;
  SELECT * INTO sub FROM public.subscriptions WHERE parent_id=auth.uid() FOR UPDATE;
  start_time:=CASE WHEN sub.tier='plus' AND sub.status='active'
    THEN greatest(now(),sub.expires_at) ELSE now() END;
  IF sub.tier='plus' AND sub.status='active' AND sub.expires_at IS NULL THEN end_time:=NULL;
  ELSE end_time:=start_time+make_interval(months=>(d.snapshot->>'duration_months')::integer); END IF;
  INSERT INTO public.subscription_periods(parent_id,source,starts_at,ends_at,snapshot)
  VALUES(d.parent_id,'demo',start_time,end_time,
    d.snapshot||jsonb_build_object('demo_transaction_id',d.id));
  INSERT INTO public.subscriptions(parent_id,tier,status,max_kids,start_date,expires_at,notes)
  VALUES(d.parent_id,'plus','active',(d.snapshot->>'max_kids')::integer,now(),end_time,'DEMO '||d.id)
  ON CONFLICT(parent_id) DO UPDATE SET tier='plus',status='active',max_kids=EXCLUDED.max_kids,
    expires_at=EXCLUDED.expires_at,updated_at=now(),notes=EXCLUDED.notes;
  INSERT INTO public.subscription_logs(parent_id,action,old_tier,new_tier,reason)
  VALUES(d.parent_id,'DEMO_PURCHASE',sub.tier,'plus','Mô phỏng, không thu tiền: '||d.id);
  UPDATE public.demo_payment_transactions SET status='paid',paid_at=now(),
    external_transaction_id='DEMO-'||id::text WHERE id=d.id RETURNING * INTO d;
  RETURN to_jsonb(d);
END $$;
CREATE OR REPLACE FUNCTION public.confirm_demo_payment(p_transaction uuid,p_token text)
RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
  SELECT private.confirm_demo_payment(p_transaction,p_token);
$$;

REVOKE ALL ON FUNCTION private.demo_payment_available(),public.demo_payment_available(),
  private.create_demo_payment(uuid,uuid,text),public.create_demo_payment(uuid,uuid,text),
  private.confirm_demo_payment(uuid,text),public.confirm_demo_payment(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.demo_payment_available(),public.demo_payment_available(),
  private.create_demo_payment(uuid,uuid,text),public.create_demo_payment(uuid,uuid,text),
  private.confirm_demo_payment(uuid,text),public.confirm_demo_payment(uuid,text) TO authenticated;

-- Publish only tables already readable under existing RLS. Never publish answers
-- or private PIN/unlock tables, and never broaden their SELECT policies.
DO $$
DECLARE table_name text;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM pg_publication WHERE pubname='supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime;
  END IF;
  FOREACH table_name IN ARRAY ARRAY['kid_profiles','subscriptions','kid_progress',
    'study_sessions','study_daily_usage','kid_equipment','notifications','support_requests',
    'learning_orders','plan_prices','lessons','user_roles','demo_payment_transactions'] LOOP
    IF NOT EXISTS(SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime'
      AND schemaname='public' AND tablename=table_name) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I',table_name);
    END IF;
  END LOOP;
END $$;
COMMIT;
