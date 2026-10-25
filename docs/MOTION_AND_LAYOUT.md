# Flutter Samples: motion and proportion pass

The newly added material is the local `../flutter-samples` repository, not a registered skill: it contains no `SKILL.md`. Relevant examples were read directly before implementation:

- `hero_animations/hero_dialog_route.dart`: curved route fade on entry and dismissal.
- `animations/list_details/list_page.dart`: custom route timing and movement tied to animation values.
- `animations/turn_on_the_light/turn_on_the_light.dart`: immediate visual feedback tied to gestures and local state.

Source: Flutter Samples, Diego Velásquez, MIT. See `FLUTTER_SAMPLES_LICENSE.txt`. Patterns were adapted to current Flutter APIs; no old sample dependencies were installed.

## Implemented

- Shared 360ms forward / 260ms reverse fade-and-slide routes for topics, lessons, results and profile.
- Finite 420ms entry motion for profile gates, tabs, onboarding steps and lesson steps. Indexed tab children remain mounted so navigation does not discard their state.
- Hints expand/collapse in 240ms; progress segments interpolate instead of jumping.
- Buttons press down by 3px with a shortening solid shadow; release restores the Brilliant treatment.
- Primary actions size to their label, with 24px horizontal padding, minimum 48px tap height and a 320px width cap. Long labels can wrap within the available width. Removed the global infinite-width button minimum. The action with an icon uses a compact row.
- Entry illustration pieces settle with rotation, translation and scale. Balance/lever interpolate their physical positions, robot traces its command path, circuit lamps fade with a green halo. Existing gears, paper fold and ballistic flight use the shared motion preference.
- System reduced-motion/accessibility preference disables custom spatial animation. Effects are finite and do not write intermediate values into the persisted lesson model.

## Verification

Automated coverage includes all 24 lesson screens at 320px, all eight completion paths, session restoration, real gestures and retry flows, plus route push/pop with reduced motion on/off and action sizing at 320px/1000px with text scales 1x/2x. See `motion-test-output.txt` for the final run.

Native device FPS/120Hz performance has not been measured; web preview is for visual verification.

Final result (2026-10-23): `flutter analyze` reported no issues; all 37 tests passed. Web build succeeded. Browser at 390×844 confirmed compact hero/topic/lesson actions, entering topic and lesson, opening/closing hints, and saving/exiting back to the topic. Browser error log was empty. Screenshots: `motion-home-mobile.jpg`, `motion-topic-mobile.jpg`, `motion-lesson-mobile.jpg`.
