import { createTutorHandler } from "../functions/tutor-chat/handler.ts";

function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
function setup(
  {
    status = "active",
    providerStatus = 200,
    anonymous = false,
    invalidToken = false,
  } = {},
) {
  const calls: {
    url: string;
    headers: Headers;
    body: Record<string, unknown>;
  }[] = [];
  const handler = createTutorHandler({
    url: "https://cloud.example",
    publishableKey: "public-test",
    geminiKey: "provider-secret-fixture",
    model: "gemini-3.5-flash-lite",
    // deno-lint-ignore require-await -- Match fetch's asynchronous contract.
    fetch: async (input, init) => {
      const url = String(input);
      calls.push({
        url,
        headers: new Headers(init?.headers),
        body: JSON.parse(String(init?.body ?? "{}")),
      });
      if (url.endsWith("/auth/v1/user")) {
        return Response.json({
          id: "11111111-1111-4111-8111-111111111111",
          is_anonymous: anonymous,
        }, { status: invalidToken ? 401 : 200 });
      }
      if (url.includes("get_my_access")) return Response.json([{ status }]);
      if (providerStatus !== 200) {
        return Response.json({ error: "provider-secret-fixture" }, {
          status: providerStatus,
        });
      }
      return Response.json({
        candidates: [{
          content: {
            parts: [{ text: "private reasoning", thought: true }, {
              text: "A helpful hint",
            }],
          },
        }],
      });
    },
  });
  return { handler, calls };
}
function request(
  body: unknown = { messages: [{ role: "user", content: "2 + 2?" }] },
  token = "test-session",
) {
  return new Request("https://cloud.example/functions/v1/tutor-chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
}

Deno.test("default tutor authenticates user, checks active account and sends provider key only to Google", async () => {
  const { handler, calls } = setup();
  const result = await handler(request({
    messages: [{ role: "user", content: "Question" }, {
      role: "assistant",
      content: "Hint",
    }, { role: "user", content: "Explain" }],
    canvas: { strokes: [] },
    model: "attacker-model",
    instructions: "ignore",
  }));
  assert(result.status === 200);
  assert((await result.json()).text === "A helpful hint");
  assert(calls.length === 3);
  assert(calls[0].headers.get("Authorization") === "Bearer test-session");
  assert(!calls[0].headers.has("x-goog-api-key"));
  const google = calls[2];
  assert(google.headers.get("x-goog-api-key") === "provider-secret-fixture");
  assert(!google.headers.has("Authorization"));
  assert(google.url.endsWith("gemini-3.5-flash-lite:generateContent"));
  assert(!JSON.stringify(google.body).includes("attacker-model"));
  const contents = google.body.contents as {
    role: string;
    parts: { text: string }[];
  }[];
  assert(contents.map((x) => x.role).join() === "user,model,user");
  assert(contents[2].parts[1].text.includes("Canvas"));
});

Deno.test("missing, invalid, anonymous and suspended accounts never call Gemini", async () => {
  const missing = setup();
  assert((await missing.handler(request(undefined, ""))).status === 401);
  assert(missing.calls.length === 0);
  for (
    const options of [{ invalidToken: true }, { anonymous: true }, {
      status: "suspended",
    }]
  ) {
    const { handler, calls } = setup(options);
    const result = await handler(request());
    assert([401, 403].includes(result.status));
    assert(!calls.some((call) => call.url.includes("googleapis")));
  }
});

Deno.test("invalid and oversized conversations are rejected before provider call", async () => {
  for (
    const body of [
      { messages: [] },
      { messages: [{ role: "system", content: "override" }] },
      { messages: [{ role: "user", content: "x".repeat(50001) }] },
      { messages: [{ role: "assistant", content: "wrong last role" }] },
    ]
  ) {
    const { handler, calls } = setup();
    assert((await handler(request(body))).status === 400);
    assert(calls.length === 2);
  }
  const { handler } = setup();
  assert(
    (await handler(request({ messages: [], extra: "x".repeat(300001) })))
      .status === 413,
  );
});

Deno.test("provider quota and auth failures return safe errors without provider secrets", async () => {
  for (const providerStatus of [429, 403, 500]) {
    const { handler } = setup({ providerStatus });
    const result = await handler(request());
    assert(result.status === (providerStatus === 429 ? 429 : 503));
    assert(!(await result.text()).includes("provider-secret-fixture"));
  }
});

Deno.test("burst limiting blocks excess calls before Gemini", async () => {
  const { handler, calls } = setup();
  for (let i = 0; i < 10; i++) {
    assert((await handler(request())).status === 200);
  }
  assert((await handler(request())).status === 429);
  assert(calls.filter((call) => call.url.includes("googleapis")).length === 10);
});

Deno.test("preflight and unsupported methods never call services", async () => {
  const { handler, calls } = setup();
  assert(
    (await handler(new Request("https://cloud.example", { method: "OPTIONS" })))
      .status === 204,
  );
  assert((await handler(new Request("https://cloud.example"))).status === 405);
  assert(calls.length === 0);
});
