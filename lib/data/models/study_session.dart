import 'question.dart';

class StudySession {
  final Map<String, dynamic> data;
  const StudySession(this.data);
  String get id => data['id'] as String;
  String get kidId => data['kid_id'] as String;
  String get kind => data['kind'] as String;
  String get title => data['title']?.toString() ?? 'Học toán';
  String get status => data['status']?.toString() ?? 'active';
  String get theory => data['theory']?.toString() ?? '';
  String get essayPrompt => data['essay_prompt']?.toString() ?? '';
  int get index => (data['question_index'] as num?)?.toInt() ?? 0;
  int get hearts => (data['hearts'] as num?)?.toInt() ?? 0;
  int get remainingSeconds => (data['remaining_seconds'] as num?)?.toInt() ?? 0;
  bool get essayRequired => data['essay_required'] == true;
  bool get essayPassed => data['essay_passed'] == true;
  bool get completed => status == 'completed';
  bool get quizDone => index >= questions.length;
  List<Question> get questions => (data['questions'] as List? ?? [])
      .map((q) => Question.fromMap(Map<String, dynamic>.from(q as Map)))
      .toList();
  Question? get currentQuestion => quizDone ? null : questions[index];
  Map<String, dynamic> get viewState =>
      Map<String, dynamic>.from(data['view_state'] as Map? ?? {});
}
