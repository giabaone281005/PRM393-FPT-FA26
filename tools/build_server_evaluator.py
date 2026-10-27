"""Build the deployed evaluator from the app's existing pure Dart sources.

Run from the repository root. Generated JS is committed for repeatable deploys;
version.ts pins its exact bytes in the private evaluator registry.
"""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
target = root / 'supabase/functions/learning-api'
dart = shutil.which('dart')
if not dart:
    raise SystemExit('Dart SDK is required')
subprocess.run([dart, 'compile', 'js', '-O2', '--no-source-maps', '-o',
                str(target / 'evaluator.js'), str(root / 'tools/server_evaluator.dart')],
               cwd=root, check=True)
(target / 'evaluator.js.deps').unlink(missing_ok=True)
digest = hashlib.sha256((target / 'evaluator.js').read_bytes()).hexdigest()
(target / 'version.ts').write_text(
    '// SHA-256 of evaluator.js; regenerate with tools/build_server_evaluator.py.\n'
    f'export const implementationHash = {json.dumps(digest)};\n', encoding='utf-8')
print('Evaluator SHA-256:', digest)
