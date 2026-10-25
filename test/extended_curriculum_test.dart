import 'dart:convert';

import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/experiments/extended_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'extended_solutions.dart';
import 'math_experiments_test.dart' show mathSolutionStates;

void main() {
  test('Every extension starts unsolved and survives JSON restoration', () {
    for (final spec in extensionExperiments.values.expand((s) => s)) {
      expect(spec.isCorrect(spec.initialData()), false, reason: spec.id);
      expect(spec.isCorrect({}), false, reason: spec.id);
      final restored = (jsonDecode(
        jsonEncode(extendedSolutions[spec.id]),
      ) as Map).cast<String, dynamic>();
      expect(spec.isCorrect(restored), true, reason: spec.id);
    }
  });

  test(
    'Challenges enforce constraints beyond a plausible final appearance',
    () {
      final route = extensionExperiments['coding']!.last;
      expect(
        route.isCorrect(extendedSolutions['coding-shortest']!),
        false,
        reason:
            'A shortest route missing the required checkpoint is insufficient',
      );
      expect(
        extensionExperiments['science']!.first.isCorrect({
          'segments': [2, 0, 2],
        }),
        false,
        reason: 'Same distance but missing final rest',
      );
      expect(
        extensionExperiments['data']!.last.isCorrect({
          'heights': [4, 4, 4],
        }),
        false,
        reason: 'Same mean but wrong distribution',
      );
      expect(
        extensionExperiments['probability']!.last.isCorrect({
          'balls': ['B', 'B', 'B', 'R'],
        }),
        false,
        reason: 'Correct ratio but wrong total',
      );
      expect(
        extensionExperiments['circuits']!.first.isCorrect({
          'rgb': [1, 1, 0],
        }),
        false,
        reason: 'Previous yellow solution must not pass a cyan challenge',
      );
      expect(
        extensionExperiments['geometry']!.last.isCorrect({
          'points': [
            [0, 0],
            [4, 0],
            [4, 2],
            [0, 2],
          ],
        }),
        false,
        reason: 'Correct perimeter but wrong area',
      );
    },
  );

  testWidgets(
    'Configured equation can remove more than the original three pairs',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = (await tester.runAsync(
        () async => LearningStore(await SharedPreferences.getInstance()),
      ))!;
      await tester.runAsync(() => store.createDeviceProfile('An'));
      await tester.runAsync(() => store.saveProgress('logic', {'step': 3}));
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: LessonPage(topic: topicById('logic'), store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('4/6'), findsOneWidget);
      expect(find.text('x + 5 = 9'), findsOneWidget);
      final button = find.byKey(const ValueKey('remove-pair'));
      for (int i = 0; i < 5; i++) {
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
      }
      expect(find.text('x + 0 = 4'), findsOneWidget);
      final check = find.text('Kiểm tra');
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(find.text('Bạn đã tìm ra!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      store.dispose();
    },
  );

  testWidgets('Previous completion opens new material and retains earned XP', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = (await tester.runAsync(
      () async => LearningStore(await SharedPreferences.getInstance()),
    ))!;
    await tester.runAsync(() => store.createDeviceProfile('An'));
    final topic = topicById('logic');
    final foundation = topic.experiments.take(3).toList();
    await tester.runAsync(
      () => store.finish(
        'logic',
        experiments: foundation,
        draft: {'states': mathSolutionStates},
      ),
    );
    expect(store.points, 30);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LessonPage(topic: topic, store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ExperimentWorkspace>(find.byType(ExperimentWorkspace))
          .spec
          .id,
      'logic-invariant',
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(
      () => store.finish(
        'logic',
        experiments: topic.experiments,
        draft: {
          'states': {
            'logic-invariant': extendedSolutions['logic-invariant'],
            'logic-hidden': extendedSolutions['logic-hidden'],
            'logic-counterexample': extendedSolutions['logic-counterexample'],
          },
        },
      ),
    );
    expect(store.points, 30);
    expect(
      store.completedExperimentIds('logic'),
      containsAll(topic.experiments.map((s) => s.id)),
    );
    final restored = (await tester.runAsync(
      () async => LearningStore(await SharedPreferences.getInstance()),
    ))!;
    expect(restored.completedExperimentIds('logic'), hasLength(6));
    restored.dispose();
    store.dispose();
  });
}
