import 'package:brilliant_mobile/app_preferences.dart';
import 'package:brilliant_mobile/entry_flow.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/settings_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  late LearningStore store;
  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'Matlingo',
      packageName: 'com.learningstudio.brilliant_mobile',
      version: '2.0.3',
      buildNumber: '42',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    store = LearningStore(await SharedPreferences.getInstance());
    await store.createDeviceProfile('An');
    await store.finishOnboarding(['logic'], 10);
    await store.saveProgress('logic', {'step': 1});
  });
  tearDown(() => store.dispose());
  Future<void> menu(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('app-settings')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Popup hides unavailable Premium and preserves the selected tab',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(280, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(LearnApp(store: store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chủ đề'));
      await tester.pumpAndSettle();
      for (final entry in {
        'appearance': AppearancePage,
        'about': AboutMatlingoPage,
        'help': HelpMatlingoPage,
      }.entries) {
        await menu(tester);
        expect(
          find.byWidgetPredicate((widget) => widget is PopupMenuItem),
          findsNWidgets(4),
        );
        expect(find.byKey(const ValueKey('menu-gift')), findsNothing);
        final item = find.byKey(ValueKey('menu-${entry.key}'));
        final bounds = tester.getRect(item);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(280));
        await tester.tap(item);
        await tester.pumpAndSettle();
        expect(find.byType(entry.value), findsOneWidget);
        if (entry.key == 'about') {
          expect(find.text('Phiên bản 2.0.3 (42)'), findsOneWidget);
          expect(find.text('13 chủ đề · 71 hoạt động'), findsOneWidget);
        }
        Navigator.pop(tester.element(find.byType(entry.value)));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          1,
        );
        expect(store.progress('logic')!['step'], 1);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Help search opens matching answers', (tester) async {
    await tester.pumpWidget(LearnApp(store: store));
    await tester.pumpAndSettle();
    await menu(tester);
    await tester.tap(find.byKey(const ValueKey('menu-help')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('help-search')), 'XP');
    await tester.pumpAndSettle();
    await tester.tap(find.text('XP được tính ra sao?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('30 XP lần đầu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Dismissing popup keeps session; logout retains profile and saved lesson',
    (tester) async {
      final id = store.profile!.id;
      await tester.pumpWidget(LearnApp(store: store));
      await tester.pumpAndSettle();
      await menu(tester);
      Navigator.pop(tester.element(find.byKey(const ValueKey('menu-logout'))));
      await tester.pumpAndSettle();
      expect(store.hasSession, true);
      await menu(tester);
      await tester.tap(find.byKey(const ValueKey('menu-logout')));
      await tester.pumpAndSettle();
      expect(find.byType(EntryPage), findsOneWidget);
      expect(store.hasSession, false);
      await store.activateProfile(id);
      await tester.pumpAndSettle();
      expect(store.progress('logic')!['step'], 1);
      expect(tester.takeException(), isNull);
    },
  );
}
