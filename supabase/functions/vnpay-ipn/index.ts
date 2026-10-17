import { verifySignature, uuidFromReference } from '../_shared/vnpay.mjs';
import { json, required, rest } from '../_shared/http.ts';

Deno.serve(async (req) => {
  if (req.method !== 'GET') return json({ RspCode: '99', Message: 'Method not allowed' }, 405);
  try {
    const params: Record<string, string> = {};
    for (const [key, value] of new URL(req.url).searchParams) {
      if (!key.startsWith('vnp_') || key in params) return json({ RspCode: '97', Message: 'Invalid parameters' });
      params[key] = value;
    }
    if (!verifySignature(params, required('VNPAY_HASH_SECRET')) || params.vnp_TmnCode !== required('VNPAY_TMN_CODE')) {
      return json({ RspCode: '97', Message: 'Invalid signature' });
    }
    const orderId = uuidFromReference(params.vnp_TxnRef || '');
    if (!orderId) return json({ RspCode: '01', Message: 'Order not found' });
    const amount = Number(params.vnp_Amount);
    if (!/^\d+$/.test(params.vnp_Amount || '') || !Number.isSafeInteger(amount) || amount % 100 !== 0) {
      return json({ RspCode: '04', Message: 'Invalid amount' });
    }
    const result = await rest('rpc/settle_vnpay_order', required('SUPABASE_SERVICE_ROLE_KEY'), {
      p_order: orderId, p_transaction: params.vnp_TransactionNo || '', p_amount: amount / 100,
      p_code: params.vnp_ResponseCode || '', p_transaction_status: params.vnp_TransactionStatus || '',
    }, true);
    return json({ RspCode: result, Message: result === '00' ? 'Confirm Success' : result === '02' ? 'Already confirmed' : 'Rejected' });
  } catch (_) {
    // Non-success acknowledgement lets VNPay retry; no false confirmation on database failure.
    return json({ RspCode: '99', Message: 'Temporary processing error' });
  }
});
