import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/experiments/math_catalog.dart';
import 'package:brilliant_mobile/experiments/math_experiments.dart';

const mathSolutionStates = <String, Map<String, dynamic>>{
  'logic-balance': {'blocks': 4},
  'logic-remove': {'pairs': 3},
  'logic-gears': {'turns': 2},
  'math-paint': {
    'painted': [0, 1, 2],
  },
  'math-fold': {'folds': 2},
  'math-share': {
    'baskets': [3, 3, 3],
  },
  'science-launch': {'angle': 45, 'launched': true},
  'science-motion': {
    'segments': [2, 0, 1],
  },
  'science-lever': {'position': 3},
  'data-sort': {
    'order': [1, 2, 3, 4],
  },
  'data-bins': {
    'bins': [0, 0, 1, 1, 2, 2],
  },
  'data-mean': {
    'heights': [4, 4, 4],
  },
};

void main() {
  test(
    'All twelve math experiments require work and accept durable solutions',
    () {
      final specs = mathExperiments.values.expand((v) => v).toList();
      expect(specs.length, 12);
      expect(specs.map((s) => s.mechanism).toSet().length, 12);
      for (final spec in specs) {
        expect(spec.isCorrect(spec.initialData()), isFalse, reason: spec.id);
        final restored = (jsonDecode(
          jsonEncode(mathSolutionStates[spec.id]),
        ) as Map).cast<String, dynamic>();
        expect(spec.isCorrect(restored), isTrue, reason: spec.id);
        expect(spec.isCorrect({}), isFalse, reason: spec.id);
      }
      expect(
        mathExperiments['math']!.first.isCorrect({
          'painted': [8, 9, 10],
        }),
        isFalse,
      );
      expect(
        mathExperiments['data']!.last.isCorrect({
          'heights': [5, 5, 5],
        }),
        isFalse,
      );
    },
  );

  testWidgets(
    'Every experiment fits a 240px surface and emits no state in build',
    (tester) async {
      for (final spec in mathExperiments.values.expand((v) => v)) {
        var changes = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 240,
                    child: MathExperiment(
                      key: ValueKey(spec.id),
                      spec: spec,
                      data: spec.initialData(),
                      locked: false,
                      onChanged: (_) => changes++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: spec.id);
        expect(changes, 0, reason: spec.id);
      }
    },
  );

  testWidgets('Tap alternatives edit balance, fold, and fraction state', (
    tester,
  ) async {
    for (final entry in {
      'logic-balance': 'balance-drop',
      'math-fold': 'fold-again',
      'math-paint': 'paint-0',
    }.entries) {
      final spec = mathExperiments.values
          .expand((v) => v)
          .firstWhere((s) => s.id == entry.key);
      Map<String, dynamic>? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MathExperiment(
                spec: spec,
                data: spec.initialData(),
                locked: false,
                onChanged: (data) => result = data,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(ValueKey(entry.value)));
      expect(result, isNotNull, reason: entry.key);
      expect(result, isNot(equals(spec.initial)), reason: entry.key);
    }
  });
}
