# Lesson appearance

Lessons now use a subject palette and a deterministic variation for each activity index. The background, title, stage label, progress, primary action, hints and answer controls share that palette. Reopening the same activity restores the same palette without writing appearance data into learning progress.

Topic seeds: logic violet; fractions blue; science terracotta; data forest green; geometry ocean blue; coding teal; circuits ochre; probability rose; algebra purple; optimization olive; geography emerald; Marxism–Leninism burgundy; painting magenta. Each activity shifts the seed hue slightly. Flutter's seeded color schemes provide matching text, surface and control colors in both brightness modes.

The lesson theme is scoped to the lesson route. Existing app typography, text scaling and motion preferences remain inherited. It does not change the user's global appearance preference or introduce a new dark-mode setting. The light drawing surface of existing experimental canvases is preserved because their diagrams use fixed educational colors. New reasoning activities use the lesson's brightness for their complete surface, code panel and selections. Correct/incorrect feedback remains identifiable by its icon and wording.

Implementation files: `lib/lesson_theme.dart`, `lib/journey_app.dart`, `lib/app_theme.dart`, `lib/experiments/reasoning_workspace.dart`. Tests: `test/lesson_theme_test.dart`.

Validation: all 155 Flutter tests passed; the final answer-control icon adjustment also passed the six focused lesson/theme tests. Static analysis passes. Tests cover palette assignment for all 13 subjects, distinct colors for all 71 activities, deterministic reopening, minimum 4.5:1 contrast for principal text/color pairs in both brightness modes, next-activity color changes, progress persistence and theme scoping. Real-font 320px renders with 1.3 text scale were inspected for the three added subject areas. Preview PNGs are generated under `build/lesson-<topic>-<brightness>.png`. Existing standalone validation passes (50 interaction, 2,491 depth, 17,552 spatial checks).
