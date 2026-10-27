"""Write a newly CLI-created, empty registry migration; never rewrite history."""
import hashlib
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[1]
target = Path(sys.argv[1]).resolve()
if target.parent != root / 'supabase/migrations' or not target.is_file() or target.read_text(encoding='utf-8').strip():
    raise SystemExit('Pass an empty migration created with supabase migration new')
catalog = json.loads((root / 'supabase/catalog.json').read_text(encoding='utf-8'))
digest = hashlib.sha256((root / 'supabase/functions/learning-api/evaluator.js').read_bytes()).hexdigest()
entries = {}
for activity in catalog['activities']:
    item = {k: v for k, v in activity.items() if k not in ('topic_id', 'position')}
    entries.setdefault(item['mechanism'], []).append(item)
data = json.dumps(entries, ensure_ascii=False, separators=(',', ':')).replace("'", "''")
sql = f"""-- Activate only the exact compiled evaluator verified by the parity corpus.
DO $registry$
DECLARE entries jsonb := '{data}'::jsonb; item record;
BEGIN
  FOR item IN SELECT key,value FROM jsonb_each(entries) LOOP
    IF EXISTS(SELECT 1 FROM private.evaluator_versions WHERE mechanism=item.key AND version=1
      AND status='active' AND implementation_hash<>'{digest}')
    THEN RAISE EXCEPTION 'An active evaluator is immutable; deploy a new evaluator version'; END IF;
    UPDATE private.evaluator_versions SET status='active',handler_key='learning-api:dart-v1',
      implementation_hash='{digest}',input_schema=jsonb_build_object('activities',item.value,'max_state_bytes',65536)
      WHERE mechanism=item.key AND version=1;
    IF NOT FOUND THEN RAISE EXCEPTION 'Missing baseline evaluator: %',item.key; END IF;
  END LOOP;
END $registry$;
"""
target.write_text(sql, encoding='utf-8')
print(f'Prepared {len(entries)} evaluators / {len(catalog["activities"])} activities, hash {digest}')
