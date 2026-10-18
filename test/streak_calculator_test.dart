import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/services/streak_calculator.dart';
import 'package:mathlingo/data/models/question.dart';
import 'package:mathlingo/data/models/wrong_answer_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Fixed deterministic reference date: Saturday, Oct 17, 2026
  final refDate = DateTime(2026, 10, 17, 14, 30);

  group('StreakCalculator - No learning activity', () {
    test('returns zero streak when activity list is empty', () {
      final result = StreakCalculator.calculate(
        activityDates: const [],
        referenceDate: refDate,
      );

      expect(result.currentStreak, 0);
      expect(result.streakCount, 0);
      expect(result.longestStreak, 0);
      expect(result.hasStudiedToday, isFalse);
      expect(result.isStreakActive, isFalse);
      expect(result.lastLearningDate, isNull);
      expect(result.totalLearningDays, 0);
      expect(result, equals(const LearningStreak.empty()));
    });

    test('calculateCurrentStreak helper returns 0 for empty activity', () {
      final streak = StreakCalculator.calculateCurrentStreak(
        activityDates: const [],
        referenceDate: refDate,
      );
      expect(streak, 0);
    });

    test('hasStudiedToday helper returns false for empty activity', () {
      final studied = StreakCalculator.hasStudiedToday(
        activityDates: const [],
        referenceDate: refDate,
      );
      expect(studied, isFalse);
    });
  });

  group('StreakCalculator - First learning day', () {
    test('returns streak of 1 when learner studies for the first time today', () {
      final activity = [DateTime(2026, 10, 17, 9, 15)];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.hasStudiedToday, isTrue);
      expect(result.isStreakActive, isTrue);
      expect(result.totalLearningDays, 1);
      expect(result.lastLearningDate, DateTime(2026, 10, 17));
    });

    test('returns streak of 1 when learner studied only yesterday', () {
      final activity = [DateTime(2026, 10, 16, 20, 0)];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.hasStudiedToday, isFalse);
      expect(result.isStreakActive, isTrue);
      expect(result.totalLearningDays, 1);
    });
  });

  group('StreakCalculator - Multiple answers on the same day', () {
    test('multiple answers on same calendar day count as 1 learning day', () {
      final activity = [
        DateTime(2026, 10, 17, 7, 30),
        DateTime(2026, 10, 17, 10, 0),
        DateTime(2026, 10, 17, 14, 45),
        DateTime(2026, 10, 17, 21, 15),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 1);
      expect(result.totalLearningDays, 1);
      expect(result.hasStudiedToday, isTrue);
    });

    test('multiple sessions across consecutive days deduplicate properly', () {
      final activity = [
        DateTime(2026, 10, 15, 8, 0),
        DateTime(2026, 10, 15, 19, 0),
        DateTime(2026, 10, 16, 11, 0),
        DateTime(2026, 10, 16, 15, 30),
        DateTime(2026, 10, 17, 9, 0),
        DateTime(2026, 10, 17, 18, 0),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.totalLearningDays, 3);
      expect(result.hasStudiedToday, isTrue);
    });
  });

  group('StreakCalculator - Consecutive learning days', () {
    test('accurately counts multi-day consecutive streaks', () {
      final activity = [
        DateTime(2026, 10, 13, 8, 0),
        DateTime(2026, 10, 14, 12, 0),
        DateTime(2026, 10, 15, 16, 0),
        DateTime(2026, 10, 16, 10, 0),
        DateTime(2026, 10, 17, 14, 0),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 5);
      expect(result.longestStreak, 5);
      expect(result.totalLearningDays, 5);
      expect(result.hasStudiedToday, isTrue);
    });
  });

  group('StreakCalculator - Studied today', () {
    test('includes today in current streak when studied today', () {
      final activity = [
        DateTime(2026, 10, 16, 15, 0),
        DateTime(2026, 10, 17, 11, 0),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 2);
      expect(result.hasStudiedToday, isTrue);
    });
  });

  group('StreakCalculator - Last studied yesterday', () {
    test('retains streak through yesterday when learner has not studied yet today', () {
      final activity = [
        DateTime(2026, 10, 14, 10, 0),
        DateTime(2026, 10, 15, 11, 0),
        DateTime(2026, 10, 16, 20, 0), // Yesterday
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate, // Today: 2026-10-17
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.hasStudiedToday, isFalse);
      expect(result.isStreakActive, isTrue);
      expect(result.lastLearningDate, DateTime(2026, 10, 16));
    });
  });

  group('StreakCalculator - Missed one or more days', () {
    test('current streak drops to zero if last learning day was earlier than yesterday', () {
      final activity = [
        DateTime(2026, 10, 13, 9, 0),
        DateTime(2026, 10, 14, 10, 0),
        DateTime(2026, 10, 15, 11, 0), // 2 days ago; skipped yesterday (Oct 16) and today (Oct 17)
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 0);
      expect(result.isStreakActive, isFalse);
      expect(result.hasStudiedToday, isFalse);
      expect(result.longestStreak, 3); // Historical longest preserved
      expect(result.totalLearningDays, 3);
      expect(result.lastLearningDate, DateTime(2026, 10, 15));
    });

    test('streak resets to 1 if user studies today after missing yesterday', () {
      final activity = [
        DateTime(2026, 10, 14, 10, 0),
        DateTime(2026, 10, 15, 10, 0),
        // Missed Oct 16
        DateTime(2026, 10, 17, 10, 0), // Studied today
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 1);
      expect(result.longestStreak, 2); // 2 from Oct 14-15
      expect(result.hasStudiedToday, isTrue);
      expect(result.totalLearningDays, 3);
    });
  });

  group('StreakCalculator - Month and year boundaries', () {
    test('handles standard month boundary correctly', () {
      // 2026 is non-leap: Feb 28 -> Mar 1
      final activity = [
        DateTime(2026, 2, 27, 15, 0),
        DateTime(2026, 2, 28, 18, 0),
        DateTime(2026, 3, 1, 9, 0),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: DateTime(2026, 3, 1, 12, 0),
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.hasStudiedToday, isTrue);

      // Next day without studying: retained through yesterday
      final nextDayResult = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: DateTime(2026, 3, 2, 12, 0),
      );
      expect(nextDayResult.currentStreak, 3);
      expect(nextDayResult.hasStudiedToday, isFalse);
    });

    test('handles leap year month boundary correctly', () {
      // 2024 is a leap year: Feb 28 -> Feb 29 -> Mar 1
      final activity = [
        DateTime(2024, 2, 28, 10, 0),
        DateTime(2024, 2, 29, 14, 0),
        DateTime(2024, 3, 1, 8, 30),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: DateTime(2024, 3, 1, 10, 0),
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.hasStudiedToday, isTrue);
    });

    test('handles year boundary correctly', () {
      // Dec 30, 2025 -> Dec 31, 2025 -> Jan 1, 2026
      final activity = [
        DateTime(2025, 12, 30, 11, 0),
        DateTime(2025, 12, 31, 22, 0),
        DateTime(2026, 1, 1, 10, 0),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: DateTime(2026, 1, 1, 15, 0),
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.hasStudiedToday, isTrue);

      // On Jan 2, 2026 before studying: retained through yesterday
      final jan2Result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: DateTime(2026, 1, 2, 9, 0),
      );
      expect(jan2Result.currentStreak, 3);
      expect(jan2Result.hasStudiedToday, isFalse);
    });
  });

  group('StreakCalculator - Date values with different times on same day', () {
    test('normalizes different times of day to same local calendar day', () {
      final morning = DateTime(2026, 10, 17, 0, 1); // 00:01
      final noon = DateTime(2026, 10, 17, 12, 0); // 12:00
      final night = DateTime(2026, 10, 17, 23, 59); // 23:59

      expect(StreakCalculator.toCalendarDay(morning), DateTime(2026, 10, 17));
      expect(StreakCalculator.toCalendarDay(noon), DateTime(2026, 10, 17));
      expect(StreakCalculator.toCalendarDay(night), DateTime(2026, 10, 17));
    });

    test('midnight crossing counts as consecutive days, not broken by short interval', () {
      // Studied at 23:55 on Day 1, then at 00:05 on Day 2 (10 minutes later)
      final activity = [
        DateTime(2026, 10, 16, 23, 55),
        DateTime(2026, 10, 17, 0, 5),
      ];

      final result = StreakCalculator.calculate(
        activityDates: activity,
        referenceDate: DateTime(2026, 10, 17, 8, 0),
      );

      expect(result.currentStreak, 2);
      expect(result.longestStreak, 2);
      expect(result.totalLearningDays, 2);
      expect(result.hasStudiedToday, isTrue);
    });
  });

  group('StreakCalculator - Integration with WrongAnswerRecord and DateStrings', () {
    test('fromWrongAnswerRecords extracts timestamps correctly', () {
      final records = [
        WrongAnswerRecord(
          questionId: 'q1',
          prompt: '1 + 1',
          questionType: QuestionType.wordProblem,
          userAnswer: 3,
          timestamp: DateTime(2026, 10, 16, 10, 0),
        ),
        WrongAnswerRecord(
          questionId: 'q2',
          prompt: '2 + 2',
          questionType: QuestionType.wordProblem,
          userAnswer: 5,
          timestamp: DateTime(2026, 10, 17, 9, 0),
        ),
      ];

      final result = StreakCalculator.fromWrongAnswerRecords(
        records,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 2);
      expect(result.hasStudiedToday, isTrue);
    });

    test('fromDateStrings safely parses ISO strings', () {
      final strings = [
        '2026-10-15T10:00:00Z',
        '2026-10-16T15:30:00Z',
        '2026-10-17T09:00:00Z',
        'invalid-date-string', // Ignored safely
      ];

      final result = StreakCalculator.fromDateStrings(
        strings,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 3);
      expect(result.totalLearningDays, 3);
    });

    test('DailyStreakService typedef works interchangeably', () {
      final result = DailyStreakService.calculate(
        activityDates: [DateTime(2026, 10, 17)],
        referenceDate: refDate,
      );
      expect(result.currentStreak, 1);
    });
  });

  group('LearningStreak - Model serialization and immutability', () {
    test('serializes to map and deserializes back faithfully', () {
      final original = LearningStreak(
        currentStreak: 7,
        longestStreak: 14,
        lastLearningDate: DateTime(2026, 10, 17),
        hasStudiedToday: true,
        totalLearningDays: 20,
      );

      final map = original.toMap();
      final restored = LearningStreak.fromMap(map);

      expect(restored, equals(original));
      expect(restored.currentStreak, 7);
      expect(restored.longestStreak, 14);
      expect(restored.lastLearningDate, DateTime(2026, 10, 17));
      expect(restored.hasStudiedToday, isTrue);
      expect(restored.totalLearningDays, 20);
    });

    test('round-trip via toJson and fromJson preserves data', () {
      final original = LearningStreak(
        currentStreak: 4,
        longestStreak: 8,
        lastLearningDate: DateTime(2026, 10, 16),
        hasStudiedToday: false,
        totalLearningDays: 12,
      );

      final jsonStr = original.toJson();
      final restored = LearningStreak.fromJson(jsonStr);

      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
    });

    test('copyWith updates fields selectively and maintains valid longest streak', () {
      const original = LearningStreak(currentStreak: 3, longestStreak: 5);

      final updated = original.copyWith(currentStreak: 6);
      expect(updated.currentStreak, 6);
      // longestStreak automatically clamped to >= currentStreak
      expect(updated.longestStreak, 6);
    });

    test('toString contains formatted streak information', () {
      const streak = LearningStreak(currentStreak: 5, longestStreak: 10);
      expect(streak.toString(), contains('currentStreak: 5'));
      expect(streak.toString(), contains('longestStreak: 10'));
    });
  });
}
