import "./evaluator.js";
import { createHandler } from "./handler.ts";
import { implementationHash } from "./version.ts";

declare global {
  var matlingoEvaluate: (input: string) => string;
}

Deno.serve(createHandler({
  url: Deno.env.get("SUPABASE_URL") ?? "",
  publishableKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  serviceKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  implementationHash,
  evaluate: globalThis.matlingoEvaluate,
}));
