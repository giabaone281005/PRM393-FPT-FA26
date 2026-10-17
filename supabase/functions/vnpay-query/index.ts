import { hashText, verifyText, queryResponseText, vnpDate } from '../_shared/vnpay.mjs';
import { cors, json, required, rest } from '../_shared/http.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  try {
    const job = Boolean(Deno.env.get('COMMERCE_JOB_KEY')) && req.headers.get('x-job-key') === Deno.env.get('COMMERCE_JOB_KEY');
    const service = required('SUPABASE_SERVICE_ROLE_KEY');
    const token = job ? service : req.headers.get('Authorization')?.replace(/^Bearer /i, '');
    if (!token) return json({ error: 'Cần đăng nhập' }, 401);
    const user = job ? new Response('{}') : await fetch(`${required('SUPABASE_URL')}/auth/v1/user`, {
      headers: { apikey: required('SUPABASE_ANON_KEY'), Authorization: `Bearer ${token}` },
    });
    if (!user.ok) return json({ error: 'Phiên hết hạn' }, 401);
    const { orderId } = await req.json();
    if (!/^[0-9a-f-]{36}$/i.test(orderId || '')) return json({ error: 'Mã đơn không hợp lệ' }, 400);
    // RLS admits only the owner or an authorized administrator.
    const [order] = await rest(`learning_orders?id=eq.${orderId}&select=*`, token, undefined, job);
    if (!order) return json({ error: 'Không tìm thấy đơn' }, 404);
    const refunds = await rest(`refund_requests?order_id=eq.${orderId}&status=in.(unknown,processing)&select=*`, service, undefined, true);
    if (order.status === 'paid' && refunds.length === 0) return json({ status: 'paid' });
    if (order.status === 'refunded') return json({ status: 'refunded' });
    const claimed = await rest('rpc/claim_vnpay_check', service, { p_order: orderId }, true);
    if (!claimed) return json({ status: order.status, message: 'Vui lòng chờ trước khi kiểm tra tiếp.' });
    const tmn = required('VNPAY_TMN_CODE'), secret = required('VNPAY_HASH_SECRET');
    const data: Record<string, string> = {
      vnp_RequestId: crypto.randomUUID().replaceAll('-', ''), vnp_Version: '2.1.0',
      vnp_Command: 'querydr', vnp_TmnCode: tmn, vnp_TxnRef: orderId.replaceAll('-', ''),
      vnp_TransactionDate: vnpDate(new Date(order.created_at)), vnp_CreateDate: vnpDate(new Date()),
      vnp_IpAddr: required('VNPAY_SERVER_IP'), vnp_OrderInfo: `Check MathLingo order ${orderId.replaceAll('-', '')}`,
    };
    const signData = ['vnp_RequestId','vnp_Version','vnp_Command','vnp_TmnCode','vnp_TxnRef',
      'vnp_TransactionDate','vnp_CreateDate','vnp_IpAddr','vnp_OrderInfo'].map(k => data[k]).join('|');
    data.vnp_SecureHash = hashText(signData, secret);
    const endpoint = Deno.env.get('VNPAY_QUERY_URL') || 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction';
    if (!['https://sandbox.vnpayment.vn/merchant_webapi/api/transaction','https://pay.vnpay.vn/merchant_webapi/api/transaction'].includes(endpoint)) throw new Error('Invalid endpoint');
    const response = await fetch(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data), signal: AbortSignal.timeout(10000) });
    if (!response.ok) throw new Error('VNPay unavailable');
    const result = await response.json();
    if (!verifyText(queryResponseText(result), result.vnp_SecureHash, secret) || result.vnp_TmnCode !== tmn
      || result.vnp_TxnRef !== data.vnp_TxnRef || (result.vnp_Command && result.vnp_Command !== 'querydr')) throw new Error('Invalid query response');
    if (result.vnp_ResponseCode !== '00') return json({ status: order.status, message: 'VNPay chưa xác nhận kết quả. Vui lòng kiểm tra lại sau.' });
    if (!['01','02'].includes(result.vnp_TransactionType) || !/^\d+$/.test(result.vnp_Amount || '')
      || Number(result.vnp_Amount) !== Number(order.amount_vnd) * 100) throw new Error('Transaction mismatch');
    if (result.vnp_TransactionType === '02') {
      if (refunds.length && result.vnp_TransactionStatus === '00') await rest('rpc/finish_refund', service, { p_request: refunds[0].id, p_status: 'succeeded', p_reference: result.vnp_TransactionNo, p_code: result.vnp_ResponseCode }, true);
      return json({ message: 'Đã kiểm tra hoàn tiền.' });
    }
    if (['00','02','07'].includes(result.vnp_TransactionStatus)) {
      const settled = await rest('rpc/settle_vnpay_order', service, {
        p_order: orderId, p_transaction: result.vnp_TransactionNo, p_amount: Number(order.amount_vnd),
        p_code: result.vnp_TransactionStatus === '00' ? '00' : '99', p_transaction_status: result.vnp_TransactionStatus,
      }, true);
      if (!['00','02'].includes(settled)) throw new Error('Unable to settle');
    }
    return json({ message: 'Đã kiểm tra với VNPay. Danh sách đơn sẽ được cập nhật.' });
  } catch (_) { return json({ error: 'Chưa đối soát được với VNPay. Không thanh toán lại nếu đã bị trừ tiền.' }, 503); }
});
