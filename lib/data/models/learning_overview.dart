import 'lesson.dart';

class TopicProgress {
  TopicProgress(this.id, this.title, this.lessons);
  final String id, title;
  final List<Lesson> lessons;
  int get completed =>
      lessons.where((l) => l.status == LessonStatus.completed).length;
  double get fraction => lessons.isEmpty ? 0 : completed / lessons.length;

  static List<TopicProgress> group(List<Lesson> lessons) {
    final groups = <String, TopicProgress>{};
    for (final lesson in lessons) {
      final group = groups.putIfAbsent(
        lesson.topicId,
        () => TopicProgress(lesson.topicId, lesson.topicTitle, []),
      );
      if (!group.lessons.any((l) => l.id == lesson.id)) {
        group.lessons.add(lesson);
      }
    }
    return groups.values.toList();
  }
}

class LearningDay {
  const LearningDay(this.date, this.seconds);
  final DateTime date;
  final int seconds;
  String get duration => '${seconds ~/ 60} phút ${seconds % 60} giây';

  // Backend usage days use Vietnam's UTC+7 calendar. A streak count cannot
  // identify which individual dates were studied.
  static List<LearningDay> week(List rows, {DateTime? now}) {
    final local = (now ?? DateTime.now()).toUtc().add(const Duration(hours: 7));
    final today = DateTime.utc(local.year, local.month, local.day);
    final usage = <String, int>{};
    for (final row in rows) {
      final date = DateTime.tryParse(row['study_date']?.toString() ?? '');
      final seconds = (row['total_seconds'] as num?)?.toInt() ?? 0;
      if (date != null && seconds >= 0) {
        usage[date.toIso8601String().substring(0, 10)] = seconds;
      }
    }
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      return LearningDay(
        date,
        usage[date.toIso8601String().substring(0, 10)] ?? 0,
      );
    });
  }
}
