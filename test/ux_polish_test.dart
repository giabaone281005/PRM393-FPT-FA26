import 'package:brilliant_mobile/app_layout.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/app_preferences.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_activity.dart';
import 'package:brilliant_mobile/learning_store.dart';
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

  test('REA text and action colors retain contrast across existing appearance choices', () {
    final appearance = AppPreferences(store.preferences);
    addTearDown(appearance.dispose);
    double contrast(Color first, Color second) {
      final a = first.computeLuminance(), b = second.computeLuminance();
      return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
    }

    for (final background in ['white', 'cream', 'mist']) {
      for (final accent in ['green', 'blue', 'violet']) {
        appearance.background = background;
        appearance.accent = accent;
        final theme = appearance.theme;
        final button = theme.filledButtonTheme.style!;
        expect(
          contrast(theme.colorScheme.onSurface, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(
            BrilliantPalette.secondaryText,
            theme.scaffoldBackgroundColor,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(
            button.foregroundColor!.resolve({})!,
            button.backgroundColor!.resolve({})!,
          ),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  testWidgets('clear topic search keeps the selected progress filter', (
    tester,
  ) async {
    await store.saveProgress('logic', {'step': 0});
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: ExplorePage(store: store)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('topic-filter-saved')));
    await tester.enterText(
      find.byKey(const ValueKey('topic-search')),
      'no-such-topic',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có chủ đề phù hợp'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('topic-search-clear')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('topic-logic')), findsOneWidget);
    expect(find.byKey(const ValueKey('topic-math')), findsNothing);
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('topic-filter-saved')))
          .selected,
      isTrue,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('topic-search')))
          .controller!
          .text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'week date targets stay at least 48dp on phones, landscape and large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final now = DateTime.now();
      for (final scenario in [
        (const Size(320, 740), 1.4),
        (const Size(375, 812), 2.0),
        (const Size(844, 390), 1.4),
        (const Size(768, 1024), 1.0),
      ]) {
        tester.view.physicalSize = scenario.$1;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(scenario),
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scenario.$2)),
              child: child!,
            ),
            home: Scaffold(body: ProfilePage(store: store)),
          ),
        );
        await tester.pumpAndSettle();
        final firstDay = find.byKey(
          ValueKey(
            'activity-${activityDay(now.subtract(const Duration(days: 6)))}',
          ),
        );
        await tester.scrollUntilVisible(
          firstDay,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        for (var ago = 0; ago < 7; ago++) {
          final day = now.subtract(Duration(days: ago));
          final date = find.byKey(ValueKey('activity-${activityDay(day)}'));
          final rect = tester.getRect(date);
          expect(rect.width, greaterThanOrEqualTo(48));
          expect(rect.height, greaterThanOrEqualTo(48));
        }
        final yesterday = now.subtract(const Duration(days: 1));
        final target = find.byKey(
          ValueKey('activity-${activityDay(yesterday)}'),
        );
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Ngày ${yesterday.day}/${yesterday.month}'),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Ngày ${yesterday.day}/${yesterday.month}'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'page actions clear landscape cutouts, gesture inset and open keyboard',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(844, 390);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final keyboard in [0.0, 160.0]) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(keyboard),
            theme: buildAppTheme(),
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(844, 390),
                padding: EdgeInsets.fromLTRB(44, 0, 24, keyboard == 0 ? 21 : 0),
                viewPadding: const EdgeInsets.fromLTRB(44, 0, 24, 21),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: Scaffold(
                appBar: const AppPageHeader(title: Text('Tài khoản')),
                body: AppPageBody(
                  children: [
                    const SizedBox(height: 800),
                    FilledButton(
                      key: const ValueKey('safe-action'),
                      onPressed: () {},
                      child: const Text('Tiếp tục'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final action = find.byKey(const ValueKey('safe-action'));
        await tester.scrollUntilVisible(
          action,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final rect = tester.getRect(action);
        expect(rect.left, greaterThanOrEqualTo(44));
        expect(rect.right, lessThanOrEqualTo(844 - 24));
        expect(
          rect.bottom,
          lessThanOrEqualTo(390 - keyboard - (keyboard == 0 ? 21 : 0)),
        );
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
