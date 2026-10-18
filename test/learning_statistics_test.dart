import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/learning_statistics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LearningStatistics - Empty statistics', () {
    test('default constructor creates empty statistics', () {
      const stats = LearningStatistics();

      expect(stats.correctAnswers, 0);
      expect(stats.incorrectAnswers, 0);
      expect(stats.totalAnswered, 0);
      expect(stats.totalAnsweredQuestions, 0);
      expect(stats.totalQuestions, 0);
      expect(stats.accuracyPercentage, 0.0);
      expect(stats.accuracy, 0.0);
    });

    test('LearningStatistics.zero constant has zero values', () {
      const stats = LearningStatistics.zero;

      expect(stats.correctAnswers, 0);
      expect(stats.incorrectAnswers, 0);
      expect(stats.totalAnswered, 0);
      expect(stats.accuracyPercentage, 0.0);
    });

    test('LearningStatistics.empty() named constructor has zero values', () {
      const stats = LearningStatistics.empty();

      expect(stats.correctAnswers, 0);
      expect(stats.incorrectAnswers, 0);
      expect(stats.totalAnswered, 0);
      expect(stats.accuracyPercentage, 0.0);
    });

    test('fromMap with empty map returns empty statistics', () {
      final stats = LearningStatistics.fromMap({});

      expect(stats.correctAnswers, 0);
      expect(stats.incorrectAnswers, 0);
      expect(stats.totalAnswered, 0);
      expect(stats.accuracyPercentage, 0.0);
    });
  });

  group('LearningStatistics - Answer counts and derived totals', () {
    test('accurately represents correct, incorrect, and total answered', () {
      const stats = LearningStatistics(
        correctAnswers: 12,
        incorrectAnswers: 3,
      );

      expect(stats.correctAnswers, 12);
      expect(stats.incorrectAnswers, 3);
      expect(stats.totalAnswered, 15);
      expect(stats.totalAnsweredQuestions, 15);
      expect(stats.totalQuestions, 15);
    });

    test('derives incorrect answers using fromTotalAndCorrect factory', () {
      final stats = LearningStatistics.fromTotalAndCorrect(
        totalAnswered: 10,
        correctAnswers: 7,
      );

      expect(stats.correctAnswers, 7);
      expect(stats.incorrectAnswers, 3);
      expect(stats.totalAnswered, 10);
    });

    test('allows consistent explicit totalAnswered in constructor', () {
      const stats = LearningStatistics(
        correctAnswers: 6,
        incorrectAnswers: 4,
        totalAnswered: 10,
      );

      expect(stats.totalAnswered, 10);
    });

    test('recordAnswer returns a new immutable instance with updated counts', () {
      const initial = LearningStatistics(correctAnswers: 2, incorrectAnswers: 1);

      final withCorrect = initial.recordAnswer(isCorrect: true);
      expect(withCorrect.correctAnswers, 3);
      expect(withCorrect.incorrectAnswers, 1);
      expect(withCorrect.totalAnswered, 4);

      final withIncorrect = initial.recordAnswer(isCorrect: false);
      expect(withIncorrect.correctAnswers, 2);
      expect(withIncorrect.incorrectAnswers, 2);
      expect(withIncorrect.totalAnswered, 4);

      // Verify original instance remains unmodified
      expect(initial.correctAnswers, 2);
      expect(initial.incorrectAnswers, 1);
    });
  });

  group('LearningStatistics - Accuracy calculation', () {
    test('calculates 100% accuracy when all answers are correct', () {
      const stats = LearningStatistics(correctAnswers: 10, incorrectAnswers: 0);

      expect(stats.accuracyPercentage, 100.0);
      expect(stats.accuracy, 100.0);
    });

    test('calculates 0% accuracy when all answers are incorrect', () {
      const stats = LearningStatistics(correctAnswers: 0, incorrectAnswers: 5);

      expect(stats.accuracyPercentage, 0.0);
      expect(stats.accuracy, 0.0);
    });

    test('calculates clean percentage for standard ratios', () {
      const statsQuarter = LearningStatistics(correctAnswers: 1, incorrectAnswers: 3);
      expect(statsQuarter.accuracyPercentage, 25.0);

      const statsHalf = LearningStatistics(correctAnswers: 4, incorrectAnswers: 4);
      expect(statsHalf.accuracyPercentage, 50.0);

      const statsThreeQuarters = LearningStatistics(correctAnswers: 3, incorrectAnswers: 1);
      expect(statsThreeQuarters.accuracyPercentage, 75.0);
    });

    test('calculates accurate floating-point percentage for repeating fractions', () {
      const stats = LearningStatistics(correctAnswers: 2, incorrectAnswers: 1);

      expect(stats.accuracyPercentage, closeTo(66.6666, 0.001));
    });
  });

  group('LearningStatistics - Zero-answer division safety', () {
    test('returns 0.0 without division by zero error when total answers is zero', () {
      const stats = LearningStatistics(correctAnswers: 0, incorrectAnswers: 0);

      expect(stats.totalAnswered, 0);
      expect(stats.accuracyPercentage, 0.0);
      expect(stats.accuracyPercentage.isNaN, isFalse);
      expect(stats.accuracyPercentage.isInfinite, isFalse);
    });
  });

  group('LearningStatistics - Serialization', () {
    test('toMap produces complete and expected keys', () {
      const stats = LearningStatistics(correctAnswers: 8, incorrectAnswers: 2);
      final map = stats.toMap();

      expect(map['correctAnswers'], 8);
      expect(map['incorrectAnswers'], 2);
      expect(map['totalAnswered'], 10);
      expect(map['accuracyPercentage'], 80.0);
    });

    test('fromMap restores instance accurately from camelCase map', () {
      final map = {
        'correctAnswers': 9,
        'incorrectAnswers': 1,
        'totalAnswered': 10,
        'accuracyPercentage': 90.0,
      };

      final stats = LearningStatistics.fromMap(map);

      expect(stats.correctAnswers, 9);
      expect(stats.incorrectAnswers, 1);
      expect(stats.totalAnswered, 10);
      expect(stats.accuracyPercentage, 90.0);
    });

    test('fromMap handles snake_case keys from database / backend schemas', () {
      final map = {
        'correct_answers': 5,
        'incorrect_answers': 5,
        'total_answered': 10,
      };

      final stats = LearningStatistics.fromMap(map);

      expect(stats.correctAnswers, 5);
      expect(stats.incorrectAnswers, 5);
      expect(stats.totalAnswered, 10);
      expect(stats.accuracyPercentage, 50.0);
    });

    test('fromMap safely parses string numeric representations', () {
      final map = {
        'correctAnswers': '7',
        'incorrectAnswers': '3',
      };

      final stats = LearningStatistics.fromMap(map);

      expect(stats.correctAnswers, 7);
      expect(stats.incorrectAnswers, 3);
      expect(stats.totalAnswered, 10);
    });

    test('round-trip toJson and fromJson preserves data and equality', () {
      const original = LearningStatistics(
        correctAnswers: 18,
        incorrectAnswers: 2,
      );

      final jsonString = original.toJson();
      final restored = LearningStatistics.fromJson(jsonString);

      expect(restored, equals(original));
      expect(restored.correctAnswers, original.correctAnswers);
      expect(restored.incorrectAnswers, original.incorrectAnswers);
      expect(restored.totalAnswered, original.totalAnswered);
      expect(restored.accuracyPercentage, original.accuracyPercentage);
    });

    test('round-trip for empty statistics', () {
      const empty = LearningStatistics.empty();
      final restored = LearningStatistics.fromJson(empty.toJson());

      expect(restored, equals(empty));
      expect(restored.totalAnswered, 0);
      expect(restored.accuracyPercentage, 0.0);
    });
  });

  group('LearningStatistics - Invalid and inconsistent input validation', () {
    test('constructor asserts against negative correct answers', () {
      expect(
        () => LearningStatistics(correctAnswers: -1, incorrectAnswers: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructor asserts against negative incorrect answers', () {
      expect(
        () => LearningStatistics(correctAnswers: 0, incorrectAnswers: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructor asserts against inconsistent totalAnswered', () {
      expect(
        () => LearningStatistics(
          correctAnswers: 4,
          incorrectAnswers: 2,
          totalAnswered: 10, // 4 + 2 != 10
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('fromCounts throws ArgumentError on negative counts', () {
      expect(
        () => LearningStatistics.fromCounts(
          correctAnswers: -5,
          incorrectAnswers: 3,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningStatistics.fromCounts(
          correctAnswers: 5,
          incorrectAnswers: -3,
        ),
        throwsArgumentError,
      );
    });

    test('fromCounts throws ArgumentError on inconsistent totalAnswered', () {
      expect(
        () => LearningStatistics.fromCounts(
          correctAnswers: 4,
          incorrectAnswers: 3,
          totalAnswered: 8,
        ),
        throwsArgumentError,
      );
    });

    test('fromTotalAndCorrect throws ArgumentError when correct exceeds total', () {
      expect(
        () => LearningStatistics.fromTotalAndCorrect(
          totalAnswered: 5,
          correctAnswers: 8,
        ),
        throwsArgumentError,
      );
    });

    test('fromTotalAndCorrect throws ArgumentError on negative numbers', () {
      expect(
        () => LearningStatistics.fromTotalAndCorrect(
          totalAnswered: -5,
          correctAnswers: 2,
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningStatistics.fromTotalAndCorrect(
          totalAnswered: 5,
          correctAnswers: -2,
        ),
        throwsArgumentError,
      );
    });

    test('fromMap throws ArgumentError on negative answer counts', () {
      expect(
        () => LearningStatistics.fromMap({'correctAnswers': -1, 'incorrectAnswers': 5}),
        throwsArgumentError,
      );

      expect(
        () => LearningStatistics.fromMap({'correctAnswers': 5, 'incorrectAnswers': -1}),
        throwsArgumentError,
      );
    });

    test('fromMap throws ArgumentError on inconsistent totalAnswered', () {
      expect(
        () => LearningStatistics.fromMap({
          'correctAnswers': 4,
          'incorrectAnswers': 2,
          'totalAnswered': 10,
        }),
        throwsArgumentError,
      );
    });

    test('fromJson throws FormatException on invalid json or non-map payloads', () {
      expect(
        () => LearningStatistics.fromJson('invalid json string'),
        throwsFormatException,
      );

      expect(
        () => LearningStatistics.fromJson('[1, 2, 3]'),
        throwsFormatException,
      );
    });
  });

  group('LearningStatistics - Equality, HashCode, CopyWith, and ToString', () {
    test('implements value equality and hash code consistency', () {
      const a = LearningStatistics(correctAnswers: 5, incorrectAnswers: 2);
      const b = LearningStatistics(correctAnswers: 5, incorrectAnswers: 2);
      const c = LearningStatistics(correctAnswers: 4, incorrectAnswers: 3);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith updates fields selectively', () {
      const original = LearningStatistics(correctAnswers: 3, incorrectAnswers: 2);

      final updatedCorrect = original.copyWith(correctAnswers: 5);
      expect(updatedCorrect.correctAnswers, 5);
      expect(updatedCorrect.incorrectAnswers, 2);
      expect(updatedCorrect.totalAnswered, 7);

      final updatedIncorrect = original.copyWith(incorrectAnswers: 4);
      expect(updatedIncorrect.correctAnswers, 3);
      expect(updatedIncorrect.incorrectAnswers, 4);
      expect(updatedIncorrect.totalAnswered, 7);
    });

    test('toString includes key statistics', () {
      const stats = LearningStatistics(correctAnswers: 8, incorrectAnswers: 2);
      final str = stats.toString();

      expect(str, contains('correctAnswers: 8'));
      expect(str, contains('incorrectAnswers: 2'));
      expect(str, contains('totalAnswered: 10'));
      expect(str, contains('accuracyPercentage: 80.0%'));
    });
  });
}
