import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/question.dart';
import 'package:mathlingo/data/models/wrong_answer_record.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/learning_statistics_repository.dart';
import 'package:mathlingo/data/repositories/wrong_answer_repository.dart';
import 'package:mathlingo/features/learning_engine/screens/learning_progress_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Practice Progress Integration - Answer Tracking', () {
    test('a correct submitted answer updates statistics exactly once', () async {
      const kidId = 'kid_progress_1';
      final statsBefore = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(statsBefore.totalAnswered, 0);

      const eventId = 'session_1:q_1:req_101';
      final updated = await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: eventId,
      );

      expect(updated.correctAnswers, 1);
      expect(updated.incorrectAnswers, 0);
      expect(updated.totalAnswered, 1);
      expect(updated.accuracyPercentage, 100.0);

      final persisted = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(persisted.correctAnswers, 1);
      expect(persisted.incorrectAnswers, 0);
      expect(persisted.totalAnswered, 1);
      expect(persisted.accuracyPercentage, 100.0);
    });

    test('an incorrect submitted answer updates statistics exactly once', () async {
      const kidId = 'kid_progress_2';
      const eventId = 'session_2:q_2:req_102';

      final updated = await LearningStatisticsRepository.recordAnswer(
        isCorrect: false,
        kidId: kidId,
        eventId: eventId,
      );

      expect(updated.correctAnswers, 0);
      expect(updated.incorrectAnswers, 1);
      expect(updated.totalAnswered, 1);
      expect(updated.accuracyPercentage, 0.0);

      final persisted = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(persisted.correctAnswers, 0);
      expect(persisted.incorrectAnswers, 1);
    });

    test('repeated processing of the same answer event does not double-count it', () async {
      const kidId = 'kid_progress_3';
      const eventId = 'session_duplicate:q_3:req_103';

      // First attempt
      final first = await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: eventId,
      );
      expect(first.correctAnswers, 1);
      expect(first.totalAnswered, 1);

      // Duplicate attempt 1
      final dup1 = await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: eventId,
      );
      expect(dup1.correctAnswers, 1);
      expect(dup1.totalAnswered, 1);

      // Duplicate attempt 2
      final dup2 = await LearningStatisticsRepository.recordAnswer(
        isCorrect: false,
        kidId: kidId,
        eventId: eventId,
      );
      expect(dup2.correctAnswers, 1);
      expect(dup2.incorrectAnswers, 0);
      expect(dup2.totalAnswered, 1);

      final finalStats = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(finalStats.correctAnswers, 1);
      expect(finalStats.totalAnswered, 1);
    });

    test('different answer events for the same question update statistics sequentially', () async {
      const kidId = 'kid_progress_sequential';
      const eventId1 = 'session_seq:q_4:req_104';
      const eventId2 = 'session_seq:q_4:req_105';

      await LearningStatisticsRepository.recordAnswer(
        isCorrect: false,
        kidId: kidId,
        eventId: eventId1,
      );
      final second = await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: eventId2,
      );

      expect(second.correctAnswers, 1);
      expect(second.incorrectAnswers, 1);
      expect(second.totalAnswered, 2);
      expect(second.accuracyPercentage, 50.0);
    });
  });

  group('Practice Progress Integration - Daily Streak Activity', () {
    test('updates daily learning activity and calculates streak consecutive days correctly', () async {
      const kidId = 'kid_streak_test';
      final day1 = DateTime(2026, 10, 10, 8, 30);
      final day2 = DateTime(2026, 10, 11, 14, 0);
      final day3 = DateTime(2026, 10, 12, 19, 15);

      await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: 'streak_e1',
        timestamp: day1,
      );
      await LearningStatisticsRepository.recordAnswer(
        isCorrect: false,
        kidId: kidId,
        eventId: 'streak_e2',
        timestamp: day2,
      );
      await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: 'streak_e3',
        timestamp: day3,
      );

      // Streak as of day3 should be 3
      final streak = await LearningStatisticsRepository.getStreak(
        kidId: kidId,
        referenceDate: day3,
      );
      expect(streak.currentStreak, 3);
      expect(streak.hasStudiedToday, isTrue);

      // Multiple answers on the same day do not increase streak count beyond consecutive days
      await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: 'streak_e4_sameday',
        timestamp: day3.add(const Duration(hours: 1)),
      );

      final streakSameDay = await LearningStatisticsRepository.getStreak(
        kidId: kidId,
        referenceDate: day3,
      );
      expect(streakSameDay.currentStreak, 3);
    });

    test('retains streak from yesterday when today has not yet been practiced', () async {
      const kidId = 'kid_streak_yesterday';
      final day1 = DateTime(2026, 10, 10, 10, 0);
      final day2 = DateTime(2026, 10, 11, 11, 0);
      final day3 = DateTime(2026, 10, 12, 12, 0);

      await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: 'y_e1',
        timestamp: day1,
      );
      await LearningStatisticsRepository.recordAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: 'y_e2',
        timestamp: day2,
      );

      final streak = await LearningStatisticsRepository.getStreak(
        kidId: kidId,
        referenceDate: day3,
      );
      expect(streak.currentStreak, 2);
      expect(streak.hasStudiedToday, isFalse);
    });
  });

  group('Practice Progress Integration - Wrong Answer Recording Coexistence', () {
    test('incorrect practice answer records in both learning stats and wrong answer repo', () async {
      const kidId = 'kid_dual_record';
      final question = Question(
        id: 'q_dual_1',
        type: QuestionType.multiplicationTable,
        prompt: '7 x 8 = ?',
        data: const {'factorA': 7, 'factorB': 8},
        correctAnswer: null,
      );

      const attemptedAnswer = 54;
      const isCorrect = false;
      const eventId = 'sess_dual:q_dual_1:req_555';

      // 1. Record in learning statistics (what StudyScreen._answer does)
      await LearningStatisticsRepository.recordAnswer(
        isCorrect: isCorrect,
        kidId: kidId,
        eventId: eventId,
      );

      // 2. Record in wrong answer repository (what StudyScreen._answer continues to do)
      if (!isCorrect) {
        final record = WrongAnswerRecord(
          questionId: question.id,
          prompt: question.prompt,
          questionType: question.type,
          userAnswer: attemptedAnswer,
          lessonId: 'lesson_mult_1',
          timestamp: DateTime.now(),
          isResolved: false,
          questionData: question.data,
        );
        await WrongAnswerRepository.saveWrongAnswer(kidId, record);
      }

      // Verify wrong answers
      final wrongList = await WrongAnswerRepository.getWrongAnswers(kidId);
      expect(wrongList.length, 1);
      expect(wrongList.first.questionId, 'q_dual_1');
      expect(wrongList.first.userAnswer, 54);

      // Verify learning statistics
      final stats = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(stats.incorrectAnswers, 1);
      expect(stats.correctAnswers, 0);
      expect(stats.totalAnswered, 1);
    });
  });

  group('Practice Progress Integration - AppStateProvider & Dashboard Refresh', () {
    test('AppStateProvider.recordPracticeAnswer updates statistics and kid streak', () async {
      final appState = AppStateProvider();
      const kidId = 'kid_provider_test';

      int notifyCount = 0;
      appState.addListener(() => notifyCount++);

      await appState.recordPracticeAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: 'provider_event_1',
      );

      expect(notifyCount, greaterThan(0));
      expect(appState.statsRevision, 1);

      final stats = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(stats.correctAnswers, 1);
      expect(stats.totalAnswered, 1);
    });

    testWidgets('LearningProgressScreen auto-refreshes when AppStateProvider statsRevision changes', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const kidId = 'kid_ui_refresh';
      final appState = AppStateProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: appState,
          child: const MaterialApp(
            home: LearningProgressScreen(kidId: kidId),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially zero
      expect(find.text('Chưa có dữ liệu học tập'), findsOneWidget);

      // Simulate practice answer submission via appState
      await appState.recordPracticeAnswer(
        isCorrect: true,
        kidId: kidId,
        eventId: 'ui_refresh_event_1',
      );
      await tester.pumpAndSettle();

      // Now 1 correct answer is displayed
      expect(find.text('1'), findsNWidgets(3)); // Streak: 1, Total: 1, Correct: 1
      expect(find.text('100%'), findsNWidgets(2)); // Card and progress section both display 100%
      expect(find.text('Chưa có dữ liệu học tập'), findsNothing);
    });

    testWidgets('merely navigating or viewing dashboard does not record any answers', (
      tester,
    ) async {
      const kidId = 'kid_no_spurious_records';
      final statsInitial = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(statsInitial.totalAnswered, 0);

      // Render dashboard
      await tester.pumpWidget(
        const MaterialApp(
          home: LearningProgressScreen(kidId: kidId),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no answers were created by viewing or rendering
      final statsAfter = await LearningStatisticsRepository.getStatistics(kidId: kidId);
      expect(statsAfter.totalAnswered, 0);
      expect(statsAfter.correctAnswers, 0);
      expect(statsAfter.incorrectAnswers, 0);
    });
  });
}
