# Matlingo backend sources

Project: `seoswmcldwwytdrfrrrb` (Singapore). Application reset was explicitly requested and applied on 2026-10-26 local time.

## Applied sources

- `schema_reset.sql`: replaces the legacy application schemas with 22 tables, RLS, constraints, indexes, role checks and signup provisioning. **Destructive and not a repeatable development reset. Do not rerun against the current project.**
- `catalog_seed.sql`: the initial 11 topics / 53 activity versions / 30 evaluator registry entries, generated from the frontend catalog. Applied together with the reset in migration `20261025185036_replace_legacy_application_with_matlingo_schema` (server UTC timestamp).
- `merge_content_policies.sql`: applied as `20261025185302_merge_content_read_policies`.
- `catalog.json`: frontend scene data exported by `dart tools/export_catalog.dart`. Dart validators are not backend implementations.
- `functions/_retired/`: the response deployed to all 12 old payment/AI endpoints. Requests receive HTTP 410 after any existing platform JWT check; OPTIONS returns 204. These endpoints perform no payments, AI calls or database writes.

No timestamped local migration files were invented: the local Supabase CLI is unavailable. The applied migration history exists in the remote project; these are reviewed SQL source artifacts. Reconcile them with the CLI before establishing a new local migration workflow. They do not include the nine earlier legacy migrations and are not a complete replayable history of that project.

## Current readiness

Existing Auth identities were retained: 12 accounts, with the two existing admins preserved and all other accounts assigned `user`. Old learning/payment application rows were deleted. No learner profiles, sessions or XP were imported from the legacy database.

The baseline release is **draft**. All 30 backend evaluators are marked **testing/pending**, not implemented. Publishing is blocked until evaluator coverage is active and activity versions are published. Mobile still uses its bundled offline catalog and has not yet been connected to this database. The admin dashboard and business mutation/sync APIs remain to be implemented. `get_my_access()` is available for authenticated clients to inspect their own app role/status.

Supabase-managed Auth and Storage schemas were preserved. No buckets or objects existed at reset; application asset tables do not themselves create upload buckets or Storage policies. Configure those when implementing asset delivery.

## Verification

Live SQL checks passed for owner isolation across two users, admin draft access, suspended-account denial, anonymous denial, blocked self-promotion/client XP writes, unique XP rewards, cross-profile FK rejection and blocked publication of unverified content. Test records were rolled back. The database has RLS on all 22 tables and no public SECURITY DEFINER functions.

Private tables deliberately have no client policies/grants; their RLS deny-all informational findings are expected. Auth still reports leaked-password protection disabled; see the [Supabase remediation](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). Multiple permissive content policies were merged into one per table. Fresh unused indexes are not evidence of a performance failure.

See `docs/SUPABASE_RESET_REPORT.md` for rollout status. Never commit secret/service-role keys, Auth tokens, local user snapshots or SDK caches. Published clients use a publishable key and user JWT; privileged credentials stay on the backend.
