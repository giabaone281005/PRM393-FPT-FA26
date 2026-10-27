# Interactive owl and Gemini chat

## Home mascot

Home now includes Cú Mây, a native 3D owl made from perspective-projected, lit mesh surfaces. Horizontal drag or the left/right controls orbit the complete model. Tapping the owl or greeting control triggers a finite blink, wing wave and encouraging message. Reset restores the initial angle. It works offline without adding packages or raster assets.

The learning action remains above the mascot, keeping start/resume easy to reach. Vertical drag over the owl continues scrolling the page. Reduced-motion settings disable its animated greeting while retaining manual camera controls and text feedback. Mascot interaction does not change drafts, completion or XP.

Files: `lib/owl_scene.dart`, `lib/home_owl_mascot.dart`, `lib/journey_app.dart`, `test/home_owl_mascot_test.dart`, `test/icon_visual_preview_test.dart`.

## Gemini

Engine settings now offer Gemini with preset endpoint `https://generativelanguage.googleapis.com/v1beta` and model `gemini-3.5-flash-lite`. Selecting Gemini fills these values and supplies a suggested connection name. Credentials use the existing account-scoped encrypted engine storage; they are excluded from public metadata and learning backups.

The adapter sends the key in `x-goog-api-key`, maps chat history to Gemini user/model roles, includes tutor and canvas instructions, and extracts visible response text. Thought parts and raw provider errors are not displayed. Gemini configurations require the official Google host and a safe model identifier. Existing providers remain available.

The supplied credential was tested successfully against Google, saved and activated in the running emulator's current account scope through the application's registry, reloaded from secure storage, and successfully used for an app-side tutor request. A temporary debug helper received the credential through the authenticated local VM service at runtime; that helper was removed. No key was written into source, config files, logs or compiled application code.

Files: `lib/data/models/engine_config.dart`, `lib/data/engines/http_ai_engine.dart`, `lib/features/engines/engine_settings_page.dart`, `test/gemini_engine_test.dart`.

Protocol references: [Gemini 3.5 Flash-Lite](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite), [generateContent API](https://ai.google.dev/api/generate-content), [API-key authentication](https://ai.google.dev/gemini-api/docs/api-key).

## Validation

`flutter analyze` passes and all 170 Flutter tests pass. New coverage checks a full model orbit, depth sorting and finite coordinates, greeting/rotation/reset, reduced motion, 280px layout with enlarged text, preserved vertical scrolling, Gemini wire format and safe failures, and configuration persistence. The real-font front/rotated mascot and home renders were inspected. Existing standalone checks pass: 50 interaction, 2,491 depth and 17,552 spatial checks.

The UI automation native pipe was unavailable, so settings persistence and the live response were verified through the app's own registry/runtime APIs rather than automated clicks. No schema, server content or reward logic changed.

The configured Android debug APK builds successfully. Scanning its unpacked entries found neither an embedded Gemini key nor the temporary configuration extension. `git diff --check` passes.
