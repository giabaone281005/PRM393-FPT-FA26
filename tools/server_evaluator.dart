// Compile the existing pure Dart evaluators for the Supabase Edge runtime.
// No Flutter dependency and no client-supplied correctness/score is accepted.
// Preserve relative library URIs: changing them changes dart2js minifier ordering
// and the pinned implementation hash even when evaluator behavior is unchanged.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:js_interop';

import '../lib/experiments/experiment_model.dart';
import '../lib/experiments/math_catalog.dart';
import '../lib/experiments/discovery_catalog.dart';
import '../lib/experiments/extended_catalog.dart';
import '../lib/experiments/diverse_catalog.dart';
import '../lib/experiments/solid_catalog.dart';

@JS('globalThis.matlingoEvaluate')
external set _evaluate(JSFunction function);

final _catalog = <String, List<ExperimentSpec>>{
  for (final entry in {...mathExperiments, ...discoveryExperiments}.entries)
    entry.key: [
      ...entry.value,
      ...(extensionExperiments[entry.key] ?? []),
      ...(diverseExperiments[entry.key] ?? []),
      ...(solidExperiments[entry.key] ?? []),
    ],
  'algebra': [
    ...extensionExperiments['algebra']!,
    ...solidExperiments['algebra']!,
  ],
  'geography': solidExperiments['geography']!,
  'optimization': extensionExperiments['optimization']!,
};

JSString _run(JSString input) {
  try {
    final request = jsonDecode(input.toDart) as Map<String, dynamic>;
    final spec = _catalog.values
        .expand((v) => v)
        .firstWhere(
          (s) =>
              s.id == request['activity_id'] &&
              s.contentVersion == request['content_version'],
        );
    final state = request['state'] as Map<String, dynamic>;
    final result = spec.evaluate(state);
    return jsonEncode({
      'is_correct': result.isCorrect,
      'misconception_codes': result.misconceptionCodes,
      'satisfied_constraints': result.satisfiedConstraints,
      'feedback_key': result.feedbackKey,
      'mechanism': spec.mechanism,
      'evaluator_version': 1,
      'config': spec.config,
      'initial_state': spec.initial,
    }).toJS;
  } catch (_) {
    return jsonEncode({'error': 'unsupported_activity_or_invalid_state'}).toJS;
  }
}

void main() => _evaluate = _run.toJS;
