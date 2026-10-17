import 'dart:convert';

import '../../data/models/wrong_answer_record.dart';

/// Immutable model representing the result of learning streak calculations.
class LearningStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLearningDate;
  final bool hasStudiedToday;
  final int totalLearningDays;

  static const LearningStreak zero = LearningStreak();

  const LearningStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLearningDate,
    this.hasStudiedToday = false,
    this.totalLearningDays = 0,
  })  : assert(currentStreak >= 0, 'currentStreak must be non-negative'),
        assert(longestStreak >= 0, 'longestStreak must be non-negative'),
        assert(
          longestStreak >= currentStreak,
          'longestStreak cannot be less than currentStreak',
        ),
        assert(totalLearningDays >= 0, 'totalLearningDays must be non-negative');

  const LearningStreak.empty()
      : currentStreak = 0,
        longestStreak = 0,
        lastLearningDate = null,
        hasStudiedToday = false,
        totalLearningDays = 0;

  int get streakCount => currentStreak;

  bool get isStreakActive => currentStreak > 0;

  LearningStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLearningDate,
    bool? hasStudiedToday,
    int? totalLearningDays,
  }) {
    final nextCurrent = currentStreak ?? this.currentStreak;
    final nextLongest = longestStreak ?? this.longestStreak;
    return LearningStreak(
      currentStreak: nextCurrent,
      longestStreak: nextLongest >= nextCurrent ? nextLongest : nextCurrent,
      lastLearningDate: lastLearningDate ?? this.lastLearningDate,
      hasStudiedToday: hasStudiedToday ?? this.hasStudiedToday,
      totalLearningDays: totalLearningDays ?? this.totalLearningDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'hasStudiedToday': hasStudiedToday,
      'totalLearningDays': totalLearningDays,
      if (lastLearningDate != null)
        'lastLearningDate': lastLearningDate!.toIso8601String(),
    };
  }

  factory LearningStreak.fromMap(Map<String, dynamic> map) {
    int parseCount(dynamic value) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    final current = parseCount(
      map['currentStreak'] ?? map['streak_count'] ?? map['current_streak'],
    );
    final longestRaw = parseCount(
      map['longestStreak'] ?? map['longest_streak'],
    );
    final longest = longestRaw >= current ? longestRaw : current;
    final total = parseCount(
      map['totalLearningDays'] ?? map['total_learning_days'],
    );

    DateTime? lastDate;
    final rawDate = map['lastLearningDate'] ?? map['last_learning_date'];
    if (rawDate != null) {
      lastDate = DateTime.tryParse(rawDate.toString());
    }

    return LearningStreak(
      currentStreak: current,
      longestStreak: longest,
      hasStudiedToday:
          map['hasStudiedToday'] == true || map['has_studied_today'] == true,
      totalLearningDays: total,
      lastLearningDate: lastDate,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory LearningStreak.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Invalid JSON for LearningStreak');
    }
    return LearningStreak.fromMap(Map<String, dynamic>.from(decoded));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningStreak &&
        other.currentStreak == currentStreak &&
        other.longestStreak == longestStreak &&
        other.hasStudiedToday == hasStudiedToday &&
        other.totalLearningDays == totalLearningDays &&
        other.lastLearningDate == lastLearningDate;
  }

  @override
  int get hashCode => Object.hash(
        currentStreak,
        longestStreak,
        hasStudiedToday,
        totalLearningDays,
        lastLearningDate,
      );

  @override
  String toString() {
    return 'LearningStreak(currentStreak: $currentStreak, longestStreak: $longestStreak, hasStudiedToday: $hasStudiedToday, totalLearningDays: $totalLearningDays, lastLearningDate: $lastLearningDate)';
  }
}

/// Service and calculator for daily learning streak tracking.
///
/// Features:
/// - Normalizes all timestamps to local calendar days (midnight 00:00:00).
/// - Multiple activities on the same local calendar day count as 1 learning day.
/// - If studied today, today is included in the streak.
/// - If not studied today but studied yesterday, the streak is retained through yesterday.
/// - If the last learning day is earlier than yesterday, the current streak is 0.
/// - Allows injecting a deterministic [referenceDate] for timezone- and time-independent testing.
class StreakCalculator {
  const StreakCalculator._();

  /// Normalizes a [DateTime] to a local calendar day at midnight (00:00:00).
  static DateTime toCalendarDay(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateTime(local.year, local.month, local.day);
  }

  /// Calculates full learning streak metrics from an iterable of activity dates.
  ///
  /// [referenceDate] specifies "today" (defaults to DateTime.now() if omitted).
  static LearningStreak calculate({
    required Iterable<DateTime> activityDates,
    DateTime? referenceDate,
  }) {
    if (activityDates.isEmpty) {
      return const LearningStreak.empty();
    }

    final uniqueDays = <DateTime>{};
    for (final date in activityDates) {
      uniqueDays.add(toCalendarDay(date));
    }

    if (uniqueDays.isEmpty) {
      return const LearningStreak.empty();
    }

    final ref = referenceDate != null
        ? toCalendarDay(referenceDate)
        : toCalendarDay(DateTime.now());

    final sortedDays = uniqueDays.toList()..sort();
    final pastOrTodayDays = sortedDays.where((d) => !d.isAfter(ref)).toList();
    final lastLearningDay =
        pastOrTodayDays.isNotEmpty ? pastOrTodayDays.last : sortedDays.last;

    // Calculate historical longest streak across all recorded calendar days
    int maxStreak = 0;
    int tempStreak = 0;
    DateTime? prevDay;

    for (final day in sortedDays) {
      if (prevDay == null) {
        tempStreak = 1;
      } else {
        final expectedNext = DateTime(prevDay.year, prevDay.month, prevDay.day + 1);
        if (day == expectedNext) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
      }
      if (tempStreak > maxStreak) {
        maxStreak = tempStreak;
      }
      prevDay = day;
    }

    final today = ref;
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final bool studiedToday = uniqueDays.contains(today);
    final bool studiedYesterday = uniqueDays.contains(yesterday);

    int currentStreak = 0;

    if (studiedToday) {
      // Studied today: count consecutive days backwards starting from today
      currentStreak = 1;
      var checkDate = yesterday;
      while (uniqueDays.contains(checkDate)) {
        currentStreak++;
        checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      }
    } else if (studiedYesterday) {
      // Not studied today, but studied yesterday: streak is retained through yesterday
      currentStreak = 1;
      var checkDate = DateTime(yesterday.year, yesterday.month, yesterday.day - 1);
      while (uniqueDays.contains(checkDate)) {
        currentStreak++;
        checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      }
    } else {
      // Last learning day was earlier than yesterday: current streak is 0
      currentStreak = 0;
    }

    final longest = maxStreak > currentStreak ? maxStreak : currentStreak;

    return LearningStreak(
      currentStreak: currentStreak,
      longestStreak: longest,
      lastLearningDate: lastLearningDay,
      hasStudiedToday: studiedToday,
      totalLearningDays: uniqueDays.length,
    );
  }

  /// Calculates only the current streak integer value.
  static int calculateCurrentStreak({
    required Iterable<DateTime> activityDates,
    DateTime? referenceDate,
  }) {
    return calculate(
      activityDates: activityDates,
      referenceDate: referenceDate,
    ).currentStreak;
  }

  /// Checks whether any activity occurred on the reference "today".
  static bool hasStudiedToday({
    required Iterable<DateTime> activityDates,
    DateTime? referenceDate,
  }) {
    final ref = referenceDate != null
        ? toCalendarDay(referenceDate)
        : toCalendarDay(DateTime.now());

    for (final date in activityDates) {
      if (toCalendarDay(date) == ref) {
        return true;
      }
    }
    return false;
  }

  /// Calculates streak from existing [WrongAnswerRecord] entries.
  static LearningStreak fromWrongAnswerRecords(
    Iterable<WrongAnswerRecord> records, {
    DateTime? referenceDate,
  }) {
    return calculate(
      activityDates: records.map((r) => r.timestamp),
      referenceDate: referenceDate,
    );
  }

  /// Calculates streak from ISO-8601 date string representations.
  static LearningStreak fromDateStrings(
    Iterable<String> dateStrings, {
    DateTime? referenceDate,
  }) {
    final dates = <DateTime>[];
    for (final str in dateStrings) {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) dates.add(parsed);
    }
    return calculate(activityDates: dates, referenceDate: referenceDate);
  }
}

/// Alias for [StreakCalculator] to support either naming convention cleanly.
typedef DailyStreakService = StreakCalculator;
