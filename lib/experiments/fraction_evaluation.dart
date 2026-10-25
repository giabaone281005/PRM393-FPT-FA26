import 'experiment_model.dart';

EvaluationResult evaluateFractionLine(ExperimentData data) {
  final position = data['position'];
  if (position is! int || position < 0 || position > 8) {
    return const EvaluationResult(
      isCorrect: false,
      feedbackKey: 'invalid-state',
    );
  }
  return EvaluationResult(
    isCorrect: position == 6,
    satisfiedConstraints: [
      'valid-position',
      if (position == 6) 'equivalent-fraction',
    ],
    feedbackKey: position == 6 ? 'fraction-match' : 'fraction-position',
  );
}

/// Only observable constraint failures are recorded; a count error alone does
/// not establish a conceptual misconception.
EvaluationResult evaluateFractionPaint(ExperimentData data) {
  final painted = data['painted'];
  if (painted is! List ||
      painted.any((v) => v is! int || v < 0 || v >= 8) ||
      painted.toSet().length != painted.length) {
    return const EvaluationResult(
      isCorrect: false,
      feedbackKey: 'invalid-state',
    );
  }
  final correct = painted.length == 3;
  return EvaluationResult(
    isCorrect: correct,
    satisfiedConstraints: ['valid-slices', if (correct) 'target-fraction'],
    feedbackKey: correct ? 'fraction-match' : 'fraction-count',
  );
}
