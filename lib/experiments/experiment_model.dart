import 'dart:convert';

typedef ExperimentData = Map<String, dynamic>;
typedef ExperimentValidator = bool Function(ExperimentData);
typedef ExperimentEvaluator = EvaluationResult Function(ExperimentData);

class EvaluationResult {
  const EvaluationResult({
    required this.isCorrect,
    this.misconceptionCodes = const [],
    this.satisfiedConstraints = const [],
    this.feedbackKey = 'try-again',
  });
  final bool isCorrect;
  final List<String> misconceptionCodes, satisfiedConstraints;
  final String feedbackKey;
}

class ExperimentSpec {
  const ExperimentSpec({
    required this.id,
    required this.title,
    required this.prompt,
    required this.hint,
    required this.explanation,
    required this.mechanism,
    required this.initial,
    required this.validator,
    this.stage = 'Khám phá',
    this.config = const {},
    this.evaluator,
    this.skillIds = const [],
    this.contentVersion = 1,
    this.mechanismVersion = 1,
  });
  final String id, title, prompt, hint, explanation, mechanism;
  final ExperimentData initial;
  final ExperimentValidator validator;
  final String stage;
  final ExperimentEvaluator? evaluator;
  final List<String> skillIds;
  final int contentVersion, mechanismVersion;

  EvaluationResult evaluate(ExperimentData data) {
    try {
      return evaluator?.call(data) ??
          EvaluationResult(isCorrect: validator(data));
    } catch (_) {
      return const EvaluationResult(
        isCorrect: false,
        feedbackKey: 'invalid-state',
      );
    }
  }

  /// Scene parameters belong to the lesson, never to mutable learner state.
  final ExperimentData config;
  ExperimentData initialData() =>
      (jsonDecode(jsonEncode(initial)) as Map).cast<String, dynamic>();
  bool isCorrect(ExperimentData data) {
    try {
      return evaluate(data).isCorrect;
    } catch (_) {
      return false;
    }
  }
}
