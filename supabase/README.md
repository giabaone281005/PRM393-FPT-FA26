# Matlingo backend sources

Project: `seoswmcldwwytdrfrrrb` (Singapore). Application reset was explicitly requested and applied on 2026-10-26 local time.

## Applied sources

- `schema_reset.sql`: replaces the legacy application schemas with 22 tables, RLS, constraints, indexes, role checks and signup provisioning. **Destructive and not a repeatable development reset. Do not rerun against the current project.**
- `catalog_seed.sql`: the initial 11 topics / 53 activity versions / 30 evaluator registry entries, generated from the frontend catalog. Applied together with the reset in migration `20261025185036_replace_legacy_application_with_matlingo_schema` (server UTC timestamp).
- `merge_content_policies.sql`: applied as `20261025185302_merge_content_read_policies`.
- `catalog.json`: frontend scene data exported by `dart tools/export_catalog.dart`. Server evaluator implementations are compiled from the same pure Dart catalogs into `functions/learning-api/evaluator.js`.
- `functions/learning-api/`: deployed canonical learning, evaluator, sync, admin and private image API. See `../docs/LEARNING_SERVER_API.md`.
- `functions/_retired/`: historical stub source, formerly deployed to 12 legacy payment/AI endpoints. After official CLI login on 2026-10-26, all 12 deployments were deleted as requested. Only `learning-api` remains (v4 after the conflict-response fix). Do not redeploy the retired stubs.

The reset source artifacts and retained legacy filenames are not a complete replayable migration history. New additive migrations are created with the local CLI, then placed after retained future-dated files as required by AGENTS.md. The connected migration tool records its own UTC timestamps; reconcile by name/content before any db push/reset.

## Current readiness

The initial application reset retained 12 Auth identities, including two admins. On 2026-10-26, the user explicitly requested deletion of every existing account to register again from scratch. All 12 Auth users and their application accounts, identities, role assignments, sync heads, refresh tokens and 35 Auth sessions were removed in a checked transaction. An independent query confirmed zero users/accounts/sessions/roles, with the 11 topics, 53 activities, 53 content versions and draft release preserved. Signup provisioning remains enabled; new signups receive the default `user` role. Old learning/payment application rows were deleted by the earlier application reset; no legacy learner profiles, sessions or XP were imported.

The baseline release is **published**, with 53 published activity versions and 30 active backend evaluators. `learning-api` exposes canonical learning mutations, server evaluation, verified completion/XP, incremental sync, progress, admin content/account operations and asset upload/signing. Public RPCs are invoker wrappers with private authority checks. `get_my_access()` lets authenticated clients inspect their own role/status.

Mobile now combines its bundled catalog/personal backup with canonical profile/session/draft/attempt/completion writes through a durable local journal. Server-confirmed XP is displayed separately from local learning points; backup snapshots never grant verified XP. Restored device branches get fresh mutable IDs; metadata conflicts require the user's choice. Automatic incremental merging of two devices and the admin dashboard UI remain pending. AI/compiler engines remain separate provider integrations. See `../docs/PHONE_READINESS.md`.

The additive `mobile_profile_backups` migration is local file `migrations/20261029000000_mobile_profile_backups.sql`, after the retained future-dated legacy files through October 28. It was created by the CLI and applied through the connected migration tool, which records its own current UTC timestamp. Reconcile by name/content rather than replaying legacy files. `tests/mobile_backup_smoke.sql` checks ownership, retry, stale revisions, suspension, invalid payload and client-write denial with all fixtures rolled back.

Supabase-managed Auth and Storage schemas were preserved. The additive content-delivery migration creates private `learning-assets` and `user-avatars` buckets. Uploads use the authenticated Edge handler; reads receive a 300-second URL only after RLS metadata checks. These are image-only pipelines, not model/GLB delivery or a public upload bucket.

## Verification

Live SQL checks passed for owner isolation across two users, admin draft access, suspended-account denial, anonymous denial, blocked self-promotion/client XP writes, unique XP rewards, cross-profile FK rejection and blocked publication of unverified content. Test records were rolled back. The database has RLS on all 22 tables and no public SECURITY DEFINER functions.

Private tables deliberately have no client policies/grants; their RLS deny-all informational findings are expected. Auth still reports leaked-password protection disabled; see the [Supabase remediation](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). Multiple permissive content policies were merged into one per table. Fresh unused indexes are not evidence of a performance failure.

See `docs/SUPABASE_RESET_REPORT.md` for rollout status. Never commit secret/service-role keys, Auth tokens, local user snapshots or SDK caches. Published clients use a publishable key and user JWT; privileged credentials stay on the backend.
