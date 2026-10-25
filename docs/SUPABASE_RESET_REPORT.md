# Supabase reset report — 26/10/2026

## Applied changes

Project `seoswmcldwwytdrfrrrb` was inspected through the connected Supabase MCP. The previous public/private application schemas contained 49 tables, including parent/kid accounts, lesson/question content, payment and subscription data. The user explicitly requested deleting the old application database and replacing it with the current Flutter model.

Applied migrations, recorded by the server in UTC:

1. `20261025185036_replace_legacy_application_with_matlingo_schema`: recreated public/private application schemas, installed 22 tables (15 public / 7 private), ownership constraints, RLS, indexes, signup provisioning and published-content guards; seeded the exported frontend catalog.
2. `20261025185302_merge_content_read_policies`: combined admin/user content read policies to remove the multiple-permissive-policy advisory.

Result: 11 topics, 53 activities and activity versions, 30 evaluator registry entries. The baseline release is draft. Auth identities were preserved: 12 accounts, 2 admin and 10 user. All previous non-admin application roles now map to user; no parent/moderator role remains in the new application schema.

Old learning/payment rows were deleted; zero learner profiles, learning sessions and XP ledger entries remain after smoke-test rollback. Supabase-managed schemas were retained. The schema metadata captured in `evidence/legacy-supabase-schema-2026-10-26.json` is **not a data backup**, and cannot restore deleted row data.

## Retired legacy endpoints

The existing deployments for create-payment, payment-callback, vnpay-checkout, vnpay-ipn, vnpay-return, vnpay-query, momo-checkout, momo-ipn, demo-pay, ai-tutor, vnpay-refund and commerce-reconcile were replaced with a no-side-effect retirement handler. Existing JWT verification settings were preserved. The deployed ai-tutor source was read back and verified to contain the retirement handler. This retains deployment history; it does not erase function names.

## Checks performed

Live transaction tests passed and were rolled back:

- User A/B see only their own account/profile/XP rows.
- Users cannot read draft activity versions, alter their role or insert XP.
- Admin can inspect all 11 draft topics and cannot bypass user ownership on learning tables.
- Suspended users cannot read their profiles, even with the same JWT subject.
- Anonymous access to accounts is denied.
- A third application role violates the role CHECK constraint.
- Duplicate topic rewards violate the unique ledger key.
- A draft referencing another profile's session violates composite FK ownership.
- Publishing the baseline while evaluator coverage is pending is rejected.

Post-checks: all 22 tables have RLS; the seven content tables have one SELECT policy each; no public SECURITY DEFINER functions; test fixtures left no learning rows.

Security advisor: private tables have intentional deny-all/no-policy INFO findings. Leaked-password protection remains disabled in Auth and requires a project configuration decision; [remediation](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). Performance findings for fresh unused indexes are expected before traffic.

## Remaining implementation

This completes the application schema reset, not the entire product backend. Evaluators, profile/session mutation APIs, sync/import, authenticated mobile integration, Storage buckets/policies and the web admin dashboard are still pending. Existing users retain login identities, but the mobile app currently remains offline and does not authenticate with Supabase.

The catalog is deliberately not published or described as server-verified. The SQL registry contains explicit pending handler names/hashes; it must be replaced by deployed, parity-tested evaluator versions before publishing.

## Git history and push

Target repository: `https://github.com/giabaone281005/PRM393-FPT-FA26.git`. At the time of the reset, the original frontend workspace and `D:/MathLingo` had no `.git` checkout. The latter is an older Flutter source copy, not a usable source of contributor commit history.

Shell GitHub access failed due to network restrictions; the public web URL returned 404. GitHub integration was offered but no authenticated GitHub tools are connected yet. No repository was initialized, no history rewritten and no code pushed.

Update: the user subsequently cloned the remote into `repo-history/`. Branch `refactor/matlingo-mobile-supabase` was created from original main `967b9cb`, with all 94 original commits retained. The application replacement and lesson-depth iterations are local. The user's latest instruction explicitly forbids pushing; do not push or create a remote PR until that instruction changes. AGENTS.md and the original migration contents remain unchanged. See docs/CODEBASE_REPLACEMENT.md and docs/LESSON_DEPTH_ITERATIONS.md in the checkout.
