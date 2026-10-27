"""Unauthenticated public smoke tests; no account/token is needed or logged."""
import json
import urllib.error
import urllib.request

base = 'https://seoswmcldwwytdrfrrrb.supabase.co/functions/v1/learning-api'
for label, request, status in [
    ('missing JWT', urllib.request.Request(base + '/sync'), 401),
    ('invalid JWT', urllib.request.Request(base + '/sync', headers={'Authorization': 'Bearer invalid-test-token'}), 401),
    ('preflight', urllib.request.Request(base + '/sync', method='OPTIONS'), 204),
]:
    try:
        response = urllib.request.urlopen(request, timeout=30)
    except urllib.error.HTTPError as error:
        response = error
    body = response.read().decode()
    if response.status != status:
        raise SystemExit(f'{label}: expected {status}, got {response.status}: {body[:300]}')
    if status == 401:
        assert json.loads(body)['error']['code'] == 'authentication_required'
    print(f'{label}: HTTP {status} passed')
