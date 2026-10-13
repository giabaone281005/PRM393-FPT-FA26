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
