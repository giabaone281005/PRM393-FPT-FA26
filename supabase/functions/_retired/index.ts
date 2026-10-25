// Safe retirement response for endpoints belonging to the deleted legacy schema.
// No database access, provider credentials, model requests or payment actions.
Deno.serve((request: Request) => new Response(
  request.method === 'OPTIONS' ? null : JSON.stringify({
    error: 'legacy_backend_retired',
    message: 'This endpoint was retired during the Matlingo backend migration.',
  }),
  {
    status: request.method === 'OPTIONS' ? 204 : 410,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
      'Cache-Control': 'no-store',
    },
  },
));
