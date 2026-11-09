import '../../experiments/experiment_model.dart';
import 'slide_lesson.dart';

/// A declarative lesson; executable code is never loaded from the catalog.
ExperimentSpec? decodeAuthoredLesson(Map row) {
  if (row['evaluator_version'] == 4 && row['mechanism'] == 'slideLesson') {
    final config = row['config'];
    if (config is! Map || !validSlideLesson(config)) return null;
    return ExperimentSpec(
      id: row['activity_id'] as String,
      title: row['title'] as String,
      prompt: row['prompt'] as String,
      hint: (row['hint_levels'] as List).first as String,
      explanation: row['explanation'] as String,
      stage: row['stage'] as String,
      mechanism: 'slideLesson',
      contentVersion: row['content_version'] as int,
      config: Map<String, dynamic>.from(config),
      initial: initialSlideState(config),
      validator: (state) => slideLessonIsCorrect(config, state),
    );
  }
  if (row['evaluator_version'] != 3 || row['mechanism'] != 'reasonedChoice') {
    return null;
  }
  final c = row['config'];
  if (c is! Map || c['choices'] is! List || c['reasons'] is! List) return null;
  if ((c['choices'] as List).any((s) => s is! String) ||
      (c['reasons'] as List).any((s) => s is! String)) {
    return null;
  }
  final choices = List<String>.from(c['choices'] as List);
  final reasons = List<String>.from(c['reasons'] as List);
  final answer = c['answer'], reason = c['reason'];
  if (choices.length < 2 ||
      choices.length > 8 ||
      reasons.length < 2 ||
      reasons.length > 8 ||
      answer is! int ||
      reason is! int ||
      answer < 0 ||
      answer >= choices.length ||
      reason < 0 ||
      reason >= reasons.length) {
    return null;
  }
  return ExperimentSpec(
    id: row['activity_id'] as String,
    title: row['title'] as String,
    stage: row['stage'] as String,
    prompt: row['prompt'] as String,
    hint: (row['hint_levels'] as List).first as String,
    explanation: row['explanation'] as String,
    mechanism: 'reasonedChoice',
    contentVersion: row['content_version'] as int,
    config: {
      ...Map<String, dynamic>.from(c),
      'choices': choices,
      'reasons': reasons,
      'knowledge': c['knowledge'] as String? ?? '',
      'source': c['source'] as String? ?? '',
    },
    initial: const {'answer': -1, 'reason': -1},
    validator: (state) =>
        state['answer'] == answer && state['reason'] == reason,
    evaluator: (state) => EvaluationResult(
      isCorrect: state['answer'] == answer && state['reason'] == reason,
      feedbackKey: state['answer'] != answer
          ? 'rethink-answer'
          : state['reason'] != reason
          ? 'rethink-reason'
          : 'correct',
      satisfiedConstraints: [
        if (state['answer'] == answer) 'answer',
        if (state['reason'] == reason) 'reason',
      ],
    ),
  );
}

ExperimentSpec withLessonText(ExperimentSpec spec, Map row) => ExperimentSpec(
  id: spec.id,
  title: row['title'] as String? ?? spec.title,
  stage: row['stage'] as String? ?? spec.stage,
  prompt: row['prompt'] as String? ?? spec.prompt,
  hint: row['hint_levels'] is List && (row['hint_levels'] as List).isNotEmpty
      ? row['hint_levels'][0] as String
      : spec.hint,
  explanation: row['explanation'] as String? ?? spec.explanation,
  mechanism: spec.mechanism,
  initial: spec.initial,
  config: spec.config,
  validator: spec.validator,
  evaluator: spec.evaluator,
  skillIds: spec.skillIds,
  contentVersion: spec.contentVersion,
  mechanismVersion: spec.mechanismVersion,
);
