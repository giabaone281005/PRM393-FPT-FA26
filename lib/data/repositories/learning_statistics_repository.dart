import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/streak_calculator.dart';
import '../models/learning_statistics.dart';

/// Repository for retrieving and persisting learning statistics using [SharedPreferences].
///
/// Ground truth counts (`correctAnswers` and `incorrectAnswers`) are persisted.
/// Derived metrics such as `totalAnswered` and `accuracyPercentage` are computed
/// by [LearningStatistics] to prevent duplicate sources of truth.
class LearningStatisticsRepository {
  /// Returns the storage key for learning statistics.
  /// If [kidId] is provided, returns a kid-specific key; otherwise returns the default key.
  static String storageKey([String? kidId]) {
    if (kidId != null && kidId.trim().isNotEmpty) {
      return 'learning_statistics:${kidId.trim()}';
    }
    return 'learning_statistics';
  }

  /// Retrieves current learning statistics from storage.
  /// Returns [LearningStatistics.empty] if empty, corrupted, or parsing fails.
  static Future<LearningStatistics> getStatistics({
    String? kidId,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getString(storageKey(kidId));
      if (raw == null || raw.trim().isEmpty) {
        return const LearningStatistics.empty();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const LearningStatistics.empty();
      }

      return LearningStatistics.fromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // Return zeroed statistics safely on JSON parsing error, format error, or storage corruption
      return const LearningStatistics.empty();
    }
  }

  /// Alias for [getStatistics].
  static Future<LearningStatistics> getLearningStatistics({
    String? kidId,
    SharedPreferences? prefs,
  }) =>
      getStatistics(kidId: kidId, prefs: prefs);

  /// Alias for [getStatistics].
  static Future<LearningStatistics> fetchStatistics({
    String? kidId,
    SharedPreferences? prefs,
  }) =>
      getStatistics(kidId: kidId, prefs: prefs);

  /// Saves learning statistics to storage.
  /// Stores only the independent ground-truth counts to avoid duplicate sources of truth.
  static Future<bool> saveStatistics(
    LearningStatistics statistics, {
    String? kidId,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final payload = {
        'correctAnswers': statistics.correctAnswers,
        'incorrectAnswers': statistics.incorrectAnswers,
      };
      return await p.setString(storageKey(kidId), jsonEncode(payload));
    } catch (_) {
      return false;
    }
  }

  /// Returns the storage key for learning activity dates.
  static String activityStorageKey([String? kidId]) {
    if (kidId != null && kidId.trim().isNotEmpty) {
      return 'learning_activity_dates:${kidId.trim()}';
    }
    return 'learning_activity_dates';
  }

  /// Returns the storage key for processed answer events to ensure idempotency.
  static String eventsStorageKey([String? kidId]) {
    if (kidId != null && kidId.trim().isNotEmpty) {
      return 'learning_processed_events:${kidId.trim()}';
    }
    return 'learning_processed_events';
  }

  /// Retrieves recorded learning activity dates.
  static Future<List<DateTime>> getActivityDates({
    String? kidId,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getStringList(activityStorageKey(kidId));
      if (raw == null || raw.isEmpty) return [];
      final dates = <DateTime>[];
      for (final s in raw) {
        final d = DateTime.tryParse(s);
        if (d != null) dates.add(d);
      }
      return dates;
    } catch (_) {
      return [];
    }
  }

  /// Records an activity date to track the learning streak.
  static Future<void> recordActivityDate(
    DateTime date, {
    String? kidId,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = p.getStringList(activityStorageKey(kidId)) ?? [];
      final iso = date.toIso8601String();
      if (!current.contains(iso)) {
        final updated = List<String>.from(current)..add(iso);
        await p.setStringList(activityStorageKey(kidId), updated);
      }
    } catch (_) {}
  }

  /// Calculates the current learning streak from recorded activity dates.
  static Future<LearningStreak> getStreak({
    String? kidId,
    DateTime? referenceDate,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final dates = await getActivityDates(kidId: kidId, prefs: p);
      return StreakCalculator.calculate(
        activityDates: dates,
        referenceDate: referenceDate,
      );
    } catch (_) {
      return const LearningStreak.empty();
    }
  }

  /// Records a single answer attempt and updates the persisted statistics and streak activity.
  ///
  /// If [eventId] is provided and has already been processed, returns current statistics
  /// without double counting.
  static Future<LearningStatistics> recordAnswer({
    required bool isCorrect,
    String? kidId,
    String? eventId,
    DateTime? timestamp,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();

      // Check event idempotency
      if (eventId != null && eventId.trim().isNotEmpty) {
        final processed = p.getStringList(eventsStorageKey(kidId)) ?? [];
        if (processed.contains(eventId.trim())) {
          return await getStatistics(kidId: kidId, prefs: p);
        }
        final updatedEvents = List<String>.from(processed)..add(eventId.trim());
        await p.setStringList(eventsStorageKey(kidId), updatedEvents);
      }

      // Record activity date for streak calculation
      final now = timestamp ?? DateTime.now();
      await recordActivityDate(now, kidId: kidId, prefs: p);

      final current = await getStatistics(kidId: kidId, prefs: p);
      final updated = current.recordAnswer(isCorrect: isCorrect);
      await saveStatistics(updated, kidId: kidId, prefs: p);
      return updated;
    } catch (_) {
      return isCorrect
          ? const LearningStatistics(correctAnswers: 1, incorrectAnswers: 0)
          : const LearningStatistics(correctAnswers: 0, incorrectAnswers: 1);
    }
  }

  /// Records a correct answer attempt and updates persisted statistics.
  static Future<LearningStatistics> recordCorrectAnswer({
    String? kidId,
    SharedPreferences? prefs,
  }) =>
      recordAnswer(isCorrect: true, kidId: kidId, prefs: prefs);

  /// Records an incorrect answer attempt and updates persisted statistics.
  static Future<LearningStatistics> recordIncorrectAnswer({
    String? kidId,
    SharedPreferences? prefs,
  }) =>
      recordAnswer(isCorrect: false, kidId: kidId, prefs: prefs);

  /// Records multiple answer attempts in batch and updates persisted statistics.
  static Future<LearningStatistics> recordAnswers({
    int correct = 0,
    int incorrect = 0,
    String? kidId,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = await getStatistics(kidId: kidId, prefs: p);
      final validCorrect = correct > 0 ? correct : 0;
      final validIncorrect = incorrect > 0 ? incorrect : 0;
      final updated = LearningStatistics(
        correctAnswers: current.correctAnswers + validCorrect,
        incorrectAnswers: current.incorrectAnswers + validIncorrect,
      );
      await saveStatistics(updated, kidId: kidId, prefs: p);
      return updated;
    } catch (_) {
      return const LearningStatistics.empty();
    }
  }

  /// Clears persisted learning statistics for the given [kidId].
  static Future<bool> clearStatistics({
    String? kidId,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.remove(activityStorageKey(kidId));
      await p.remove(eventsStorageKey(kidId));
      return await p.remove(storageKey(kidId));
    } catch (_) {
      return false;
    }
  }

  /// Alias for [clearStatistics].
  static Future<bool> resetStatistics({
    String? kidId,
    SharedPreferences? prefs,
  }) =>
      clearStatistics(kidId: kidId, prefs: prefs);
}
