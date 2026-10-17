# Supabase repair status — 17/10/2026

Project: `seoswmcldwwytdrfrrrb`. Flutter sources were not changed in this repair.

## Confirmed and repaired on Cloud

- Auth logs showed HTTP 500 on password login and signup: `confirmation_token: converting NULL to string is unsupported`.
- Four Auth users had NULL confirmation/recovery/email-change strings. Normalized NULL strings to empty strings following Supabase troubleshooting guidance, preserving existing nonempty tokens, passwords, sessions and users. Verification: zero remaining NULLs in the affected fields.
- Applied Cloud migration `20261016183250_repair_cloud_access_drift`. The reviewed SQL is preserved in `operations/repair_cloud_access_drift.sql`.
- Removed direct client access to lesson/question tables, including column grants, and restored restricted parent profile grants. Verified authenticated users cannot SELECT questions, UPDATE kid rewards or execute payment settlement.
- Added and validated the missing parents-to-auth.users foreign key, using the repository's existing NO ACTION deletion behavior. Account deletion may still require explicit handling of application/financial dependencies.
- Restricted legacy RPC execution and fixed four mutable function search paths.
- Database RPC smoke check completed for confirmed accounts: ensure_family, family_report, effective_entitlements, has_parent_pin, and curriculum/wardrobe for their active children. All smoke-check writes rolled back. This check used privileged SQL with JWT claims; it does not establish end-to-end client RLS or HTTP Auth correctness.
- Deployed existing repository sources for vnpay-checkout, vnpay-ipn, vnpay-return and vnpay-query. Confirmed all four ACTIVE. Deployment alone does not verify merchant secrets or real payment processing.

## Remaining work and limits

- Two Auth users still contain malformed password hashes (39 characters). No passwords were guessed or replaced. Recover through Auth password reset or recreate explicitly approved demo accounts through the Auth Admin API.
- Auth logs also showed email-send rate limiting (429). SMTP configuration and email delivery remain unverified.
- Cloud has application objects from migrations 18–21, but migration history contains only 13–17 plus this repair. Do not blindly rerun existing migrations or falsely mark them applied. Compare definitions before migration history reconciliation.
- Automatic approval review rejected deployment of vnpay-refund (external refunds) and commerce-reconcile (automatic financial settlement). Neither was deployed. Explicit user authorization is required for these financial capabilities.
- AI function deployment did not complete before interruption; current listing does not show ai-tutor. Provider secrets and AI configuration remain unverified.
- No full reset, deletion, or account purge was performed. No end-to-end successful login, signup email confirmation, password recovery, payment or AI test is claimed.
- Some local configuration/check scripts are only one byte; they are not usable evidence of passing checks.
- `seed.sql` includes direct Auth inserts with placeholder password hashes. Do not run it on Cloud or use it to recreate working login accounts.

Reference: https://supabase.com/docs/guides/troubleshooting/scan-error-on-column-confirmation_token-converting-null-to-string-is-unsupported-during-auth-login-a0c686
