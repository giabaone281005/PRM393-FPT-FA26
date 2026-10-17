import 'dart:convert';

class LearningStatistics {
  final int correctAnswers;
  final int incorrectAnswers;

  const LearningStatistics({
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    int? totalAnswered,
  })  : assert(correctAnswers >= 0, 'correctAnswers must be non-negative'),
        assert(incorrectAnswers >= 0, 'incorrectAnswers must be non-negative'),
        assert(
          totalAnswered == null ||
              totalAnswered == correctAnswers + incorrectAnswers,
          'totalAnswered must equal correctAnswers + incorrectAnswers',
        );

  const LearningStatistics.empty()
      : correctAnswers = 0,
        incorrectAnswers = 0;

  static const LearningStatistics zero = LearningStatistics.empty();

  factory LearningStatistics.fromCounts({
    required int correctAnswers,
    required int incorrectAnswers,
    int? totalAnswered,
  }) {
    if (correctAnswers < 0) {
      throw ArgumentError.value(
        correctAnswers,
        'correctAnswers',
        'correctAnswers must be non-negative',
      );
    }
    if (incorrectAnswers < 0) {
      throw ArgumentError.value(
        incorrectAnswers,
        'incorrectAnswers',
        'incorrectAnswers must be non-negative',
      );
    }
    if (totalAnswered != null &&
        totalAnswered != correctAnswers + incorrectAnswers) {
      throw ArgumentError.value(
        totalAnswered,
        'totalAnswered',
        'totalAnswered ($totalAnswered) does not match correctAnswers ($correctAnswers) + incorrectAnswers ($incorrectAnswers)',
      );
    }
    return LearningStatistics(
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      totalAnswered: totalAnswered,
    );
  }

  factory LearningStatistics.fromTotalAndCorrect({
    required int totalAnswered,
    required int correctAnswers,
  }) {
    if (totalAnswered < 0) {
      throw ArgumentError.value(
        totalAnswered,
        'totalAnswered',
        'totalAnswered must be non-negative',
      );
    }
    if (correctAnswers < 0) {
      throw ArgumentError.value(
        correctAnswers,
        'correctAnswers',
        'correctAnswers must be non-negative',
      );
    }
    if (correctAnswers > totalAnswered) {
      throw ArgumentError.value(
        correctAnswers,
        'correctAnswers',
        'correctAnswers ($correctAnswers) cannot exceed totalAnswered ($totalAnswered)',
      );
    }
    return LearningStatistics(
      correctAnswers: correctAnswers,
      incorrectAnswers: totalAnswered - correctAnswers,
      totalAnswered: totalAnswered,
    );
  }

  int get totalAnswered => correctAnswers + incorrectAnswers;

  int get totalAnsweredQuestions => totalAnswered;

  int get totalQuestions => totalAnswered;

  double get accuracyPercentage =>
      totalAnswered == 0 ? 0.0 : (correctAnswers / totalAnswered) * 100.0;

  double get accuracy => accuracyPercentage;

  LearningStatistics copyWith({
    int? correctAnswers,
    int? incorrectAnswers,
  }) {
    return LearningStatistics(
      correctAnswers: correctAnswers ?? this.correctAnswers,
      incorrectAnswers: incorrectAnswers ?? this.incorrectAnswers,
    );
  }

  LearningStatistics recordAnswer({required bool isCorrect}) {
    return LearningStatistics(
      correctAnswers: isCorrect ? correctAnswers + 1 : correctAnswers,
      incorrectAnswers: isCorrect ? incorrectAnswers : incorrectAnswers + 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'totalAnswered': totalAnswered,
      'accuracyPercentage': accuracyPercentage,
    };
  }

  factory LearningStatistics.fromMap(Map<String, dynamic> map) {
    int? parseCount(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    final correct =
        parseCount(map['correctAnswers'] ?? map['correct_answers']) ?? 0;
    final incorrect =
        parseCount(map['incorrectAnswers'] ?? map['incorrect_answers']) ?? 0;

    if (correct < 0) {
      throw ArgumentError.value(
        correct,
        'correctAnswers',
        'correctAnswers must be non-negative',
      );
    }
    if (incorrect < 0) {
      throw ArgumentError.value(
        incorrect,
        'incorrectAnswers',
        'incorrectAnswers must be non-negative',
      );
    }

    final total = parseCount(map['totalAnswered'] ?? map['total_answered']);
    if (total != null && total != correct + incorrect) {
      throw ArgumentError.value(
        total,
        'totalAnswered',
        'totalAnswered ($total) does not match sum of correctAnswers ($correct) and incorrectAnswers ($incorrect)',
      );
    }

    return LearningStatistics(
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      totalAnswered: total,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LearningStatistics.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Invalid JSON for LearningStatistics');
    }
    return LearningStatistics.fromMap(Map<String, dynamic>.from(decoded));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningStatistics &&
        other.correctAnswers == correctAnswers &&
        other.incorrectAnswers == incorrectAnswers;
  }

  @override
  int get hashCode => Object.hash(correctAnswers, incorrectAnswers);

  @override
  String toString() {
    return 'LearningStatistics(correctAnswers: $correctAnswers, incorrectAnswers: $incorrectAnswers, totalAnswered: $totalAnswered, accuracyPercentage: $accuracyPercentage%)';
  }
}
