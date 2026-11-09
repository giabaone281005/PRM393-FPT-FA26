import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";
import { existsSync, readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";

// Only the two public Flutter connection fields enter the browser bundle.
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "VITE_");
  const path = fileURLToPath(
    new URL("../config/app.mobile.json", import.meta.url),
  );
  const config = existsSync(path)
    ? JSON.parse(readFileSync(path, "utf8").replace(/^\uFEFF/, ""))
    : {};
  const url = env.VITE_SUPABASE_URL || config.SUPABASE_URL || "";
  const key =
    env.VITE_SUPABASE_PUBLISHABLE_KEY || config.SUPABASE_PUBLISHABLE_KEY || "";
  if (key.startsWith("sb_secret_"))
    throw new Error("CMS requires a publishable key.");
  if (key.startsWith("eyJ")) {
    const claims = JSON.parse(
      Buffer.from(key.split(".")[1], "base64url").toString(),
    );
    if (claims.role !== "anon")
      throw new Error("Privileged API keys cannot be bundled.");
  }
  return {
    base: "/cms/",
    plugins: [react()],
    define: {
      "import.meta.env.VITE_SUPABASE_URL": JSON.stringify(url),
      "import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY": JSON.stringify(key),
    },
    build: {
      sourcemap: false,
      rolldownOptions: {
        output: {
          codeSplitting: {
            groups: [
              { name: "math-renderer", test: /node_modules[\\/]katex/ },
              { name: "cloud-client", test: /node_modules[\\/]@supabase/ },
            ],
          },
        },
      },
    },
    server: { strictPort: true },
  };
});
