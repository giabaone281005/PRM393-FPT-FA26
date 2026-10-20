import { cors, json } from '../_shared/http.ts';

// Demo must never use the merchant settlement RPC or grant purchased rights.
// Keep the endpoint explicit for older app versions until a separate demo
// environment and ledger are available.
Deno.serve((req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  return json({ error: 'Thanh toán mô phỏng đã tắt. Vui lòng chọn cổng thanh toán.' }, 403);
});
