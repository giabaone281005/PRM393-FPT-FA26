BEGIN;
-- Compatibility with the first deployed commerce revision.
CREATE OR REPLACE FUNCTION private.admin_upgrade_subscription(target_parent_id uuid,new_tier public.subscription_tier,
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

-- Full refunds only. An uncertain provider response must be investigated, never retried blindly.
ALTER TABLE public.learning_orders DROP CONSTRAINT learning_orders_status_check;
ALTER TABLE public.learning_orders ADD CONSTRAINT learning_orders_status_check CHECK(status IN ('pending','paid','failed','expired','refunded'));
ALTER TABLE public.subscription_periods ADD COLUMN revoked_at timestamptz;
CREATE TABLE public.refund_requests(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),order_id uuid NOT NULL REFERENCES public.learning_orders(id),
 requested_by uuid NOT NULL,reason text NOT NULL CHECK(length(btrim(reason)) BETWEEN 5 AND 500),
 status text NOT NULL DEFAULT 'requested' CHECK(status IN ('requested','processing','unknown','succeeded','failed')),
 external_reference text, response_code text,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
CREATE UNIQUE INDEX refund_one_inflight ON public.refund_requests(order_id) WHERE status<>'failed';
CREATE INDEX refunds_status_time ON public.refund_requests(status,updated_at);
ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.refund_requests FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.refund_requests TO authenticated;GRANT ALL ON public.refund_requests TO service_role;
CREATE POLICY refunds_admin ON public.refund_requests FOR SELECT TO authenticated USING(public.is_admin());
CREATE FUNCTION private.request_refund(p_order uuid,p_reason text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_id uuid;BEGIN
 IF NOT public.is_admin() OR NOT coalesce(length(btrim(p_reason)) BETWEEN 5 AND 500,false) THEN RAISE EXCEPTION 'Cần quyền admin và lý do 5–500 ký tự';END IF;
 PERFORM 1 FROM public.learning_orders WHERE id=p_order AND status='paid' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Chỉ hoàn đơn đã thanh toán'; END IF;
 INSERT INTO public.refund_requests(order_id,requested_by,reason) VALUES(p_order,auth.uid(),btrim(p_reason)) ON CONFLICT(order_id) WHERE status<>'failed' DO NOTHING;
 SELECT id INTO v_id FROM public.refund_requests WHERE order_id=p_order AND status<>'failed';
 PERFORM private.audit('REFUND_REQUEST','order',p_order::text,jsonb_build_object('reason',p_reason,'request_id',v_id)); RETURN v_id;
END $$;
CREATE FUNCTION public.request_refund(p_order uuid,p_reason text) RETURNS uuid LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.request_refund(p_order,p_reason); $$;
REVOKE ALL ON FUNCTION private.request_refund(uuid,text),public.request_refund(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.request_refund(uuid,text),public.request_refund(uuid,text) TO authenticated;
CREATE FUNCTION private.recompute_subscription(p_parent uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_until timestamptz;v_next timestamptz;v_perpetual boolean;BEGIN
 PERFORM 1 FROM public.parents WHERE id=p_parent FOR UPDATE;
 SELECT bool_or(ends_at IS NULL),max(ends_at) INTO v_perpetual,v_until FROM public.subscription_periods
 WHERE parent_id=p_parent AND revoked_at IS NULL AND NOT (snapshot?'revoked_at') AND snapshot->>'tier'='plus' AND starts_at<=now() AND (ends_at IS NULL OR ends_at>now());
 IF NOT coalesce(v_perpetual,false) AND v_until IS NOT NULL THEN
 LOOP
 SELECT bool_or(ends_at IS NULL),max(ends_at) INTO v_perpetual,v_next FROM public.subscription_periods WHERE parent_id=p_parent AND revoked_at IS NULL AND NOT (snapshot?'revoked_at') AND snapshot->>'tier'='plus' AND starts_at<=v_until AND (ends_at IS NULL OR ends_at>v_until);
 EXIT WHEN coalesce(v_perpetual,false) OR v_next IS NULL OR v_next<=v_until;
 v_until:=v_next;
 END LOOP;
 END IF;
 UPDATE public.subscriptions SET tier=CASE WHEN coalesce(v_perpetual,false) OR v_until>now() THEN 'plus'::public.subscription_tier ELSE 'basic'::public.subscription_tier END,
 max_kids=CASE WHEN coalesce(v_perpetual,false) OR v_until>now() THEN 3 ELSE 1 END,status='active',
 expires_at=CASE WHEN coalesce(v_perpetual,false) THEN NULL ELSE v_until END,updated_at=now() WHERE parent_id=p_parent;
END $$;
CREATE FUNCTION public.claim_refund(p_request uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$ DECLARE r public.refund_requests;BEGIN
 UPDATE public.refund_requests SET status='processing',updated_at=now() WHERE id=p_request AND status='requested' RETURNING * INTO r;
 IF NOT FOUND THEN RETURN NULL;END IF;
 RETURN (SELECT to_jsonb(r)||jsonb_build_object('order',to_jsonb(o),'payment',to_jsonb(p)) FROM public.learning_orders o JOIN public.learning_payments p ON p.order_id=o.id WHERE o.id=r.order_id);
END $$;
CREATE FUNCTION private.finish_refund(p_request uuid,p_status text,p_reference text,p_code text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.refund_requests;o public.learning_orders;BEGIN
 IF p_status NOT IN ('succeeded','failed','unknown') THEN RAISE EXCEPTION 'Invalid status';END IF;
 SELECT * INTO r FROM public.refund_requests WHERE id=p_request FOR UPDATE;
 IF NOT FOUND OR r.status='succeeded' THEN RETURN;END IF;
 SELECT * INTO o FROM public.learning_orders WHERE id=r.order_id FOR UPDATE;
 PERFORM 1 FROM public.parents WHERE id=o.parent_id FOR UPDATE;
 UPDATE public.refund_requests SET status=p_status,external_reference=left(p_reference,100),response_code=left(p_code,20),updated_at=now() WHERE id=r.id;
 IF p_status='succeeded' THEN
 UPDATE public.learning_orders SET status='refunded' WHERE id=o.id;
 UPDATE public.subscription_periods SET revoked_at=now() WHERE payment_id IN (SELECT id FROM public.learning_payments WHERE order_id=o.id);
 PERFORM private.recompute_subscription(o.parent_id);
 INSERT INTO public.notifications(parent_id,title,body,kind,dedupe_key) VALUES(o.parent_id,'Giao dịch đã hoàn tiền','Thời gian Plus của giao dịch này đã được thu hồi. Các thành tích học tập được giữ lại.','refund','refund:'||o.id) ON CONFLICT DO NOTHING;
 END IF;
 PERFORM private.audit('REFUND_RESULT','order',o.id::text,jsonb_build_object('status',p_status,'code',p_code,'reference',p_reference));
END $$;
CREATE FUNCTION public.finish_refund(p_request uuid,p_status text,p_reference text,p_code text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.finish_refund(p_request,p_status,p_reference,p_code); $$;
REVOKE ALL ON FUNCTION public.claim_refund(uuid),private.finish_refund(uuid,text,text,text),public.finish_refund(uuid,text,text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.claim_refund(uuid),private.finish_refund(uuid,text,text,text),public.finish_refund(uuid,text,text,text) TO service_role;

-- Disabled until an operator configures a provider and quota. Photos are never stored.
CREATE TABLE public.ai_settings(id boolean PRIMARY KEY DEFAULT true CHECK(id),basic_daily integer NOT NULL DEFAULT 0 CHECK(basic_daily BETWEEN 0 AND 100),plus_daily integer NOT NULL DEFAULT 0 CHECK(plus_daily BETWEEN 0 AND 1000),enabled boolean NOT NULL DEFAULT false);
INSERT INTO public.ai_settings DEFAULT VALUES;
ALTER TABLE public.ai_settings ENABLE ROW LEVEL SECURITY;REVOKE ALL ON public.ai_settings FROM PUBLIC,anon,authenticated;
GRANT SELECT,UPDATE ON public.ai_settings TO authenticated;GRANT ALL ON public.ai_settings TO service_role;
CREATE POLICY ai_settings_read ON public.ai_settings FOR SELECT TO authenticated USING(true);
CREATE POLICY ai_settings_admin ON public.ai_settings FOR UPDATE TO authenticated USING(public.is_admin()) WITH CHECK(public.is_admin());
CREATE TRIGGER ai_settings_audit AFTER UPDATE ON public.ai_settings FOR EACH ROW EXECUTE FUNCTION private.audit_catalog();
-- The generic catalog trigger expects a column named id; boolean IDs are converted to text.
CREATE TABLE private.ai_requests(parent_id uuid NOT NULL REFERENCES public.parents(id),request_id uuid NOT NULL,kid_id uuid NOT NULL REFERENCES public.kid_profiles(id),phase text NOT NULL CHECK(phase IN ('ocr','hint')),study_date date NOT NULL,status text NOT NULL CHECK(status IN ('processing','completed','failed')),response jsonb,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(parent_id,request_id));
CREATE INDEX ai_parent_day ON private.ai_requests(parent_id,study_date,created_at DESC);
ALTER TABLE private.ai_requests ENABLE ROW LEVEL SECURITY;
CREATE FUNCTION private.claim_ai(p_parent uuid,p_kid uuid,p_request uuid,p_phase text) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r private.ai_requests;cfg public.ai_settings;quota integer;plus boolean;BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.kid_profiles k WHERE k.id=p_kid AND k.parent_id=p_parent AND NOT archived) OR p_phase NOT IN ('ocr','hint') THEN RAISE EXCEPTION 'Invalid family/request';END IF;
 PERFORM 1 FROM public.parents WHERE id=p_parent FOR UPDATE;
 SELECT * INTO r FROM private.ai_requests WHERE parent_id=p_parent AND request_id=p_request;
 IF FOUND THEN IF r.kid_id<>p_kid OR r.phase<>p_phase THEN RAISE EXCEPTION 'Request conflict';END IF;RETURN jsonb_build_object('status',r.status,'response',r.response);END IF;
 SELECT * INTO cfg FROM public.ai_settings WHERE id=true;
 IF NOT cfg.enabled THEN RAISE EXCEPTION 'AI chưa được bật';END IF;
 SELECT EXISTS(SELECT 1 FROM public.subscriptions WHERE parent_id=p_parent AND tier='plus' AND status='active' AND (expires_at IS NULL OR expires_at>now())) INTO plus;
 IF NOT plus AND NOT EXISTS(SELECT 1 FROM public.parents WHERE id=p_parent AND active_kid_id=p_kid) THEN RAISE EXCEPTION 'Bé chưa được chọn với Basic';END IF;
 quota:=CASE WHEN plus THEN cfg.plus_daily ELSE cfg.basic_daily END;
 IF (SELECT count(*) FROM private.ai_requests WHERE parent_id=p_parent AND study_date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)>=quota THEN RAISE EXCEPTION 'Đã hết lượt AI hôm nay';END IF;
 IF EXISTS(SELECT 1 FROM private.ai_requests WHERE parent_id=p_parent AND created_at>now()-interval '5 seconds') THEN RAISE EXCEPTION 'Vui lòng chờ vài giây';END IF;
 INSERT INTO private.ai_requests(parent_id,request_id,kid_id,phase,study_date,status) VALUES(p_parent,p_request,p_kid,p_phase,(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date,'processing');
 RETURN jsonb_build_object('status','claimed','remaining',quota-1-(SELECT count(*) FROM private.ai_requests WHERE parent_id=p_parent AND study_date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date AND request_id<>p_request));
END $$;
CREATE FUNCTION public.claim_ai(p_parent uuid,p_kid uuid,p_request uuid,p_phase text) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.claim_ai(p_parent,p_kid,p_request,p_phase); $$;
CREATE FUNCTION public.finish_ai(p_parent uuid,p_request uuid,p_status text,p_response jsonb) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 UPDATE private.ai_requests SET status=p_status,response=p_response WHERE parent_id=p_parent AND request_id=p_request AND status='processing' AND p_status IN ('completed','failed'); $$;
REVOKE ALL ON FUNCTION private.claim_ai(uuid,uuid,uuid,text),public.claim_ai(uuid,uuid,uuid,text),public.finish_ai(uuid,uuid,text,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.claim_ai(uuid,uuid,uuid,text),public.claim_ai(uuid,uuid,uuid,text),public.finish_ai(uuid,uuid,text,jsonb) TO service_role;
GRANT SELECT,UPDATE ON private.ai_requests TO service_role;
CREATE POLICY ai_service ON private.ai_requests TO service_role USING(true) WITH CHECK(true);

CREATE FUNCTION private.maintenance() RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE n integer;p record;BEGIN
 UPDATE public.learning_orders SET status='expired' WHERE status='pending' AND expires_at<now()-interval '24 hours';GET DIAGNOSTICS n=ROW_COUNT;
 INSERT INTO public.notifications(parent_id,title,body,kind,dedupe_key) SELECT parent_id,'Gói Plus sắp hết hạn','Gói học sẽ hết hạn trong 3 ngày. Bạn có thể mua kỳ tiếp theo trong cổng phụ huynh.','expiry','expiry:'||expires_at::text FROM public.subscriptions WHERE tier='plus' AND status='active' AND expires_at BETWEEN now() AND now()+interval '3 days' ON CONFLICT DO NOTHING;
 FOR p IN SELECT s.parent_id FROM public.subscriptions s WHERE (s.tier='plus' AND s.expires_at<=now()) OR (s.tier='basic' AND EXISTS(SELECT 1 FROM public.subscription_periods sp WHERE sp.parent_id=s.parent_id AND sp.revoked_at IS NULL AND NOT (sp.snapshot?'revoked_at') AND sp.snapshot->>'tier'='plus' AND sp.starts_at<=now() AND (sp.ends_at IS NULL OR sp.ends_at>now()))) LOOP
 PERFORM private.recompute_subscription(p.parent_id);END LOOP;
 UPDATE public.refund_requests SET status='unknown',updated_at=now() WHERE status='processing' AND updated_at<now()-interval '5 minutes';
 UPDATE private.ai_requests SET status='failed' WHERE status='processing' AND created_at<now()-interval '5 minutes';
 DELETE FROM private.ai_requests WHERE created_at<now()-interval '2 days';
 DELETE FROM private.parent_unlocks WHERE expires_at<now();
 RETURN jsonb_build_object('expired_orders',n);END $$;
CREATE FUNCTION public.commerce_maintenance() RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.maintenance(); $$;
REVOKE ALL ON FUNCTION private.maintenance(),public.commerce_maintenance() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.maintenance(),public.commerce_maintenance() TO service_role;
CREATE INDEX learning_orders_reconcile ON public.learning_orders(created_at) WHERE status IN ('pending','expired');
CREATE FUNCTION public.pending_reconciliation() RETURNS SETOF public.learning_orders LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$
 SELECT * FROM public.learning_orders WHERE (status IN ('pending','expired') AND created_at>now()-interval '7 days' OR EXISTS(SELECT 1 FROM public.refund_requests r WHERE r.order_id=learning_orders.id AND r.status='unknown')) AND (last_checked_at IS NULL OR last_checked_at<now()-interval '5 minutes') ORDER BY last_checked_at NULLS FIRST LIMIT 20; $$;
REVOKE ALL ON FUNCTION public.pending_reconciliation() FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.pending_reconciliation() TO service_role;

-- Legacy financial tables are optional and read only. Their provider/status is
-- historical information, never evidence for activating a new paid period.
CREATE FUNCTION private.legacy_commerce_history(p_parent uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE v_orders jsonb:='[]';v_payments jsonb:='[]';BEGIN
 IF NOT public.is_admin() THEN RAISE EXCEPTION 'Cần quyền admin';END IF;
 IF to_regclass('public.orders') IS NOT NULL AND EXISTS(SELECT 1 FROM pg_catalog.pg_attribute WHERE attrelid=to_regclass('public.orders') AND attname='order_code' AND NOT attisdropped) THEN
 EXECUTE 'SELECT coalesce(jsonb_agg(r),''[]''::jsonb) FROM (SELECT id,order_code,parent_id,plan_id,amount_vnd,provider,status,created_at,paid_at FROM public.orders WHERE parent_id=$1 ORDER BY created_at DESC LIMIT 20) r' INTO v_orders USING p_parent;
 END IF;
 IF to_regclass('public.payments') IS NOT NULL AND EXISTS(SELECT 1 FROM pg_catalog.pg_attribute WHERE attrelid=to_regclass('public.payments') AND attname='amount' AND NOT attisdropped) THEN
 EXECUTE 'SELECT coalesce(jsonb_agg(r),''[]''::jsonb) FROM (SELECT id,parent_id,provider,order_id,amount,status,created_at FROM public.payments WHERE parent_id=$1 ORDER BY created_at DESC LIMIT 20) r' INTO v_payments USING p_parent;
 END IF;
 RETURN jsonb_build_object('orders',v_orders,'payments',v_payments,'notice','Lịch sử hệ thống cũ. Không tự động xác minh hoặc cấp thêm Plus từ dữ liệu này.');END $$;
REVOKE ALL ON FUNCTION private.legacy_commerce_history(uuid) FROM PUBLIC,anon,authenticated;
CREATE FUNCTION private.admin_family(p_parent uuid) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT public.is_admin() THEN RAISE EXCEPTION 'Cần quyền admin';END IF;
 RETURN jsonb_build_object('parent',(SELECT jsonb_build_object('id',id,'email',email,'created_at',created_at) FROM public.parents WHERE id=p_parent),
 'kids',(SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'nickname',nickname,'grade',grade,'archived',archived,'energy_stars',energy_stars,'current_hearts',current_hearts)),'[]') FROM public.kid_profiles WHERE parent_id=p_parent),
 'subscription',(SELECT to_jsonb(s) FROM public.subscriptions s WHERE parent_id=p_parent),
 'periods',(SELECT coalesce(jsonb_agg(r),'[]') FROM (SELECT * FROM public.subscription_periods WHERE parent_id=p_parent ORDER BY starts_at DESC LIMIT 20) r),
 'orders',(SELECT coalesce(jsonb_agg(r),'[]') FROM (SELECT * FROM public.learning_orders WHERE parent_id=p_parent ORDER BY created_at DESC LIMIT 20) r),
 'support_history',(SELECT coalesce(jsonb_agg(r),'[]') FROM (SELECT * FROM public.subscription_logs WHERE parent_id=p_parent ORDER BY created_at DESC LIMIT 20) r),
 'roles',(SELECT coalesce(jsonb_agg(role),'[]') FROM public.user_roles WHERE user_id=p_parent),
 'legacy_commerce',private.legacy_commerce_history(p_parent));END $$;
CREATE FUNCTION public.admin_family(p_parent uuid) RETURNS jsonb LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.admin_family(p_parent); $$;
REVOKE ALL ON FUNCTION private.admin_family(uuid),public.admin_family(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.admin_family(uuid),public.admin_family(uuid) TO authenticated;
CREATE FUNCTION private.audit_support() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 PERFORM private.audit('SUPPORT_CHANGE','subscription',NEW.parent_id::text,jsonb_build_object('before',NEW.old_tier,'after',NEW.new_tier,'reason',NEW.reason));RETURN NEW;END $$;
CREATE TRIGGER support_audit AFTER INSERT ON public.subscription_logs FOR EACH ROW EXECUTE FUNCTION private.audit_support();
-- Prevent raw admin writes from bypassing reasons/history. RPCs remain authoritative.
REVOKE INSERT,UPDATE,DELETE ON public.subscriptions,public.subscription_logs FROM PUBLIC,anon,authenticated;
-- Retain old orphan seed records without deleting data; enforce identity for all new rows.
ALTER TABLE public.parents ADD CONSTRAINT parents_auth_user_fk FOREIGN KEY(id) REFERENCES auth.users(id) NOT VALID;
CREATE INDEX periods_payment ON public.subscription_periods(payment_id);
CREATE INDEX sessions_lesson ON public.study_sessions(lesson_id);
CREATE INDEX attempts_question ON public.question_attempts(question_id);
CREATE INDEX roles_user ON public.user_roles(user_id);
CREATE FUNCTION private.ensure_family() RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE v_email text;BEGIN
 SELECT email INTO v_email FROM auth.users WHERE id=auth.uid() AND email_confirmed_at IS NOT NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Cần xác minh email'; END IF;
 INSERT INTO public.parents(id,email) VALUES(auth.uid(),v_email) ON CONFLICT(id) DO UPDATE SET email=EXCLUDED.email;
 INSERT INTO public.subscriptions(parent_id) VALUES(auth.uid()) ON CONFLICT(parent_id) DO NOTHING;
 INSERT INTO public.user_roles(user_id,role) VALUES(auth.uid(),'parent') ON CONFLICT DO NOTHING;
END $$;
CREATE FUNCTION public.ensure_family() RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.ensure_family(); $$;
REVOKE ALL ON FUNCTION private.ensure_family(),public.ensure_family() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.ensure_family(),public.ensure_family() TO authenticated;
REVOKE INSERT(id,email),UPDATE(email) ON public.parents FROM authenticated;
INSERT INTO public.admin_audit_logs(action,target_type,target_id,details)
SELECT 'NORMALIZE_LEGACY','kid_profile',id::text,jsonb_build_object('old_stars',energy_stars,'old_limit',screen_time_limit_minutes) FROM public.kid_profiles WHERE energy_stars<0 OR screen_time_limit_minutes NOT BETWEEN 15 AND 120;
UPDATE public.kid_profiles SET energy_stars=greatest(energy_stars,0),screen_time_limit_minutes=greatest(15,least(screen_time_limit_minutes,120)) WHERE energy_stars<0 OR screen_time_limit_minutes NOT BETWEEN 15 AND 120;
ALTER TABLE public.kid_profiles ADD CONSTRAINT kid_stars_nonnegative CHECK(energy_stars>=0);
ALTER TABLE public.kid_profiles ADD CONSTRAINT kid_time_limit_range CHECK(screen_time_limit_minutes BETWEEN 15 AND 120);
-- Internal helpers must never be directly executable by an app role.
REVOKE ALL ON FUNCTION private.session_public(uuid),private.charge_session(uuid,boolean),private.assert_session_access(uuid),private.assert_learning_kid(uuid),private.award_arena_session(uuid,integer),private.join_arena(uuid),private.audit(text,text,text,jsonb),private.recompute_subscription(uuid) FROM PUBLIC,anon,authenticated;
ALTER TABLE private.parent_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.session_payloads ENABLE ROW LEVEL SECURITY;
CREATE TABLE public.support_requests(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),parent_id uuid NOT NULL REFERENCES public.parents(id),order_id uuid REFERENCES public.learning_orders(id),request_key uuid NOT NULL,message text NOT NULL CHECK(length(message) BETWEEN 5 AND 2000),status text NOT NULL DEFAULT 'open' CHECK(status IN ('open','resolved')),reply text,created_at timestamptz NOT NULL DEFAULT now(),resolved_at timestamptz,UNIQUE(parent_id,request_key));
CREATE INDEX support_parent_time ON public.support_requests(parent_id,created_at DESC);
CREATE INDEX support_open ON public.support_requests(created_at) WHERE status='open';
CREATE INDEX support_order ON public.support_requests(order_id);
ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.support_requests FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.support_requests TO authenticated;GRANT ALL ON public.support_requests TO service_role;
CREATE POLICY support_read ON public.support_requests FOR SELECT TO authenticated USING(parent_id=(SELECT auth.uid()) OR public.is_admin());
CREATE FUNCTION private.request_support(p_order uuid,p_message text,p_key uuid,p_token text) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE v_id uuid;BEGIN
 IF NOT private.parent_authorized(p_token) THEN RAISE EXCEPTION 'Cần mở cổng phụ huynh';END IF;
 IF NOT coalesce(length(btrim(p_message)) BETWEEN 5 AND 2000 AND p_key IS NOT NULL,false) THEN RAISE EXCEPTION 'Nội dung cần 5–2000 ký tự';END IF;
 IF p_order IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.learning_orders WHERE id=p_order AND parent_id=auth.uid()) THEN RAISE EXCEPTION 'Không có quyền với đơn';END IF;
 PERFORM 1 FROM public.parents WHERE id=auth.uid() FOR UPDATE;
 SELECT id INTO v_id FROM public.support_requests WHERE parent_id=auth.uid() AND request_key=p_key;IF FOUND THEN RETURN v_id;END IF;
 IF (SELECT count(*) FROM public.support_requests WHERE parent_id=auth.uid() AND created_at>now()-interval '1 day')>=5 THEN RAISE EXCEPTION 'Đã gửi 5 yêu cầu trong ngày, vui lòng chờ phản hồi';END IF;
 INSERT INTO public.support_requests(parent_id,order_id,request_key,message) VALUES(auth.uid(),p_order,p_key,btrim(p_message)) RETURNING id INTO v_id;
 RETURN v_id;END $$;
CREATE FUNCTION private.resolve_support(p_id uuid,p_reply text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ DECLARE r public.support_requests;BEGIN
 IF NOT public.is_admin() OR NOT coalesce(length(btrim(p_reply)) BETWEEN 5 AND 2000,false) THEN RAISE EXCEPTION 'Cần quyền admin và phản hồi 5–2000 ký tự';END IF;
 SELECT * INTO r FROM public.support_requests WHERE id=p_id FOR UPDATE;IF NOT FOUND THEN RAISE EXCEPTION 'Không tìm thấy yêu cầu';END IF;
 IF r.status='resolved' THEN RETURN;END IF;
 UPDATE public.support_requests SET reply=btrim(p_reply),status='resolved',resolved_at=now() WHERE id=p_id;
 INSERT INTO public.notifications(parent_id,title,body,kind,dedupe_key) VALUES(r.parent_id,'Yêu cầu hỗ trợ đã có phản hồi',left(p_reply,500),'support','support:'||r.id) ON CONFLICT DO NOTHING;
 PERFORM private.audit('SUPPORT_REPLY','support',r.id::text,jsonb_build_object('order_id',r.order_id,'reply',p_reply));END $$;
CREATE FUNCTION public.request_support(p_order uuid,p_message text,p_key uuid,p_token text) RETURNS uuid LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.request_support(p_order,p_message,p_key,p_token); $$;
CREATE FUNCTION public.resolve_support(p_id uuid,p_reply text) RETURNS void LANGUAGE sql SECURITY INVOKER SET search_path='' AS $$ SELECT private.resolve_support(p_id,p_reply); $$;
REVOKE ALL ON FUNCTION private.request_support(uuid,text,uuid,text),private.resolve_support(uuid,text),public.request_support(uuid,text,uuid,text),public.resolve_support(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION private.request_support(uuid,text,uuid,text),private.resolve_support(uuid,text),public.request_support(uuid,text,uuid,text),public.resolve_support(uuid,text) TO authenticated;
COMMIT;
