import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/entry_flow.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<LearningStore> store() async {
    SharedPreferences.setMockInitialValues({});
    return LearningStore(await SharedPreferences.getInstance());
  }

  testWidgets(
    'Entry validates a name and creates an explicit device profile at 320px',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final learning = await store();
      addTearDown(learning.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: EntryPage(store: learning),
        ),
      );
      final create = find.byKey(const ValueKey('entry-create'));
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(learning.hasSession, isFalse);
      expect(find.text('Nhập tên từ 1 đến 40 ký tự.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('entry-name')),
        '  An  ',
      );
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(learning.profile!.name, 'An');
      expect(learning.profile!.mode, 'device');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Onboarding persists multiple interests and a daily rhythm', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final learning = await store();
    addTearDown(learning.dispose);
    await learning.createDeviceProfile('An');
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: OnboardingPage(store: learning),
      ),
    );
    expect(find.text('Matlingo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    for (final key in ['geometry', 'coding']) {
      final chip = find.byKey(ValueKey('interest-$key'));
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }
    final next = find.byKey(const ValueKey('onboarding-continue'));
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Matlingo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final minutes = find.byKey(const ValueKey('minutes-20'));
    await tester.ensureVisible(minutes);
    await tester.tap(minutes);
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(learning.profile!.onboarded, isTrue);
    expect(learning.profile!.interests, containsAll(['geometry', 'coding']));
    expect(learning.profile!.dailyMinutes, 20);
    expect(tester.takeException(), isNull);
  });
}
