# Emulator QA — 17/10/2026

- Flutter analysis: no issues.
- Flutter tests: 17 passed.
- Backend handler/signature tests: 21 passed.
- SQL structural checker: 15 files passed. Staging SQL regression suites were not executed by this check.
- Debug APK built and installed on Pixel_9 / emulator-5554 with config/app.json. Supabase initialization completed.
- Four dedicated QA accounts created for this user-requested test: qa.admin.20261017@mathlingo.test, qa.moderator.20261017@mathlingo.test, qa.basic.20261017@mathlingo.test, qa.plus.20261017@mathlingo.test. Existing accounts and passwords were not changed.
- Confirmed real HTTP password login (200), ensure_family (204), family_report (200), role checks, and restricted direct answer access for all four accounts. Admin dashboard is allowed for admin and denied for the other three; CMS is allowed for admin/moderator and denied for parents.
- Basic and Plus each have a grade-1 child. Both return 30 curriculum lessons and wardrobe data. Plus has max_kids=3 and a 30-day QA entitlement; no payment was processed.
- Parent PIN for these QA fixtures: 8426. Child mode uses the parent's account and selected child profile; there is no separate child password.
- No real VNPay payment/refund, Gemini call, SMTP delivery or end-to-end UI walkthrough of every feature is claimed.
- Live HTTP check results without session tokens: build/qa/live-role-checks.json (ignored build output).
- QA account credentials were delivered in chat; do not commit credentials or tokens.
