# Mobile APK with personal cloud backup

The configured Android app supports email/password Auth, local learning and personal cloud backup/restore on project `seoswmcldwwytdrfrrrb`. It does not publish the draft catalog or award server-verified XP.

## Build and install

Copy `config/app.example.json` to ignored `config/app.mobile.json`. Set `SUPABASE_PUBLISHABLE_KEY` to the project's publishable key. Never use a service-role/secret key. The publishable key is intentionally embedded in the app and relies on Auth/RLS.

```powershell
flutter pub get
flutter build apk --release --dart-define-from-file="D:\Brilliant Clone\brilliant_mobile\repo-history\config\app.mobile.json"
```

Output: `build/app/outputs/flutter-apk/app-release.apk`. Transfer it to Android and open to install, allowing that transfer app to install packages when Android asks. The existing release configuration uses debug signing for direct testing, not a Play Store production identity. Keep the signing identity consistent for upgrades. Verify cloud backup before uninstalling or clearing app data.

## Phone workflow

1. Configured mobile builds open **Tài khoản & sao lưu** and require sign-in before learning.
2. Sign in with email/password or register. When confirmation is required, enter the emailed code in **Mã xác nhận** and choose **Xác nhận & tiếp tục**; successful verification signs in automatically. If the app was closed, enter the same email on the login screen and choose **Đã có mã xác nhận? Nhập mã**. **Gửi lại mã** has a 60-second cooldown; server email limits still apply. An already open, unlinked device profile automatically links to the signed-in account and uploads.
3. Create/open the desired device profile. It automatically links to this account and backs up without a first manual save. Profiles linked to other accounts are hidden and cannot upload to the current account.
4. Continue learning. Changes to the open profile auto-save after two seconds while the app runs with a connection. Failures retain local data and retry about every 30 seconds, including a failed first upload. **Lưu lại ngay** remains available for an immediate save. Before closing/uninstalling, verify the cloud timestamp.
5. On another phone/install, sign in, refresh the list and choose **Khôi phục thành hồ sơ riêng**. Return to the profile picker and open the restored profile. Appearance preferences and unsent chat text are not included.

Restore adds a separate profile, preserving unsent local work. Stale revisions are rejected; refresh/restore to retain both versions. This is personal snapshot backup, not automatic multi-device merging. Cloud logout stops uploads, closes the active device profile and returns to the required login screen. Builds without cloud configuration retain offline mode for development.

## Email confirmation troubleshooting

Registration without a session does not prove that a new account was created or an email was delivered. Supabase can return an obfuscated response when an already-confirmed email is registered again. That operation does not replace the existing account's password; use **Đăng nhập** with the original password, or complete a password recovery flow if it was forgotten. Diagnose SMTP separately from Auth logs; keep email confirmation enabled and never change `auth.users` directly to bypass it. The app's registration message covers both new and existing emails without disclosing account existence.

The mobile code field accepts 6–10 digits with paste/autofill and verifies with `OtpType.email`. Resend uses `OtpType.signup`. Neither code nor password is added to LearningStore or cloud backups. The REA-aligned email template is `supabase/templates/confirmation.html`; see its README for applying it to the hosted project. Creating this file does not update live SMTP or the hosted email template.

## Data and security

`mobile_profile_backups` stores owner-scoped version-3 profile/learning JSON, revision and server timestamp. The private SECURITY DEFINER routine checks `auth.uid()`, expected owner, active user role and payload size. Its exposed wrapper is SECURITY INVOKER. Client grants are SELECT-only with ownership RLS. Anonymous/admin/suspended accounts cannot use this user-mobile backup path. Identical retries return the same receipt; updates require the previous revision. Limits: 1 MiB per profile and 100 profiles per account.

Local history/XP is personal data; backup snapshots cannot grant `xp_ledger` rewards or verified completions. Mobile 1.3.1+5 additionally submits real lesson states through the canonical API and shows server-confirmed XP separately. Published content and server evaluators are deployed. The admin dashboard UI and automatic incremental merge across devices remain pending. See `PHONE_READINESS.md` and `LEARNING_SERVER_API.md`.

## Checks

- `test/cloud_backup_test.dart`: explicit linking, restore on fresh preferences, local draft preservation, offline retry, stale writes, account switching, automatic saves and narrow-phone UI.
- `supabase/tests/mobile_backup_smoke.sql`: live RPC read/write/update, retry, stale revisions, cross-owner and direct-write denial, malformed payload, suspended/anonymous denial. Fixtures roll back.
- Migration replay was checked in a rolled-back transaction. Legacy history still needs reconciliation; do not run blanket `supabase db push/reset`.
- Mailbox confirmation and physical-phone installation/login need user interaction and are not claimed by automated checks.
