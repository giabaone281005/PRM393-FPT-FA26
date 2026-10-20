import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mathlingo/core/supabase/supabase_service.dart';
import 'package:mathlingo/core/theme/app_theme.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/learning_history_repository.dart';
import 'package:mathlingo/features/learning_engine/screens/learning_history_screen.dart';
import 'package:mathlingo/features/learning_engine/study_screen.dart';
import 'package:mathlingo/features/home/screens/home_screen.dart';

// Only use with disposable development fixtures. Credentials are supplied from
// ignored build/feature-qa.json, never committed or printed by this test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('QA_EMAIL');
  const password = String.fromEnvironment('QA_PASSWORD');
  const kid = String.fromEnvironment('QA_KID');
  const lesson = String.fromEnvironment('QA_LESSON');

  Future<void> visible(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(finder, findsWidgets);
  }

  Future<void> press(WidgetTester tester, String label) async {
    final finder = find.widgetWithText(FilledButton, label);
    await visible(tester, finder);
    for (var i = 0; i < 80; i++) {
      if (tester.widget<FilledButton>(finder).onPressed != null) break;
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(tester.widget<FilledButton>(finder).onPressed, isNotNull);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  testWidgets(
    'real history resume, grading, completion and fresh-login review persist',
    (tester) async {
      expect(email, anyOf(endsWith('@example.invalid'), 'parent@demo.test'));
      expect(password, isNotEmpty);
      GoogleFonts.config.allowRuntimeFetching = true;
      await SupabaseService.initialize();
      final cloud = SupabaseService.client!;
      await cloud.auth.signInWithPassword(email: email, password: password);
      final state = AppStateProvider();
      for (var i = 0; i < 80 && state.isLoadingFromCloud; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(state.hasKids, isTrue);
      expect(state.currentKid.id, kid);
      final history = LearningHistoryRepository();
      final before = (await history.fetch(kid, kind: 'lesson')).single;
      expect(before.questionIndex, 1);
      expect(before.canResume, isTrue);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: LearningHistoryScreen(kidId: kid),
          ),
        ),
      );
      await visible(tester, find.text('QA — Hành trình cộng'));
      await tester.tap(find.text('QA — Hành trình cộng'));
      await visible(tester, find.text('Em đã trả lời: 4'));
      await tester.tap(find.text('Tiếp tục phiên học'));
      await visible(tester, find.text('4 + 2 = ?'));
      final studyScroll = find
          .descendant(
            of: find.byType(StudyScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('6'),
        250,
        scrollable: studyScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('CHỌN ĐÁP ÁN NÀY'),
        250,
        scrollable: studyScroll,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('CHỌN ĐÁP ÁN NÀY'));
      await visible(tester, find.text('Lưu kết quả và nhận thưởng'));
      await press(tester, 'Lưu kết quả và nhận thưởng');
      await visible(tester, find.text('Hoàn thành!'));
      final confirmed = (await history.fetch(
        kid,
        kind: 'lesson',
        status: 'completed',
      )).single;
      expect(confirmed.id, before.id);
      expect(confirmed.questionIndex, 2);
      expect(confirmed.attemptCount, 3);
      expect(confirmed.correctCount, 2);
      expect(confirmed.accuracy, 67);
      expect(confirmed.lessonId, lesson);
      await tester.pumpWidget(const SizedBox.shrink());
      // A fresh client and fresh login model app restart without trusting widget
      // state or the previous client's in-memory caches.
      final fresh = SupabaseClient(
        SupabaseService.supabaseUrl,
        SupabaseService.anonKey,
      );
      await fresh.auth.signInWithPassword(email: email, password: password);
      final reopened = LearningHistoryRepository(client: fresh);
      final persisted = (await reopened.fetch(
        kid,
        kind: 'lesson',
        status: 'completed',
      )).single;
      expect(persisted.id, before.id);
      expect(
        (await reopened.review(persisted.id)).map((a) => a.answer),
        unorderedEquals(['4', '5', '6']),
      );
      // Real dashboard -> topic -> completed lesson -> replay. The replay
      // persists separately and must not award the first-completion reward twice.
      await state.refreshFromCloud();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      );
      await visible(tester, find.text('Tiến độ của em'));
      await tester.scrollUntilVisible(find.text('QA Hành trình cộng'), 300);
      await tester.ensureVisible(find.text('QA Hành trình cộng'));
      await tester.pumpAndSettle();
      expect(find.text('1/1 bài · 100% hoàn thành'), findsWidgets);
      await tester.tap(find.text('QA Hành trình cộng'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bài 1: QA — Hành trình cộng'));
      await tester.pumpAndSettle();
      await press(tester, 'Ôn lại bài (không nhận thưởng lần hai)');
      await visible(tester, find.text('Câu hỏi'));
      await tester.tap(find.text('Câu hỏi'));
      await tester.pumpAndSettle();
      for (final value in ['5', '6']) {
        final scroll = find
            .descendant(
              of: find.byType(StudyScreen),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text(value),
          250,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(value));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('CHỌN ĐÁP ÁN NÀY'),
          250,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('CHỌN ĐÁP ÁN NÀY'));
        if (value == '5') await visible(tester, find.text('4 + 2 = ?'));
      }
      await press(tester, 'Lưu kết quả và nhận thưởng');
      await visible(tester, find.text('Hoàn thành!'));
      final replayed = await reopened.fetch(
        kid,
        kind: 'lesson',
        status: 'completed',
      );
      expect(replayed, hasLength(2));
      final replay = replayed.singleWhere((entry) => entry.id != before.id);
      expect(replay.xp, 0);
      expect(replay.stars, 0);
      expect(replay.accuracy, 100);
      expect((await reopened.review(before.id)), hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
      await fresh.auth.signOut(scope: SignOutScope.local);
      await fresh.dispose();
      await cloud.auth.signOut(scope: SignOutScope.local);
    },
  );
}
