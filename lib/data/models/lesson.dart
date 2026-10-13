import 'question.dart';

enum LessonStatus {
  locked,
  available,
  inProgress,
  completed,
}

class Lesson {
  final String id;
  final int grade;
  final int lessonNumber;
  final String title;
  final String subtitle;
  final int estimatedMinutes;
  final int xpReward;
  final int starReward;
  LessonStatus status;
  int starsEarned;
  final List<Question> questions;

  Lesson({
    required this.id,
    required this.grade,
    required this.lessonNumber,
    required this.title,
    required this.subtitle,
    this.estimatedMinutes = 3,
    this.xpReward = 30,
    this.starReward = 3,
    this.status = LessonStatus.locked,
    this.starsEarned = 0,
    required this.questions,
  });
}
