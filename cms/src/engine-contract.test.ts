import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import {
  correctExtended,
  extendedEngines,
  initialExtended,
  validExtended,
  type ExtendedConfig,
  type ExtendedEngine,
} from "./engine-contract";
import { newSlide, templateLesson, validateLesson } from "./domain";
import {
  qualityReport,
  subjects,
  suggestEngines,
  topicRecipe,
} from "./planner";
export type EngineFixture = {
  engine: ExtendedEngine;
  config: ExtendedConfig;
  initial: Record<string, unknown>;
  correct: Record<string, unknown>;
  wrong: Record<string, unknown>[];
};
export const fixtures: EngineFixture[] = JSON.parse(
  readFileSync(
    new URL(
      "../../supabase/tests/fixtures/studio_engines.json",
      import.meta.url,
    ),
    "utf8",
  ),
);
describe("Studio engine contract", () => {
  for (const f of fixtures)
    it(`${f.engine} validates, restores initial state and rejects forged/incomplete answers`, () => {
      expect(validExtended(f.engine, f.config)).toBe(true);
      expect(initialExtended(f.engine, f.config)).toEqual(f.initial);
      expect(correctExtended(f.engine, f.config, f.correct)).toBe(true);
      for (const s of f.wrong)
        expect(correctExtended(f.engine, f.config, s)).toBe(false);
      const d = templateLesson("math", "blank");
      d.config.slides = [newSlide(f.engine)];
      expect(validateLesson(d)).toEqual([]);
    });
  it("rejects unreachable targets, malformed arrays, duplicate keys and impossible budgets", () => {
    for (const [engine, config] of [
      ["solid3D", { target_volume: 7 }],
      ["polygonVertices", { target_area: 7 }],
      ["causalLab", { target_product: 5, axes: ["x", "y"] }],
      ["globe3D", { target_latitude: 1, target_longitude: 15 }],
      ["resourceBudget", { items: ["a", "b"], minima: [8, 8] }],
      ["sequenceTiles", { items: ["a", "b"], answer_values: [0, 0] }],
      [
        "categorySort",
        { items: ["a", "b"], choices: ["c", "d"], answer_values: [0, 9] },
      ],
      ["evidenceBoard", { items: ["a", "b"], answer_values: [0, 0] }],
    ] as [ExtendedEngine, ExtendedConfig][])
      expect(validExtended(engine, config)).toBe(false);
    expect(Object.keys(extendedEngines)).toHaveLength(29);
  });
  it("suggests engines with Vietnamese accents and makes subject-specific four-step recipes", () => {
    expect(suggestEngines("Góc và tam giác")).toContain("polygonVertices");
    expect(suggestEngines("Vòng lặp và đường đi")).toContain("loopBuilder");
    expect(suggestEngines("Vận tốc và độ dốc")).toContain("graph");
    for (const subject of subjects) {
      const d = topicRecipe({ id: "topic", title: subject, subject });
      expect(d.config.slides).toHaveLength(4);
      expect(validateLesson(d)).toEqual([]);
    }
  });
  it("checks only published peers in the same topic, excludes itself and warns at strict thresholds", () => {
    const doc = templateLesson("math", "blank");
    doc.config.slides = [newSlide("quiz")];
    const peer = {
      ...structuredClone(doc),
      id: "published",
      builder_status: "published",
    };
    const q = qualityReport(doc, [
      peer,
      { ...peer, id: "other", topic_id: "science" },
      { ...peer, id: "draft", builder_status: "draft" },
    ]);
    expect(q.ratio).toBe(1);
    expect(q.duplicates).toHaveLength(1);
    expect(q.warnings).toHaveLength(2);
    const mixed = templateLesson("math", "blank");
    mixed.config.slides = [newSlide("quiz"), newSlide("solid3D")];
    expect(qualityReport(mixed, []).warnings).toEqual([]);
  });
});
