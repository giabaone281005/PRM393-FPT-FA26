// @ts-nocheck
import { createHmac, timingSafeEqual } from 'node:crypto';
import { Buffer } from 'node:buffer';

export const momoSign = (raw: string, secret: string) =>
    createHmac('sha256', secret).update(raw, 'utf8').digest('hex');

export function momoVerify(raw: string, actual: string, secret: string) {
    if (!/^[a-f0-9]{64}$/i.test(actual)) return false;
    return timingSafeEqual(Buffer.from(actual.toLowerCase(), 'hex'), Buffer.from(momoSign(raw, secret), 'hex'));
}