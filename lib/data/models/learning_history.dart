class LearningHistoryEntry {
  LearningHistoryEntry.fromMap(Map<String, dynamic> row)
    : id = row['id'] as String,
      kidId = row['kid_id'] as String,
      lessonId = row['lesson_id'] as String?,
      title = row['title'] as String,
      kind = row['kind'] as String,
      status = row['status'] as String,
      updatedAt = DateTime.parse(row['updated_at'] as String),
      durationSeconds = (row['duration_seconds'] as num?)?.toInt() ?? 0,
      questionIndex = (row['question_index'] as num?)?.toInt() ?? 0,
      questionCount = (row['question_count'] as num?)?.toInt() ?? 0,
      correctCount = (row['correct_count'] as num?)?.toInt() ?? 0,
      attemptCount = (row['attempt_count'] as num?)?.toInt() ?? 0,
      accuracy = (row['accuracy_percent'] as num?)?.toInt(),
      xp = (row['xp_earned'] as num?)?.toInt() ?? 0,
      stars = (row['stars_awarded'] as num?)?.toInt() ?? 0;

  final String id, kidId, title, kind, status;
  final String? lessonId;
  final DateTime updatedAt;
  final int durationSeconds,
      questionIndex,
      questionCount,
      correctCount,
      attemptCount,
      xp,
      stars;
  final int? accuracy;
  bool get completed => status == 'completed';
  bool get canResume => status == 'active' || status == 'paused';
  String get kindLabel => switch (kind) {
    'practice' => 'Luyện tập',
    'arena' => 'Đấu trường',
    _ => 'Bài học',
  };
  String get statusLabel => completed
      ? 'Hoàn thành'
      : canResume
      ? 'Đang học'
      : 'Đã kết thúc';
}

class LearningAttempt {
  LearningAttempt.fromMap(Map<String, dynamic> row)
    : id = row['id'] as String,
      prompt = row['prompt']?.toString() ?? 'Câu hỏi',
      answer = row['answer']?.toString() ?? 'Chưa có đáp án',
      correct = row['is_correct'] == true,
      hintsUsed = (row['hints_used'] as num?)?.toInt() ?? 0,
      hints = (row['hints'] as List? ?? [])
          .map((hint) {
            final h = hint as Map;
            return (h['hint_text'] ?? h['hintText'] ?? '').toString();
          })
          .where((hint) => hint.isNotEmpty)
          .toList();
  final String id, prompt, answer;
  final bool correct;
  final int hintsUsed;
  final List<String> hints;
}
