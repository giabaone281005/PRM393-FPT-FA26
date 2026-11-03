import { legacyEvaluate } from "./legacy_evaluator.ts";
import "./evaluator_v2.js";
import { createHandler } from "./handler.ts";
import { implementationHash } from "./version.ts";
import { implementationHash as expandedHash } from "./version_v2.ts";

declare global {
  var matlingoEvaluate: (input: string) => string;
}

Deno.serve(createHandler({
  url: Deno.env.get("SUPABASE_URL") ?? "",
  publishableKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  serviceKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  implementationHash,
  implementationHashes: { 1: implementationHash, 2: expandedHash },
  evaluate: (input) => {
    const legacy = legacyEvaluate(input);
    if (!JSON.parse(legacy).error) return legacy;
    return globalThis.matlingoEvaluate(input);
  },
}));
