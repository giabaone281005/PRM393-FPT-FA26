import { canonicalQuery, signature, vnpDate } from '../_shared/vnpay.mjs';
import { cors, json, required, rest } from '../_shared/http.ts';

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
    const tmn = required('VNPAY_TMN_CODE');
    const secret = required('VNPAY_HASH_SECRET');
    const returnUrl = required('VNPAY_RETURN_URL');
    if (!returnUrl.startsWith('https://')) throw new Error('Invalid return URL');
    const payload = await req.json();
    if (typeof payload.parentToken !== 'string' || !await rest('rpc/parent_authorized', token, { p_token: payload.parentToken })) return json({ error: 'Cần mở lại cổng phụ huynh' }, 403);
    const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    let order;
    if (payload.orderId) {
      if (!uuid.test(payload.orderId)) return json({ error: 'Mã đơn không hợp lệ' }, 400);
      const rows = await rest(`learning_orders?id=eq.${payload.orderId}&parent_id=eq.${user.id}&select=*`, token);
      order = rows[0];
    } else {
      if (!uuid.test(payload.priceId) || !uuid.test(payload.requestId)) return json({ error: 'Yêu cầu không hợp lệ' }, 400);
      order = await rest('rpc/create_learning_order', token, { p_price: payload.priceId, p_key: payload.requestId, p_token: payload.parentToken });
    }
    if (!order) return json({ error: 'Không tìm thấy đơn hàng' }, 404);
    if (order.status !== 'pending' || new Date(order.expires_at) <= new Date()) {
      return json({ error: 'Đơn đã xử lý hoặc hết hạn. Hãy kiểm tra lịch sử trước khi tạo đơn mới.' }, 409);
    }
    const amount = Number(order.amount_vnd);
    if (!Number.isSafeInteger(amount) || amount <= 0) throw new Error('Invalid amount');
    const params : Record<string, string> = {
      vnp_Version: '2.1.0', vnp_Command: 'pay', vnp_TmnCode: tmn,
      vnp_Amount: String(amount * 100), vnp_CurrCode: 'VND',
      vnp_TxnRef: order.id.replaceAll('-', ''), vnp_OrderInfo: `MathLingo order ${order.id.replaceAll('-', '')}`,
      vnp_OrderType: 'other', vnp_Locale: 'vn', vnp_ReturnUrl: returnUrl,
      vnp_IpAddr: req.headers.get('x-forwarded-for')?.split(',')[0].trim() || '127.0.0.1',
      vnp_CreateDate: vnpDate(new Date(order.created_at)), vnp_ExpireDate: vnpDate(new Date(order.expires_at)),
    };
    if (payload.method === 'qr') params.vnp_BankCode = 'VNPAYQR';
    const endpoint = Deno.env.get('VNPAY_PAYMENT_URL') || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
    if (!['https://sandbox.vnpayment.vn/paymentv2/vpcpay.html', 'https://pay.vnpay.vn/vpcpay.html'].includes(endpoint)) {
      throw new Error('Invalid payment endpoint');
    }
    await rest('rpc/reserve_learning_checkout', required('SUPABASE_SERVICE_ROLE_KEY'), {
      p_order: order.id, p_parent: user.id, p_provider: 'vnpay',
      p_environment: endpoint.includes('sandbox.') ? 'sandbox' : 'live',
    }, true);
    return json({ order, checkoutUrl: `${endpoint}?${canonicalQuery(params)}&vnp_SecureHash=${signature(params, secret)}` });
  } catch (error) {
    console.error('Checkout failed', error instanceof Error ? error.message : 'unknown');
    return json({ error: 'Chưa thể tạo thanh toán. Vui lòng thử lại hoặc liên hệ hỗ trợ.' }, 503);
  }
});
