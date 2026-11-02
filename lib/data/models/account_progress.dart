import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'learning_journal.dart';

String accountProgressHash(Map<String, dynamic> payload) {
  final copy = learningCopy(payload);
  (copy['profile'] as Map).remove('id');
  (copy['learning'] as Map).remove('serverSync');
  dynamic sorted(dynamic value) {
    if (value is Map) {
      return {
        for (final key in value.keys.map((k) => k.toString()).toList()..sort())
          key: sorted(value[key]),
      };
    }
    if (value is List) return value.map(sorted).toList();
    return value;
  }

  return sha256.convert(utf8.encode(jsonEncode(sorted(copy)))).toString();
}

/// Preserve unsent local work when another device has already saved a revision.
/// This merges personal progress only; it never grants verified server XP.
Map<String, dynamic> mergeAccountProgress(
  Map<String, dynamic> local,
  Map<String, dynamic> remote,
) {
  final result = learningCopy(local);
  final a = learningMap(local['learning']), b = learningMap(remote['learning']);
  final done = {...learningMap(b['completed']), ...learningMap(a['completed'])};
  final history = <String, dynamic>{};
  for (final row in [
    ...(b['history'] as List? ?? []),
    ...(a['history'] as List? ?? []),
  ]) {
    if (row is Map) history['${row['course']}/${row['finishedAt']}'] = row;
  }
  final records = history.values.toList()
    ..sort((x, y) => '${x['finishedAt']}'.compareTo('${y['finishedAt']}'));
  final drafts = {...learningMap(b['drafts']), ...learningMap(a['drafts'])};
  for (final topic in done.keys) {
    drafts.remove(topic);
  }
  final daily = learningMap(b['dailyActivity']);
  for (final entry in learningMap(a['dailyActivity']).entries) {
    final before = learningMap(daily[entry.key]),
        after = learningMap(entry.value);
    daily[entry.key] = {
      for (final key in {...before.keys, ...after.keys})
        key: ((before[key] as num?) ?? 0) > ((after[key] as num?) ?? 0)
            ? before[key]
            : after[key],
    };
  }
  final remoteSync = learningMap(b['serverSync']);
  final localSync = learningMap(a['serverSync']);
  result['learning'] = {
    ...b,
    ...a,
    'completed': done,
    'history': records.reversed.take(100).toList().reversed.toList(),
    'drafts': drafts,
    'dailyActivity': daily,
    'serverSync': {
      ...remoteSync,
      ...localSync,
      'sessions': {
        ...learningMap(remoteSync['sessions']),
        ...learningMap(localSync['sessions']),
      },
      'active': {
        ...learningMap(remoteSync['active']),
        ...learningMap(localSync['active']),
      },
    },
  };
  return result;
}
