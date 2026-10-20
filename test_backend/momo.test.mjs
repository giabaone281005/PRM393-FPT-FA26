import test from 'node:test';
import assert from 'node:assert/strict';
import { momoSign } from '../supabase/functions/_shared/momo.ts';

const env = new Map(Object.entries({ SUPABASE_URL: 'https://database.invalid', SUPABASE_ANON_KEY: 'anon',
  SUPABASE_SERVICE_ROLE_KEY: 'service', MOMO_PARTNER_CODE: 'PARTNER', MOMO_ACCESS_KEY: 'access',
  MOMO_SECRET_KEY: 'secret', MOMO_IPN_URL: 'https://database.invalid/ipn', MOMO_REDIRECT_URL: 'https://database.invalid/return',
  COMMERCE_JOB_KEY: 'job-key' }));
const handlers = [];
globalThis.Deno = { env: { get: key => env.get(key) }, serve: handler => handlers.push(handler) };
await import('../supabase/functions/momo-checkout/index.ts');
await import('../supabase/functions/momo-ipn/index.ts');
await import('../supabase/functions/momo-query/index.ts');
await import('../supabase/functions/demo-pay/index.ts');
await import('../supabase/functions/commerce-reconcile/index.ts');
const [checkout, ipn, query, demo, job] = handlers;
const id = '12345678-1234-4234-8234-1234567890ab';
const gateway = id.replaceAll('-', '');
const order = { id, parent_id: id, amount_vnd: 99000, status: 'pending', expires_at: new Date(Date.now() + 900000).toISOString() };
const attempt = { order_id: id, provider: 'momo', environment: 'sandbox', gateway_order_id: gateway };
const json = (value, status = 200) => new Response(JSON.stringify(value), { status });
const request = value => new Request('https://handler.invalid', { method: 'POST',
  headers: { Authorization: 'Bearer user', 'Content-Type': 'application/json' }, body: JSON.stringify(value) });

function checkoutFetch(provider, saved = null) {
  return async (url, options) => {
    if (url.includes('/auth/')) return json({ id });
    if (url.endsWith('/parent_authorized')) return json(true);
    if (url.includes('/learning_orders?')) return json([order]);
    if (url.endsWith('/reserve_learning_checkout')) {
      assert.equal(options.headers.Authorization, 'Bearer service');
      assert.deepEqual(JSON.parse(options.body), { p_order: id, p_parent: id, p_provider: 'momo', p_environment: 'sandbox' });
      return json({ ...attempt, checkout_response: saved });
    }
    if (url.endsWith('/save_learning_checkout')) return json(JSON.parse(options.body).p_response);
    assert.equal(url, 'https://test-payment.momo.vn/v2/gateway/api/create');
    return provider(JSON.parse(options.body));
  };
}

test('MoMo checkout retries preserve provider order and idempotency key after timeout', async () => {
  const requests = [];
  globalThis.fetch = checkoutFetch(async body => {
    requests.push(body);
    if (requests.length === 1) throw Error('network timeout after provider accepted');
    return json({ resultCode: 0, payUrl: 'https://test-payment.momo.vn/pay/one' });
  });
  assert.equal((await checkout(request({ orderId: id, parentToken: 'proof' }))).status, 503);
  assert.equal((await checkout(request({ orderId: id, parentToken: 'proof' }))).status, 200);
  assert.equal(requests.length, 2);
  assert.deepEqual(requests[0], requests[1]);
  assert.equal(requests[0].orderId, gateway);
  assert.equal(requests[0].requestId, gateway);
});

test('persisted MoMo checkout returns the same link without a provider call', async () => {
  const saved = { payUrl: 'https://test-payment.momo.vn/pay/one', deeplink: null };
  globalThis.fetch = checkoutFetch(() => assert.fail('must not create another provider transaction'), saved);
  const result = await checkout(request({ orderId: id, parentToken: 'proof' }));
  assert.equal(result.status, 200);
  assert.equal((await result.json()).payUrl, saved.payUrl);
});

test('duplicate or in-flight provider operation never creates a new order ID', async () => {
  for (const resultCode of [40, 41, 43]) {
    globalThis.fetch = checkoutFetch(body => {
      assert.equal(body.orderId, gateway);
      return json({ resultCode });
    });
    assert.equal((await checkout(request({ orderId: id, parentToken: 'proof' }))).status, 409);
  }
});

test('a different parent or expired order cannot reserve or charge', async () => {
  globalThis.fetch = async url => url.includes('/auth/') ? json({ id }) : url.endsWith('/parent_authorized') ? json(true)
    : url.includes('/learning_orders?') ? json([]) : assert.fail('must not reserve or charge');
  assert.equal((await checkout(request({ orderId: id, parentToken: 'proof' }))).status, 404);
});

function ipnRequest(overrides = {}) {
  const p = { amount: 99000, extraData: '', message: 'Success', orderId: gateway, orderInfo: 'MathLingo',
    orderType: 'momo_wallet', partnerCode: 'PARTNER', payType: 'qr', requestId: gateway,
    responseTime: 1792000000000, resultCode: 0, transId: 1234567890, ...overrides };
  const raw = `accessKey=access&amount=${p.amount}&extraData=${p.extraData}&message=${p.message}&orderId=${p.orderId}&orderInfo=${p.orderInfo}&orderType=${p.orderType}&partnerCode=${p.partnerCode}&payType=${p.payType}&requestId=${p.requestId}&responseTime=${p.responseTime}&resultCode=${p.resultCode}&transId=${p.transId}`;
  return request({ ...p, signature: momoSign(raw, 'secret') });
}

test('forged MoMo signature never reaches the database', async () => {
  globalThis.fetch = () => assert.fail('must not access database');
  assert.equal((await ipn(request({ signature: 'bad' }))).status, 400);
});

test('verified additional transaction is acknowledged only after the review is persisted', async () => {
  let called = false;
  globalThis.fetch = async (url, options) => {
    if (url.includes('/learning_checkout_attempts?')) return json([attempt]);
    assert.ok(url.endsWith('/settle_momo_order'));
    assert.equal(options.headers.Authorization, 'Bearer service');
    assert.equal(JSON.parse(options.body).p_transaction, '1234567890');
    called = true;
    return json('REVIEW');
  };
  assert.equal((await ipn(ipnRequest())).status, 204);
  assert.equal(called, true);
  globalThis.fetch = async () => json({ error: 'temporary database failure' }, 500);
  assert.equal((await ipn(ipnRequest())).status, 500);
});

test('MoMo callback cannot settle another provider or a mismatching gateway request', async () => {
  globalThis.fetch = async url => url.includes('/learning_checkout_attempts?') ? json([{ ...attempt, provider: 'vnpay' }]) : assert.fail('must not settle');
  assert.equal((await ipn(ipnRequest())).status, 400);
  globalThis.fetch = async url => url.includes('/learning_checkout_attempts?') ? json([attempt]) : assert.fail('must not settle');
  assert.equal((await ipn(ipnRequest({ requestId: 'other-request' }))).status, 400);
});

function queryFetch(mutator, settle) {
  return async (url, options) => {
    if (url.includes('/auth/')) return json({ id });
    if (url.includes('/learning_orders?')) return json([order]);
    if (url.includes('/learning_checkout_attempts?')) return json([attempt]);
    if (url.endsWith('/claim_vnpay_check')) return json(true);
    if (url.endsWith('/settle_momo_order')) return settle(JSON.parse(options.body));
    assert.equal(url, 'https://test-payment.momo.vn/v2/gateway/api/query');
    const body = JSON.parse(options.body);
    assert.equal(body.signature, momoSign(`accessKey=access&orderId=${gateway}&partnerCode=PARTNER&requestId=${body.requestId}`, 'secret'));
    return json(mutator({ partnerCode: 'PARTNER', orderId: gateway, requestId: body.requestId, amount: 99000, resultCode: 0, transId: 1234567890 }));
  };
}

test('MoMo query validates correlation and amount before settlement', async () => {
  for (const change of [p => ({ ...p, amount: 1 }), p => ({ ...p, orderId: 'other' }), p => ({ ...p, requestId: 'other' })]) {
    globalThis.fetch = queryFetch(change, () => assert.fail('mismatching response must not settle'));
    assert.equal((await query(request({ orderId: id }))).status, 503);
  }
  let settled = false;
  globalThis.fetch = queryFetch(p => p, body => { assert.equal(body.p_amount, 99000); settled = true; return json('OK'); });
  assert.equal((await query(request({ orderId: id }))).status, 200);
  assert.equal(settled, true);
});

test('pending query does not mark failed or activate Plus', async () => {
  globalThis.fetch = queryFetch(p => ({ ...p, resultCode: 1000 }), () => assert.fail('must not settle'));
  assert.equal((await query(request({ orderId: id }))).status, 200);
});

test('demo is disabled even with a valid user and enabled legacy environment flag', async () => {
  env.set('DEMO_PAY_ENABLED', 'true');
  globalThis.fetch = () => assert.fail('demo must never invoke a merchant settlement');
  assert.equal((await demo(request({ action: 'simulate', orderId: id, parentToken: 'proof' }))).status, 403);
});

test('maintenance sends MoMo orders to the MoMo query endpoint', async () => {
  let queried = false;
  globalThis.fetch = async url => {
    if (url.endsWith('/pending_reconciliation')) return json([order]);
    if (url.includes('/learning_checkout_attempts?')) return json([attempt]);
    if (url.endsWith('/commerce_maintenance')) return json({ expired_orders: 0 });
    assert.ok(url.endsWith('/momo-query'));
    queried = true;
    return json({ status: 'pending' });
  };
  const result = await job(new Request('https://handler.invalid', { method: 'POST', headers: { 'x-job-key': 'job-key' }, body: '{}' }));
  assert.equal(result.status, 200);
  assert.equal(queried, true);
});
