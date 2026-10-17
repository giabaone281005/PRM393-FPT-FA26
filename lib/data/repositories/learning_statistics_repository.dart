import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  /// Records a single answer attempt and updates the persisted statistics.
  static Future<LearningStatistics> recordAnswer({
    required bool isCorrect,
    String? kidId,
    SharedPreferences? prefs,
  }) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
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
