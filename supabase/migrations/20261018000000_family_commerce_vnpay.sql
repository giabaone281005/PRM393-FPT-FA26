-- New migration after the already deployed 20261017 migration. Never rerun old seeds.
-- Cloud has legacy public.orders/public.payments with a different schema.
-- Leave those objects and their data untouched. New commerce uses learning_*.
-- This revision is for databases where migration 18 has NOT committed.
BEGIN;
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO authenticated, service_role;

-- Preserve existing admin assignments, then authorize by verified UID only.
INSERT INTO public.user_roles(user_id, role)
SELECT u.id, 'admin' FROM auth.users u
WHERE EXISTS (SELECT 1 FROM public.admins a WHERE a.id = u.id
  OR (lower(a.email) = lower(u.email) AND u.email_confirmed_at IS NOT NULL))
ON CONFLICT (user_id, role) DO NOTHING;
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT auth.uid() IS NOT NULL AND EXISTS (
 SELECT 1 FROM public.user_roles WHERE user_id = auth.uid() AND role = 'admin');
$$;
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;
DROP POLICY IF EXISTS "Admins can view all kid profiles" ON public.kid_profiles;
DROP POLICY IF EXISTS "Allow select kid profiles for leaderboard" ON public.kid_profiles;
CREATE POLICY "Admins read kids by verified role" ON public.kid_profiles
FOR SELECT TO authenticated USING (public.is_admin());

CREATE TABLE public.learning_plans (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), code text NOT NULL UNIQUE,
 name text NOT NULL CHECK (length(name) BETWEEN 1 AND 120),
 description text NOT NULL DEFAULT '', tier public.subscription_tier NOT NULL,
 max_kids integer NOT NULL CHECK(max_kids BETWEEN 1 AND 3),
 published boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.plan_prices (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 plan_id uuid NOT NULL REFERENCES public.learning_plans(id),
 label text NOT NULL CHECK(length(label) BETWEEN 1 AND 120),
 duration_months integer NOT NULL CHECK(duration_months IN (1,3,6,12)),
 amount_vnd bigint NOT NULL CHECK(amount_vnd BETWEEN 0 AND 9999999999),
 currency text NOT NULL DEFAULT 'VND' CHECK(currency = 'VND'),
 published boolean NOT NULL DEFAULT false,
 CHECK(NOT published OR amount_vnd > 0),
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX plan_prices_plan ON public.plan_prices(plan_id);
CREATE TABLE public.learning_orders (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 parent_id uuid NOT NULL REFERENCES public.parents(id),
 plan_price_id uuid NOT NULL REFERENCES public.plan_prices(id),
 amount_vnd bigint NOT NULL CHECK(amount_vnd > 0),
 currency text NOT NULL DEFAULT 'VND' CHECK(currency = 'VND'),
 snapshot jsonb NOT NULL,
 status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','paid','failed','expired')),
 idempotency_key uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 expires_at timestamptz NOT NULL DEFAULT now() + interval '15 minutes',
 paid_at timestamptz, last_checked_at timestamptz,
 UNIQUE(parent_id,idempotency_key)
);
CREATE INDEX learning_orders_parent_created ON public.learning_orders(parent_id,created_at DESC);
CREATE INDEX learning_orders_price ON public.learning_orders(plan_price_id);
CREATE FUNCTION public.claim_vnpay_check(p_order uuid) RETURNS boolean
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 WITH claimed AS (UPDATE public.learning_orders SET last_checked_at=now() WHERE id=p_order
 AND (last_checked_at IS NULL OR last_checked_at<now()-interval '1 minute') RETURNING id)
 SELECT EXISTS(SELECT 1 FROM claimed); $$;
REVOKE ALL ON FUNCTION public.claim_vnpay_check(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.claim_vnpay_check(uuid) TO service_role;
CREATE TABLE public.learning_payments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 order_id uuid NOT NULL UNIQUE REFERENCES public.learning_orders(id),
 provider text NOT NULL CHECK(provider = 'vnpay'),
 external_transaction_id text NOT NULL,
 amount_vnd bigint NOT NULL CHECK(amount_vnd > 0),
 verified_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(provider,external_transaction_id)
);
CREATE TABLE public.payment_events (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 order_id uuid NOT NULL REFERENCES public.learning_orders(id),
 provider text NOT NULL CHECK(provider = 'vnpay'),
 external_event_id text NOT NULL,
 response_code text NOT NULL, received_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(provider,external_event_id)
);
CREATE INDEX payment_events_order ON public.payment_events(order_id);
CREATE TABLE public.subscription_periods (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 parent_id uuid NOT NULL REFERENCES public.parents(id),
 payment_id uuid UNIQUE REFERENCES public.learning_payments(id),
 source text NOT NULL CHECK(source IN ('vnpay','legacy_admin','admin')),
 starts_at timestamptz NOT NULL, ends_at timestamptz,
 snapshot jsonb NOT NULL DEFAULT '{}',
 CHECK(ends_at IS NULL OR ends_at > starts_at)
);
CREATE INDEX subscription_periods_parent ON public.subscription_periods(parent_id,starts_at DESC);
INSERT INTO public.subscription_periods(parent_id,source,starts_at,ends_at,snapshot)
SELECT parent_id,'legacy_admin',start_date,expires_at,
jsonb_build_object('tier',tier,'max_kids',max_kids,'status',status)
FROM public.subscriptions WHERE expires_at IS NULL OR expires_at > start_date;

CREATE FUNCTION private.admin_upgrade_subscription(target_parent_id uuid,new_tier public.subscription_tier,
 duration_days integer,upgrade_notes text) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE previous public.subscription_tier; until_time timestamptz; max_allowed integer;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin() THEN RAISE EXCEPTION 'Chỉ admin được điều chỉnh gói'; END IF;
 IF nullif(btrim(upgrade_notes),'') IS NULL THEN RAISE EXCEPTION 'Cần ghi lý do điều chỉnh'; END IF;
 IF duration_days IS NOT NULL AND (duration_days<1 OR duration_days>3650) THEN RAISE EXCEPTION 'Thời hạn không hợp lệ'; END IF;
 PERFORM 1 FROM public.parents WHERE id=target_parent_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy phụ huynh'; END IF;
 SELECT tier INTO previous FROM public.subscriptions WHERE parent_id=target_parent_id;
 until_time:=CASE WHEN new_tier='plus' AND duration_days IS NOT NULL THEN greatest(now(),(SELECT expires_at FROM public.subscriptions WHERE parent_id=target_parent_id AND tier='plus' AND status='active'))+make_interval(days=>duration_days) ELSE NULL END;
 IF new_tier='plus' AND EXISTS(SELECT 1 FROM public.subscriptions WHERE parent_id=target_parent_id AND tier='plus' AND status='active' AND expires_at IS NULL) THEN until_time:=NULL;END IF;
 IF new_tier='basic' THEN UPDATE public.subscription_periods SET snapshot=snapshot||jsonb_build_object('revoked_by_admin',auth.uid(),'revoked_at',now()) WHERE parent_id=target_parent_id AND snapshot->>'tier'='plus';END IF;
 max_allowed:=CASE WHEN new_tier='plus' THEN 3 ELSE 1 END;
 INSERT INTO public.subscriptions(parent_id,tier,status,max_kids,expires_at,upgraded_by,notes)
 VALUES(target_parent_id,new_tier,'active',max_allowed,until_time,auth.uid(),upgrade_notes)
 ON CONFLICT(parent_id) DO UPDATE SET tier=EXCLUDED.tier,status='active',max_kids=EXCLUDED.max_kids,
 expires_at=EXCLUDED.expires_at,upgraded_by=EXCLUDED.upgraded_by,notes=EXCLUDED.notes,updated_at=now();
 INSERT INTO public.subscription_logs(parent_id,action,old_tier,new_tier,performed_by,reason)
 VALUES(target_parent_id,'ADMIN_CHANGE',previous,new_tier,auth.uid(),upgrade_notes);
 INSERT INTO public.subscription_periods(parent_id,source,starts_at,ends_at,snapshot)
 VALUES(target_parent_id,'admin',now(),until_time,jsonb_build_object('tier',new_tier,'max_kids',max_allowed,'reason',upgrade_notes,'actor',auth.uid()));
 RETURN jsonb_build_object('success',true,'tier',new_tier,'expires_at',until_time);
END $$;
REVOKE ALL ON FUNCTION private.admin_upgrade_subscription(uuid,public.subscription_tier,integer,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.admin_upgrade_subscription(uuid,public.subscription_tier,integer,text) TO authenticated;
CREATE OR REPLACE FUNCTION public.admin_upgrade_subscription(target_parent_id uuid,new_tier public.subscription_tier,
 duration_days integer DEFAULT NULL,upgrade_notes text DEFAULT NULL) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.admin_upgrade_subscription(target_parent_id,new_tier,duration_days,upgrade_notes); $$;
REVOKE ALL ON FUNCTION public.admin_upgrade_subscription(uuid,public.subscription_tier,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.admin_upgrade_subscription(uuid,public.subscription_tier,integer,text) TO authenticated;

-- Draft catalog: administrator must set real prices before publishing.
INSERT INTO public.learning_plans(code,name,description,tier,max_kids,published)
VALUES ('plus','MathLingo Plus','Tối đa 3 bé, lộ trình toán lớp 1–5. Thanh toán một kỳ, không tự gia hạn.','plus',3,true);
INSERT INTO public.plan_prices(plan_id,label,duration_months,amount_vnd)
SELECT id,'Plus 1 tháng',1,0 FROM public.learning_plans WHERE code='plus';
INSERT INTO public.plan_prices(plan_id,label,duration_months,amount_vnd)
SELECT id,'Plus 12 tháng',12,0 FROM public.learning_plans WHERE code='plus';

ALTER TABLE public.learning_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.plan_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_periods ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.learning_plans,public.plan_prices,public.learning_orders,public.learning_payments,
public.payment_events,public.subscription_periods FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.learning_plans,public.plan_prices,public.learning_orders,public.learning_payments,
public.subscription_periods TO authenticated;
GRANT INSERT,UPDATE ON public.learning_plans,public.plan_prices TO authenticated;
GRANT ALL ON public.learning_plans,public.plan_prices,public.learning_orders,public.learning_payments,
public.payment_events,public.subscription_periods TO service_role;
CREATE POLICY catalog_read ON public.learning_plans FOR SELECT TO authenticated
USING(published OR public.is_admin());
CREATE POLICY catalog_admin ON public.learning_plans FOR ALL TO authenticated
USING(public.is_admin()) WITH CHECK(public.is_admin());
CREATE POLICY price_read ON public.plan_prices FOR SELECT TO authenticated
USING(public.is_admin() OR (published AND EXISTS(SELECT 1 FROM public.learning_plans p WHERE p.id=plan_id AND p.published)));
CREATE POLICY price_admin ON public.plan_prices FOR ALL TO authenticated
USING(public.is_admin()) WITH CHECK(public.is_admin());
CREATE POLICY order_read ON public.learning_orders FOR SELECT TO authenticated
USING(parent_id = (SELECT auth.uid()) OR public.is_admin());
CREATE POLICY payment_read ON public.learning_payments FOR SELECT TO authenticated
USING(EXISTS(SELECT 1 FROM public.learning_orders o WHERE o.id=order_id AND (o.parent_id=(SELECT auth.uid()) OR public.is_admin())));
CREATE POLICY period_read ON public.subscription_periods FOR SELECT TO authenticated
USING(parent_id=(SELECT auth.uid()) OR public.is_admin());

CREATE FUNCTION private.freeze_purchased_price() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.learning_orders WHERE plan_price_id=OLD.id)
 AND (NEW.amount_vnd,NEW.duration_months,NEW.plan_id,NEW.label,NEW.currency)
 IS DISTINCT FROM (OLD.amount_vnd,OLD.duration_months,OLD.plan_id,OLD.label,OLD.currency) THEN
 RAISE EXCEPTION 'Giá đã có đơn hàng. Hãy tạo phiên bản giá mới.'; END IF;
 RETURN NEW; END $$;
CREATE TRIGGER freeze_purchased_price BEFORE UPDATE ON public.plan_prices
FOR EACH ROW EXECUTE FUNCTION private.freeze_purchased_price();

CREATE FUNCTION private.create_learning_order(p_price uuid,p_key uuid) RETURNS public.learning_orders
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v public.learning_orders; price public.plan_prices; plan public.learning_plans;
BEGIN
 IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Cần đăng nhập'; END IF;
 PERFORM 1 FROM public.parents WHERE id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Chưa có hồ sơ phụ huynh'; END IF;
 SELECT * INTO v FROM public.learning_orders WHERE parent_id=auth.uid() AND idempotency_key=p_key;
 IF FOUND THEN
  IF v.plan_price_id<>p_price THEN RAISE EXCEPTION 'Mã yêu cầu đã được dùng'; END IF;
  RETURN v;
 END IF;
 SELECT * INTO price FROM public.plan_prices WHERE id=p_price AND published FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Gói chưa được mở bán'; END IF;
 SELECT * INTO plan FROM public.learning_plans WHERE id=price.plan_id AND published FOR SHARE;
 IF NOT FOUND OR plan.tier<>'plus' THEN RAISE EXCEPTION 'Gói không hợp lệ'; END IF;
 IF EXISTS(SELECT 1 FROM public.subscriptions WHERE parent_id=auth.uid() AND tier='plus'
 AND status='active' AND expires_at IS NULL) THEN RAISE EXCEPTION 'Gia đình đã có Plus không thời hạn'; END IF;
 INSERT INTO public.learning_orders(parent_id,plan_price_id,amount_vnd,idempotency_key,snapshot)
 VALUES(auth.uid(),p_price,price.amount_vnd,p_key,jsonb_build_object(
 'name',plan.name,'label',price.label,'tier',plan.tier,'max_kids',plan.max_kids,
 'duration_months',price.duration_months)) RETURNING * INTO v;
 RETURN v;
END $$;
REVOKE ALL ON FUNCTION private.create_learning_order(uuid,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.create_learning_order(uuid,uuid) TO authenticated;
CREATE FUNCTION public.create_learning_order(p_price uuid,p_key uuid) RETURNS jsonb
LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT to_jsonb(private.create_learning_order(p_price,p_key)); $$;
REVOKE ALL ON FUNCTION public.create_learning_order(uuid,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.create_learning_order(uuid,uuid) TO authenticated;

-- Only a verified backend IPN can call this. Row locks serialize duplicate IPNs and purchases.
CREATE FUNCTION private.settle_vnpay_order(p_order uuid,p_transaction text,p_amount bigint,p_code text,p_transaction_status text)
RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE o public.learning_orders; payment_id uuid; start_time timestamptz; end_time timestamptz; old_tier public.subscription_tier;
BEGIN
 SELECT * INTO o FROM public.learning_orders WHERE id=p_order FOR UPDATE;
 IF NOT FOUND THEN RETURN '01'; END IF;
 IF o.amount_vnd<>p_amount THEN RETURN '04'; END IF;
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
REVOKE ALL ON FUNCTION private.settle_vnpay_order(uuid,text,bigint,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.settle_vnpay_order(uuid,text,bigint,text,text) TO service_role;
CREATE FUNCTION public.settle_vnpay_order(p_order uuid,p_transaction text,p_amount bigint,p_code text,p_transaction_status text)
RETURNS text LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
SELECT private.settle_vnpay_order(p_order,p_transaction,p_amount,p_code,p_transaction_status); $$;
REVOKE ALL ON FUNCTION public.settle_vnpay_order(uuid,text,bigint,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.settle_vnpay_order(uuid,text,bigint,text,text) TO service_role;

CREATE OR REPLACE FUNCTION public.check_max_kids_limit() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$ DECLARE allowed integer:=1; BEGIN
 PERFORM 1 FROM public.parents WHERE id=NEW.parent_id FOR UPDATE;
 SELECT CASE WHEN tier='plus' AND status='active' AND (expires_at IS NULL OR expires_at>now())
 THEN least(max_kids,3) ELSE 1 END INTO allowed FROM public.subscriptions WHERE parent_id=NEW.parent_id;
 IF (SELECT count(*) FROM public.kid_profiles WHERE parent_id=NEW.parent_id AND id<>NEW.id)>=coalesce(allowed,1)
 THEN RAISE EXCEPTION 'Đã đạt số hồ sơ bé theo gói hiện tại'; END IF;
 RETURN NEW;
END $$;
-- Prevent moving a profile between households to bypass the insertion limit.
CREATE FUNCTION private.keep_kid_parent() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN IF NEW.parent_id<>OLD.parent_id THEN RAISE EXCEPTION 'Không thể chuyển gia đình của hồ sơ'; END IF; RETURN NEW; END $$;
CREATE TRIGGER keep_kid_parent BEFORE UPDATE ON public.kid_profiles FOR EACH ROW EXECUTE FUNCTION private.keep_kid_parent();

-- Audit is append-only; only server functions insert it.
DROP POLICY IF EXISTS "Admins can view all subscription logs" ON public.subscription_logs;
CREATE POLICY "Admins read subscription logs" ON public.subscription_logs FOR SELECT TO authenticated USING(public.is_admin());
REVOKE INSERT,UPDATE,DELETE ON public.subscription_logs FROM authenticated,anon;
-- Basic offers the first three lessons per topic; paid payload is never exposed through raw tables.
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
ALTER TABLE public.parents ADD COLUMN pin_failures integer NOT NULL DEFAULT 0;
ALTER TABLE public.parents ADD COLUMN pin_locked_until timestamptz;
ALTER TABLE public.parents ALTER COLUMN parent_pin_hash SET DEFAULT '';
UPDATE public.parents SET parent_pin_hash=CASE WHEN parent_pin_hash='1234' THEN ''
 ELSE extensions.crypt(parent_pin_hash,extensions.gen_salt('bf',10)) END
WHERE parent_pin_hash ~ '^[0-9]{4}$';
REVOKE SELECT,INSERT,UPDATE ON public.parents FROM PUBLIC,anon,authenticated;
GRANT SELECT(id,email,created_at,updated_at),INSERT(id,email),UPDATE(email) ON public.parents TO authenticated;
CREATE FUNCTION private.verify_parent_pin(p_pin text) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE p public.parents; BEGIN
 SELECT * INTO p FROM public.parents WHERE id=auth.uid() FOR UPDATE;
 IF NOT FOUND OR p.parent_pin_hash='' OR p.pin_locked_until>now() THEN RETURN false; END IF;
 IF p_pin ~ '^[0-9]{4}$' AND extensions.crypt(p_pin,p.parent_pin_hash)=p.parent_pin_hash THEN
 UPDATE public.parents SET pin_failures=0,pin_locked_until=NULL WHERE id=p.id; RETURN true; END IF;
 UPDATE public.parents SET pin_failures=CASE WHEN p.pin_failures>=4 THEN 0 ELSE p.pin_failures+1 END,
 pin_locked_until=CASE WHEN p.pin_failures>=4 THEN now()+interval '5 minutes' ELSE NULL END WHERE id=p.id;
 RETURN false;
END $$;
CREATE FUNCTION private.set_parent_pin(p_old text,p_new text) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE p public.parents; BEGIN
 IF p_new !~ '^[0-9]{4}$' OR p_new='1234' THEN RETURN false; END IF;
 SELECT * INTO p FROM public.parents WHERE id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RETURN false; END IF;
 IF p.parent_pin_hash<>'' AND NOT private.verify_parent_pin(p_old) THEN RETURN false; END IF;
 UPDATE public.parents SET parent_pin_hash=extensions.crypt(p_new,extensions.gen_salt('bf',10)),
 pin_failures=0,pin_locked_until=NULL WHERE id=p.id; RETURN true;
END $$;
REVOKE ALL ON FUNCTION private.verify_parent_pin(text),private.set_parent_pin(text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.verify_parent_pin(text),private.set_parent_pin(text,text) TO authenticated;
CREATE FUNCTION public.verify_parent_pin(p_pin text) RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.verify_parent_pin(p_pin); $$;
CREATE FUNCTION public.set_parent_pin(p_old text,p_new text) RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.set_parent_pin(p_old,p_new); $$;
CREATE FUNCTION private.has_parent_pin() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.parents WHERE id=auth.uid() AND parent_pin_hash<>''); $$;
REVOKE ALL ON FUNCTION private.has_parent_pin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.has_parent_pin() TO authenticated;
CREATE FUNCTION public.has_parent_pin() RETURNS boolean LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.has_parent_pin(); $$;
REVOKE ALL ON FUNCTION public.verify_parent_pin(text),public.set_parent_pin(text,text),public.has_parent_pin() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.verify_parent_pin(text),public.set_parent_pin(text,text),public.has_parent_pin() TO authenticated;

ALTER TABLE public.lessons ADD COLUMN access_tier public.subscription_tier NOT NULL DEFAULT 'basic';
UPDATE public.lessons SET access_tier='plus' WHERE lesson_number>3;
REVOKE SELECT ON public.lessons,public.questions FROM PUBLIC,anon,authenticated;
CREATE FUNCTION private.get_kid_curriculum(p_kid uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_grade integer; plus boolean; result jsonb;
BEGIN
 SELECT k.grade INTO v_grade FROM public.kid_profiles k WHERE k.id=p_kid AND k.parent_id=auth.uid();
 IF NOT FOUND THEN RAISE EXCEPTION 'Không có quyền với hồ sơ'; END IF;
 SELECT EXISTS(SELECT 1 FROM public.subscriptions WHERE parent_id=auth.uid() AND tier='plus' AND status='active'
 AND (expires_at IS NULL OR expires_at>now())) INTO plus;
 SELECT coalesce(jsonb_agg(to_jsonb(l) || jsonb_build_object(
 'theory',CASE WHEN plus OR l.access_tier='basic' THEN l.theory ELSE NULL END,
 'essay_prompt',CASE WHEN plus OR l.access_tier='basic' THEN l.essay_prompt ELSE NULL END,
 'essay_guidance',CASE WHEN plus OR l.access_tier='basic' THEN l.essay_guidance ELSE NULL END,
 'is_completed',coalesce(p.is_completed,false),'stars_earned',coalesce(p.stars_earned,0),
 'questions',CASE WHEN plus OR l.access_tier='basic' THEN
 (SELECT coalesce(jsonb_agg(to_jsonb(q) ORDER BY q.order_index),'[]') FROM public.questions q WHERE q.lesson_id=l.id)
 ELSE '[]'::jsonb END) ORDER BY t.topic_number,l.order_index),'[]') INTO result
 FROM public.lessons l JOIN public.topics t ON t.id=l.topic_id
 LEFT JOIN public.kid_progress p ON p.lesson_id=l.id AND p.kid_id=p_kid WHERE t.grade=v_grade;
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION private.get_kid_curriculum(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.get_kid_curriculum(uuid) TO authenticated;
CREATE FUNCTION public.get_kid_curriculum(p_kid uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT private.get_kid_curriculum(p_kid); $$;
REVOKE ALL ON FUNCTION public.get_kid_curriculum(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_kid_curriculum(uuid) TO authenticated;

CREATE FUNCTION private.complete_kid_lesson(p_kid uuid,p_lesson uuid,p_accuracy integer,p_duration integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE l public.lessons; today date; previous date; current_streak integer;
BEGIN
 IF p_accuracy NOT BETWEEN 0 AND 100 OR p_duration NOT BETWEEN 0 AND 14400 THEN RAISE EXCEPTION 'Kết quả không hợp lệ'; END IF;
 PERFORM 1 FROM public.kid_profiles WHERE id=p_kid AND parent_id=auth.uid() FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Không có quyền'; END IF;
 SELECT lessons.* INTO l FROM public.lessons JOIN public.topics t ON t.id=topic_id
 WHERE lessons.id=p_lesson AND t.grade=(SELECT grade FROM public.kid_profiles WHERE id=p_kid);
 IF NOT FOUND THEN RAISE EXCEPTION 'Bài học không hợp lệ'; END IF;
 IF l.access_tier='plus' AND NOT EXISTS(SELECT 1 FROM public.subscriptions WHERE parent_id=auth.uid()
 AND tier='plus' AND status='active' AND (expires_at IS NULL OR expires_at>now())) THEN RAISE EXCEPTION 'Cần gói Plus'; END IF;
 IF EXISTS(SELECT 1 FROM public.kid_progress WHERE kid_id=p_kid AND lesson_id=p_lesson AND is_completed) THEN RETURN; END IF;
 IF EXISTS(SELECT 1 FROM public.lessons prev WHERE prev.topic_id=l.topic_id AND prev.order_index<l.order_index
 AND NOT EXISTS(SELECT 1 FROM public.kid_progress p WHERE p.kid_id=p_kid AND p.lesson_id=prev.id AND p.is_completed))
 THEN RAISE EXCEPTION 'Hãy hoàn thành các bài trước'; END IF;
 INSERT INTO public.kid_progress(kid_id,lesson_id,is_completed,accuracy_percent,stars_earned,completed_at)
 VALUES(p_kid,p_lesson,true,p_accuracy,l.star_reward,now())
 ON CONFLICT(kid_id,lesson_id) DO UPDATE SET is_completed=true,accuracy_percent=EXCLUDED.accuracy_percent,
 stars_earned=EXCLUDED.stars_earned,completed_at=now();
 UPDATE public.kid_profiles SET energy_stars=energy_stars+l.star_reward WHERE id=p_kid;
 INSERT INTO public.study_sessions(kid_id,lesson_id,started_at,duration_seconds,xp_earned)
 VALUES(p_kid,p_lesson,now()-make_interval(secs=>p_duration),p_duration,l.xp_reward);
 IF (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::time < '21:00'::time THEN
 today:=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
 SELECT last_activity_date,streak_count INTO previous,current_streak FROM public.kid_streaks WHERE kid_id=p_kid;
 IF previous IS DISTINCT FROM today THEN
 INSERT INTO public.kid_streaks(kid_id,streak_count,last_activity_date)
 VALUES(p_kid,CASE WHEN previous=today-1 THEN current_streak+1 ELSE 1 END,today)
 ON CONFLICT(kid_id) DO UPDATE SET streak_count=EXCLUDED.streak_count,last_activity_date=EXCLUDED.last_activity_date;
 END IF; END IF;
END $$;
REVOKE ALL ON FUNCTION private.complete_kid_lesson(uuid,uuid,integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.complete_kid_lesson(uuid,uuid,integer,integer) TO authenticated;
CREATE FUNCTION public.complete_kid_lesson(p_kid uuid,p_lesson uuid,p_accuracy integer,p_duration integer)
RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.complete_kid_lesson(p_kid,p_lesson,p_accuracy,p_duration); $$;
REVOKE ALL ON FUNCTION public.complete_kid_lesson(uuid,uuid,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.complete_kid_lesson(uuid,uuid,integer,integer) TO authenticated;
REVOKE INSERT,UPDATE,DELETE ON public.kid_progress,public.kid_streaks FROM authenticated;
COMMIT;
