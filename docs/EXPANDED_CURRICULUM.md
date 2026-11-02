# Expanded learning curriculum

The app now bundles **20 topics, 139 activities and 40 interaction mechanisms**. This adds 68 activities: six for each of seven new topics, plus two transfer/challenge activities for each existing topic. Existing topic/activity IDs and the original ordering remain intact. The new activities use the existing check, hint, retry, completion, daily-time and automatic account-save flow.

## Learning progression

| New topic | Suggested starting age | Foundation → application → challenge |
|---|---:|---|
| English in daily life | 6+ | Greetings/listening → sentence building/introduction → listening inference/polite spoken request |
| Vietnamese and communication | 6+ | Vocabulary/purpose → story order/connectors → evidence-based argument/revision |
| Biology | 8+ | Plant parts/ecosystem roles → life cycle/photosynthesis → controlled model/fair experiment |
| Chemistry | 12+ | States/tools → phase change/atom counts → conservation model/evaluating observations |
| Astronomy | 8+ | Objects/distance → motion/Moon phases → mission constraints/seasons evidence |
| Money and choices | 10+ | Contextual needs/budget terms → planning/arithmetic → constrained budget/evaluating claims |
| Digital citizenship | 10+ | Privacy/tools → verification/AI limitations → phishing investigation/project planning |

Ages suggest an entry point, not a proficiency diagnosis or access restriction. Older learners can start with foundations. Age suggestions filter topics by accessible starting age; 14+ includes earlier foundations. The existing philosophy topic is suggested from 16. The six discovery paths and course roadmaps cover all 20 topics once. Topic pages show the suggested age and basic-to-challenge progression; activities retain their stage labels and roadmap previews.

## Reusable interactions

`curriculum_engine.dart` supplies deterministic validators and feedback; `curriculum_workspace.dart` supplies themed widgets for nine mechanisms:

- `matchPairs`: connect each item to a meaning, unit or function.
- `sequenceTiles`: reorder by long-press drag or accessible up/down buttons.
- `categorySort`: classify several items into reusable categories.
- `clozeBank`: fill context-dependent language or numeric blanks.
- `evidenceBoard`: select multiple relevant observations, rejecting distractors and duplicates.
- `causalExperiment`: choose two parameters, predict, run and compare a six-trial visual log. Parameter changes invalidate the previous observation. Equations and simplifications are explicit.
- `resourceBudget`: distribute ten units while satisfying several lower bounds; accepts multiple valid solutions and allows correcting allocations.
- `listeningChoice`: normal/slow English playback, replay/stop, transcript alternative and comprehension check.
- `speechPractice`: explicit microphone action or typed response; compares normalized words/order with a model sentence.

These mechanisms reuse `ExperimentSpec` and durable JSON state. Validators reject unsolved, malformed, out-of-range and incomplete responses. No AI/provider key or arbitrary code execution is needed for these activities.

## Audio behavior

`LanguageAudio` is injectable for tests. Its device adapter uses pinned [flutter_tts 4.2.5](https://pub.dev/packages/flutter_tts/versions/4.2.5) and [speech_to_text 7.5.0](https://pub.dev/packages/speech_to_text/versions/7.5.0). Android declares microphone permission and TTS/recognition service queries; iOS includes microphone/speech-recognition usage descriptions. Bluetooth routing is disabled in the recognizer, so this implementation does not request Bluetooth permissions.

Microphone permission is requested only after the learner taps the speak button. Recognition requests are limited to a short phrase (up to 15 seconds), select US English if available, and stop on leaving the workspace, app backgrounding, locking a checked answer or explicit Stop. Stale callbacks are ignored. Typing stops an active recognition request. Matlingo stores the text response with progress, not a raw audio recording; the OS recognition service may use network processing. Unsupported voices, denied permissions and unavailable recognition leave transcript/typing alternatives accessible. This is phrase practice, **not a pronunciation-quality score, fluency assessment or continuous conversation engine**.

## Server compatibility

Migration `20261108000000_expanded_learning_topics.sql` adds seven topic metadata rows with `ON CONFLICT DO NOTHING`. It preserves existing metadata, RLS, publication state and user data. It was created by the CLI then placed after the repository's retained future-dated migrations. Remote history uses the connected tool's timestamp; reconcile by name/content, as described in `supabase/README.md`.

The Admin catalog has 20 topic records. The new seven records remain draft on the canonical server; these local activities have **not** been registered or published as new server evaluators. Their personal progress still saves through the existing account snapshot RPC. Local learning points remain separate from server-verified XP. New sessions containing unpublished activities stay durable and wait for a compatible server release. Existing sessions already pinned to an older compatible release can finish syncing after local lessons are appended; a guard prevents sending a new activity to an older release. No client XP authority was added.

The tutor FAQ now describes 20 topics/139 activities, age suggestions and the actual audio alternatives. The deployed tutor retains its authenticated active-learner checks and existing provider-secret handling.

## Verification

Final checks on 2026-11-02: `flutter analyze --no-pub` has no issues; all **232 Flutter tests** pass. The **9 tutor/FAQ Deno tests**, Deno check and lint pass. Standalone checks pass (50 / 2,491 / 17,552), as do 729 server/mobile parity cases using the committed LF snapshot. The configured Android debug APK builds successfully at `build/app/outputs/flutter-apk/app-debug.apk`. Java native-access and flutter_tts KGP migration notices are warnings on the current SDK; a future Flutter upgrade needs a compatible plugin release.

See `build/expanded-full-tests.log`, `build/expanded-learning-tests.log` and `build/expanded-regressions.log` for test runs. Tests cover all new validators/JSON restoration, actual touch interactions, audio failure/permission fallback, cancellation/late callbacks, all 20 completion flows, older pinned server sessions, forbidden new-to-old release requests, and layout at 320px with text scale 1.4 in light/dark themes. `build/curriculum-preview/english.png` is a real-font render used for visual review.

The metadata migration was replayed twice inside a rolled-back transaction, confirming 20 topics, seven draft additions and retained RLS, before application. `supabase/tests/expanded_topics_smoke.sql` checks the applied state. No destructive reset or legacy migration replay was used.

`supabase/tests/expanded_progress_smoke.sql` passed against the deployed account RPCs: English response text, biology observations/trial history and budget allocations survived save/load, and an idempotent retry retained its revision. All writes used a generated user inside a rolled-back transaction; an independent query found zero leftover curriculum fixtures. The Admin private realtime subscription and authenticated reads are checked separately. Security advisors retain the existing private-schema deny-all informational findings and the pre-existing leaked-password-protection setting; this change creates no new tables, grants or policies.

## Changed implementation areas

- Curriculum content, deterministic evaluation, widgets: `lib/experiments/curriculum_{catalog,engine,workspace}.dart`; contextual feedback integrates through `contextual_guidance.dart`.
- Device audio adapter and dependency/platform declarations: `lib/data/engines/language_audio.dart`, `pubspec.yaml`, `pubspec.lock`, Android manifest and iOS Info.plist.
- Discovery and appearance: `lib/learning_catalog.dart`, `lib/discovery_paths.dart`, `lib/journey_app.dart`, `lib/lesson_theme.dart`, `lib/data/repositories/catalog_roadmaps.dart`.
- Older pinned session compatibility: `lib/data/providers/learning_sync_controller.dart`.
- Metadata/FAQ: the additive migration, two SQL smoke files, `supabase/functions/tutor-chat/app_knowledge.ts` and its tests.
- Tests: `test/expanded_learning_test.dart`, `test/curriculum_solutions.dart`, and existing catalog, layout, completion, theme and sync regressions updated for the larger catalog. The canonical evaluator export explicitly excludes these unpublished mechanisms.

Previously uncommitted account/Admin work, screenshots and other artifacts remain in the workspace. No commit or push was performed.

Device speech quality, installed voice availability and real microphone input require testing on the target device. Widget audio tests use an injected fake; an Android build cannot establish acoustic recognition quality. The shipped server evaluator remains the 53-activity baseline. On this Windows checkout, its direct parity command has the pre-existing CRLF byte-hash mismatch; the committed LF snapshot must be used to verify the unchanged implementation hash.
