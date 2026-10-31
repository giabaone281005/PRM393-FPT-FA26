import { createTutorHandler } from "./handler.ts";

Deno.serve(createTutorHandler({
  url: Deno.env.get("SUPABASE_URL") ?? "",
  publishableKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  geminiKey: Deno.env.get("GEMINI_API_KEY") ?? "",
  model: Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash-lite",
}));
