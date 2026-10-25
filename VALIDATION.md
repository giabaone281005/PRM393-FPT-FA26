# Current validation

The active app is the Matlingo frontend imported from brilliant_mobile. Historical MathLingo reports are in docs/legacy/repository-root and do not validate this codebase.

Run flutter pub get, flutter analyze, flutter test, dart tools/check_diverse.dart, dart tools/check_space.dart, dart tools/check_depth.dart and flutter build apk --debug. CI follows this workflow without accessing the live database.

The current local environment cannot write the Flutter SDK cache or read the full dependency cache, so full Flutter tests/builds remain unverified. Standalone checks pass: 2,491 depth, 17,552 geometry and 50 interaction checks. See docs/LESSON_DEPTH_ITERATIONS.md for three local implementation/test iterations and docs/SUPABASE_RESET_REPORT.md for live database smoke tests; backend integration and server evaluators are still pending.

Legacy migrations are retained unchanged for contributor/history preservation. Their filenames do not match every migration recorded on the remote project. Do not run supabase db push/reset until reconciling that history against the executed sources described in supabase/README.md.
