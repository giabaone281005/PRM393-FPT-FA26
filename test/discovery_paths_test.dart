import 'extended_solutions.dart';

import 'package:brilliant_mobile/discovery_paths.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'math_experiments_test.dart' show mathSolutionStates;

void main() {
  late LearningStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LearningStore(await SharedPreferences.getInstance());
  });
  tearDown(() => store.dispose());

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Path map opens an interactive topic and preserves its saved step at 320px',
    (tester) async {
      phone(tester);
      await tester.runAsync(() async {
        await store.createDeviceProfile('An');
        await store.finishOnboarding(['math'], 10);
        await store.saveProgress('math', {
          'version': 3,
          'step': 1,
          'states': <String, dynamic>{},
          'touched': <String>[],
          'checked': <String>[],
          'hints': <String>[],
        });
      });
      await tester.pumpWidget(
        MaterialApp(
          home: LearningPathsPage(
            store: store,
            onOpen: (context, topic) => openTopic(context, topic, store),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LearningPathsPage), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('path-topic-math')));
      expect(find.byType(TopicPage), findsOneWidget);
      final page = tester.widget<TopicPage>(find.byType(TopicPage));
      expect(page.topic.id, 'math');
      expect(store.progress('math')!['step'], 1);
      Navigator.pop(tester.element(find.byType(TopicPage)));
      await tester.pumpAndSettle();
      expect(find.byType(LearningPathsPage), findsOneWidget);
      expect(store.points, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Review suggestions use real practice history and never award XP on navigation',
    (tester) async {
      phone(tester);
      await tester.runAsync(() async {
        await store.createDeviceProfile('An');
        await store.finishOnboarding(['logic'], 10);
        final topic = topicById('logic');
        await store.finish(
          topic.id,
          experiments: topic.experiments,
          draft: {
            'states': {
              for (final s in topic.experiments)
                s.id: (mathSolutionStates[s.id] ?? extendedSolutions[s.id]),
            },
            'attempts': 8,
            'hints': [topic.experiments[0].id, topic.experiments[1].id],
            'seconds': 120,
          },
        );
      });
      await tester.pumpWidget(LearnApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('Chọn chủ đề'), findsOneWidget);
      await tap(tester, find.text('Chủ đề'));
      await tap(tester, find.byKey(const ValueKey('topic-filter-completed')));
      await tap(tester, find.byKey(const ValueKey('topic-logic')));
      expect(
        tester.widget<TopicPage>(find.byType(TopicPage)).topic.id,
        'logic',
      );
      expect(store.points, 30);
      expect(store.history.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
