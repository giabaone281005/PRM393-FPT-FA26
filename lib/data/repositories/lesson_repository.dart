import '../../core/supabase/supabase_service.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson.dart';
import '../models/question.dart';
import 'study_repository.dart';

class LessonRepository {
  static Future<List<Lesson>> fetchLessonsForGrade(
    int grade, {
    String? kidId,
  }) async {
    final client = SupabaseService.client;
    if (client == null || kidId == null) return [];
    dynamic rows;
    final prefs = await SharedPreferences.getInstance();
    final key = 'study:${client.auth.currentUser!.id}:curriculum:$kidId';
    try {
      rows = await client.rpc('get_kid_curriculum', params: {'p_kid': kidId});
      await prefs.setString(
        key,
        jsonEncode({
          'expires': DateTime.now()
              .add(const Duration(minutes: 15))
              .toIso8601String(),
          'rows': rows,
        }),
      );
    } catch (error) {
      if (!StudyRepository.isTransient(error)) rethrow;
      final raw = prefs.getString(key);
      if (raw == null) rethrow;
      final cached = jsonDecode(raw);
      if (!DateTime.parse(cached['expires']).isAfter(DateTime.now())) rethrow;
      rows = cached['rows'];
    }
    return lessonsFromRows(rows as List, grade);
  }

  static List<Lesson> lessonsFromRows(List rows, int grade) {
    // Lesson numbers can repeat; progress and study sessions use the lesson ID.
    final uniqueRows = <String, Map<String, dynamic>>{};
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      uniqueRows.putIfAbsent(row['id'].toString(), () => row);
    }

    return uniqueRows.values.map((row) {
      final completed = row['is_completed'] == true;
      final status = completed
          ? LessonStatus.completed
          : row['can_start'] == true
          ? LessonStatus.available
          : LessonStatus.locked;
      final questions = (row['questions'] as List? ?? []).map((rawQ) {
        final q = Map<String, dynamic>.from(rawQ as Map);
        final payload = Map<String, dynamic>.from(q['payload'] as Map? ?? {});
        final type = switch (q['question_type']) {
          'drag_counters' => QuestionType.dragCounters,
          'clock_rotation' => QuestionType.clockRotation,
          'area_grid' => QuestionType.areaGrid,
          'multiplication_table' => QuestionType.multiplicationTable,
          _ => QuestionType.wordProblem,
        };
        return Question(
          id: q['id'].toString(),
          type: type,
          prompt: q['prompt']?.toString() ?? '',
          subtitle: payload['subtitle']?.toString() ?? '',
          data: payload,
          correctAnswer: payload['correctAnswer'] ?? payload['answer'],
          socraticHints: (q['socratic_hints'] as List? ?? [])
              .map(
                (h) => SocraticHint(
                  step: h['step'] ?? 1,
                  questionText: h['questionText'] ?? h['question_text'] ?? '',
                  hintText: h['hintText'] ?? h['hint_text'] ?? '',
                ),
              )
              .toList(),
        );
      }).toList();
      return Lesson(
        id: row['id'].toString(),
        grade: grade,
        lessonNumber: row['lesson_number'] as int,
        title: row['title'] as String,
        topicId: row['topic_id']?.toString() ?? '',
        topicTitle: row['topic_title']?.toString() ?? 'Bài học',
        subtitle: row['subtitle']?.toString() ?? '',
        estimatedMinutes: row['estimated_minutes'] as int,
        xpReward: row['xp_reward'] as int,
        starReward: row['star_reward'] as int,
        status: status,
        starsEarned: (row['stars_earned'] as num?)?.toInt() ?? 0,
        theory: row['theory']?.toString(),
        essayPrompt: row['essay_prompt']?.toString(),
        essayGuidance: row['essay_guidance']?.toString(),
        miniGameType: row['mini_game_type']?.toString(),
        requiresPlus: row['access_tier'] == 'plus',
        questions: questions,
      );
    }).toList();
  }
}
