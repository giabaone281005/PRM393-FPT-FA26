# Lesson-depth development iterations

User instruction: iterate plan → implement → test → record findings → plan next change. Keep all work local; do not push.

## Iteration 1 — Explain constraints and reveal help progressively

Problem: 3D activities currently return one generic hint for an incorrect model. Learners cannot distinguish a correct volume from an incorrect surface area, or correct latitude from incorrect longitude.

Plan: add structured, deterministic evaluation for the four spatial activities, returning satisfied constraints and contextual feedback; provide three hint levels and persist the highest level used per activity. Keep original hint tracking for compatibility. Do not infer misconception/mastery from timing, camera rotation or count of attempts.

Acceptance: each constraint can be tested independently; equivalent valid solids remain accepted; malformed state is rejected; hint level survives save/resume; reveal controls fit the existing lesson layout. Keep completion/XP semantics unchanged.

Validation: standalone exhaustive model checks plus focused widget regression. Report unavailable Flutter tooling separately; no claim of mobile render verification without running it.

Implemented: structured evaluators and constraint-specific feedback for four spatial activities; three progressive hints; saved per-activity hint depth with legacy hint compatibility. Added a save/reopen widget regression.

Results: 911 standalone lesson-depth checks passed; 17,552 spatial engine checks and 50 interaction checks remain passing. Full widget/render verification still depends on Flutter SDK/cache access. No cloud content release or evaluator was published by this local iteration.

Status: implementation and standalone validation complete; widget execution pending environment access.

## Iteration 2 — Compare models to discover relationships

Plan after iteration 1: let learners save a reference solid and compare volume/surface while changing dimensions. Preserve that reference with the draft, explain what changes, and ensure comparison state cannot satisfy a target or award XP by itself.

Acceptance: reference copy is independent of subsequent changes; restored reference is validated; controls respect locking; no camera event changes learning data. Run model and widget checks and record remaining limitations before choosing iteration 3.

Implemented: learners can save/replace/remove a reference solid, compare volume and surface changes, and discover equal-volume/different-surface or equal-surface/different-volume cases. Reference state is validated, copied by value and persisted in the experiment draft; it cannot satisfy the current target.

Results: 922 depth checks passed, spatial/interaction regression remains passing, and static analysis of model/guidance is clean. Added a widget regression for saving a reference and changing dimensions. Flutter widget execution remains blocked by SDK cache permissions.

Status: implementation and standalone validation complete; render/widget execution pending environment access.

## Iteration 3 — Transfer fraction reasoning between representations

Plan: extend the same progressive-help interaction to the initial fraction painting activity and the fraction number line. Distinguish invalid state from a valid model that has the wrong fraction; retain three help levels across save/resume. Keep existing completion/XP rules and avoid changing the target using learner state.

Acceptance: all 256 subsets of eight slices are evaluated correctly, every number-line position is tested, malformed state is rejected, multiple valid slice selections remain valid and guidance does not modify the model. No mastery is inferred from using hints or finishing once.

Implemented: fraction-paint and number-line activities now use the same persisted three-level help UI. Fraction number-line evaluation reports valid-position/equivalent-fraction constraints. Feedback locates the selected point relative to the target and explains the numerator/denominator relationship without changing learner state.

Results: 2,491 depth checks passed, including all 256 painted subsets and malformed/edge number-line states; 17,552 spatial checks and 50 diversity checks remain passing. Model/guidance static analysis is clean. Added a widget regression for the number-line hint UI; execution remains blocked by Flutter cache permissions.

Status: implementation and standalone validation complete; widget/render execution pending environment access.

## Iteration 4 — Independent transfer checkpoint and device QA

Next plan: validate the three completed local iterations with Flutter widget tests and 320px/large-text device rendering first; resolve any layout/state issues. Then design an independent fraction transfer checkpoint with immutable versioned variants and explicit distinction between completion and unassisted evidence. No new mastery claim or cloud-verified reward until both model and integrated session tests pass.

Exit criteria: full widget suite executes successfully, save/resume preserves hint/reference state, layout has no overflow, and at least three deterministic checkpoint variants are solvable and restore exactly. This iteration is queued behind the current SDK/cache access blocker; standalone checks do not substitute for UI verification.

Status: planned, integration test environment required before expansion.
