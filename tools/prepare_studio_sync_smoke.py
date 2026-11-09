"""Render a rollback-only hosted Studio smoke suite from the shared fixtures."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
fixtures = json.loads((root / 'supabase/tests/fixtures/studio_engines.json').read_text(encoding='utf-8'))
fixtures.extend([
    {'engine': 'story', 'config': {'text': 'Read before experimenting.', 'image_url': '', 'image_alt': ''}, 'correct': {'ack': True}},
    {'engine': 'quiz', 'config': {'choices': ['Four', 'Five'], 'answer': 0}, 'correct': {'answer': 0}},
    {'engine': 'pairs', 'config': {'pairs': [{'left': 'One', 'right': '1'}, {'left': 'Two', 'right': '2'}]}, 'correct': {'values': [0, 1]}},
    {'engine': 'graph', 'config': {'min_a': -3, 'max_a': 3, 'min_b': -3, 'max_b': 3, 'start_a': 0, 'start_b': 0, 'target_a': 2, 'target_b': 1}, 'correct': {'a': 2, 'b': 1}},
])
assert len(fixtures) == 33
source = (root / 'supabase/tests/studio_sync_smoke.sql').read_text(encoding='utf-8')
output = root / 'build/studio-sync-smoke.sql'
output.parent.mkdir(exist_ok=True)
output.write_text(source.replace('__STUDIO_ENGINE_FIXTURES__', json.dumps(fixtures, ensure_ascii=False)), encoding='utf-8')
print(output)
