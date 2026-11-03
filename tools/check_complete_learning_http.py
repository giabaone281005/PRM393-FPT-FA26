"""Check deployed catalog/evaluators/XP with a disposable, pre-provisioned user.

The fixture JSON contains email/password/id and must stay in ignored build/.
Never use an existing learner: this suite creates real attempts/completions.
"""

from pathlib import Path
import argparse
import concurrent.futures
import json
import urllib.request
import urllib.error
import uuid

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--fixture", type=Path, required=True)
args = parser.parse_args()
fixture = json.loads(args.fixture.read_text(encoding="utf8"))
assert fixture["email"].startswith("matching-") and fixture["email"].endswith(
    "@example.invalid"
)
config = json.loads((root / "config/app.mobile.json").read_text(encoding="utf8"))
base, key = config["SUPABASE_URL"], config["SUPABASE_PUBLISHABLE_KEY"]


def request(path, body=None, token=None):
    headers = {"apikey": key, "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(
        base + path,
        data=None if body is None else json.dumps(body).encode(),
        headers=headers,
    )
    try:
        with urllib.request.urlopen(req, timeout=45) as response:
            raw = response.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raise AssertionError(
            f"{path}: HTTP {error.code}: {error.read().decode()[:500]}"
        ) from None


login = request(
    "/auth/v1/token?grant_type=password",
    {"email": fixture["email"], "password": fixture["password"]},
)
assert login["user"]["id"] == fixture["id"]
token = login["access_token"]


def api(route, body=None):
    return request("/functions/v1/learning-api/" + route, body, token)


def mutate(kind, payload, op=None):
    return api(
        "mutate",
        {
            "operation_id": op or str(uuid.uuid4()),
            "operation_type": kind,
            "payload": payload,
        },
    )


catalog = api("catalog?app_version=1.3.2")
assert catalog["release"]["version_label"] == "frontend-complete-2026-11-03"
assert len(catalog["topics"]) == 20 and len(catalog["activities"]) == 139
assert all(t["status"] == "active" for t in catalog["topics"])
export = json.loads((root / "supabase/catalog.json").read_text(encoding="utf8"))
local = {a["id"]: a for a in export["activities"]}
for remote in catalog["activities"]:
    source = local[remote["activity_id"]]
    for field in (
        "content_version",
        "mechanism",
        "mechanism_version",
        "evaluator_version",
        "config",
        "initial_state",
        "title",
        "stage",
        "prompt",
        "hint_levels",
        "explanation",
        "skill_ids",
        "position",
        "topic_id",
    ):
        assert remote[field] == source[field], (remote["activity_id"], field)
print("Live catalog: all 139 activities match every exported content field", flush=True)
profile = str(uuid.uuid4())
mutate(
    "profile.create",
    {
        "id": profile,
        "name": "Matching HTTP fixture",
        "daily_minutes": 10,
        "interest_topic_ids": [],
        "onboarded": True,
    },
)
cases = json.loads(
    (root / "build/server_evaluator_cases.json").read_text(encoding="utf8")
)
solutions = {
    c["request"]["activity_id"]: c["request"]["state"]
    for c in cases
    if c["expected"]["is_correct"]
}


def complete_topic(topic_id, selected, release_id, expected_xp):
    session = str(uuid.uuid4())
    mutate(
        "session.start",
        {
            "id": session,
            "profile_id": profile,
            "topic_id": topic_id,
            "release_id": release_id,
        },
    )
    for index, activity in enumerate(selected):
        payload = {
            "session_id": session,
            "activity_id": activity["activity_id"],
            "content_version": activity["content_version"],
            "hint_level": 0,
        }
        if index == 0:
            result = api(
                "attempts",
                {
                    "operation_id": str(uuid.uuid4()),
                    "payload": {**payload, "state": activity["initial_state"]},
                },
            )
            assert not result["result"]["attempt"]["is_correct"]
        result = api(
            "attempts",
            {
                "operation_id": str(uuid.uuid4()),
                "payload": {**payload, "state": solutions[activity["activity_id"]]},
            },
        )
        assert result["result"]["attempt"]["evaluation_status"] == "verified"
        assert result["result"]["attempt"]["is_correct"], activity["activity_id"]
    op = str(uuid.uuid4())
    result = mutate("session.complete", {"session_id": session}, op)
    assert result["result"]["xp_awarded"] == expected_xp, result
    assert mutate("session.complete", {"session_id": session}, op) == result
    print(
        f"{topic_id}: {len(selected)} correct attempts, wrong-answer rejection, {expected_xp} XP, retry stable",
        flush=True,
    )
    return len(selected)


groups = {
    t["id"]: [a for a in catalog["activities"] if a["topic_id"] == t["id"]]
    for t in catalog["topics"]
}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    futures = [
        executor.submit(complete_topic, topic, activities, catalog["release"]["id"], 30)
        for topic, activities in groups.items()
    ]
    assert sum(f.result() for f in futures) == 139
progress = api("progress?profile_id=" + profile)
assert progress["verified_xp"] == 600, progress
old = api("catalog?app_version=1.3.1")
assert (
    old["release"]["version_label"] == "frontend-baseline-2026-10-26"
    and len(old["activities"]) == 53
)
complete_topic(
    "math",
    [a for a in old["activities"] if a["topic_id"] == "math"],
    old["release"]["id"],
    0,
)
assert api("progress?profile_id=" + profile)["verified_xp"] == 600
request("/auth/v1/logout?scope=global", {}, token)
report = {
    "topics": 20,
    "activities": 139,
    "verified_xp": 600,
    "legacy_release_supported": True,
    "catalog_fields_match": True,
    "completion_retry_stable": True,
}
(root / "build/matching-live-result.json").write_text(
    json.dumps(report, indent=2), encoding="utf8"
)
print(
    "PASS: 20 topics / 139 activities / 600 verified XP; legacy session awards no duplicate XP",
    flush=True,
)
