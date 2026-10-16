// import { createClient } from "npm:@supabase/supabase-js@2";
// import { createHmac } from "node:crypto";
// import QRCode from "npm:qrcode@1.5.4";
//
// const hmac = (k: string, d: string) => createHmac("sha256", k).update(d).digest("hex");
// const AMOUNT = 499000;
// const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info" };
// const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
//
// Deno.serve(async (req) => {
//     if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
//     const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
//     const { data: { user } } = await sb.auth.getUser(req.headers.get("Authorization")!.replace("Bearer ", ""));
//     if (!user) return json({ error: "unauthorized" }, 401);
//     const { provider } = await req.json();
//     const cb = `${Deno.env.get("SUPABASE_URL")}/functions/v1/payment-callback?provider=${provider}`;
//     let orderId: string, qr: string;
//
//     if (provider === "momo") {
//         const P = Deno.env.get("MOMO_PARTNER")!, A = Deno.env.get("MOMO_ACCESS")!, S = Deno.env.get("MOMO_SECRET")!;
//         orderId = `PLUS${Date.now()}`;
//         const requestId = orderId, orderInfo = "Nang cap Plus", extraData = "", redirectUrl = "https://example.com", requestType = "captureWallet";
//         const raw = `accessKey=${A}&amount=${AMOUNT}&extraData=${extraData}&ipnUrl=${cb}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${P}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;
//         const r = await (await fetch("https://test-payment.momo.vn/v2/gateway/api/create", {
//             method: "POST", headers: { "Content-Type": "application/json" },
//             body: JSON.stringify({ partnerCode: P, requestId, amount: AMOUNT, orderId, orderInfo, redirectUrl, ipnUrl: cb, requestType, extraData, lang: "vi", signature: hmac(S, raw) }),
//         })).json();
//         if (r.resultCode !== 0) return json({ error: r.message }, 400);
//         qr = r.qrCodeUrl ?? r.payUrl;
//     } else {
//         const id = Deno.env.get("ZP_APP_ID")!, k1 = Deno.env.get("ZP_KEY1")!;
//         const d = new Date(Date.now() + 7 * 3600e3);
//         const yymmdd = d.toISOString().slice(2, 10).replace(/-/g, "");
//         orderId = `${yymmdd}_${Date.now()}`;
//         const o: Record<string, string> = {
//             app_id: id, app_user: user.id, app_trans_id: orderId, app_time: String(Date.now()),
//             amount: String(AMOUNT), item: "[]", embed_data: "{}", description: "Nang cap Plus", bank_code: "", callback_url: cb,
//         };
//         o.mac = hmac(k1, `${o.app_id}|${o.app_trans_id}|${o.app_user}|${o.amount}|${o.app_time}|${o.embed_data}|${o.item}`);
//         const r = await (await fetch("https://sb-openapi.zalopay.vn/v2/create", {
//             method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: new URLSearchParams(o),
//         })).json();
//         if (r.return_code !== 1) return json({ error: r.return_message }, 400);
//         qr = r.qr_code ?? r.order_url;
//     }
//     await sb.from("payments").insert({ parent_id: user.id, provider, order_id: orderId, amount: AMOUNT, qr_content: qr });
//     return json({ order_id: orderId, qr_image: await QRCode.toDataURL(qr, { width: 360 }) });
// });