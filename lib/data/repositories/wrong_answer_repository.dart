import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/wrong_answer_record.dart';

class WrongAnswerRepository {
  static String storageKey(String kidId) => 'wrong_answers:$kidId';

  static Future<List<WrongAnswerRecord>> getWrongAnswers(
    String kidId, {
    String? lessonId,
    bool? includeResolved,
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty) return [];
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final raw = p.getString(storageKey(kidId));
      if (raw == null || raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final records = <WrongAnswerRecord>[];
      for (final item in decoded) {
        if (item is Map) {
          try {
            records.add(
              WrongAnswerRecord.fromMap(Map<String, dynamic>.from(item)),
            );
          } catch (_) {
            // Ignore malformed individual items safely
          }
        }
      }

      var filtered = records;
      if (lessonId != null) {
        filtered = filtered.where((r) => r.lessonId == lessonId).toList();
      }
      if (includeResolved != null) {
        filtered = filtered
            .where((r) => r.isResolved == includeResolved)
            .toList();
      }

      return filtered;
    } catch (_) {
      // Return empty list safely on JSON parsing error or storage corruption
      return [];
    }
  }

  static Future<void> saveWrongAnswer(
    String kidId,
    WrongAnswerRecord record, {
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty || record.questionId.trim().isEmpty) return;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = await getWrongAnswers(
        kidId,
        includeResolved: null,
        prefs: p,
      );

      final updated = List<WrongAnswerRecord>.from(current);
      final existingIndex = updated.indexWhere(
        (r) => r.questionId == record.questionId,
      );

      if (existingIndex >= 0) {
        // Update with latest attempt details
        updated[existingIndex] = record.copyWith(isResolved: false);
      } else {
        updated.add(record);
      }

      final encoded = jsonEncode(updated.map((r) => r.toMap()).toList());
      await p.setString(storageKey(kidId), encoded);
    } catch (_) {
      // Graceful error recovery without throwing
    }
  }

  static Future<bool> markResolved(
    String kidId,
    String questionId, {
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty || questionId.trim().isEmpty) return false;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = await getWrongAnswers(
        kidId,
        includeResolved: null,
        prefs: p,
      );

      final index = current.indexWhere((r) => r.questionId == questionId);
      if (index < 0) return false;

      final updated = List<WrongAnswerRecord>.from(current);
      updated[index] = updated[index].copyWith(isResolved: true);

      final encoded = jsonEncode(updated.map((r) => r.toMap()).toList());
      await p.setString(storageKey(kidId), encoded);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearWrongAnswers(
    String kidId, {
    String? lessonId,
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty) return;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      if (lessonId == null) {
        await p.remove(storageKey(kidId));
      } else {
        final current = await getWrongAnswers(
          kidId,
          includeResolved: null,
          prefs: p,
        );
        final remaining = current.where((r) => r.lessonId != lessonId).toList();
        if (remaining.isEmpty) {
          await p.remove(storageKey(kidId));
        } else {
          final encoded = jsonEncode(remaining.map((r) => r.toMap()).toList());
          await p.setString(storageKey(kidId), encoded);
        }
      }
    } catch (_) {
      // Graceful error recovery
    }
  }

  static Future<void> clearResolved(
    String kidId, {
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty) return;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = await getWrongAnswers(
        kidId,
        includeResolved: null,
        prefs: p,
      );
      final remaining = current.where((r) => !r.isResolved).toList();
      if (remaining.isEmpty) {
        await p.remove(storageKey(kidId));
      } else {
        final encoded = jsonEncode(remaining.map((r) => r.toMap()).toList());
        await p.setString(storageKey(kidId), encoded);
      }
    } catch (_) {
      // Graceful error recovery
    }
  }

  static Future<int> countUnresolved(
    String kidId, {
    String? lessonId,
    SharedPreferences? prefs,
  }) async {
    final list = await getWrongAnswers(
      kidId,
      lessonId: lessonId,
      includeResolved: false,
      prefs: prefs,
    );
    return list.length;
  }

  static Future<WrongAnswerRecord?> getWrongAnswer(
    String kidId,
    String questionId, {
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty || questionId.trim().isEmpty) return null;
    final list = await getWrongAnswers(
      kidId,
      includeResolved: null,
      prefs: prefs,
    );
    final index = list.indexWhere((r) => r.questionId == questionId);
    return index >= 0 ? list[index] : null;
  }

  static Future<bool> deleteWrongAnswer(
    String kidId,
    String questionId, {
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty || questionId.trim().isEmpty) return false;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = await getWrongAnswers(
        kidId,
        includeResolved: null,
        prefs: p,
      );
      final initialLength = current.length;
      final remaining = current
          .where((r) => r.questionId != questionId)
          .toList();
      if (remaining.length == initialLength) return false;

      if (remaining.isEmpty) {
        await p.remove(storageKey(kidId));
      } else {
        final encoded = jsonEncode(remaining.map((r) => r.toMap()).toList());
        await p.setString(storageKey(kidId), encoded);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> markAllResolved(
    String kidId, {
    String? lessonId,
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty) return 0;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = await getWrongAnswers(
        kidId,
        includeResolved: null,
        prefs: p,
      );
      if (current.isEmpty) return 0;

      var updatedCount = 0;
      final updated = current.map((r) {
        if ((lessonId == null || r.lessonId == lessonId) && !r.isResolved) {
          updatedCount++;
          return r.copyWith(isResolved: true);
        }
        return r;
      }).toList();

      if (updatedCount > 0) {
        final encoded = jsonEncode(updated.map((r) => r.toMap()).toList());
        await p.setString(storageKey(kidId), encoded);
      }
      return updatedCount;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> recordReviewAttempt(
    String kidId,
    String questionId, {
    required bool isCorrect,
    SharedPreferences? prefs,
  }) async {
    if (kidId.trim().isEmpty || questionId.trim().isEmpty) return false;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final current = await getWrongAnswers(
        kidId,
        includeResolved: null,
        prefs: p,
      );
      final index = current.indexWhere((r) => r.questionId == questionId);
      if (index < 0) return false;

      final updated = List<WrongAnswerRecord>.from(current);
      final existing = updated[index];
      updated[index] = existing.copyWith(
        isResolved: isCorrect,
        reviewCount: existing.reviewCount + 1,
        lastReviewedAt: DateTime.now(),
      );

      final encoded = jsonEncode(updated.map((r) => r.toMap()).toList());
      await p.setString(storageKey(kidId), encoded);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<String>> getLessonIdsWithWrongAnswers(
    String kidId, {
    bool onlyUnresolved = true,
    SharedPreferences? prefs,
  }) async {
    final list = await getWrongAnswers(
      kidId,
      includeResolved: onlyUnresolved ? false : null,
      prefs: prefs,
    );
    final lessonIds = <String>{};
    for (final item in list) {
      if (item.lessonId != null && item.lessonId!.trim().isNotEmpty) {
        lessonIds.add(item.lessonId!);
      }
    }
    return lessonIds.toList();
  }
}
