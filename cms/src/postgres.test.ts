import { afterAll, beforeAll, expect, it } from "vitest";
import { PGlite } from "@electric-sql/pglite";
import { readFileSync } from "node:fs";
import { payload, templateLesson, newSlide } from "./domain";

// Real embedded PostgreSQL, in memory. Never connects to a hosted project.
const db = new PGlite();
const curriculum = JSON.parse(
  readFileSync(
    new URL("../content/three-topic-curriculum.json", import.meta.url),
    "utf8",
  ),
) as {
  lessons: import("./domain").Lesson[];
  solutions: Record<string, Record<string, Record<string, unknown>>>;
};
const read = (name: string) =>
  readFileSync(new URL(`../../supabase/${name}`, import.meta.url), "utf8");
const fn = (source: string, name: string) =>
  source.match(
    new RegExp(
      `CREATE (?:OR REPLACE )?FUNCTION ${name.replaceAll(".", "\\.")}\\([\\s\\S]*?\\$\\$;`,
    ),
  )![0];
const admin = "11111111-1111-4111-8111-111111111111",
  user = "22222222-2222-4222-8222-222222222222";
const migration = read("migrations/20261114000000_studio_tinkercad_v2.sql");
const editMigration =
  read("migrations/20261115000000_admin_existing_lesson_editing.sql") +
  read("migrations/20261116000000_admin_metadata_compatibility.sql");
beforeAll(async () => {
  await db.exec(`CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role;
    CREATE SCHEMA private; CREATE SCHEMA auth; CREATE SCHEMA storage; CREATE SCHEMA extensions;
    GRANT USAGE ON SCHEMA public,private,auth,storage TO authenticated;
    CREATE TABLE auth.users(id uuid PRIMARY KEY,raw_user_meta_data jsonb DEFAULT '{}');
    CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    CREATE FUNCTION extensions.digest(text,text) RETURNS bytea LANGUAGE sql IMMUTABLE AS $$ SELECT sha256(convert_to($1,'UTF8')) $$;
    CREATE FUNCTION extensions.digest(bytea,text) RETURNS bytea LANGUAGE sql IMMUTABLE AS $$ SELECT sha256($1) $$;
    CREATE TABLE storage.buckets(id text PRIMARY KEY,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    CREATE TABLE storage.objects(id uuid DEFAULT gen_random_uuid(),bucket_id text,name text);
    ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
    GRANT SELECT,INSERT ON storage.objects TO authenticated;
    CREATE FUNCTION storage.foldername(text) RETURNS text[] LANGUAGE sql IMMUTABLE AS $$ SELECT (string_to_array($1,'/'))[1:array_length(string_to_array($1,'/'),1)-1] $$;`);
  const schema = read("schema_reset.sql");
  // Only extract table/function definitions. No DROP SCHEMA or reset/seed statements execute.
  await db.exec(
    schema.slice(
      schema.indexOf("CREATE TABLE private.account_access"),
      schema.indexOf("INSERT INTO public.accounts(id,display_name)"),
    ),
  );
  await db.exec(
    schema.slice(schema.indexOf("CREATE FUNCTION private.handle_auth_signup")),
  );
  await db.exec(
    fn(
      read("migrations/20261030000000_learning_server_api.sql"),
      "private.learning_actor",
    ),
  );
  const author = read("migrations/20261110000000_admin_lesson_authoring.sql");
  await db.exec(fn(author, "private.learning_catalog"));
  await db.exec(
    author.slice(
      0,
      author.indexOf("CREATE OR REPLACE FUNCTION private.supported_activity"),
    ),
  );
  const slides = read("migrations/20261112000000_slide_cms_engines.sql");
  await db.exec(
    slides.slice(
      0,
      slides.indexOf("CREATE OR REPLACE FUNCTION private.supported_activity"),
    ),
  );
  await db.exec(
    read("migrations/20261113000000_builder_payload_authority.sql"),
  );
  await db.exec(migration);
  await db.exec(editMigration);
  await db.exec(
    read("migrations/20261117000000_studio_mobile_engine_expansion.sql"),
  );
  await db.exec(read("migrations/20261118000000_studio_language_engines.sql"));
  await db.exec(`INSERT INTO auth.users(id) VALUES('${admin}'),('${user}'); UPDATE private.account_access SET role='admin' WHERE user_id='${admin}';
    INSERT INTO public.topics(id,title,subject,status,icon_key,sort_order) VALUES('studio-topic','Studio','Math','active','functions',0);
    SELECT set_config('request.jwt.claim.sub','${admin}',false);`);
}, 30000);
afterAll(async () => {
  await db.close();
});
it("replays the entire additive migration without destroying existing data", async () => {
  await db.exec(migration);
  await db.exec(editMigration);
  await db.exec(
    read("migrations/20261117000000_studio_mobile_engine_expansion.sql"),
  );
  await db.exec(read("migrations/20261118000000_studio_language_engines.sql"));
  await db.exec(editMigration);
  await db.exec(
    read("migrations/20261117000000_studio_mobile_engine_expansion.sql"),
  );
  await db.exec(read("migrations/20261118000000_studio_language_engines.sql"));
  expect(
    (
      await db.query<{ n: number }>(
        "SELECT count(*)::int n FROM public.accounts",
      )
    ).rows[0].n,
  ).toBe(2);
  expect(
    (
      await db.query<{ n: number }>(
        "SELECT count(*)::int n FROM pg_policies WHERE schemaname='storage' AND policyname LIKE 'studio_asset_%'",
      )
    ).rows[0].n,
  ).toBe(2);
});
it("upgrades an existing compiled choice to a new authored version while preserving the original answers", async () => {
  const doc = templateLesson("studio-topic", "blank");
  doc.mechanism = "reasonedChoice";
  doc.config = {
    knowledge: "Chia đều",
    source: "QA",
    choices: ["4", "8"],
    reasons: ["Chia hai", "Cộng hai"],
    answer: 0,
    reason: 0,
  };
  await db.exec(
    "INSERT INTO private.evaluator_versions(mechanism,version,handler_key,implementation_hash,input_schema,status) VALUES('reasonedChoice',2,'test:legacy',repeat('a',64),'{}','active') ON CONFLICT DO NOTHING",
  );
  await db.query(
    "INSERT INTO public.activities(id,topic_id) VALUES($1,'studio-topic')",
    [doc.id],
  );
  await db.query(
    "INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,mechanism,mechanism_version,evaluator_version,config,initial_state,status,published_at) VALUES($1,1,$2,$3,$4,'[\"Gợi ý\"]',$5,'reasonedChoice',1,2,$6::jsonb,'{\"answer\":-1,\"reason\":-1}','published',now())",
    [
      doc.id,
      doc.title,
      doc.stage,
      doc.prompt,
      doc.explanation,
      JSON.stringify(doc.config),
    ],
  );
  const original = structuredClone(doc.config);
  doc.config.answer = 1;
  doc.config.reason = 1;
  doc.title = "Bài hiện có đã sửa";
  await db.query("SELECT private.admin_content_mutate($1::uuid,$2::jsonb)", [
    crypto.randomUUID(),
    JSON.stringify({ ...payload(doc), revision: 0 }),
  ]);
  const versions = await db.query<{
    content_version: number;
    evaluator_version: number;
    config: unknown;
  }>(
    "SELECT content_version,evaluator_version,config FROM public.activity_versions WHERE activity_id=$1 ORDER BY content_version",
    [doc.id],
  );
  expect(versions.rows).toHaveLength(2);
  expect(versions.rows[0].config).toEqual(original);
  expect(versions.rows[1].evaluator_version).toBe(3);
  expect(versions.rows[1].config).toEqual(doc.config);
});
it("requires a fresh explicit conversion token before replacing a packaged engine with Studio", async () => {
  const doc = templateLesson("studio-topic", "blank");
  doc.mechanism = "solidExplorer";
  doc.config = { target_volume: 12 };
  await db.exec(
    "INSERT INTO private.evaluator_versions(mechanism,version,handler_key,implementation_hash,input_schema,status) VALUES('solidExplorer',1,'test:legacy',repeat('b',64),'{}','active') ON CONFLICT DO NOTHING",
  );
  await db.query(
    "INSERT INTO public.activities(id,topic_id) VALUES($1,'studio-topic')",
    [doc.id],
  );
  await db.query(
    "INSERT INTO public.activity_versions(activity_id,content_version,title,stage,prompt,hint_levels,explanation,mechanism,mechanism_version,evaluator_version,config,initial_state,status,published_at) VALUES($1,1,$2,$3,$4,'[\"Hint\"]',$5,'solidExplorer',1,1,$6::jsonb,'{}','published',now())",
    [
      doc.id,
      doc.title,
      doc.stage,
      doc.prompt,
      doc.explanation,
      JSON.stringify(doc.config),
    ],
  );
  doc.mechanism = "slideLesson";
  doc.config = { schema_version: 1, slides: [newSlide("barChart")] };
  const body = { ...payload(doc), revision: 0 };
  for (const token of [undefined, 0, 2])
    await expect(
      db.query("SELECT private.admin_content_mutate($1::uuid,$2::jsonb)", [
        crypto.randomUUID(),
        JSON.stringify({ ...body, convert_from_version: token }),
      ]),
    ).rejects.toThrow(/immutable/i);
  await db.query("SELECT private.admin_content_mutate($1::uuid,$2::jsonb)", [
    crypto.randomUUID(),
    JSON.stringify({ ...body, convert_from_version: 1 }),
  ]);
  const rows = await db.query<{ mechanism: string; content_version: number }>(
    "SELECT mechanism,content_version FROM public.activity_versions WHERE activity_id=$1 ORDER BY content_version",
    [doc.id],
  );
  expect(rows.rows).toEqual([
    { mechanism: "solidExplorer", content_version: 1 },
    { mechanism: "slideLesson", content_version: 2 },
  ]);
});
it("matches CMS/mobile initial state, accepted and rejected answers across every extended engine", async () => {
  const fixtures = JSON.parse(read("tests/fixtures/studio_engines.json"));
  for (const f of fixtures) {
    const cfg = {
      schema_version: 1,
      slides: [{ ...newSlide(f.engine), config: f.config }],
    };
    const result = await db.query<{ valid: boolean; initial: unknown }>(
      "SELECT private.valid_slide_lesson($1::jsonb) valid, private.initial_slide_state($1::jsonb) initial",
      [JSON.stringify(cfg)],
    );
    expect(result.rows[0].valid, f.engine).toBe(true);
    expect(result.rows[0].initial).toEqual({ index: 0, slides: [f.initial] });
    for (const state of [f.correct, ...f.wrong]) {
      const row = await db.query<{ correct: boolean }>(
        "SELECT private.evaluate_slide_lesson($1::jsonb,$2::jsonb) correct",
        [JSON.stringify(cfg), JSON.stringify({ slides: [state] })],
      );
      expect(
        row.rows[0].correct ?? false,
        `${f.engine}: ${JSON.stringify(state)}`,
      ).toBe(state === f.correct);
    }
  }
});
it("rejects unknown/malformed configurations and unreachable targets", async () => {
  for (const [engine, config] of [
    ["execute-code", {}],
    ["solid3D", { target_volume: 7 }],
    ["polygonVertices", { target_area: 7 }],
    ["resourceBudget", { items: ["a", "b"], minima: [9, 9] }],
    ["causalLab", { axes: ["x", "y"], target_product: 5 }],
    ["loopBuilder", { target_repeat: 2, target_body: ["eval", "R"] }],
    ["sequenceTiles", { items: ["a", "b"], answer_values: [0, 0] }],
    ["globe3D", { target_latitude: 1, target_longitude: 30 }],
  ]) {
    const cfg = {
      schema_version: 1,
      slides: [{ ...newSlide("quiz"), engine, config }],
    };
    expect(
      (
        await db.query<{ valid: boolean }>(
          "SELECT private.valid_slide_lesson($1::jsonb) valid",
          [JSON.stringify(cfg)],
        )
      ).rows[0].valid,
    ).toBe(false);
  }
});
it("saves and publishes real revisions, preserves immutable content and gates older mobile releases", async () => {
  const doc = templateLesson("studio-topic", "blank");
  doc.config.slides = [newSlide("solid3D")];
  const body = { ...payload(doc), revision: 0 };
  const save = await db
    .query<{
      r: { revision: number };
    }>("SELECT public.admin_builder_save($1::uuid,$2::jsonb) r", [
      crypto.randomUUID(),
      JSON.stringify(body),
    ])
    .catch((e) => {
      throw new Error(`${e.message}\n${e.where}\n${e.internalQuery}`);
    });
  expect(save.rows[0].r.revision).toBe(1);
  const operation = crypto.randomUUID();
  const publish = { ...body, builder_revision: 1 };
  const first = await db.query<{ r: unknown }>(
    "SELECT private.admin_content_mutate($1::uuid,$2::jsonb) r",
    [operation, JSON.stringify(publish)],
  );
  const retried = await db.query<{ r: unknown }>(
    "SELECT private.admin_content_mutate($1::uuid,$2::jsonb) r",
    [operation, JSON.stringify(publish)],
  );
  expect(retried.rows).toEqual(first.rows);
  expect(
    (
      await db.query<{ v: string }>(
        "SELECT min_app_version v FROM public.content_releases ORDER BY published_at DESC LIMIT 1",
      )
    ).rows[0].v,
  ).toBe("1.3.7");
  await db.exec(`SELECT set_config('request.jwt.claim.sub','${user}',false)`);
  const older = await db.query<{ r: { activities: unknown[] } }>(
    "SELECT private.learning_catalog('1.3.4') r",
  );
  const current = await db.query<{ r: { activities: unknown[] } }>(
    "SELECT private.learning_catalog('1.3.7') r",
  );
  expect(
    older.rows[0].r.activities.some(
      (a) => (a as { activity_id: string }).activity_id === doc.id,
    ),
  ).toBe(false);
  expect(
    current.rows[0].r.activities.some(
      (a) => (a as { activity_id: string }).activity_id === doc.id,
    ),
  ).toBe(true);
  await db.exec(`SELECT set_config('request.jwt.claim.sub','${admin}',false)`);
  await expect(
    db.exec(
      "UPDATE public.activity_versions SET title='overwrite' WHERE status='published'",
    ),
  ).rejects.toThrow();
  await expect(
    db.query("SELECT public.admin_builder_save($1::uuid,$2::jsonb)", [
      crypto.randomUUID(),
      JSON.stringify(body),
    ]),
  ).rejects.toThrow(/revision conflict/i);
});
it("enforces Admin-only progress and Storage RLS, including owner paths and revoked roles", async () => {
  await db.exec(
    `SELECT set_config('request.jwt.claim.sub','${admin}',false); SET ROLE authenticated;`,
  );
  expect(
    (
      await db.query<{ r: Record<string, number> }>(
        "SELECT public.admin_studio_progress($1::uuid) r",
        [user],
      )
    ).rows[0].r.verified_xp,
  ).toBe(0);
  await db.exec(
    `INSERT INTO storage.objects(bucket_id,name) VALUES('lesson-assets','${admin}/ok.png')`,
  );
  await expect(
    db.exec(
      `INSERT INTO storage.objects(bucket_id,name) VALUES('lesson-assets','${user}/bad.png')`,
    ),
  ).rejects.toThrow(/row-level security/i);
  await db.exec(
    `RESET ROLE; SELECT set_config('request.jwt.claim.sub','${user}',false); SET ROLE authenticated;`,
  );
  await expect(
    db.query("SELECT public.admin_studio_progress($1::uuid)", [admin]),
  ).rejects.toThrow(/access denied/i);
  await expect(
    db.exec(
      `INSERT INTO storage.objects(bucket_id,name) VALUES('lesson-assets','${user}/bad.png')`,
    ),
  ).rejects.toThrow(/row-level security/i);
  expect((await db.query("SELECT * FROM storage.objects")).rows).toHaveLength(
    0,
  );
  await db.exec(
    `RESET ROLE; UPDATE private.account_access SET status='suspended' WHERE user_id='${admin}'; SELECT set_config('request.jwt.claim.sub','${admin}',false); SET ROLE authenticated;`,
  );
  await expect(
    db.query("SELECT public.admin_studio_progress($1::uuid)", [user]),
  ).rejects.toThrow(/access denied/i);
  await db.exec(
    `RESET ROLE; UPDATE private.account_access SET status='active' WHERE user_id='${admin}';`,
  );
});

it("validates and scores every authored curriculum part on PostgreSQL", async () => {
  for (const lesson of curriculum.lessons) {
    const config = lesson.config;
    const state = {
      index: 5,
      slides: config.slides!.map((s) => curriculum.solutions[lesson.id][s.id]),
    };
    const result = await db.query<{
      valid: boolean;
      correct: boolean;
      wrong: boolean;
    }>(
      "SELECT private.valid_slide_lesson($1::jsonb) valid,private.evaluate_slide_lesson($1::jsonb,$2::jsonb) correct,private.evaluate_slide_lesson($1::jsonb,'{}') wrong",
      [JSON.stringify(config), JSON.stringify(state)],
    );
    expect(result.rows[0], lesson.id).toEqual({
      valid: true,
      correct: true,
      wrong: false,
    });
  }
});

it("round-trips lesson icons through real Admin draft, publish and learner catalogue APIs", async () => {
  await db.exec(`SELECT set_config('request.jwt.claim.sub','${admin}',false)`);
  const doc = templateLesson("studio-topic", "blank");
  doc.config.lesson_icon = "robot";
  const body = { ...payload(doc), revision: 0 };
  const save = await db.query<{ r: { revision: number } }>(
    "SELECT public.admin_builder_save($1::uuid,$2::jsonb) r",
    [crypto.randomUUID(), JSON.stringify(body)],
  );
  await db.query("SELECT private.admin_content_mutate($1::uuid,$2::jsonb)", [
    crypto.randomUUID(),
    JSON.stringify({ ...body, builder_revision: save.rows[0].r.revision }),
  ]);
  await db.exec(`SELECT set_config('request.jwt.claim.sub','${user}',false)`);
  const rows = await db.query<{
    r: {
      activities: { activity_id: string; config: { lesson_icon: string } }[];
    };
  }>("SELECT private.learning_catalog('1.3.8') r");
  expect(
    rows.rows[0].r.activities.find((a) => a.activity_id === doc.id)?.config
      .lesson_icon,
  ).toBe("robot");
  await db.exec(`SELECT set_config('request.jwt.claim.sub','${admin}',false)`);
});
