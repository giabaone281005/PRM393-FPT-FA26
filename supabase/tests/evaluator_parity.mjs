import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
globalThis.self = globalThis;
createRequire(import.meta.url)('../functions/learning-api/evaluator.js');
const cases = JSON.parse(readFileSync(new URL('../../build/server_evaluator_cases.json', import.meta.url)));
for (const { request, expected } of cases) {
  assert.deepEqual(JSON.parse(globalThis.matlingoEvaluate(JSON.stringify(request))), expected, JSON.stringify(request));
}
const source = readFileSync(new URL('../functions/learning-api/evaluator.js', import.meta.url));
const version = readFileSync(new URL('../functions/learning-api/version.ts', import.meta.url), 'utf8');
assert(version.includes(createHash('sha256').update(source).digest('hex')));
assert(JSON.parse(globalThis.matlingoEvaluate('{"activity_id":"unknown","content_version":1,"state":{}}')).error);
console.log(`${cases.length} server/mobile evaluator parity checks passed across 53 activities.`);
