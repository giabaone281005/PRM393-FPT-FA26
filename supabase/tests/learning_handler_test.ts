import { createHandler } from "../functions/learning-api/handler.ts";

function assert(ok: unknown, message = "Assertion failed"): asserts ok {
  if (!ok) throw new Error(message);
}
const actor = "11111111-1111-4111-8111-111111111111";
const operation = "22222222-2222-4222-8222-222222222222";
function setup(
  role = "user",
  status = "active",
  failure?: { code: string; message: string },
) {
  const calls: {
    path: string;
    authorization: string | null;
    body: Record<string, unknown>;
  }[] = [];
  const handler = createHandler({
    url: "https://example.supabase.co",
    publishableKey: "public-test-key",
    serviceKey: "server-test-key",
    implementationHash: "hash",
    evaluate: () =>
      JSON.stringify({
        is_correct: false,
        mechanism: "balanceBlocks",
        evaluator_version: 1,
      }),
    // deno-lint-ignore require-await -- Preserve the real fetch Promise contract.
    fetch: async (input, init) => {
      const path = new URL(String(input)).pathname;
      calls.push({
        path,
        authorization: new Headers(init?.headers).get("authorization"),
        body: JSON.parse(String(init?.body ?? "{}")),
      });
      if (path === "/auth/v1/user") return Response.json({ id: actor });
      if (path.endsWith("get_my_access")) {
        return Response.json([{ role, status }]);
      }
      if (failure) return Response.json(failure, { status: 400 });
      return Response.json({ ok: true });
    },
  });
  return { handler, calls };
}
function request(path: string, body?: unknown, token = "valid-user-token") {
  return new Request(
    `https://example.supabase.co/functions/v1/learning-api/${path}`,
    {
      method: body === undefined ? "GET" : "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    },
  );
}

Deno.test("requires Auth validation and active role before any business request", async () => {
  const { handler, calls } = setup();
  const result = await handler(
    new Request("https://example/learning-api/sync"),
  );
  assert(result.status === 401 && calls.length === 0);
  const suspended = setup("user", "suspended");
  assert((await suspended.handler(request("sync"))).status === 403);
  assert(suspended.calls.length === 2);
});
Deno.test("attempt ignores client correctness/owner and uses server evaluation and verified Auth owner", async () => {
  const { handler, calls } = setup();
  const response = await handler(request("attempts", {
    operation_id: operation,
    payload: {
      session_id: operation,
      activity_id: "logic-balance",
      content_version: 1,
      state: { blocks: 0 },
      is_correct: true,
      owner_id: operation,
    },
    evaluation: { is_correct: true },
    owner_id: operation,
  }));
  assert(response.status === 200);
  const last = calls.at(-1)!;
  assert(last.path.endsWith("/record_learning_attempt"));
  assert(last.authorization === "Bearer server-test-key");
  assert(last.body.owner_id === actor);
  assert(
    (last.body.evaluation as Record<string, unknown>).is_correct === false,
  );
});
Deno.test("normal mutations retain user JWT; admin cannot submit learner state", async () => {
  const user = setup();
  await user.handler(
    request("mutate", {
      operation_id: operation,
      operation_type: "profile.create",
      payload: { id: operation },
    }),
  );
  assert(user.calls.at(-1)!.authorization === "Bearer valid-user-token");
  const admin = setup("admin");
  assert(
    (await admin.handler(
      request("attempts", { operation_id: operation, payload: { state: {} } }),
    )).status === 403,
  );
});
Deno.test("reject oversized streamed bodies and deeply nested/large states", async () => {
  const { handler, calls } = setup();
  assert(
    (await handler(
      request("mutate", {
        operation_id: operation,
        payload: { x: "x".repeat(300001) },
      }),
    )).status === 413,
  );
  const body = {
    operation_id: operation,
    payload: { state: { list: Array(129).fill(1) } },
  };
  assert((await handler(request("attempts", body))).status === 400);
  assert(calls.every((c) => !c.path.endsWith("record_learning_attempt")));
});
Deno.test("returns accurate safe business errors without exposing SQL diagnostics", async () => {
  const { handler } = setup("user", "active", {
    code: "22023",
    message: "Required activities are not complete",
  });
  const result = await handler(
    request("mutate", {
      operation_id: operation,
      operation_type: "session.complete",
      payload: {},
    }),
  );
  assert(result.status === 400);
  assert((await result.json()).error.code === "activities_incomplete");
  const unknown = setup("user", "active", {
    code: "XX000",
    message: "secret diagnostic",
  });
  const text = await (await unknown.handler(request("sync"))).text();
  assert(
    !text.includes("secret diagnostic") && !text.includes("server-test-key"),
  );
});
Deno.test("sync retains bigint cursor strings and stable high-water mark", async () => {
  const { handler, calls } = setup();
  await handler(
    request(
      "sync?revision=9007199254740993&index=1&high_water=9007199254740995&limit=2",
    ),
  );
  assert(calls.at(-1)!.body.after_revision === "9007199254740993");
  assert(calls.at(-1)!.body.until_revision === "9007199254740995");
});
Deno.test("OPTIONS works without credentials", async () => {
  const { handler, calls } = setup();
  assert(
    (await handler(
      new Request("https://example/learning-api", { method: "OPTIONS" }),
    )).status === 204,
  );
  assert(calls.length === 0);
});

Deno.test("application revision conflicts use PT409 without a transient SQL retry code", async () => {
  const { handler } = setup("user", "active", {
    code: "PT409",
    message: "Learning revision conflict",
  });
  const response = await handler(
    request("mutate", {
      operation_id: operation,
      operation_type: "profile.update",
      payload: {},
    }),
  );
  assert(response.status === 409);
  assert((await response.json()).error.code === "revision_conflict");
});

Deno.test("invalid Auth JWT reported as login failure even when Auth returns 403", async () => {
  const handler = createHandler({
    url: "https://example.supabase.co",
    publishableKey: "public",
    serviceKey: "secret",
    implementationHash: "",
    evaluate: () => "",
    // deno-lint-ignore require-await -- Match fetch's Promise contract.
    fetch: async () =>
      Response.json({ code: "bad_jwt", message: "invalid JWT" }, {
        status: 403,
      }),
  });
  const response = await handler(request("sync"));
  assert(response.status === 401);
  assert((await response.json()).error.code === "authentication_required");
});

Deno.test("asset signing first requires RLS-visible metadata", async () => {
  const calls: string[] = [];
  const handler = createHandler({
    url: "https://example.supabase.co",
    publishableKey: "public",
    serviceKey: "secret",
    implementationHash: "",
    evaluate: () => "",
    // deno-lint-ignore require-await -- Preserve the real fetch Promise contract.
    fetch: async (input) => {
      const path = new URL(String(input)).pathname;
      calls.push(path);
      if (path === "/auth/v1/user") return Response.json({ id: actor });
      if (path.endsWith("get_my_access")) {
        return Response.json([{ role: "user", status: "active" }]);
      }
      return Response.json([]);
    },
  });
  assert((await handler(request(`assets/${operation}`))).status === 404);
  assert(calls.every((x) => !x.includes("/object/sign/")));
});
Deno.test("rejects MIME spoofing before storage upload", async () => {
  const { handler, calls } = setup();
  const response = await handler(
    request("assets", {
      mime_type: "image/png",
      base64: btoa("<script>alert(1)</script>"),
    }),
  );
  assert(response.status === 400);
  assert(calls.every((x) => !x.path.startsWith("/storage/")));
});
Deno.test("uploads image bytes under verified owner path, hashes content and registers server metadata", async () => {
  const image = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 0]);
  let uploaded = false;
  let registered = false;
  const handler = createHandler({
    url: "https://example.supabase.co",
    publishableKey: "public",
    serviceKey: "secret",
    implementationHash: "",
    evaluate: () => "",
    // deno-lint-ignore require-await -- Preserve the real fetch Promise contract.
    fetch: async (input, init) => {
      const path = new URL(String(input)).pathname;
      if (path === "/auth/v1/user") return Response.json({ id: actor });
      if (path.endsWith("get_my_access")) {
        return Response.json([{ role: "user", status: "active" }]);
      }
      if (path === "/rest/v1/assets") return Response.json([]);
      if (path.startsWith(`/storage/v1/object/user-avatars/${actor}/`)) {
        assert(
          new Headers(init?.headers).get("authorization") === "Bearer secret",
        );
        assert(
          init?.body instanceof Uint8Array && init.body.length === image.length,
        );
        uploaded = true;
        return Response.json({ Key: path });
      }
      if (path.endsWith("register_learning_asset")) {
        const body = JSON.parse(String(init?.body));
        assert(
          body.actor === actor && body.asset_data.byte_size === image.length,
        );
        assert(
          body.asset_data.sha256.length === 64 &&
            body.asset_data.bucket_id === "user-avatars",
        );
        registered = true;
        return Response.json({ id: operation, status: "ready" });
      }
      throw new Error("Unexpected endpoint");
    },
  });
  const response = await handler(
    request("assets", {
      mime_type: "image/png",
      base64: btoa(String.fromCharCode(...image)),
    }),
  );
  assert(response.status === 200 && uploaded && registered);
});
