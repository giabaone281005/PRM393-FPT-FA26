import { cors, json, required, rest } from '../_shared/http.ts';
import { momoSign } from '../_shared/momo.ts';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const ENDPOINTS = [
    'https://test-payment.momo.vn/v2/gateway/api/create',
    'https://payment.momo.vn/v2/gateway/api/create',
];

Deno.serve(async (req) => {
    if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
    if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
    try {
        const token = req.headers.get('Authorization')?.replace(/^Bearer /i, '');
        if (!token) return json({ error: 'Cần đăng nhập' }, 401);
        const userRes = await fetch(`${required('SUPABASE_URL')}/auth/v1/user`, {
            headers: { apikey: required('SUPABASE_ANON_KEY'), Authorization: `Bearer ${token}` },
        });
        if (!userRes.ok) return json({ error: 'Phiên đăng nhập hết hạn' }, 401);
        const user = await userRes.json();

        const payload = await req.json();
        if (typeof payload.parentToken !== 'string' ||
            !await rest('rpc/parent_authorized', token, { p_token: payload.parentToken })) {
            return json({ error: 'Cần mở lại cổng phụ huynh' }, 403);
        }

        let order;
        if (payload.orderId) {
            if (!UUID.test(payload.orderId)) return json({ error: 'Mã đơn không hợp lệ' }, 400);
            const rows = await rest(`learning_orders?id=eq.${payload.orderId}&parent_id=eq.${user.id}&select=*`, token);
            order = rows[0];
        } else {
            if (!UUID.test(payload.priceId) || !UUID.test(payload.requestId)) return json({ error: 'Yêu cầu không hợp lệ' }, 400);
            order = await rest('rpc/create_learning_order', token,
                { p_price: payload.priceId, p_key: payload.requestId, p_token: payload.parentToken });
        }
        if (!order) return json({ error: 'Không tìm thấy đơn hàng' }, 404);
        if (order.status !== 'pending' || new Date(order.expires_at) <= new Date()) {
            return json({ error: 'Đơn đã xử lý hoặc hết hạn.' }, 409);
        }

        const partnerCode = required('MOMO_PARTNER_CODE');
        const accessKey = required('MOMO_ACCESS_KEY');
        const secretKey = required('MOMO_SECRET_KEY');
        const ipnUrl = required('MOMO_IPN_URL');
        const redirectUrl = required('MOMO_REDIRECT_URL');
        const endpoint = Deno.env.get('MOMO_ENDPOINT') ?? ENDPOINTS[0];
        if (!ENDPOINTS.includes(endpoint)) throw new Error('Invalid endpoint');

        const amount = Number(order.amount_vnd);
        if (!Number.isSafeInteger(amount) || amount <= 0) throw new Error('Invalid amount');

        const attempt = await rest('rpc/reserve_learning_checkout', required('SUPABASE_SERVICE_ROLE_KEY'), {
            p_order: order.id, p_parent: user.id, p_provider: 'momo',
            p_environment: endpoint === ENDPOINTS[0] ? 'sandbox' : 'live',
        }, true);
        if (attempt.checkout_response) return json({ order, ...attempt.checkout_response });

        // Retry the same provider operation, including after a timeout.
        // requestId is MoMo's idempotency key; never create a timestamp suffix.
        const ref = order.id.replaceAll('-', '');
        const orderId = attempt.gateway_order_id;
        const requestId = orderId;
        const orderInfo = `MathLingo order ${ref}`;
        const extraData = '';
        const requestType = 'captureWallet';

        // Thứ tự key phải đúng alphabet
        const raw = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&ipnUrl=${ipnUrl}` +
            `&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${partnerCode}` +
            `&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;

        const res = await fetch(endpoint, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                partnerCode, partnerName: 'MathLingo', storeId: 'MathLingo',
                requestId, amount, orderId, orderInfo, redirectUrl, ipnUrl,
                lang: 'vi', requestType, autoCapture: true, extraData,
                signature: momoSign(raw, secretKey),
            }),
            signal: AbortSignal.timeout(30000),
        });
        const data = await res.json();
        if ([40, 41, 43].includes(data.resultCode)) {
            return json({ error: 'Lượt thanh toán đã tồn tại hoặc đang xử lý. Kiểm tra đơn hiện tại; không thanh toán lại.' }, 409);
        }
        if (!res.ok || data.resultCode !== 0 || !data.payUrl) {
            console.error('MoMo create failed', data.resultCode, data.message);
            throw new Error('MoMo error');
        }
        const payUrl = new URL(data.payUrl);
        if (payUrl.protocol !== 'https:' || !['test-payment.momo.vn', 'payment.momo.vn'].includes(payUrl.hostname)) throw new Error('Invalid payment URL');
        const saved = await rest('rpc/save_learning_checkout', required('SUPABASE_SERVICE_ROLE_KEY'), {
            p_order: order.id, p_gateway: orderId,
            p_response: { payUrl: data.payUrl, deeplink: data.deeplink ?? null, qrCodeUrl: data.qrCodeUrl ?? null },
        }, true);
        return json({ order, ...saved });
    } catch (e) {
        console.error('MoMo checkout failed', e instanceof Error ? e.message : 'unknown');
        return json({ error: 'Chưa thể tạo thanh toán MoMo. Vui lòng thử lại.' }, 503);
    }
});
