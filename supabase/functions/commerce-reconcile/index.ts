import { json, required, rest } from '../_shared/http.ts';
Deno.serve(async (req) => {
  if (req.method !== 'POST' || req.headers.get('x-job-key') !== required('COMMERCE_JOB_KEY')) return json({ error: 'Unauthorized' }, 401);
  try {
    const service = required('SUPABASE_SERVICE_ROLE_KEY');
    const rows = await rest('rpc/pending_reconciliation', service, {}, true);
    let checked = 0;
    for (let index = 0; index < rows.length; index += 4) {
      const results = await Promise.allSettled(rows.slice(index, index + 4).map((row: { id: string }) => fetch(`${required('SUPABASE_URL')}/functions/v1/vnpay-query`, {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'x-job-key': required('COMMERCE_JOB_KEY') }, body: JSON.stringify({ orderId: row.id }), signal: AbortSignal.timeout(15000),
      })));
      checked += results.filter(r => r.status === 'fulfilled' && r.value.ok).length;
    }
    const maintenance = await rest('rpc/commerce_maintenance', service, {}, true);
    return json({ checked, ...maintenance });
  } catch (_) { return json({ error: 'Reconciliation incomplete' }, 503); }
});
