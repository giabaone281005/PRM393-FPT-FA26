BEGIN;

UPDATE public.learning_plans
SET name = 'MathLingo Plus',
    description = 'Học không giới hạn cho cả gia đình: tối đa 3 bé, toàn bộ lộ trình toán lớp 1–5. Thanh toán một kỳ, không tự gia hạn. Mua khi đang dùng thử thì thời gian dùng thử được cộng dồn.',
    features = jsonb_build_array('Tối đa 3 hồ sơ bé', 'Toàn bộ bài học và lộ trình lớp 1–5', 'Thanh toán MoMo hoặc VNPay (QR, thẻ, app ngân hàng)', 'Thanh toán một kỳ, không tự gia hạn', 'Dùng thử trước được cộng dồn khi mua'),
    requires_wallet = false,
    sort_order = 2,
    published = true
WHERE code = 'plus';

UPDATE public.plan_prices pp
SET label = 'Plus 1 tháng', amount_vnd = 99000, published = true
    FROM public.learning_plans p
WHERE p.id = pp.plan_id AND p.code = 'plus' AND pp.duration_months = 1 AND pp.amount_vnd = 0;

UPDATE public.plan_prices pp
SET label = 'Plus 12 tháng', amount_vnd = 899000, published = true
    FROM public.learning_plans p
WHERE p.id = pp.plan_id AND p.code = 'plus' AND pp.duration_months = 12 AND pp.amount_vnd = 0;

INSERT INTO public.plan_prices(plan_id, label, duration_months, amount_vnd, published)
SELECT p.id, 'Plus 3 tháng', 3, 249000, true
FROM public.learning_plans p
WHERE p.code = 'plus'
  AND NOT EXISTS (SELECT 1 FROM public.plan_prices x WHERE x.plan_id = p.id AND x.duration_months = 3 AND x.published);

COMMIT;