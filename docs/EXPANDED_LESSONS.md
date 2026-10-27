# Local curriculum expansion

The catalog now contains 13 topics and 71 activities (18 added). Stable IDs and ordering of the original activities are preserved. Coding's six Python reading activities follow its existing interactive activities.

Each new activity includes a concept note, a scenario, an answer and a separate justification, a hint, an explanation and a named source. Both answer and justification must be correct. State is stored through the existing lesson draft/completion flow. These are introductory lessons; the Python exercises ask learners to trace code rather than execute it.

## Added content

- Marxism–Leninism: sources and components; material conditions; forces and relations of production; surplus-value model; social change; critical source reading. The course describes claims in their historical/theoretical context and distinguishes understanding from agreement.
- Painting: value; form and light; overlap and depth; emphasis; rhythm; visual evidence in critique.
- Python: variable tracing; branch boundaries; accumulation; list aliasing; function return; boundary tests.

## Sources

- [Lenin, The Three Sources and Three Component Parts of Marxism (1913), Marxists Internet Archive](https://www.marxists.org/archive/lenin/works/1913/mar/x01.htm).
- [Marx, Preface to A Contribution to the Critique of Political Economy (1859)](https://www.marxists.org/archive/marx/works/1859/critique-pol-economy/preface.htm).
- [Getty Museum, Elements of Art](https://www.getty.edu/education/teachers/building_lessons/formal_analysis.html) and [Principles of Design](https://www.getty.edu/education/teachers/building_lessons/formal_analysis2.html).
- [Python Tutorial: Control Flow](https://docs.python.org/3/tutorial/controlflow.html) and [Data Structures](https://docs.python.org/3/tutorial/datastructures.html).

Examples, numerical scenarios and Vietnamese explanations were authored for this app; they are not quotations or a complete academic syllabus.

## Validation and boundary

`flutter analyze` passes; all 152 Flutter tests pass. Tests include all nine answer/reason combinations per new activity, malformed states, JSON restoration, locked controls, small-screen layout, persisted drafts, and complete lesson flows for all 13 topics. Existing standalone checks pass: 50 interaction, 2,491 depth, 17,552 spatial checks. All 729 parity cases across the original 53 published server activities pass. The configured Android debug APK builds successfully. `git diff --check` passes.

This expansion is local mobile content. No schema, published server catalog or deployed evaluator is changed. The parity export remains scoped to the original server release; new activities are validated by the local lesson tests. A server content release is a separate task.

Changed files: `lib/experiments/deep_catalog.dart`, `lib/experiments/reasoning_workspace.dart`, `lib/experiments/contextual_guidance.dart`, `lib/learning_catalog.dart`, `lib/journey_app.dart`, `lib/discovery_paths.dart`, `lib/topic_illustration.dart`, `lib/data/models/learning_modules.dart`, `lib/data/repositories/catalog_roadmaps.dart`, `test/deep_solutions.dart`, `test/deep_lessons_test.dart`, `test/widget_test.dart`, `test/engine_registry_test.dart`, `test/server_evaluator_export_test.dart`, and this document.
