import 'extended_solutions.dart';

import 'package:brilliant_mobile/learning_activity.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'math_experiments_test.dart' show mathSolutionStates;

void main() {
  testWidgets('Simple profile switches daily totals and fits a small screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = LearningStore(await SharedPreferences.getInstance());
    await store.createDeviceProfile('An');
    await store.finishOnboarding(['logic'], 10);
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    await store.saveProgress('logic', {
      'step': 1,
      'activeMsByDay': {
        activityDay(today): 90000,
        activityDay(yesterday): 180000,
      },
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(280, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    await tester.pumpWidget(LearnApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('1 phút 30 giây'), findsOneWidget);
    expect(find.text('7 ngày gần đây'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(ValueKey('activity-${activityDay(yesterday)}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('activity-${activityDay(yesterday)}')),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 phút'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  test(
    'Foreground time splits at local midnight and skips zero elapsed time',
    () {
      final totals = <String, dynamic>{};
      addActiveTime(totals, DateTime(2026, 10, 24, 0, 0, 15), 30000);
      expect(totals, {'2026-10-23': 15000, '2026-10-24': 15000});
      addActiveTime(totals, DateTime(2026, 10, 24, 0, 0, 15), 0);
      expect(totals['2026-10-24'], 15000);
    },
  );

  test('Daily totals survive saves, completion, review, reload and profile changes', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = LearningStore(preferences);
    await store.createDeviceProfile('An');
    final owner = store.profile!.id;
    final now = DateTime.now();
    final day = activityDay(now);
    Map<String, dynamic> draft(int ms) => {
      'states': {
        for (final spec in topicById('logic').experiments)
          spec.id: (mathSolutionStates[spec.id] ?? extendedSolutions[spec.id]),
      },
      'activeMsByDay': {day: ms},
      'seconds': ms ~/ 1000,
    };
    await store.saveProgress('logic', draft(90000));
    await store.saveProgress('logic', draft(90000));
    expect(store.activityOn(now).activeMs, 90000);
    await store.saveProgress('logic', draft(150000));
    await store.finish(
      'logic',
      experiments: topicById('logic').experiments,
      draft: draft(150000),
    );
    expect(store.activityOn(now).activeMs, 150000);
    expect(store.activityOn(now).sessions, 1);
    await store.saveProgress('logic', draft(45000));
    await store.finish(
      'logic',
      experiments: topicById('logic').experiments,
      draft: draft(45000),
    );
    expect(store.activityOn(now).activeMs, 195000);
    expect(store.activityOn(now).sessions, 2);
    expect(store.activityOn(now).xp, 30);
    final restored = LearningStore(preferences);
    expect(restored.activityOn(now).activeMs, 195000);
    await restored.createDeviceProfile('Bình');
    expect(restored.activityOn(now).hasActivity, false);
    await restored.activateProfile(owner);
    expect(restored.activityOn(now).sessions, 2);
    store.dispose();
    restored.dispose();
  });

  test(
    'Failed completion does not add a daily completion or duplicate time',
    () async {
      SharedPreferences.setMockInitialValues({});
      var fail = false;
      final store = LearningStore(
        await SharedPreferences.getInstance(),
        writeSnapshot: (_, _) async => !fail,
      );
      await store.createDeviceProfile('An');
      final now = DateTime.now();
      final draft = {
        'states': {
          for (final spec in topicById('logic').experiments)
            spec.id:
                (mathSolutionStates[spec.id] ?? extendedSolutions[spec.id]),
        },
        'activeMsByDay': {activityDay(now): 60000},
      };
      await store.saveProgress('logic', draft);
      fail = true;
      await expectLater(
        store.finish(
          'logic',
          experiments: topicById('logic').experiments,
          draft: draft,
        ),
        throwsStateError,
      );
      expect(store.activityOn(now).sessions, 0);
      expect(store.activityOn(now).activeMs, 60000);
      fail = false;
      await store.finish(
        'logic',
        experiments: topicById('logic').experiments,
        draft: draft,
      );
      expect(store.activityOn(now).sessions, 1);
      expect(store.activityOn(now).activeMs, 60000);
      store.dispose();
    },
  );
}
