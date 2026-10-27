import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_mobile/learning_catalog.dart';

import 'math_experiments_test.dart' show mathSolutionStates;
import 'discovery_experiments_test.dart' show discoverySolutionStates;
import 'extended_solutions.dart';

void main() {
  test('export server parity corpus for all 53 activities', () {
    final solutions = {
      ...mathSolutionStates,
      ...discoverySolutionStates,
      ...extendedSolutions,
    };
    final cases = <Map<String, dynamic>>[];
    for (final topic in topics) {
      for (final spec in topic.experiments) {
        // This corpus targets the 53 published server activities. New local
        // lessons have separate exhaustive tests until a server release exists.
        if (spec.mechanism == 'reasonedChoice') continue;
        expect(solutions.containsKey(spec.id), true, reason: spec.id);
        expect(spec.isCorrect(solutions[spec.id]!), true, reason: spec.id);
        final candidates = [
          spec.initialData(),
          solutions[spec.id]!,
          <String, dynamic>{},
          for (final key in solutions[spec.id]!.keys)
            for (final value in [null, 'invalid', -999, false, <dynamic>[]])
              {...solutions[spec.id]!, key: value},
          if (spec.mechanism == 'solidExplorer')
            for (var w = 1; w <= 5; w++)
              for (var h = 1; h <= 5; h++)
                for (var d = 1; d <= 5; d++)
                  {'width': w, 'height': h, 'depth': d},
        ];
        for (final state in candidates) {
          // Compare durable JSON state, the actual wire protocol.
          final restored = (jsonDecode(jsonEncode(state)) as Map)
              .cast<String, dynamic>();
          final result = spec.evaluate(restored);
          cases.add({
            'request': {
              'activity_id': spec.id,
              'content_version': spec.contentVersion,
              'state': state,
            },
            'expected': {
              'is_correct': result.isCorrect,
              'misconception_codes': result.misconceptionCodes,
              'satisfied_constraints': result.satisfiedConstraints,
              'feedback_key': result.feedbackKey,
              'mechanism': spec.mechanism,
              'evaluator_version': 1,
              'config': spec.config,
              'initial_state': spec.initial,
            },
          });
        }
      }
    }
    expect(solutions.length, 53);
    Directory('build').createSync(recursive: true);
    File('build/server_evaluator_cases.json')
        .writeAsStringSync(jsonEncode(cases));
  });
}
