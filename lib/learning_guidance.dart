import 'learning_catalog.dart';
import 'learning_store.dart';

/// A local suggestion, never a claim about proficiency or an AI assessment.
class GuidanceRecommendation {
  const GuidanceRecommendation(
    this.topic,
    this.reason, {
    this.isReview = false,
  });

  final LearningTopic topic;
  final String reason;
  final bool isReview;
}

class TopicActivity {
  const TopicActivity({
    required this.completed,
    required this.practiceCount,
    required this.lastPracticed,
    required this.needsReview,
  });

  final bool completed;

  /// Completed sessions retained in local history, including the first session.
  final int practiceCount;
  final DateTime? lastPracticed;
  final bool needsReview;
}

DateTime? _date(dynamic value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

DateTime _utcDay(DateTime value) {
  final utc = value.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day);
}

int _count(dynamic value) => value is num ? value.toInt() : 0;

TopicActivity topicActivity(
  LearningStore store,
  String topicId, {
  DateTime? now,
}) {
  final records = store.history.where((record) => record['course'] == topicId);
  DateTime? lastPracticed;
  for (final record in records) {
    final date = _date(record['finishedAt']);
    if (date != null &&
        (lastPracticed == null || date.isAfter(lastPracticed))) {
      lastPracticed = date;
    }
  }
  // Store history is newest first. Difficulty reflects the latest session only;
  // a later comfortable session clears an earlier invitation to practise.
  final latest = records.firstOrNull;
  final completed = store.completed.contains(topicId);
  final extraPractice =
      latest != null &&
      (_count(latest['attempts']) >= 6 || _count(latest['hints']) >= 2);
  final aWeekLater =
      lastPracticed != null &&
      _utcDay(now ?? DateTime.now())
              .difference(_utcDay(lastPracticed))
              .inDays >=
          7;
  return TopicActivity(
    completed: completed,
    practiceCount: records.length,
    lastPracticed: lastPracticed,
    needsReview: completed && (extraPractice || aWeekLater),
  );
}

/// Stable offline rules inspired by targeted review, not Brilliant's algorithm.
/// Reading this function never changes saved progress, history or XP.
GuidanceRecommendation recommendNext(LearningStore store, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final known = {for (final topic in topics) topic.id: topic};
  final drafts = store.inProgress.where(known.containsKey).toList();
  if (drafts.isNotEmpty) {
    drafts.sort((a, b) {
      if (a == b) return 0;
      if (a == store.lastCourse) return -1;
      if (b == store.lastCourse) return 1;
      final aDate = _date(store.progress(a)?['updatedAt']);
      final bDate = _date(store.progress(b)?['updatedAt']);
      if (aDate == null) return bDate == null ? 0 : 1;
      return bDate == null ? -1 : bDate.compareTo(aDate);
    });
    return GuidanceRecommendation(
      known[drafts.first]!,
      'Tiếp tục từ chỗ bạn đã lưu. Các thao tác trước vẫn ở đây.',
    );
  }

  final activity = {
    for (final topic in topics)
      topic.id: topicActivity(store, topic.id, now: clock),
  };
  final review = topics
      .where((topic) => activity[topic.id]!.needsReview)
      .toList();
  if (review.isNotEmpty) {
    review.sort((a, b) => _oldestFirst(activity[a.id]!, activity[b.id]!));
    final topic = review.first;
    final latest = store.history.firstWhere((r) => r['course'] == topic.id);
    final usedSupport =
        _count(latest['attempts']) >= 6 || _count(latest['hints']) >= 2;
    return GuidanceRecommendation(
      topic,
      usedSupport
          ? 'Lần trước bạn đã thử vài cách hoặc dùng gợi ý. Thử lại một lượt để khám phá thêm nhé.'
          : 'Đã một tuần từ lần khám phá gần nhất. Bạn có thể thử lại theo một cách mới.',
      isReview: true,
    );
  }

  final interests = store.profile?.interests ?? const <String>[];
  final fresh = topics
      .where((topic) => !activity[topic.id]!.completed)
      .toList();
  if (fresh.isNotEmpty) {
    final topic = fresh.firstWhere(
      (topic) => interests.contains(topic.id),
      orElse: () => fresh.first,
    );
    return GuidanceRecommendation(
      topic,
      interests.contains(topic.id)
          ? 'Một khám phá mới trong chủ đề bạn đã chọn.'
          : 'Thử một ý tưởng mới bằng chính đôi tay của bạn.',
    );
  }

  final revisit = topics.toList()
    ..sort((a, b) => _oldestFirst(activity[a.id]!, activity[b.id]!));
  return GuidanceRecommendation(
    revisit.first,
    'Bạn đã khám phá tất cả chủ đề hiện có. Chọn một bài quen và thử cách làm khác nhé.',
    isReview: true,
  );
}

int _oldestFirst(TopicActivity a, TopicActivity b) {
  if (a.lastPracticed == null) return b.lastPracticed == null ? 0 : -1;
  if (b.lastPracticed == null) return 1;
  return a.lastPracticed!.compareTo(b.lastPracticed!);
}
