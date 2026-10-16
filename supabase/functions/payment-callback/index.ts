//  @ts-nocheck
// import { createClient } from "npm:@supabase/supabase-js@2";
// import { createHmac } from "node:crypto";
// const hmac = (k: string, d: string) => createHmac("sha256", k).update(d).digest("hex");
//
// Deno.serve(async (req) => {
//     const provider = new URL(req.url).searchParams.get("provider");
//     const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
//     const body = await req.json();
//     let orderId = "", ok = false, amount = 0;
//
//     if (provider === "momo") {
//         const b = body, A = Deno.env.get("MOMO_ACCESS")!, S = Deno.env.get("MOMO_SECRET")!;
//         const raw = `accessKey=${A}&amount=${b.amount}&extraData=${b.extraData}&message=${b.message}&orderId=${b.orderId}&orderInfo=${b.orderInfo}&orderType=${b.orderType}&partnerCode=${b.partnerCode}&payType=${b.payType}&requestId=${b.requestId}&responseTime=${b.responseTime}&resultCode=${b.resultCode}&transId=${b.transId}`;
//         if (hmac(S, raw) !== b.signature) return new Response("bad sig", { status: 400 });
//         orderId = b.orderId; amount = b.amount; ok = b.resultCode === 0;
//     } else {
//         if (hmac(Deno.env.get("ZP_KEY2")!, body.data) !== body.mac)
//             return Response.json({ return_code: -1, return_message: "mac not equal" });
//         const d = JSON.parse(body.data);
//         orderId = d.app_trans_id; amount = d.amount; ok = true;
//     }
//
//     const { data: p } = await sb.from("payments").select("*").eq("order_id", orderId).maybeSingle();
//     if (p && p.status === "pending" && p.amount === amount) {
//         if (ok) {
//             await sb.from("payments").update({ status: "paid" }).eq("id", p.id);
//             await sb.rpc("activate_plus", { p_parent: p.parent_id, p_days: 365 });
//         } else await sb.from("payments").update({ status: "failed" }).eq("id", p.id);
//     }
//     return provider === "momo" ? new Response(null, { status: 204 }) : Response.json({ return_code: 1, return_message: "success" });
// });