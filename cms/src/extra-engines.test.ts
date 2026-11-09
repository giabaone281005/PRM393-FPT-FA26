import { expect, it } from "vitest";
import {
  extraConfig,
  validExtra,
  correctExtra,
  type ExtraEngine,
} from "./extra-engines";
it("rejects invalid domains, zero denominators, malformed charts and missing geometry targets", () => {
  const cases: [ExtraEngine, Record<string, unknown>][] = [
    ["numberLine", { min: 5, max: 5, start: 5, target: 5 }],
    ["fractionBoard", { denominator: 0, numerator: 1 }],
    ["quadraticGraph", { target_a: 0, target_b: 0, target_c: 1 }],
    ["barChart", { labels: ["A", "B"], target_values: [1] }],
    ["coordinatePoint", { target_x: 10, target_y: 0 }],
    ["vennDiagram", { items: ["a", "b"], answer_values: [0, 4] }],
    [
      "fractionCompare",
      {
        left_numerator: 1,
        left_denominator: 0,
        right_numerator: 1,
        right_denominator: 2,
      },
    ],
    ["shapeMatch", { target_shape: "<script>" }],
    ["numberInput", { target_value: 1.5 }],
  ];
  for (const [engine, config] of cases)
    expect(validExtra(engine, config)).toBe(false);
  for (const engine of cases.map(([e]) => e))
    expect(validExtra(engine, {})).toBe(false);
});
it("uses exact rational comparisons and rejects duplicate shaded parts or forged numeric answers", () => {
  expect(
    correctExtra(
      "fractionCompare",
      {
        ...extraConfig("fractionCompare"),
        left_numerator: 2,
        left_denominator: 4,
        right_numerator: 3,
        right_denominator: 6,
      },
      { comparison: 1 },
    ),
  ).toBe(true);
  expect(
    correctExtra("fractionBoard", extraConfig("fractionBoard"), {
      selected: [0, 0, 1, 2],
    }),
  ).toBe(false);
  for (const value of [12, true, null, "12.0", "12x", "+12", "Infinity", "1e1"])
    expect(
      correctExtra("numberInput", extraConfig("numberInput"), { value }),
    ).toBe(false);
});
