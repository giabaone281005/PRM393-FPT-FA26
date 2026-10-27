import 'extended_solutions.dart';
import 'deep_solutions.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/entry_flow.dart';

import 'math_experiments_test.dart' show mathSolutionStates;
import 'discovery_experiments_test.dart' show discoverySolutionStates;

final solutions = {
  ...deepSolutions,
  ...mathSolutionStates,
  ...discoverySolutionStates,
  ...extendedSolutions,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LearningStore store;
  setUpAll(() async {
    for (final family in ['CofoBrilliant', 'NotoSans']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    for (final family in ['CofoRobert', 'NotoSerif']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family-Medium.ttf'))).load();
    }
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LearningStore(await SharedPreferences.getInstance());
  });
  Future<void> learner() async {
    await store.createDeviceProfile('An');
    await store.finishOnboarding(['geometry', 'coding'], 10);
  }

  Map<String, dynamic> solvedDraft(LearningTopic topic) => {
    'step': 2,
    'states': {
      for (final spec in topic.experiments) spec.id: solutions[spec.id],
    },
    'touched': topic.experiments.map((s) => s.id).toList(),
    'checked': topic.experiments.map((s) => s.id).toList(),
    'attempts': 3,
    'hints': [],
    'seconds': 95,
  };
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  void screen(WidgetTester tester, [Size size = const Size(390, 1000)]) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('Catalog has thirteen topics, 71 activities and 31 mechanisms', () {
    final specs = experimentCatalog.values.expand((e) => e).toList();
    expect(topics.length, 13);
    expect(specs.length, 71);
    expect(specs.map((e) => e.id).toSet().length, 71);
    expect(specs.map((e) => e.mechanism).toSet().length, 31);
    for (final spec in specs) {
      expect(spec.isCorrect(spec.initialData()), false, reason: spec.id);
      expect(spec.isCorrect(solutions[spec.id]!), true, reason: spec.id);
      expect(spec.isCorrect({}), false, reason: spec.id);
    }
  });
  test('Session and onboarding survive a fresh store instance', () async {
    expect(store.hasSession, false);
    await learner();
    final id = store.profile!.id;
    final restored = LearningStore(await SharedPreferences.getInstance());
    expect(restored.profile!.id, id);
    expect(restored.profile!.name, 'An');
    expect(restored.profile!.interests, ['geometry', 'coding']);
    expect(restored.profile!.onboarded, true);
    await restored.signOut();
    final signedOut = LearningStore(await SharedPreferences.getInstance());
    expect(signedOut.hasSession, false);
    expect(signedOut.profiles.length, 1);
    await signedOut.activateProfile(id);
    expect(signedOut.profile!.name, 'An');
  });
  test('Drafts, completion and XP remain isolated across profiles', () async {
    await learner();
    final first = store.profile!.id;
    await store.saveProgress('geometry', {
      'step': 1,
      'states': {
        'geometry-mirror': {
          'cells': [11],
        },
      },
    });
    expect(
      await store
          .finish(
            'logic',
            experiments: topics.first.experiments,
            draft: solvedDraft(topics.first),
          )
          .then((receipt) => receipt.awarded),
      true,
    );
    await store.createDeviceProfile('Bình');
    expect(store.points, 0);
    expect(store.progress('geometry'), isNull);
    await store.saveProgress('math', {'step': 0});
    await store.activateProfile(first);
    expect(store.points, 30);
    expect(store.progress('geometry')!['step'], 1);
    expect(store.progress('math'), isNull);
    expect(
      await store
          .finish(
            'logic',
            experiments: topics.first.experiments,
            draft: solvedDraft(topics.first),
          )
          .then((receipt) => receipt.awarded),
      false,
    );
    expect(store.points, 30);
    expect(store.history.length, 2);
    expect(store.history.first['xp'], 0);
  });
  test('Finishing rejects unsolved states and serializes queued writes before logout', () async {
    await learner();
    await expectLater(
      store.finish(
        'logic',
        experiments: topics.first.experiments,
        draft: {'states': {}, 'seconds': 0},
      ),
      throwsStateError,
    );
    expect(store.points, 0);
    final writes = [
      for (int i = 0; i < 12; i++)
        store.saveProgress('logic', {
          'step': 0,
          'states': {
            'logic-balance': {'blocks': i},
          },
        }),
    ];
    await store.signOut();
    await Future.wait(writes);
    final restored = LearningStore(await SharedPreferences.getInstance());
    expect(restored.hasSession, false);
    await restored.activateProfile(restored.profiles.first.id);
    expect(
      (restored.progress('logic')!['states'] as Map)['logic-balance']['blocks'],
      11,
    );
  });
  test('Legacy XP is retained without trusting old exercise answers', () async {
    SharedPreferences.setMockInitialValues({
      'completed': ['logic'],
      'progress:math': jsonEncode({'step': 2, 'correct': true}),
    });
    final legacy = LearningStore(await SharedPreferences.getInstance());
    await legacy.flush();
    expect(legacy.hasSession, false);
    await legacy.activateProfile(legacy.profiles.first.id);
    expect(legacy.points, 30);
    expect(legacy.progress('math')!['step'], 0);
    expect(legacy.progress('math')!['states'], isEmpty);
  });
  test(
    'A failed durable completion retains the draft and awards once after retry',
    () async {
      final prefs = await SharedPreferences.getInstance();
      var failWrites = false;
      final guarded = LearningStore(
        prefs,
        writeSnapshot: (key, value) async =>
            failWrites ? false : prefs.setString(key, value),
      );
      await guarded.createDeviceProfile('An');
      final owner = guarded.profile!.id;
      final draft = solvedDraft(topics.first);
      await guarded.saveProgress('logic', draft);
      failWrites = true;
      await expectLater(
        guarded.finish(
          'logic',
          experiments: topics.first.experiments,
          draft: draft,
          expectedProfileId: owner,
        ),
        throwsStateError,
      );
      expect(guarded.points, 0);
      expect(guarded.progress('logic'), isNotNull);
      expect(guarded.history, isEmpty);
      expect(guarded.saveError, isNotNull);
      failWrites = false;
      final receipt = await guarded.finish(
        'logic',
        experiments: topics.first.experiments,
        draft: draft,
        expectedProfileId: owner,
      );
      expect(receipt.awarded, true);
      expect(receipt.ownerId, owner);
      expect(guarded.points, 30);
      expect(guarded.progress('logic'), isNull);
    },
  );
  test('An old lesson cannot finish into a newly active profile', () async {
    await learner();
    final owner = store.profile!.id;
    await store.createDeviceProfile('Người khác');
    await expectLater(
      store.finish(
        'logic',
        experiments: topics.first.experiments,
        draft: solvedDraft(topics.first),
        expectedProfileId: owner,
      ),
      throwsStateError,
    );
    expect(store.points, 0);
    expect(store.history, isEmpty);
  });

  testWidgets('Entry to onboarding to dashboard, logout and return', (
    tester,
  ) async {
    screen(tester, const Size(320, 800));
    await tester.pumpWidget(LearnApp(store: store));
    expect(find.byType(EntryPage), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('entry-name')), 'Linh');
    await tap(tester, find.byKey(const ValueKey('entry-create')));
    expect(find.byType(OnboardingPage), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('interest-geometry')));
    await tap(tester, find.byKey(const ValueKey('onboarding-continue')));
    await tap(tester, find.byKey(const ValueKey('minutes-10')));
    await tap(tester, find.byKey(const ValueKey('onboarding-continue')));
    expect(find.byType(HomeShell), findsOneWidget);
    final id = store.profile!.id;
    await tap(tester, find.text('Hồ sơ'));
    await tap(tester, find.text('Đóng phiên & đổi hồ sơ'));
    expect(find.byType(EntryPage), findsOneWidget);
    await tap(tester, find.byKey(ValueKey('profile-$id')));
    expect(find.byType(HomeShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final topic in topics) {
    testWidgets(
      '${topic.id}: full lesson saves every step and completes with 30 XP',
      (tester) async {
        screen(tester);
        await tester.runAsync(learner);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: LessonPage(topic: topic, store: store),
          ),
        );
        await tester.pumpAndSettle();
        for (int i = 0; i < topic.experiments.length; i++) {
          final spec = topic.experiments[i];
          final workspace = tester.widget<ExperimentWorkspace>(
            find.byType(ExperimentWorkspace),
          );
          expect(workspace.spec.id, spec.id);
          workspace.onChanged(solutions[spec.id]!);
          await tester.pumpAndSettle();
          await tap(tester, find.text('Kiểm tra'));
          expect(find.text('Bạn đã tìm ra!'), findsOneWidget);
          expect(store.progress(topic.id)!['step'], i);
          await tap(
            tester,
            find.text(
              i == topic.experiments.length - 1
                  ? 'Hoàn thành hành trình'
                  : 'Khám phá tiếp',
            ),
          );
        }
        expect(store.completed, contains(topic.id));
        expect(store.points, 30);
        expect(store.progress(topic.id), isNull);
        expect(
          store.history.first['experimentIds'],
          hasLength(topic.experiments.length),
        );
        expect(find.byType(CompletionPage), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        await tester
            .pump(); // Disposing a finished lesson must not recreate its draft.
        expect(store.progress(topic.id), isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Actual gestures, wrong retry, lifecycle save and exact resume', (
    tester,
  ) async {
    screen(tester);
    await tester.runAsync(learner);
    Future<void> mount() => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LessonPage(topic: topics.first, store: store),
      ),
    );
    await mount();
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const ValueKey('balance-drop')));
    await tap(tester, find.text('Kiểm tra'));
    expect(find.text('Thử thêm một cách nhé'), findsOneWidget);
    for (int i = 0; i < 3; i++) {
      await tap(tester, find.byKey(const ValueKey('balance-drop')));
    }
    await tap(tester, find.text('Kiểm tra'));
    await tap(tester, find.text('Khám phá tiếp'));
    await tester.ensureVisible(find.byKey(const ValueKey('remove-swipe')));
    await tester.drag(
      find.byKey(const ValueKey('remove-swipe')),
      const Offset(140, 0),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.runAsync(store.flush);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await mount();
    await tester.pumpAndSettle();
    expect(find.text('Bóc từng lớp'), findsOneWidget);
    expect(
      (store.progress('logic')!['states'] as Map)['logic-remove']['pairs'],
      1,
    );
    expect(find.text('x + 2 = 6'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('reset-experiment')));
    expect(find.text('x + 3 = 7'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Kiểm tra'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'All lesson screens fit 320px and expose the correct interactive surfaces',
    (tester) async {
      screen(tester, const Size(320, 640));
      await tester.runAsync(learner);
      for (final topic in topics) {
        for (int step = 0; step < topic.experiments.length; step++) {
          await tester.pumpWidget(const SizedBox());
          await tester.pump();
          await tester.runAsync(
            () => store.saveProgress(topic.id, {
              'step': step,
              'states': {},
              'touched': [],
              'checked': [],
              'attempts': 0,
              'seconds': 0,
              'hints': [],
            }),
          );
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(),
              home: LessonPage(topic: topic, store: store),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ExperimentWorkspace), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          if (topic.experiments[step].mechanism == 'reasonedChoice') {
            expect(find.byKey(const ValueKey('answer-0')), findsOneWidget);
            expect(find.byKey(const ValueKey('reason-0')), findsOneWidget);
          } else {
            expect(find.byIcon(Icons.radio_button_off), findsNothing);
          }
          expect(tester.takeException(), isNull, reason: '${topic.id}:$step');
        }
      }
    },
  );
  testWidgets(
    'Saved checked state is revalidated and an untouched lesson cannot complete',
    (tester) async {
      screen(tester);
      await tester.runAsync(learner);
      await tester.runAsync(
        () => store.saveProgress('logic', {
          'step': 0,
          'states': {
            'logic-balance': {'blocks': 1},
          },
          'touched': ['logic-balance'],
          'checked': ['logic-balance'],
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: LessonPage(topic: topics.first, store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thử thêm một cách nhé'), findsOneWidget);
      expect(find.text('Khám phá tiếp'), findsNothing);
    },
  );
}
