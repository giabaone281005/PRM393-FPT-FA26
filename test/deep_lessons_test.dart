import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/experiments/deep_catalog.dart';
import 'package:brilliant_mobile/experiments/experiment_model.dart';
import 'package:brilliant_mobile/experiments/reasoning_workspace.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';

import 'deep_solutions.dart';

void main() {
  test(
    'every new lesson requires the correct answer and independent reason',
    () {
      final lessons = deepExperiments.values.expand((v) => v).toList();
      expect(lessons.length, 18);
      for (final spec in lessons) {
        expect(spec.isCorrect(spec.initialData()), false, reason: spec.id);
        expect(spec.isCorrect(deepSolutions[spec.id]!), true, reason: spec.id);
        for (var a = 0; a < 3; a++) {
          for (var r = 0; r < 3; r++) {
            final state = {'answer': a, 'reason': r};
            expect(
              spec.isCorrect(state),
              a == deepSolutions[spec.id]!['answer'] &&
                  r == deepSolutions[spec.id]!['reason'],
              reason: '${spec.id} $state',
            );
          }
        }
        for (final field in ['answer', 'reason']) {
          for (final bad in [null, '0', 0.0, -1, 3, true, <int>[]]) {
            expect(
              spec.isCorrect({...deepSolutions[spec.id]!, field: bad}),
              false,
              reason: '${spec.id} $field=$bad',
            );
          }
        }
        expect(spec.config['knowledge'], isNotEmpty);
        expect(spec.config['source'], isNotEmpty);
      }
      expect(topicById('coding').experiments.take(3).map((s) => s.id), [
        'coding-route',
        'coding-loop',
        'coding-sort',
      ]);
      expect(topics.first.id, 'logic');
    },
  );

  test(
    'new topics persist drafts and validate all activities before completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LearningStore(prefs);
      await store.createDeviceProfile('An');
      for (final topicId in ['painting', 'marxism']) {
        final topic = topicById(topicId);
        final draft = <String, dynamic>{
          'step': 2,
          'states': {
            for (final spec in topic.experiments)
              spec.id: deepSolutions[spec.id],
          },
          'touched': topic.experiments.map((s) => s.id).toList(),
          'checked': topic.experiments.map((s) => s.id).toList(),
          'attempts': 6,
          'hints': [],
          'seconds': 120,
        };
        await store.saveProgress(topicId, draft);
        final restored = LearningStore(prefs);
        expect(restored.progress(topicId)!['states'], draft['states']);
        final receipt = await restored.finish(
          topicId,
          experiments: topic.experiments,
          draft: draft,
        );
        expect(receipt.awarded, true);
        expect(restored.completed, contains(topicId));
      }
    },
  );

  testWidgets(
    'reasoning workspace fits 320px, restores selections and locks changes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final spec = deepExperiments['coding']!.first;
      ExperimentData data = spec.initialData();
      var locked = false;
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.4)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ReasoningWorkspace(
                        spec: spec,
                        data: data,
                        locked: locked,
                        onChanged: (value) => setState(() => data = value),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      for (final key in ['answer-1', 'reason-2']) {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }
      expect(spec.isCorrect(data), true);
      rebuild(() {
        data = (jsonDecode(jsonEncode(data)) as Map).cast<String, dynamic>();
        locked = true;
      });
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('answer-1')))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
