import "./evaluator.js";

declare global {
  var matlingoEvaluate: (input: string) => string;
}

export const legacyEvaluate = globalThis.matlingoEvaluate;
