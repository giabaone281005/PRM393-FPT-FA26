import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

// Packaged runners can check their parent repository.
const base = process.argv[2]
  ? pathToFileURL(resolve(process.argv[2], 'supabase/tests/evaluator_parity.mjs'))
  : import.meta.url;
globalThis.self = globalThis;
createRequire(base)('../functions/learning-api/evaluator.js');
const legacyEvaluate = globalThis.matlingoEvaluate;
createRequire(base)('../functions/learning-api/evaluator_v2.js');
const cases = JSON.parse(readFileSync(new URL('../../build/server_evaluator_cases.json', base)));
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
// Accept Windows checkout line endings while still checking pinned source content.
function sourceHash(source) {
  return createHash('sha256').update(source.toString('utf8').replace(/\r\n/g, '\n')).digest('hex');
}
const source = readFileSync(new URL('../functions/learning-api/evaluator_v2.js', base));
const version = readFileSync(new URL('../functions/learning-api/version_v2.ts', base), 'utf8');
assert(version.includes(sourceHash(source)), 'evaluator_v2.js differs from its pinned hash (ignoring CRLF).');
const legacySource = readFileSync(new URL('../functions/learning-api/evaluator.js', base));
const legacyVersion = readFileSync(new URL('../functions/learning-api/version.ts', base), 'utf8');
assert(legacyVersion.includes(sourceHash(legacySource)), 'evaluator.js differs from its pinned hash (ignoring CRLF).');
assert(JSON.parse(globalThis.matlingoEvaluate('{"activity_id":"unknown","content_version":1,"state":{}}')).error);
console.log(`${cases.length} expanded + ${legacyChecks} legacy server/mobile evaluator parity checks passed across 139 activities.`);
