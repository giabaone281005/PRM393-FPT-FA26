import 'dart:convert';

import 'question.dart';

class WrongAnswerRecord {
  final String questionId;
  final String prompt;
  final QuestionType questionType;
  final dynamic userAnswer;
  final String? lessonId;
  final DateTime timestamp;
  final bool isResolved;
  final Map<String, dynamic>? questionData;

  const WrongAnswerRecord({
    required this.questionId,
    required this.prompt,
    required this.questionType,
    required this.userAnswer,
    this.lessonId,
    required this.timestamp,
    this.isResolved = false,
    this.questionData,
  });

  static QuestionType parseQuestionType(dynamic type) {
    if (type == null) return QuestionType.wordProblem;
    final str = type.toString();
    for (final t in QuestionType.values) {
      if (t.name == str) return t;
    }
    return switch (str) {
      'drag_counters' => QuestionType.dragCounters,
      'clock_rotation' => QuestionType.clockRotation,
      'area_grid' => QuestionType.areaGrid,
      'multiplication_table' => QuestionType.multiplicationTable,
      _ => QuestionType.wordProblem,
    };
  }

  WrongAnswerRecord copyWith({
    String? questionId,
    String? prompt,
    QuestionType? questionType,
    dynamic userAnswer,
    String? lessonId,
    DateTime? timestamp,
    bool? isResolved,
    Map<String, dynamic>? questionData,
  }) {
    return WrongAnswerRecord(
      questionId: questionId ?? this.questionId,
      prompt: prompt ?? this.prompt,
      questionType: questionType ?? this.questionType,
      userAnswer: userAnswer ?? this.userAnswer,
      lessonId: lessonId ?? this.lessonId,
      timestamp: timestamp ?? this.timestamp,
      isResolved: isResolved ?? this.isResolved,
      questionData: questionData ?? this.questionData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'prompt': prompt,
      'questionType': questionType.name,
      'userAnswer': userAnswer,
      'lessonId': lessonId,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved,
      if (questionData != null) 'questionData': questionData,
    };
  }

  factory WrongAnswerRecord.fromMap(Map<String, dynamic> map) {
    return WrongAnswerRecord(
      questionId: map['questionId']?.toString() ?? '',
      prompt: map['prompt']?.toString() ?? '',
      questionType: parseQuestionType(map['questionType']),
      userAnswer: map['userAnswer'],
      lessonId: map['lessonId']?.toString(),
      timestamp:
          DateTime.tryParse(map['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      isResolved: map['isResolved'] == true,
      questionData: map['questionData'] is Map
          ? Map<String, dynamic>.from(map['questionData'] as Map)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WrongAnswerRecord.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Invalid JSON for WrongAnswerRecord');
    }
    return WrongAnswerRecord.fromMap(Map<String, dynamic>.from(decoded));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WrongAnswerRecord &&
        other.questionId == questionId &&
        other.prompt == prompt &&
        other.questionType == questionType &&
        other.lessonId == lessonId &&
        other.isResolved == isResolved;
  }

  @override
  int get hashCode =>
      Object.hash(questionId, prompt, questionType, lessonId, isResolved);
}
