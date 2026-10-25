/// Activity is grouped by the device's local calendar day.
String activityDay(DateTime time) {
  final local = time.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

/// Split foreground stopwatch time at local midnight, including sessions that
/// span days. Background time never reaches this function.
void addActiveTime(
  Map<String, dynamic> totals,
  DateTime end,
  int milliseconds,
) {
  if (milliseconds <= 0) return;
  final localEnd = end.toLocal();
  var cursor = localEnd.subtract(Duration(milliseconds: milliseconds));
  while (cursor.isBefore(localEnd)) {
    final midnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
    final until = midnight.isBefore(localEnd) ? midnight : localEnd;
    final key = activityDay(cursor);
    totals[key] =
        ((totals[key] as num?)?.toInt() ?? 0) +
        until.difference(cursor).inMilliseconds;
    cursor = until;
  }
}

class DailyLearningActivity {
  const DailyLearningActivity({this.activeMs, this.sessions = 0, this.xp = 0});
  final int? activeMs;
  final int sessions, xp;
  bool get hasActivity => (activeMs ?? 0) > 0 || sessions > 0;
}
