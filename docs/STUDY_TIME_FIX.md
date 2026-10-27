# Live lesson time

The profile previously displayed any recorded duration below 60 seconds as `<1 phút`, and the lesson had no live time readout. This hid second-by-second progress even though the foreground stopwatch was sampled on saves.

Lessons now show `Phiên này · MM:SS`, refreshed once per second using the existing monotonic stopwatch plus the saved session duration. Only the readout rebuilds on a tick; durable autosave remains every 15 seconds, with a final save when leaving or pausing. Profiles display exact units such as `12 giây` and `1 phút 30 giây` instead of the less-than-one-minute label. Unknown legacy timing remains unknown.

The clock pauses when the app is not resumed or another route covers the lesson, and continues from the saved duration when reopened. Paused sessions no longer perform periodic autosaves. Time measures the foreground lesson, rather than time browsing home/profile or spent with the app in the background. Existing daily aggregation, midnight splitting and reward rules are unchanged.

Changed files: `lib/journey_app.dart`, `lib/learning_activity.dart`, `test/study_timer_test.dart`, `test/daily_activity_test.dart`, `test/extended_curriculum_test.dart`, and this document. The existing equation test now waits for scrolling to settle before tapping, accommodating the extra timer row without weakening its assertions.

Validation: all 175 Flutter tests pass; `flutter analyze`, `git diff --check` and the configured Android debug APK build pass. Tests explicitly verify second ticks without per-second disk writes, minute/hour boundaries, reopen continuity, no duplicate accounting, covered-route/background exclusion, profile second labels, and the existing daily persistence/midnight behavior. The real-font lesson render was inspected. Standalone checks pass: 50 interaction, 2,491 depth, 17,552 spatial checks. No backend schema or deployed function was changed.
