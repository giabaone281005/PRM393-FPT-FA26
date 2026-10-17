import test from 'node:test';
import assert from 'node:assert/strict';
import { canonicalQuery, signature, verifySignature, vnpDate, uuidFromReference } from '../supabase/functions/_shared/vnpay.mjs';

test('VNPay canonical encoding matches documented Node encodeURIComponent + space replacement', () => {
  assert.equal(canonicalQuery({ z: 'a+b', a: 'Thanh toan 100', vnp_SecureHash: 'excluded' }), 'a=Thanh+toan+100&z=a%2Bb');
});
test('signed result rejects changed amount, wrong merchant secret, missing/invalid hash', () => {
  const data = { vnp_Amount: '100000', vnp_TmnCode: 'TEST', vnp_TxnRef: '123' };
  const signed = { ...data, vnp_SecureHash: signature(data, 'secret') };
  assert.equal(verifySignature(signed, 'secret'), true);
  assert.equal(verifySignature({ ...signed, vnp_Amount: '1' }, 'secret'), false);
  assert.equal(verifySignature(signed, 'wrong'), false);
  assert.equal(verifySignature(data, 'secret'), false);
  assert.equal(verifySignature({ ...data, vnp_SecureHash: 'xyz' }, 'secret'), false);
});
test('VNPay uses GMT+7 date and alphanumeric transaction reference', () => {
  assert.equal(vnpDate(new Date('2026-12-31T18:00:00Z')), '20270101010000');
  assert.equal(uuidFromReference('123456781234123412341234567890ab'), '12345678-1234-1234-1234-1234567890ab');
  assert.equal(uuidFromReference('bad'), null);
});
