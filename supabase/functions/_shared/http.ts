export const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
export function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { ...cors, 'Content-Type': 'application/json' } });
}
export function required(name: string) {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing configuration: ${name}`);
  return value;
}
export async function rest(path: string, token: string, body?: unknown, service = false) {
  const res = await fetch(`${required('SUPABASE_URL')}/rest/v1/${path}`, {
    method: body === undefined ? 'GET' : 'POST',
    headers: { apikey: required(service ? 'SUPABASE_SERVICE_ROLE_KEY' : 'SUPABASE_ANON_KEY'),
      Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok) throw new Error('Database request failed');
  if (res.status === 204) return null;
  const responseText = await res.text();
  return responseText ? JSON.parse(responseText) : null;
}
