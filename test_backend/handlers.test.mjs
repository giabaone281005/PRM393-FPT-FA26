import test from 'node:test';
import assert from 'node:assert/strict';
import { signature, hashText, queryResponseText } from '../supabase/functions/_shared/vnpay.mjs';

const env = new Map(Object.entries({ SUPABASE_URL: 'https://database.invalid', SUPABASE_ANON_KEY: 'test-anon',
  SUPABASE_SERVICE_ROLE_KEY: 'test-service', VNPAY_TMN_CODE: 'TESTCODE', VNPAY_HASH_SECRET: 'test-secret',
  VNPAY_RETURN_URL: 'https://database.invalid/return', VNPAY_SERVER_IP: '127.0.0.1' }));
const handlers = [];
globalThis.Deno = { env: { get: (key) => env.get(key) }, serve: (handler) => handlers.push(handler) };
await import('../supabase/functions/vnpay-checkout/index.ts');
await import('../supabase/functions/vnpay-ipn/index.ts');
await import('../supabase/functions/vnpay-query/index.ts');
const [checkout, ipn, query] = handlers;
const id = '12345678-1234-1234-1234-1234567890ab';
const ref = id.replaceAll('-', '');
const asJson = (data, status = 200) => new Response(JSON.stringify(data), { status });
const request = (data, token = 'test-user') => new Request('https://functions.invalid', {
  method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, body: JSON.stringify(data),
});
const order = { id, parent_id: id, amount_vnd: 99000, status: 'pending',
  created_at: new Date().toISOString(), expires_at: new Date(Date.now() + 900000).toISOString() };

test('checkout rejects unauthenticated requests before database access', async () => {
  globalThis.fetch = () => { throw new Error('must not fetch'); };
  assert.equal((await checkout(new Request('https://functions.invalid', { method: 'POST' }))).status, 401);
});
test('checkout reads amount from server order and signs the returned VNPay URL', async () => {
  globalThis.fetch = async (url) => url.includes('/auth/') ? asJson({ id }) : url.endsWith('/parent_authorized') ? asJson(true) : asJson(order);
  const res = await checkout(request({ parentToken:'proof', priceId: id, requestId: id, amount: 1 }));
  assert.equal(res.status, 200);
  const data = await res.json();
  const params = Object.fromEntries(new URL(data.checkoutUrl).searchParams);
  assert.equal(params.vnp_Amount, '9900000');
  assert.equal(params.vnp_TxnRef, ref);
  assert.equal(params.vnp_SecureHash, signature(params, 'test-secret'));
});
test('expired order is not reopened for payment', async () => {
  globalThis.fetch = async (url) => url.includes('/auth/') ? asJson({ id }) : url.endsWith('/parent_authorized') ? asJson(true) : asJson([{ ...order, expires_at: '2020-01-01T00:00:00Z' }]);
  assert.equal((await checkout(request({ parentToken:'proof', orderId: id }))).status, 409);
});
test('IPN with forged hash never reaches settlement', async () => {
  globalThis.fetch = () => { throw new Error('must not fetch'); };
  const res = await ipn(new Request('https://functions.invalid?vnp_SecureHash=bad'));
  assert.equal((await res.json()).RspCode, '97');
});
test('verified IPN calls service-only atomic settlement; database failure is retryable', async () => {
  const p = { vnp_TmnCode: 'TESTCODE', vnp_TxnRef: ref, vnp_Amount: '9900000',
    vnp_ResponseCode: '00', vnp_TransactionStatus: '00', vnp_TransactionNo: '123456' };
  const url = 'https://functions.invalid?' + new URLSearchParams({ ...p, vnp_SecureHash: signature(p, 'test-secret') });
  globalThis.fetch = async (target, options) => {
    assert.ok(target.endsWith('/rpc/settle_vnpay_order'));
    assert.equal(options.headers.Authorization, 'Bearer test-service');
    const body = JSON.parse(options.body);
    assert.equal(body.p_order, id); assert.equal(body.p_amount, 99000);
    return asJson('00');
  };
  assert.equal((await (await ipn(new Request(url))).json()).RspCode, '00');
  globalThis.fetch = async () => asJson({ error: 'temporary' }, 500);
  assert.equal((await (await ipn(new Request(url))).json()).RspCode, '99');
});
test('IPN rejects duplicate query parameters even if one value could be signed', async () => {
  assert.equal((await (await ipn(new Request('https://functions.invalid?vnp_Amount=1&vnp_Amount=2'))).json()).RspCode, '97');
});
test('reconciliation verifies provider response and settles only a successful matching payment', async () => {
  let settled = false;
  globalThis.fetch = async (url, options) => {
    if (url.includes('/auth/')) return asJson({ id });
    if (url.includes('/learning_orders?')) return asJson([order]);
    if (url.includes('/refund_requests?')) return asJson([]);
    if (url.endsWith('/claim_vnpay_check')) return asJson(true);
    if (url.endsWith('/settle_vnpay_order')) { settled = true; return asJson('00'); }
    const data = { vnp_ResponseId: 'response1', vnp_Command: 'querydr', vnp_ResponseCode: '00',
      vnp_Message: 'Success', vnp_TmnCode: 'TESTCODE', vnp_TxnRef: ref, vnp_Amount: '9900000',
      vnp_BankCode: 'TEST', vnp_PayDate: '20261016120000', vnp_TransactionNo: '123456',
      vnp_TransactionType: '01', vnp_TransactionStatus: '00', vnp_OrderInfo: 'test' };
    assert.equal(JSON.parse(options.body).vnp_Command, 'querydr');
    return asJson({ ...data, vnp_SecureHash: hashText(queryResponseText(data), 'test-secret') });
  };
  assert.equal((await query(request({ orderId: id }))).status, 200);
  assert.equal(settled, true);
});
