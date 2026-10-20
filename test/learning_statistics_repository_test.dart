import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/learning_statistics.dart';
import 'package:mathlingo/data/repositories/learning_statistics_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LearningStatisticsRepository - Empty storage', () {
    test('returns empty statistics when storage has no entry', () async {
      final stats = await LearningStatisticsRepository.getStatistics();

      expect(stats.correctAnswers, 0);
      expect(stats.incorrectAnswers, 0);
      expect(stats.totalAnswered, 0);
      expect(stats.accuracyPercentage, 0.0);
      expect(stats, equals(const LearningStatistics.empty()));
    });

    test('returns empty statistics for specific kidId when storage is empty', () async {
      final stats = await LearningStatisticsRepository.getStatistics(kidId: 'kid_123');

      expect(stats.correctAnswers, 0);
      expect(stats.incorrectAnswers, 0);
      expect(stats.totalAnswered, 0);
      expect(stats.accuracyPercentage, 0.0);
    });

    test('alias methods getLearningStatistics and fetchStatistics return empty statistics', () async {
      final stats1 = await LearningStatisticsRepository.getLearningStatistics();
      final stats2 = await LearningStatisticsRepository.fetchStatistics();

      expect(stats1, equals(const LearningStatistics.empty()));
      expect(stats2, equals(const LearningStatistics.empty()));
    });
  });

  group('LearningStatisticsRepository - Recording correct answers', () {
    test('records a single correct answer starting from empty storage', () async {
      final updated = await LearningStatisticsRepository.recordCorrectAnswer();

      expect(updated.correctAnswers, 1);
      expect(updated.incorrectAnswers, 0);
      expect(updated.totalAnswered, 1);
      expect(updated.accuracyPercentage, 100.0);
    });

    test('increments correct answers sequentially across multiple calls', () async {
      await LearningStatisticsRepository.recordCorrectAnswer();
      await LearningStatisticsRepository.recordCorrectAnswer();
      final third = await LearningStatisticsRepository.recordCorrectAnswer();

      expect(third.correctAnswers, 3);
      expect(third.incorrectAnswers, 0);
      expect(third.totalAnswered, 3);
      expect(third.accuracyPercentage, 100.0);
    });

    test('recordAnswer(isCorrect: true) records correct answer', () async {
      final result = await LearningStatisticsRepository.recordAnswer(isCorrect: true);

      expect(result.correctAnswers, 1);
      expect(result.incorrectAnswers, 0);
      expect(result.accuracyPercentage, 100.0);
    });
  });

  group('LearningStatisticsRepository - Recording incorrect answers', () {
    test('records a single incorrect answer starting from empty storage', () async {
      final updated = await LearningStatisticsRepository.recordIncorrectAnswer();

      expect(updated.correctAnswers, 0);
      expect(updated.incorrectAnswers, 1);
      expect(updated.totalAnswered, 1);
      expect(updated.accuracyPercentage, 0.0);
    });

    test('increments incorrect answers sequentially across multiple calls', () async {
      await LearningStatisticsRepository.recordIncorrectAnswer();
      final second = await LearningStatisticsRepository.recordIncorrectAnswer();

      expect(second.correctAnswers, 0);
      expect(second.incorrectAnswers, 2);
      expect(second.totalAnswered, 2);
      expect(second.accuracyPercentage, 0.0);
    });

    test('recordAnswer(isCorrect: false) records incorrect answer', () async {
      final result = await LearningStatisticsRepository.recordAnswer(isCorrect: false);

      expect(result.correctAnswers, 0);
      expect(result.incorrectAnswers, 1);
      expect(result.accuracyPercentage, 0.0);
    });
  });

  group('LearningStatisticsRepository - Accuracy after multiple answers', () {
    test('accurately calculates accuracy through mixed answer progressions', () async {
      // 3 correct, 1 incorrect -> 75%
      await LearningStatisticsRepository.recordCorrectAnswer();
      await LearningStatisticsRepository.recordCorrectAnswer();
      await LearningStatisticsRepository.recordCorrectAnswer();
      final fourth = await LearningStatisticsRepository.recordIncorrectAnswer();

      expect(fourth.correctAnswers, 3);
      expect(fourth.incorrectAnswers, 1);
      expect(fourth.totalAnswered, 4);
      expect(fourth.accuracyPercentage, 75.0);

      // Add 1 more correct -> 4 / 5 = 80%
      final fifth = await LearningStatisticsRepository.recordCorrectAnswer();
      expect(fifth.correctAnswers, 4);
      expect(fifth.incorrectAnswers, 1);
      expect(fifth.totalAnswered, 5);
      expect(fifth.accuracyPercentage, 80.0);

      // Add 3 incorrect -> 4 / 8 = 50%
      await LearningStatisticsRepository.recordIncorrectAnswer();
      await LearningStatisticsRepository.recordIncorrectAnswer();
      final eighth = await LearningStatisticsRepository.recordIncorrectAnswer();
      expect(eighth.correctAnswers, 4);
      expect(eighth.incorrectAnswers, 4);
      expect(eighth.totalAnswered, 8);
      expect(eighth.accuracyPercentage, 50.0);
    });

    test('recordAnswers supports batch additions', () async {
      final result = await LearningStatisticsRepository.recordAnswers(
        correct: 6,
        incorrect: 2,
      );

      expect(result.correctAnswers, 6);
      expect(result.incorrectAnswers, 2);
      expect(result.totalAnswered, 8);
      expect(result.accuracyPercentage, 75.0);
    });
  });

  group('LearningStatisticsRepository - Persistence and reload', () {
    test('persists updates and reloads accurately', () async {
      await LearningStatisticsRepository.recordCorrectAnswer(kidId: 'kid_test');
      await LearningStatisticsRepository.recordCorrectAnswer(kidId: 'kid_test');
      await LearningStatisticsRepository.recordIncorrectAnswer(kidId: 'kid_test');

      // Reload fresh from storage
      final reloaded = await LearningStatisticsRepository.getStatistics(kidId: 'kid_test');

      expect(reloaded.correctAnswers, 2);
      expect(reloaded.incorrectAnswers, 1);
      expect(reloaded.totalAnswered, 3);
      expect(reloaded.accuracyPercentage, closeTo(66.6666, 0.001));
    });

    test('stores only ground truth counts without duplicating derived accuracy in storage payload', () async {
      const stats = LearningStatistics(correctAnswers: 9, incorrectAnswers: 1);
      await LearningStatisticsRepository.saveStatistics(stats, kidId: 'kid_raw_check');

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(LearningStatisticsRepository.storageKey('kid_raw_check'));
      expect(raw, isNotNull);

      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded.containsKey('correctAnswers'), isTrue);
      expect(decoded.containsKey('incorrectAnswers'), isTrue);
      // Ensure accuracy is NOT duplicated in storage
      expect(decoded.containsKey('accuracyPercentage'), isFalse);
      expect(decoded.containsKey('accuracy'), isFalse);
    });

    test('isolates statistics by kidId', () async {
      await LearningStatisticsRepository.recordCorrectAnswer(kidId: 'kid_alice');
      await LearningStatisticsRepository.recordIncorrectAnswer(kidId: 'kid_bob');

      final aliceStats = await LearningStatisticsRepository.getStatistics(kidId: 'kid_alice');
      final bobStats = await LearningStatisticsRepository.getStatistics(kidId: 'kid_bob');
      final defaultStats = await LearningStatisticsRepository.getStatistics();

      expect(aliceStats.correctAnswers, 1);
      expect(aliceStats.incorrectAnswers, 0);

      expect(bobStats.correctAnswers, 0);
      expect(bobStats.incorrectAnswers, 1);

      expect(defaultStats.totalAnswered, 0);
    });

    test('clearStatistics removes persisted data and resets to empty', () async {
      await LearningStatisticsRepository.recordCorrectAnswer(kidId: 'kid_clear');
      expect((await LearningStatisticsRepository.getStatistics(kidId: 'kid_clear')).totalAnswered, 1);

      final cleared = await LearningStatisticsRepository.clearStatistics(kidId: 'kid_clear');
      expect(cleared, isTrue);

      final afterClear = await LearningStatisticsRepository.getStatistics(kidId: 'kid_clear');
      expect(afterClear, equals(const LearningStatistics.empty()));
    });
  });

  group('LearningStatisticsRepository - Invalid or corrupted stored data error handling', () {
    test('returns empty statistics when storage contains invalid json syntax', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LearningStatisticsRepository.storageKey('kid_corrupt'),
        '{invalid_json: true, unterminated...',
      );

      final stats = await LearningStatisticsRepository.getStatistics(
        kidId: 'kid_corrupt',
        prefs: prefs,
      );

      expect(stats, equals(const LearningStatistics.empty()));
    });

    test('returns empty statistics when storage contains non-map json types', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LearningStatisticsRepository.storageKey('kid_list'),
        '[1, 2, 3]',
      );

      final stats = await LearningStatisticsRepository.getStatistics(
        kidId: 'kid_list',
        prefs: prefs,
      );

      expect(stats, equals(const LearningStatistics.empty()));
    });

    test('returns empty statistics when storage contains blank or whitespace strings', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LearningStatisticsRepository.storageKey('kid_blank'),
        '   ',
      );

      final stats = await LearningStatisticsRepository.getStatistics(
        kidId: 'kid_blank',
        prefs: prefs,
      );

      expect(stats, equals(const LearningStatistics.empty()));
    });

    test('returns empty statistics when stored map contains negative counts', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LearningStatisticsRepository.storageKey('kid_neg'),
        jsonEncode({'correctAnswers': -5, 'incorrectAnswers': 3}),
      );

      final stats = await LearningStatisticsRepository.getStatistics(
        kidId: 'kid_neg',
        prefs: prefs,
      );

      expect(stats, equals(const LearningStatistics.empty()));
    });

    test('returns empty statistics when stored map has inconsistent totalAnswered', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        LearningStatisticsRepository.storageKey('kid_inconsistent'),
        jsonEncode({
          'correctAnswers': 3,
          'incorrectAnswers': 2,
          'totalAnswered': 99,
        }),
      );

      final stats = await LearningStatisticsRepository.getStatistics(
        kidId: 'kid_inconsistent',
        prefs: prefs,
      );

      expect(stats, equals(const LearningStatistics.empty()));
    });
  });

  group('LearningStatisticsRepository - Injected SharedPreferences and scoped usage', () {
    test('explicit prefs parameter functions correctly and isolates data', () async {
      final prefs = await SharedPreferences.getInstance();
      const kidId = 'scoped_kid';

      expect(
        (await LearningStatisticsRepository.getStatistics(kidId: kidId, prefs: prefs)).totalAnswered,
        0,
      );

      await LearningStatisticsRepository.recordCorrectAnswer(kidId: kidId, prefs: prefs);
      await LearningStatisticsRepository.recordAnswer(isCorrect: true, kidId: kidId, prefs: prefs);
      await LearningStatisticsRepository.recordIncorrectAnswer(kidId: kidId, prefs: prefs);

      final current = await LearningStatisticsRepository.getStatistics(kidId: kidId, prefs: prefs);
      expect(current.correctAnswers, 2);
      expect(current.incorrectAnswers, 1);
      expect(current.totalAnswered, 3);
      expect(current.accuracyPercentage, closeTo(66.6666, 0.001));

      await LearningStatisticsRepository.recordAnswers(correct: 2, incorrect: 0, kidId: kidId, prefs: prefs);
      expect(
        (await LearningStatisticsRepository.getStatistics(kidId: kidId, prefs: prefs)).correctAnswers,
        4,
      );

      await LearningStatisticsRepository.resetStatistics(kidId: kidId, prefs: prefs);
      expect(
        (await LearningStatisticsRepository.getStatistics(kidId: kidId, prefs: prefs)).totalAnswered,
        0,
      );
    });
  });
}
