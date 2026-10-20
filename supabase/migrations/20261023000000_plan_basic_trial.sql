BEGIN;

-- 1) Mở rộng catalog để lưu mô tả gói
ALTER TABLE public.learning_plans
    ADD COLUMN IF NOT EXISTS features        jsonb   NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS trial_days      integer NOT NULL DEFAULT 0 CHECK (trial_days BETWEEN 0 AND 30),
    ADD COLUMN IF NOT EXISTS requires_wallet boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS sort_order      integer NOT NULL DEFAULT 100;

-- (lặp lại cho an toàn, chạy nhiều lần không sao)
ALTER TABLE public.subscription_periods DROP CONSTRAINT IF EXISTS subscription_periods_source_check;
ALTER TABLE public.subscription_periods ADD CONSTRAINT subscription_periods_source_check
    CHECK (source IN ('vnpay','momo','trial','legacy_admin','admin'));

-- 2) Ví đã gắn: chỉ lưu dạng băm + 3 số cuối
CREATE TABLE public.parent_wallets (
                                       id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
                                       parent_id uuid NOT NULL REFERENCES public.parents(id) ON DELETE CASCADE,
                                       provider text NOT NULL CHECK (provider IN ('momo','vnpay')),
                                       wallet_hash text NOT NULL,
                                       wallet_hint text NOT NULL,
                                       status text NOT NULL DEFAULT 'linked' CHECK (status IN ('linked','unlinked')),
                                       provider_token text,                       -- để dành: token liên kết thật của MoMo/VNPay sau này
                                       created_at timestamptz NOT NULL DEFAULT now(),
                                       UNIQUE (provider, wallet_hash)             -- 1 ví chỉ thuộc 1 gia đình
);
CREATE UNIQUE INDEX one_linked_wallet_per_parent ON public.parent_wallets(parent_id) WHERE status = 'linked';

-- 3) Mỗi gia đình / mỗi ví chỉ dùng thử một lần
CREATE TABLE public.trial_grants (
                                     parent_id uuid PRIMARY KEY REFERENCES public.parents(id) ON DELETE CASCADE,
                                     wallet_id uuid NOT NULL UNIQUE REFERENCES public.parent_wallets(id),
                                     plan_code text NOT NULL DEFAULT 'basic_trial',
                                     started_at timestamptz NOT NULL DEFAULT now(),
                                     ends_at timestamptz NOT NULL
);

ALTER TABLE public.parent_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trial_grants   ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.parent_wallets, public.trial_grants FROM PUBLIC, anon, authenticated;
-- Chỉ mở cột an toàn. App phải select đúng các cột này, không dùng select() trần
GRANT SELECT (id, parent_id, provider, wallet_hint, status, created_at) ON public.parent_wallets TO authenticated;
GRANT SELECT ON public.trial_grants TO authenticated;
GRANT ALL ON public.parent_wallets, public.trial_grants TO service_role;
CREATE POLICY wallets_read ON public.parent_wallets FOR SELECT TO authenticated
                                                                      USING (parent_id = (SELECT auth.uid()) OR public.is_admin());
CREATE POLICY trials_read ON public.trial_grants FOR SELECT TO authenticated
                                                         USING (parent_id = (SELECT auth.uid()) OR public.is_admin());

-- 4) Gắn ví (cần đã mở cổng phụ huynh)
CREATE FUNCTION private.link_wallet(p_provider text, p_phone text, p_token text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE digits text; h text; w public.parent_wallets;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Cần đăng nhập'; END IF;
  IF NOT private.parent_authorized(p_token) THEN RAISE EXCEPTION 'Cần mở cổng phụ huynh'; END IF;
  IF p_provider NOT IN ('momo','vnpay') THEN RAISE EXCEPTION 'Loại ví không hợp lệ'; END IF;
  digits := regexp_replace(coalesce(p_phone,''), '[^0-9]', '', 'g');
  IF digits ~ '^84' THEN digits := '0' || substr(digits, 3); END IF;
  IF digits !~ '^0[0-9]{9}$' THEN RAISE EXCEPTION 'Số điện thoại ví không hợp lệ'; END IF;
  h := encode(extensions.digest(p_provider || ':' || digits, 'sha256'), 'hex');

  PERFORM 1 FROM public.parents WHERE id = auth.uid() FOR UPDATE;
SELECT * INTO w FROM public.parent_wallets WHERE provider = p_provider AND wallet_hash = h;
IF FOUND AND w.parent_id <> auth.uid() THEN
    RAISE EXCEPTION 'Ví này đã được liên kết với tài khoản khác';
END IF;

  IF NOT FOUND THEN
UPDATE public.parent_wallets SET status = 'unlinked' WHERE parent_id = auth.uid() AND status = 'linked';
INSERT INTO public.parent_wallets(parent_id, provider, wallet_hash, wallet_hint)
VALUES (auth.uid(), p_provider, h, repeat('*', 7) || right(digits, 3)) RETURNING * INTO w;
ELSE
UPDATE public.parent_wallets SET status = 'unlinked' WHERE parent_id = auth.uid() AND status = 'linked' AND id <> w.id;
UPDATE public.parent_wallets SET status = 'linked' WHERE id = w.id RETURNING * INTO w;
END IF;
RETURN jsonb_build_object('id', w.id, 'provider', w.provider, 'hint', w.wallet_hint);
END $$;

-- 5) Bắt đầu dùng thử 7 ngày
CREATE FUNCTION private.start_basic_trial(p_token text) RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE w public.parent_wallets; cur public.subscriptions; ends timestamptz; old_tier public.subscription_tier;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Cần đăng nhập'; END IF;
  IF NOT private.parent_authorized(p_token) THEN RAISE EXCEPTION 'Cần mở cổng phụ huynh'; END IF;
  PERFORM 1 FROM public.parents WHERE id = auth.uid() FOR UPDATE;

SELECT * INTO w FROM public.parent_wallets WHERE parent_id = auth.uid() AND status = 'linked';
IF NOT FOUND THEN RAISE EXCEPTION 'Cần gắn ví MoMo/VNPay trước khi dùng thử'; END IF;
  IF EXISTS (SELECT 1 FROM public.trial_grants WHERE parent_id = auth.uid()) THEN
    RAISE EXCEPTION 'Gia đình này đã dùng thử rồi'; END IF;
  IF EXISTS (SELECT 1 FROM public.trial_grants WHERE wallet_id = w.id) THEN
    RAISE EXCEPTION 'Ví này đã được dùng để dùng thử'; END IF;
  IF EXISTS (SELECT 1 FROM public.subscription_periods WHERE parent_id = auth.uid() AND source IN ('vnpay','momo')) THEN
    RAISE EXCEPTION 'Dùng thử chỉ dành cho gia đình chưa từng mua Plus'; END IF;

SELECT * INTO cur FROM public.subscriptions WHERE parent_id = auth.uid();
IF FOUND AND cur.tier = 'plus' AND cur.status = 'active' AND (cur.expires_at IS NULL OR cur.expires_at > now()) THEN
    RAISE EXCEPTION 'Gia đình đang có gói Plus'; END IF;
  old_tier := cur.tier;

  ends := now() + interval '7 days';
INSERT INTO public.trial_grants(parent_id, wallet_id, ends_at) VALUES (auth.uid(), w.id, ends);

INSERT INTO public.subscriptions(parent_id, tier, status, max_kids, start_date, expires_at, notes)
VALUES (auth.uid(), 'plus', 'active', 1, now(), ends, 'TRIAL_7D')
    ON CONFLICT (parent_id) DO UPDATE SET tier = 'plus', status = 'active', max_kids = 1,
                                   start_date = now(), expires_at = ends, notes = 'TRIAL_7D', updated_at = now();

INSERT INTO public.subscription_periods(parent_id, source, starts_at, ends_at, snapshot)
VALUES (auth.uid(), 'trial', now(), ends, jsonb_build_object('tier','plus','max_kids',1,'plan','basic_trial'));
INSERT INTO public.subscription_logs(parent_id, action, old_tier, new_tier, reason)
VALUES (auth.uid(), 'TRIAL_START', old_tier, 'plus', 'Dùng thử Basic 7 ngày, ví ' || w.provider);

RETURN jsonb_build_object('success', true, 'ends_at', ends);
END $$;

-- Wrapper public + phân quyền (cùng mẫu với create_learning_order)
CREATE FUNCTION public.link_wallet(p_provider text, p_phone text, p_token text) RETURNS jsonb
    LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.link_wallet(p_provider, p_phone, p_token); $$;
CREATE FUNCTION public.start_basic_trial(p_token text) RETURNS jsonb
    LANGUAGE sql SECURITY INVOKER SET search_path = '' AS $$ SELECT private.start_basic_trial(p_token); $$;
REVOKE ALL ON FUNCTION private.link_wallet(text,text,text), public.link_wallet(text,text,text),
    private.start_basic_trial(text), public.start_basic_trial(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.link_wallet(text,text,text), public.link_wallet(text,text,text),
                          private.start_basic_trial(text), public.start_basic_trial(text) TO authenticated;

-- 6) Gói Basic dùng thử trong catalog (kèm mô tả)
INSERT INTO public.learning_plans(code, name, description, tier, max_kids, published, features, trial_days, requires_wallet, sort_order)
VALUES (
           'basic_trial',
           'Basic – Dùng thử 7 ngày',
           'Trải nghiệm toàn bộ lộ trình toán lớp 1–5 cho 1 bé trong 7 ngày. Cần gắn ví MoMo hoặc VNPay để bắt đầu. Hết 7 ngày, tài khoản tự về chế độ Basic giới hạn và không bị trừ tiền.',
           'basic', 1, true,
           jsonb_build_array('7 ngày miễn phí', '1 hồ sơ bé', 'Mở toàn bộ bài học lớp 1–5', 'Vườn luyện tập hồi tim luôn miễn phí', 'Cần gắn ví MoMo/VNPay (mỗi ví dùng thử 1 lần)', 'Không tự động trừ tiền'),
           7, true, 1
       );

COMMIT;