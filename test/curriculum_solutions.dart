import 'package:brilliant_mobile/experiments/curriculum_catalog.dart';
import 'package:brilliant_mobile/experiments/experiment_model.dart';

/// Representative complete states; independent semantic/interaction tests live
/// in expanded_learning_test.dart rather than relying on these smoke fixtures.
Map<String, dynamic> curriculumSolution(ExperimentSpec s) {
  final c = s.config;
  switch (s.mechanism) {
    case 'evidenceBoard':
      return {'selected': List<int>.from(c['target'] as List)};
    case 'speechPractice':
      return {'response': (c['accepted'] as List).first};
    case 'listeningChoice':
      return {'experienced': true, 'answer': c['target']};
    case 'causalExperiment':
      final goal = c['goal'] as int;
      for (var x = 0; x <= 3; x++) {
        for (var y = 0; y <= 3; y++) {
          if (x * y == goal) {
            return {
              'x': x,
              'y': y,
              'prediction': goal,
              'observed': [x, y, goal],
              'trials': [
                [x, y, goal],
              ],
            };
          }
        }
      }
      throw StateError('Unsatisfiable model ${s.id}');
    case 'resourceBudget':
      final values = List<int>.from(c['minima'] as List);
      values[0] += 10 - values.reduce((a, b) => a + b);
      return {'values': values};
    default:
      return {'values': List<int>.from(c['target'] as List)};
  }
}

final curriculumSolutionStates = <String, Map<String, dynamic>>{
  for (final s in [
    ...expandedCurriculum.values.expand((v) => v),
    ...curriculumExtensions.values.expand((v) => v),
  ])
    s.id: curriculumSolution(s),
};
