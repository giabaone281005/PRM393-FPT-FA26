import { required, rest } from '../_shared/http.ts';
import { momoVerify } from '../_shared/momo.ts';
import { uuidFromReference } from '../_shared/vnpay.mjs';

// Các mã chưa có kết quả cuối: không được đánh failed
const PENDING = new Set([1000, 7000, 7002, 9000]);
const reply = (status: number) => new Response(null, { status });

Deno.serve(async (req) => {
    if (req.method !== 'POST') return reply(405);
    try {
        const p = await req.json();
        const secret = required('MOMO_SECRET_KEY');
        const raw = `accessKey=${required('MOMO_ACCESS_KEY')}&amount=${p.amount}&extraData=${p.extraData ?? ''}` +
            `&message=${p.message}&orderId=${p.orderId}&orderInfo=${p.orderInfo}&orderType=${p.orderType}` +
            `&partnerCode=${p.partnerCode}&payType=${p.payType}&requestId=${p.requestId}` +
            `&responseTime=${p.responseTime}&resultCode=${p.resultCode}&transId=${p.transId}`;

        if (p.partnerCode !== required('MOMO_PARTNER_CODE') || !momoVerify(raw, String(p.signature ?? ''), secret)) {
            return reply(400); // sai chữ ký
        }
        const orderUuid = uuidFromReference(String(p.orderId).split('_')[0]);
        if (!orderUuid) return reply(400);
        if (!Number.isSafeInteger(Number(p.amount)) || Number(p.amount) <= 0 || !Number.isInteger(Number(p.resultCode))) return reply(400);
        const [attempt] = await rest(`learning_checkout_attempts?order_id=eq.${orderUuid}&select=provider,gateway_order_id`, required('SUPABASE_SERVICE_ROLE_KEY'), undefined, true);
        if (attempt && (attempt.provider !== 'momo' || attempt.gateway_order_id !== p.orderId || p.requestId !== attempt.gateway_order_id)) return reply(400);
        if (PENDING.has(Number(p.resultCode))) return reply(204);

        const result = await rest('rpc/settle_momo_order', required('SUPABASE_SERVICE_ROLE_KEY'), {
            p_order: orderUuid,
            p_transaction: String(p.transId),
            p_amount: Number(p.amount),
            p_result: Number(p.resultCode),
        }, true);

        // REVIEW is persisted for operators; retries must not grant more Plus.
        if (result === 'OK' || result === 'REVIEW') return reply(204);
        if (result === 'RETRY') return reply(500); // để MoMo gửi lại
        console.error('MoMo IPN rejected', result);
        return reply(400);
    } catch (_) {
        return reply(500); // lỗi tạm thời: MoMo sẽ gửi lại
    }
});
