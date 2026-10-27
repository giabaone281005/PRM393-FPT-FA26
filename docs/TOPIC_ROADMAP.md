# Topic prescreen roadmap and interactive colors

The topic prescreen now shows a scrollable roadmap with raised, tilted checkpoint islands, curved connecting paths, depth shadows and finite press/selection animations. Each checkpoint uses its activity palette. Selecting a checkpoint previews its prompt and state; the persistent bottom action starts or resumes the existing learning session. Upcoming previews explicitly identify the checkpoint from which learning resumes. Previewing never changes progress or awards XP.

Completion indicators use credited activity IDs or revalidated checked/touched draft states. A saved `checked` flag with an invalid answer does not show completion. The map updates when the learning store changes. The layout accommodates narrow screens and large text; animation durations honor the existing reduced-motion setting. The depth effect is drawn with native Flutter transforms, gradients and shadows.

Interactive colors now extend beyond the page background: outlined action buttons have colored fills, text and borders; disabled buttons use a distinct muted treatment; sliders, switches and chips inherit subject colors. Math drag tokens and drop targets use the activity palette. Circuit connection selection and switch controls use the palette. Reasoning answer buttons use a strong primary fill when selected and a softer colored fill otherwise. Educational colors such as RGB mixing channels and the diagrams' physical quantities remain tied to their meaning.

Files changed for this update:

- `lib/topic_roadmap.dart`
- `lib/journey_app.dart`
- `lib/lesson_theme.dart`
- `lib/experiments/math_experiments.dart`
- `lib/experiments/discovery_experiments.dart`
- `lib/experiments/reasoning_workspace.dart`
- `test/topic_roadmap_test.dart`
- `test/widget_test.dart`
- This document.

Validation: `flutter analyze` passes and all 160 Flutter tests pass. The five roadmap tests cover validated/invalid completion, preview isolation, resume position, 280px/large-text layout, persistent CTA, reduced motion, actual button/token/slider colors and a real-font render. Existing standalone checks pass: 50 interaction, 2,491 depth and 17,552 spatial checks. The inspected visual preview is generated at `build/topic-roadmap-preview.png`. No database, remote catalog or learning-reward rules were changed.
