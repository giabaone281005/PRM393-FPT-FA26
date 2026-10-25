import 'package:brilliant_mobile/app_preferences.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LearningStore(await SharedPreferences.getInstance());
    await store.createDeviceProfile('An');
    await store.finishOnboarding(['logic'], 10);
  });
  tearDown(() => store.dispose());

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        160,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Empty home chooses a topic and profile is a main tab', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(LearnApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Hành trình'), findsNothing);
    expect(find.text('DÀNH CHO 10 PHÚT TÒ MÒ'), findsNothing);
    expect(find.text('Tìm đường cho sự tò mò'), findsNothing);
    await tap(tester, find.text('Chọn chủ đề'));
    expect(find.text('Chủ đề của bạn'), findsOneWidget);
    await tap(tester, find.byKey(const ValueKey('topic-logic')));
    expect(tester.widget<TopicPage>(find.byType(TopicPage)).topic.id, 'logic');
    Navigator.pop(tester.element(find.byType(TopicPage)));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Hồ sơ'));
    expect(find.text('An'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Đóng phiên & đổi hồ sơ'),
      120,
      scrollable: find
          .descendant(
            of: find.byType(ProfilePage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Đóng phiên & đổi hồ sơ'), findsOneWidget);
    expect(store.points, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home resumes the saved lesson without replacing its state', (
    tester,
  ) async {
    phone(tester);
    await store.saveProgress('logic', {
      'step': 1,
      'states': {
        'logic-balance': {'blocks': 4},
      },
      'checked': ['logic-balance'],
    });
    final before = store.progress('logic');
    await tester.pumpWidget(LearnApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Bước 2 / 5'), findsOneWidget);
    await tap(tester, find.text('Học tiếp'));
    expect(find.text('Bóc từng lớp'), findsOneWidget);
    expect(store.progress('logic')!['states'], before!['states']);
    expect(store.points, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Appearance updates live, survives reload and preserves learning',
    (tester) async {
      phone(tester);
      await store.saveProgress('logic', {'step': 1});
      await tester.pumpWidget(LearnApp(store: store));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('app-settings')));
      await tap(tester, find.byKey(const ValueKey('menu-appearance')));
      await tap(tester, find.byKey(const ValueKey('background-cream')));
      await tap(tester, find.byKey(const ValueKey('accent-violet')));
      await tap(tester, find.byKey(const ValueKey('text-size-1.3')));
      await tap(tester, find.byKey(const ValueKey('headings-sans')));
      await tap(tester, find.byKey(const ValueKey('reduce-motion')));
      final restored = AppPreferences(store.preferences);
      expect(restored.background, 'cream');
      expect(restored.accent, 'violet');
      expect(restored.textSize, 1.3);
      expect(restored.sansHeadings, true);
      expect(restored.reduceMotion, true);
      final context = tester.element(find.byType(AppearancePage));
      expect(
        Theme.of(context).scaffoldBackgroundColor,
        const Color(0xFFFFFBF2),
      );
      expect(MediaQuery.disableAnimationsOf(context), true);
      expect(MediaQuery.textScalerOf(context).scale(10), 13);
      expect(store.progress('logic')!['step'], 1);
      restored.dispose();
      Navigator.pop(context);
      await tester.pumpAndSettle();
      await tap(tester, find.text('Chủ đề'));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Appearance queues rapid changes without losing another setting',
    () async {
      final settings = AppPreferences(store.preferences);
      await Future.wait([
        settings.update(background: 'cream'),
        settings.update(accent: 'violet'),
        settings.update(textSize: 1.3),
      ]);
      final restored = AppPreferences(store.preferences);
      expect(restored.background, 'cream');
      expect(restored.accent, 'violet');
      expect(restored.textSize, 1.3);
      settings.dispose();
      restored.dispose();
    },
  );

  test('Corrupt appearance falls back to usable defaults', () async {
    await store.preferences.setString(AppPreferences.storageKey, '{broken');
    final restored = AppPreferences(store.preferences);
    expect(restored.background, 'white');
    expect(restored.textSize, 1);
    restored.dispose();
  });
}
