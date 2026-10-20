import { cors, json, required, rest } from '../_shared/http.ts';
import { momoSign } from '../_shared/momo.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  try {
    const jobKey = Deno.env.get('COMMERCE_JOB_KEY');
    const job = Boolean(jobKey) && req.headers.get('x-job-key') === jobKey;
    const service = required('SUPABASE_SERVICE_ROLE_KEY');
    const token = job ? service : req.headers.get('Authorization')?.replace(/^Bearer /i, '');
    if (!token) return json({ error: 'Cần đăng nhập' }, 401);
    if (!job) {
      const user = await fetch(`${required('SUPABASE_URL')}/auth/v1/user`, {
        headers: { apikey: required('SUPABASE_ANON_KEY'), Authorization: `Bearer ${token}` },
      });
      if (!user.ok) return json({ error: 'Phiên hết hạn' }, 401);
    }
    const { orderId } = await req.json();
    if (!/^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(orderId ?? '')) return json({ error: 'Mã đơn không hợp lệ' }, 400);
    const [order] = await rest(`learning_orders?id=eq.${orderId}&select=*`, token, undefined, job);
    if (!order) return json({ error: 'Không tìm thấy đơn' }, 404);
    if (['paid', 'refunded'].includes(order.status)) return json({ status: order.status });
    const [attempt] = await rest(`learning_checkout_attempts?order_id=eq.${orderId}&select=*`, token, undefined, job);
    if (!attempt || attempt.provider !== 'momo') return json({ error: 'Đơn chưa có lượt thanh toán MoMo để đối soát.' }, 409);
    const endpoint = Deno.env.get('MOMO_ENDPOINT') ?? 'https://test-payment.momo.vn/v2/gateway/api/create';
    const expected = attempt.environment === 'sandbox'
      ? 'https://test-payment.momo.vn/v2/gateway/api/create'
      : 'https://payment.momo.vn/v2/gateway/api/create';
    if (endpoint !== expected) throw new Error('Payment environment mismatch');
    // This service-only RPC is a provider-independent order cooldown.
    if (!await rest('rpc/claim_vnpay_check', service, { p_order: orderId }, true)) {
      return json({ status: order.status, message: 'Vui lòng chờ trước khi kiểm tra tiếp.' });
    }
    const partnerCode = required('MOMO_PARTNER_CODE');
    const requestId = crypto.randomUUID();
    const gatewayId = attempt.gateway_order_id;
    const raw = `accessKey=${required('MOMO_ACCESS_KEY')}&orderId=${gatewayId}&partnerCode=${partnerCode}&requestId=${requestId}`;
    const response = await fetch(endpoint.replace(/create$/, 'query'), {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ partnerCode, orderId: gatewayId, requestId, lang: 'vi', signature: momoSign(raw, required('MOMO_SECRET_KEY')) }),
      signal: AbortSignal.timeout(30000),
    });
    if (!response.ok) throw new Error('MoMo unavailable');
    const result = await response.json();
    if (result.partnerCode !== partnerCode || result.orderId !== gatewayId || result.requestId !== requestId) throw new Error('Transaction mismatch');
    if (result.resultCode !== 0) return json({ status: order.status, message: 'MoMo chưa xác nhận thành công. Không thanh toán lại nếu đã bị trừ tiền.' });
    if (!Number.isSafeInteger(result.amount) || result.amount !== Number(order.amount_vnd) ||
      !Number.isSafeInteger(result.transId) || result.transId <= 0) throw new Error('Invalid transaction');
    const settled = await rest('rpc/settle_momo_order', service, {
      p_order: orderId, p_transaction: String(result.transId), p_amount: result.amount, p_result: 0,
    }, true);
    if (!['OK', 'REVIEW'].includes(settled)) throw new Error('Unable to settle');
    return json({ status: settled === 'OK' ? 'paid' : order.status, review: settled === 'REVIEW' });
  } catch (_) {
    return json({ error: 'Chưa đối soát được với MoMo. Không thanh toán lại nếu đã bị trừ tiền.' }, 503);
  }
});
