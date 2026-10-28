import 'package:brilliant_mobile/entry_flow.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'User: onboarding, wrong retry, full Logic, reopen, review and isolation',
    (tester) async {
      tester.testTextInput.register();
      // Real device storage, isolated from personal profiles and Auth sessions.
      final runId = DateTime.now().microsecondsSinceEpoch;
      SharedPreferences.setPrefix('matlingo.user.e2e.$runId.');
      final preferences = await SharedPreferences.getInstance();
      var store = LearningStore(preferences);

      Future<void> tap(Finder finder) async {
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            160,
            scrollable: find.byType(Scrollable).last,
          );
        }
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      Future<void> key(String value) => tap(find.byKey(ValueKey(value)));

      Future<void> openLogic() async {
        await tap(find.text('Chủ đề'));
        await key('topic-logic');
        await tap(
          find.text(
            store.completed.contains('logic')
                ? 'Khám phá lại'
                : 'Vào phòng thí nghiệm',
          ),
        );
        expect(find.byType(LessonPage), findsOneWidget);
      }

      Future<void> solveLogic({bool retryWrong = false}) async {
        // Exercise controls through taps/drags; never inject solution state.
        for (var step = 0; step < 6; step++) {
          debugPrint('E2E Logic step ${step + 1}; review=${!retryWrong}');
          switch (step) {
            case 0:
              await key('balance-drop');
              if (retryWrong) {
                await tap(find.text('Kiểm tra'));
                expect(find.text('Thử thêm một cách nhé'), findsOneWidget);
                expect(store.points, 0);
                await tap(find.text('Gợi ý nhỏ'));
              }
              for (var i = 0; i < 3; i++) {
                await key('balance-drop');
              }
            case 1:
              final swipe = find.byKey(const ValueKey('remove-swipe'));
              await tester.ensureVisible(swipe);
              await tester.drag(swipe, const Offset(140, 0));
              await tester.pumpAndSettle();
              for (var i = 0; i < 2; i++) {
                await key('remove-pair');
              }
            case 2:
              await key('gear-forward');
              await key('gear-forward');
            case 3:
              for (var i = 0; i < 5; i++) {
                await key('remove-pair');
              }
            case 4:
              // This activity starts with one block already on the scale.
              for (var i = 0; i < 5; i++) {
                await key('balance-drop');
              }
            case 5:
              await key('condition-a');
          }
          await tap(find.text('Kiểm tra'));
          expect(
            find.text('Bạn đã tìm ra!'),
            findsOneWidget,
            reason: 'Logic step ${step + 1}: ${store.progress('logic')}',
          );
          await tap(
            find.text(step == 5 ? 'Hoàn thành hành trình' : 'Khám phá tiếp'),
          );
        }
        expect(find.byType(CompletionPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      try {
        await tester.pumpWidget(LearnApp(store: store));
        await tester.pumpAndSettle();
        expect(find.byType(EntryPage), findsOneWidget);
        await key('entry-create');
        expect(find.text('Nhập tên từ 1 đến 40 ký tự.'), findsOneWidget);
        expect(store.hasSession, false);
        await tester.enterText(
          find.byKey(const ValueKey('entry-name')),
          '  E2E User  ',
        );
        await key('entry-create');
        await key('interest-logic');
        await key('onboarding-continue');
        await key('minutes-10');
        await key('onboarding-continue');
        expect(find.byType(HomeShell), findsOneWidget);
        expect(store.profile!.name, 'E2E User');
        expect(store.profile!.dailyMinutes, 10);
        final firstProfile = store.profile!.id;

        await openLogic();
        await solveLogic(retryWrong: true);
        expect(store.completed, contains('logic'));
        expect(store.points, 30);
        expect(store.history, hasLength(1));
        expect(store.progress('logic'), isNull);

        // Reload the real platform preference cache before reconstructing state.
        await store.flush();
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        store.dispose();
        await preferences.reload();
        store = LearningStore(preferences);
        expect(store.profile!.id, firstProfile);
        expect(store.points, 30);
        expect(store.completed, contains('logic'));
        await tester.pumpWidget(LearnApp(store: store));
        await tester.pumpAndSettle();
        await openLogic();
        await solveLogic();
        expect(store.points, 30, reason: 'Review must not award duplicate XP');
        expect(store.history, hasLength(2));
        expect(store.history.first['xp'], 0);
        await tap(find.text('Về trang chủ'));

        await tap(find.text('Hồ sơ'));
        await tap(find.text('Đóng phiên & đổi hồ sơ'));
        expect(find.byType(EntryPage), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('entry-name')),
          'E2E Second User',
        );
        await key('entry-create');
        await key('interest-logic');
        await key('onboarding-continue');
        await key('minutes-10');
        await key('onboarding-continue');
        expect(store.profile!.id, isNot(firstProfile));
        expect(store.points, 0);
        expect(store.completed, isEmpty);
        expect(store.history, isEmpty);
        await tap(find.text('Hồ sơ'));
        await tap(find.text('Đóng phiên & đổi hồ sơ'));
        await key('profile-$firstProfile');
        expect(find.byType(HomeShell), findsOneWidget);
        expect(store.points, 30);
        expect(store.completed, contains('logic'));
        expect(store.history, hasLength(2));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await store.flush();
        store.dispose();
        // Remove only this run's prefixed keys, never clear app/user storage.
        for (final name in preferences.getKeys().toList()) {
          await preferences.remove(name);
        }
      }
    },
  );
}
