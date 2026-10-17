import { hashText, verifyText, vnpDate } from '../_shared/vnpay.mjs';
import { cors, json, required, rest } from '../_shared/http.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  let requestId: string | null = null;
  const service = required('SUPABASE_SERVICE_ROLE_KEY');
  try {
    const token = req.headers.get('Authorization')?.replace(/^Bearer /i, '');
    if (!token) return json({ error: 'Cần đăng nhập' }, 401);
    const userRes = await fetch(`${required('SUPABASE_URL')}/auth/v1/user`, { headers: { apikey: required('SUPABASE_ANON_KEY'), Authorization: `Bearer ${token}` } });
    if (!userRes.ok) return json({ error: 'Phiên hết hạn' }, 401);
    const user = await userRes.json();
    if (!await rest('rpc/is_admin', token, {})) return json({ error: 'Cần quyền admin' }, 403);
    const { orderId, reason } = await req.json();
    if (!/^[0-9a-f-]{36}$/i.test(orderId || '') || typeof reason !== 'string' || reason.trim().length < 5 || reason.length > 500) return json({ error: 'Mã đơn/lý do không hợp lệ' }, 400);
    const tmn = required('VNPAY_TMN_CODE'), secret = required('VNPAY_HASH_SECRET');
    const serverIp = required('VNPAY_SERVER_IP');
    const endpoint = Deno.env.get('VNPAY_QUERY_URL') || 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction';
    if (!['https://sandbox.vnpayment.vn/merchant_webapi/api/transaction','https://pay.vnpay.vn/merchant_webapi/api/transaction'].includes(endpoint)) throw new Error('Invalid endpoint');
    const id = await rest('rpc/request_refund', token, { p_order: orderId, p_reason: reason });
    const claim = await rest('rpc/claim_refund', service, { p_request: id }, true);
    if (!claim) return json({ message: 'Yêu cầu đã được ghi nhận. Kiểm tra lịch sử hoàn tiền; không gửi lại nếu trạng thái chưa rõ.' }, 202);
    requestId = id;
    const data: Record<string, string> = {
      vnp_RequestId: id.replaceAll('-', ''), vnp_Version: '2.1.0', vnp_Command: 'refund',
      vnp_TmnCode: tmn, vnp_TransactionType: '02', vnp_TxnRef: orderId.replaceAll('-', ''),
      vnp_Amount: String(Number(claim.order.amount_vnd) * 100), vnp_TransactionNo: claim.payment.external_transaction_id,
      vnp_TransactionDate: vnpDate(new Date(claim.order.created_at)), vnp_CreateBy: user.id,
      vnp_CreateDate: vnpDate(new Date(claim.created_at)), vnp_IpAddr: serverIp,
      vnp_OrderInfo: `Refund MathLingo ${orderId.replaceAll('-', '')}`,
    };
    data.vnp_SecureHash = hashText(['vnp_RequestId','vnp_Version','vnp_Command','vnp_TmnCode','vnp_TransactionType','vnp_TxnRef','vnp_Amount','vnp_TransactionNo','vnp_TransactionDate','vnp_CreateBy','vnp_CreateDate','vnp_IpAddr','vnp_OrderInfo'].map(k => data[k]).join('|'), secret);
    const response = await fetch(endpoint, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data), signal: AbortSignal.timeout(10000) });
    if (!response.ok) throw new Error('Unavailable');
    const result = await response.json();
    const signed = ['vnp_ResponseId','vnp_Command','vnp_ResponseCode','vnp_Message','vnp_TmnCode','vnp_TxnRef','vnp_Amount','vnp_BankCode','vnp_PayDate','vnp_TransactionNo','vnp_TransactionType','vnp_TransactionStatus','vnp_OrderInfo'].map(k => result[k] ?? '').join('|');
    if (!verifyText(signed, result.vnp_SecureHash, secret) || result.vnp_TmnCode !== tmn || result.vnp_TxnRef !== data.vnp_TxnRef || result.vnp_Command !== 'refund' || result.vnp_TransactionType !== '02' || result.vnp_Amount !== data.vnp_Amount) throw new Error('Invalid response');
    // A successful API acknowledgement is not sufficient: the transaction must be confirmed.
    const status = result.vnp_ResponseCode === '00' && result.vnp_TransactionStatus === '00' ? 'succeeded' : ['00','94','99'].includes(result.vnp_ResponseCode) ? 'unknown' : 'failed';
    await rest('rpc/finish_refund', service, { p_request: id, p_status: status, p_reference: result.vnp_TransactionNo, p_code: result.vnp_ResponseCode }, true);
    requestId = null;
    return json({ status });
  } catch (_) {
    if (requestId) {
      try { await rest('rpc/finish_refund', service, { p_request: requestId, p_status: 'unknown', p_reference: null, p_code: 'NETWORK' }, true); } catch (_) { /* maintenance marks stale claims unknown */ }
    }
    return json({ error: 'Chưa xác định được kết quả. Kiểm tra tại VNPay trước khi xử lý tiếp.' }, 503);
  }
});
