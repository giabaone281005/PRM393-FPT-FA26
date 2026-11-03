import 'experiment_model.dart';
import 'math_catalog.dart';
import 'discovery_catalog.dart';
import 'extended_catalog.dart';
import 'diverse_catalog.dart';
import 'solid_catalog.dart';
import 'deep_catalog.dart';
import 'curriculum_catalog.dart';

final _existingCatalog = <String, List<ExperimentSpec>>{
  for (final entry in {...mathExperiments, ...discoveryExperiments}.entries)
    entry.key: [
      ...entry.value,
      ...(extensionExperiments[entry.key] ?? []),
      ...(diverseExperiments[entry.key] ?? []),
      ...(solidExperiments[entry.key] ?? []),
      ...(deepExperiments[entry.key] ?? []),
    ],
  'algebra': [
    ...extensionExperiments['algebra']!,
    ...solidExperiments['algebra']!,
  ],
  'geography': solidExperiments['geography']!,
  'optimization': extensionExperiments['optimization']!,
  'marxism': deepExperiments['marxism']!,
  'painting': deepExperiments['painting']!,
};
final experimentCatalog = <String, List<ExperimentSpec>>{
  for (final entry in _existingCatalog.entries)
    entry.key: [...entry.value, ...?curriculumExtensions[entry.key]],
  ...expandedCurriculum,
};
