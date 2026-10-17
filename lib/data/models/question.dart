enum QuestionType {
  dragCounters, // Lớp 1-2: Kéo thả que tính / hoa quả
  multiplicationTable, // Lớp 2-3: Bảng cửu chương
  clockRotation, // Lớp 2-3: Xoay kim đồng hồ
  areaGrid, // Lớp 3-4: Đo diện tích / chu vi lưới ô vuông
  wordProblem, // Lớp 4-5: Phân tích bài toán có lời văn
}

class SocraticHint {
  final int step;
  final String questionText;
  final String hintText;

  SocraticHint({
    required this.step,
    required this.questionText,
    required this.hintText,
  });
}

class Question {
  factory Question.fromMap(Map<String, dynamic> q) {
    final payload = Map<String, dynamic>.from(q['payload'] as Map? ?? {});
    return Question(
      id: q['id'].toString(),
      type: switch (q['question_type']) {
        'drag_counters' => QuestionType.dragCounters,
        'clock_rotation' => QuestionType.clockRotation,
        'area_grid' => QuestionType.areaGrid,
        'multiplication_table' => QuestionType.multiplicationTable,
        _ => QuestionType.wordProblem,
      },
      prompt: q['prompt']?.toString() ?? '',
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
  }
  final String id;
  final QuestionType type;
  final String prompt;
  final String subtitle;
  final Map<String, dynamic> data;
  final dynamic correctAnswer;
  final List<SocraticHint> socraticHints;

  Question({
    required this.id,
    required this.type,
    required this.prompt,
    this.subtitle = '',
    required this.data,
    required this.correctAnswer,
    this.socraticHints = const [],
  });
}
