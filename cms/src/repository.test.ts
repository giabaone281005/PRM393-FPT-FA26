import { describe, expect, it, vi } from "vitest";
import type { SupabaseClient } from "@supabase/supabase-js";
import { SupabaseRepository } from "./repository";
import { payload, templateLesson } from "./domain";

function fixture(
  handler: (name: string, args: Record<string, unknown>) => unknown,
  owners = ["admin"],
) {
  let index = 0;
  const rpc = vi.fn((name: string, args: Record<string, unknown>) => ({
    abortSignal: async () => handler(name, args),
  }));
  const db = {
    auth: {
      getSession: async () => ({
        data: {
          session: {
            user: { id: owners[Math.min(index++, owners.length - 1)] },
          },
        },
      }),
    },
    rpc,
  } as unknown as SupabaseClient;
  return { repository: new SupabaseRepository(db, "admin"), rpc };
}

describe("CMS backend adapter authority", () => {
  it("denies ordinary users, suspended admins and missing access rows", async () => {
    for (const access of [
      [],
      [{ role: "user", status: "active" }],
      [{ role: "admin", status: "suspended" }],
    ]) {
      const { repository } = fixture(() => ({ data: access, error: null }));
      await expect(repository.access()).rejects.toMatchObject({ denied: true });
    }
  });
  it("discards acknowledgements if the account changes while a mutation is in flight", async () => {
    const { repository } = fixture(
      () => ({ data: { revision: 1 }, error: null }),
      ["admin", "other"],
    );
    await expect(
      repository.saveDraft(templateLesson("math", "blank"), 0, "operation"),
    ).rejects.toMatchObject({ denied: true });
  });
  it("maps server conflicts and revoked permissions without silently succeeding", async () => {
    for (const code of ["PT409", "42501"]) {
      const { repository } = fixture(() => ({ data: null, error: { code } }));
      await expect(
        repository.saveDraft(templateLesson("math", "blank"), 0, "operation"),
      ).rejects.toMatchObject(
        code === "PT409" ? { conflict: true } : { denied: true },
      );
    }
  });
  it("sends the existing RPC contract and separate revision counters for publication", async () => {
    const { repository, rpc } = fixture(() => ({
      data: { revision: 9 },
      error: null,
    }));
    const doc = templateLesson("math", "graph");
    expect(await repository.saveDraft(doc, 8, "stable-draft-id")).toBe(9);
    expect(rpc).toHaveBeenLastCalledWith("admin_builder_save", {
      operation_id: "stable-draft-id",
      payload: { ...payload(doc), revision: 8 },
    });
    await repository.publish(doc, 3, 9, "stable-publish-id");
    expect(rpc).toHaveBeenLastCalledWith("admin_content_mutate", {
      operation_id: "stable-publish-id",
      payload: { ...payload(doc), revision: 3, builder_revision: 9 },
    });
  });
  it("loads every topic page instead of truncating the CMS library at 100 rows", async () => {
    const { repository, rpc } = fixture((_name, args) => ({
      data: {
        total: 101,
        items: Array.from(
          { length: args.page_offset === 0 ? 100 : 1 },
          (_, i) => ({ id: `topic-${Number(args.page_offset) + i}` }),
        ),
      },
      error: null,
    }));
    expect(await repository.topics()).toHaveLength(101);
    expect(rpc).toHaveBeenCalledTimes(2);
  });
  it("keeps a newer draft above published content and preserves archive status", async () => {
    const { repository } = fixture((name) => ({
      error: null,
      data: {
        items:
          name === "admin_content_read"
            ? [
                {
                  activity_id: "lesson",
                  content_version: 2,
                  title: "Published",
                  revision: 4,
                  editor_status: "archived",
                },
              ]
            : [
                {
                  id: "lesson",
                  title: "Draft",
                  builder_status: "draft",
                  draft_revision: 8,
                  content_revision: 4,
                  status: "archived",
                },
              ],
      },
    }));
    const rows = await repository.lessons("math");
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      title: "Draft",
      draft_revision: 8,
      content_revision: 4,
      content_version: 2,
      status: "archived",
    });
  });
});
