import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
globalThis.self = globalThis;
createRequire(import.meta.url)('../functions/learning-api/evaluator.js');
const legacyEvaluate = globalThis.matlingoEvaluate;
createRequire(import.meta.url)('../functions/learning-api/evaluator_v2.js');
const cases = JSON.parse(readFileSync(new URL('../../build/server_evaluator_cases.json', import.meta.url)));
let legacyChecks = 0;
const legacyActivities = new Set();
for (const { request, expected } of cases) {
  assert.deepEqual(JSON.parse(globalThis.matlingoEvaluate(JSON.stringify(request))), expected, JSON.stringify(request));
  const oldRequest = request.activity_id === 'math-number-line' ? { ...request, content_version: 1 } : request;
  const oldResult = JSON.parse(legacyEvaluate(JSON.stringify(oldRequest)));
  if (!oldResult.error) {
    assert.deepEqual(oldResult, { ...expected, evaluator_version: 1 }, JSON.stringify(oldRequest));
    legacyChecks++;
    legacyActivities.add(request.activity_id);
  }
}
assert.equal(new Set(cases.map((c) => c.request.activity_id)).size, 139);
assert.equal(legacyActivities.size, 53);
assert.equal(legacyChecks, 729);
const source = readFileSync(new URL('../functions/learning-api/evaluator_v2.js', import.meta.url));
const version = readFileSync(new URL('../functions/learning-api/version_v2.ts', import.meta.url), 'utf8');
assert(version.includes(createHash('sha256').update(source).digest('hex')));
const legacySource = readFileSync(new URL('../functions/learning-api/evaluator.js', import.meta.url));
const legacyVersion = readFileSync(new URL('../functions/learning-api/version.ts', import.meta.url), 'utf8');
assert(legacyVersion.includes(createHash('sha256').update(legacySource).digest('hex')));
assert(JSON.parse(globalThis.matlingoEvaluate('{"activity_id":"unknown","content_version":1,"state":{}}')).error);
console.log(`${cases.length} expanded + ${legacyChecks} legacy server/mobile evaluator parity checks passed across 139 activities.`);
