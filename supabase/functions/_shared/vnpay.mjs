import { createHmac, timingSafeEqual } from 'node:crypto';
import { Buffer } from 'node:buffer';

export function canonicalQuery(params) {
  const encode = (value) => encodeURIComponent(value).replace(/%20/g, '+');
  return Object.keys(params).filter((key) => key !== 'vnp_SecureHash' && key !== 'vnp_SecureHashType')
    .sort().map((key) => `${encode(key)}=${encode(String(params[key]))}`).join('&');
}

export function signature(params, secret) {
  return hashText(canonicalQuery(params), secret);
}

export function hashText(text, secret) {
  return createHmac('sha512', secret).update(text, 'utf8').digest('hex');
}

export function verifyText(text, actual, secret) {
  if (!/^[a-fA-F0-9]{128}$/.test(actual || '')) return false;
  return timingSafeEqual(Buffer.from(actual.toLowerCase(), 'hex'), Buffer.from(hashText(text, secret), 'hex'));
}

export function queryResponseText(p) {
  return ['vnp_ResponseId','vnp_Command','vnp_ResponseCode','vnp_Message','vnp_TmnCode',
    'vnp_TxnRef','vnp_Amount','vnp_BankCode','vnp_PayDate','vnp_TransactionNo',
    'vnp_TransactionType','vnp_TransactionStatus','vnp_OrderInfo','vnp_PromotionCode',
    'vnp_PromotionAmount'].map(key => p[key] ?? '').join('|');
}

export function verifySignature(params, secret) {
  const actual = params.vnp_SecureHash ?? '';
  if (!/^[a-fA-F0-9]{128}$/.test(actual)) return false;
  return timingSafeEqual(Buffer.from(actual.toLowerCase(), 'hex'), Buffer.from(signature(params, secret), 'hex'));
}

export function vnpDate(date) {
  return new Date(date.getTime() + 7 * 60 * 60 * 1000).toISOString().replace(/[-:T]/g, '').slice(0, 14);
}

export function uuidFromReference(ref) {
  if (!/^[a-f0-9]{32}$/i.test(ref)) return null;
  return `${ref.slice(0,8)}-${ref.slice(8,12)}-${ref.slice(12,16)}-${ref.slice(16,20)}-${ref.slice(20)}`;
}
