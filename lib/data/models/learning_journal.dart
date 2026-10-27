import 'dart:convert';
import 'dart:math';

Map<String, dynamic> learningMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

Map<String, dynamic> learningCopy(Map<String, dynamic> value) =>
    (jsonDecode(jsonEncode(value)) as Map).cast<String, dynamic>();

String learningUuid() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Stored in the same snapshot/transaction as local progress, never a second
/// best-effort preferences write. Requests keep their IDs across crashes/retries.
class LearningJournal {
  static Map<String, dynamic> root(Map<String, dynamic> learning) =>
      learningMap(learning['serverSync']);

  static String save(
    Map<String, dynamic> learning,
    String topic,
    Map<String, dynamic> snapshot, {
    bool complete = false,
    Map<String, Map<String, dynamic>> finalStates = const {},
  }) {
    final sync = root(learning);
    final active = learningMap(sync['active']);
    final sessions = learningMap(sync['sessions']);
    final id = active[topic] as String? ?? learningUuid();
    final row = learningMap(sessions[id]);
    final attempts = (row['attempts'] as List? ?? [])
        .map((x) => learningMap(x))
        .toList();
    final count = (snapshot['attempts'] as num?)?.toInt() ?? 0;
    final previousCount = (row['lastAttemptCount'] as num?)?.toInt() ?? 0;
    final activity = snapshot['activeActivityId'] as String?;
    final states = learningMap(snapshot['states']);
    final hints = learningMap(snapshot['hintLevels']);
    void append(String activityId, Map<String, dynamic> state) {
      attempts.add({
        'id': learningUuid(),
        'activity_id': activityId,
        'state': learningCopy(state),
        'hint_level': ((hints[activityId] as num?)?.toInt() ?? 0).clamp(0, 3),
      });
    }

    if (count > previousCount && activity != null && states[activity] is Map) {
      append(activity, learningMap(states[activity]));
    }
    for (final entry in finalStates.entries) {
      final previous = attempts
          .where((x) => x['activity_id'] == entry.key)
          .lastOrNull;
      if (previous == null ||
          jsonEncode(previous['state']) != jsonEncode(entry.value)) {
        append(entry.key, entry.value);
      }
    }
    sessions[id] = {
      ...row,
      'id': id,
      'topic': topic,
      'startedAt':
          row['startedAt'] ??
          snapshot['startedAt'] ??
          DateTime.now().toUtc().toIso8601String(),
      'snapshot': learningCopy(snapshot),
      'draftVersion': ((row['draftVersion'] as num?)?.toInt() ?? 0) + 1,
      'lastAttemptCount': count,
      'attempts': attempts,
      'complete': complete || row['complete'] == true,
    };
    if (complete) {
      active.remove(topic);
    } else {
      active[topic] = id;
    }
    sync['active'] = active;
    sync['sessions'] = sessions;
    learning['serverSync'] = sync;
    return id;
  }

  /// A restored snapshot is a new device branch. Keep its answers but never
  /// reuse mutable draft/retry IDs on two devices.
  static void fork(Map<String, dynamic> learning) {
    final sync = root(learning);
    if (sync.isEmpty) return;
    final sessions = learningMap(sync['sessions']);
    final forked = <String, dynamic>{};
    final active = <String, dynamic>{};
    for (final raw in sessions.values) {
      final old = learningMap(raw);
      if (old['verified'] == true) continue;
      final id = learningUuid();
      forked[id] = {
        'id': id,
        'topic': old['topic'],
        'startedAt': DateTime.now().toUtc().toIso8601String(),
        'snapshot': old['snapshot'],
        'draftVersion': 1,
        'lastAttemptCount': old['lastAttemptCount'] ?? 0,
        'complete': old['complete'] == true,
        'attempts': [
          for (final attempt in old['attempts'] as List? ?? [])
            {...learningMap(attempt), 'id': learningUuid()},
        ],
      };
      if (old['complete'] != true) active[old['topic'] as String] = id;
    }
    sync['sessions'] = forked;
    sync['active'] = active;
    learning['serverSync'] = sync;
  }
}
