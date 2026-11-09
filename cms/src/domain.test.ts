import { describe, expect, it, vi } from "vitest";
import {
  clone,
  correct,
  moveSlide,
  newSlide,
  normalizeLesson,
  templateLesson,
  validateLesson,
} from "./domain";
import { DraftWriter, fingerprint, type PendingWrite } from "./draft-writer";
import { CmsError, DemoRepository } from "./repository";

describe("component contract and phone scoring", () => {
  it("all templates can be published with the existing mobile engine", () => {
    for (const template of ["graph", "fractions", "blank"])
      expect(validateLesson(templateLesson("math", template))).toEqual([]);
  });
  it("reorders without mutating IDs, answers or the original document", () => {
    const original = templateLesson("math", "graph").config.slides!;
    const reordered = moveSlide(original, 3, 0);
    expect(reordered.map((s) => s.id)).toEqual([
      original[3].id,
      ...original.slice(0, 3).map((s) => s.id),
    ]);
    expect(original[0].engine).toBe("story");
    expect(reordered[0]).toEqual(original[3]);
    expect(moveSlide(original, 99, 0)).toBe(original);
  });
  it("requires real answers; wrong, duplicate and incomplete answers do not pass", () => {
    const graph = newSlide("graph"),
      quiz = newSlide("quiz"),
      pairs = newSlide("pairs");
    expect(correct(graph, { a: 0, b: 0, is_correct: true })).toBe(false);
    expect(correct(graph, { a: "2", b: 1 })).toBe(false);
    expect(correct(graph, { a: 2, b: 1 })).toBe(true);
    expect(correct(quiz, { answer: -1 })).toBe(false);
    expect(correct(quiz, { answer: 0 })).toBe(true);
    expect(correct(pairs, { values: [0, 0] })).toBe(false);
    expect(correct(pairs, { values: [0] })).toBe(false);
    expect(correct(pairs, { values: [0, 1] })).toBe(true);
  });
  it("rejects executable image URLs, duplicate IDs, malformed bounds and empty interactive content", () => {
    const base = templateLesson("math", "graph");
    const unsafe = clone(base);
    unsafe.config.slides![0].config.image_url = "javascript:alert(1)";
    const duplicate = clone(base);
    duplicate.config.slides![1].id = duplicate.config.slides![0].id;
    const bounds = clone(base);
    bounds.config.slides![1].config.max_a = -9;
    const missing = clone(base);
    missing.config.slides = [newSlide("story")];
    for (const doc of [unsafe, duplicate, bounds, missing])
      expect(validateLesson(doc).length).toBeGreaterThan(0);
    expect(validateLesson(missing, false)).toEqual([]);
  });
  it("restores published metadata revisions independently from draft revisions", () => {
    const normalized = normalizeLesson(
      {
        activity_id: "published",
        revision: 4,
        draft_revision: 9,
        hint_levels: ["Hint"],
        editor_status: "archived",
      },
      "math",
    );
    expect(normalized.content_revision).toBe(4);
    expect(normalized.draft_revision).toBe(9);
    expect(normalized.hint).toBe("Hint");
    expect(normalized.status).toBe("archived");
  });
});

describe("draft recovery and idempotent publication", () => {
  it("serializes edits made while a save is in progress", async () => {
    const repo = new DemoRepository(),
      doc = templateLesson("math", "graph");
    let release!: () => void;
    const wait = new Promise<void>((r) => {
      release = r;
    });
    const original = repo.saveDraft.bind(repo);
    const spy = vi
      .spyOn(repo, "saveDraft")
      .mockImplementationOnce(async (...args) => {
        await wait;
        return original(...args);
      });
    const writer = new DraftWriter(repo, 0);
    const first = writer.save(doc);
    const changed = clone(doc);
    changed.title = "Đã sửa trong khi lưu";
    const second = writer.save(changed);
    release();
    await Promise.all([first, second]);
    expect(spy).toHaveBeenCalledTimes(2);
    expect(writer.revision).toBe(2);
    expect(writer.saved).toBe(fingerprint(changed));
  });
  it("retries a lost acknowledgement with the same operation and snapshot before newer edits", async () => {
    const repo = new DemoRepository(),
      doc = templateLesson("math", "graph");
    const original = repo.saveDraft.bind(repo),
      calls: { id: string; title: string; revision: number }[] = [];
    let pending: PendingWrite | undefined;
    vi.spyOn(repo, "saveDraft").mockImplementation(async (d, rev, op) => {
      calls.push({ id: op, title: d.title, revision: rev });
      const result = await original(d, rev, op);
      if (calls.length === 1) throw new Error("Lost acknowledgement");
      return result;
    });
    const writer = new DraftWriter(repo, 0, (p) => {
      pending = p;
    });
    await expect(writer.save(doc)).rejects.toThrow("Lost acknowledgement");
    expect(pending?.operation).toBe(calls[0].id);
    const recovered = new DraftWriter(repo, 0, () => {}, pending);
    const edited = clone(doc);
    edited.title = "Newer edit";
    await recovered.save(edited);
    expect(calls[1]).toEqual(calls[0]);
    expect(calls[2].revision).toBe(1);
    expect(recovered.revision).toBe(2);
  });
  it("does not overwrite another editor and publication retries do not create extra versions", async () => {
    const repo = new DemoRepository(),
      doc = templateLesson("math", "graph");
    const rev = await repo.saveDraft(doc, 0, crypto.randomUUID());
    await expect(
      repo.saveDraft(doc, 0, crypto.randomUUID()),
    ).rejects.toBeInstanceOf(CmsError);
    const id = crypto.randomUUID();
    expect(await repo.publish(doc, 0, rev, id)).toBe(1);
    expect(await repo.publish(doc, 0, rev, id)).toBe(1);
    expect((await repo.lessons("math"))[0].content_revision).toBe(1);
  });
});
