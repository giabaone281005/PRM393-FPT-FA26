import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'experiments/experiment_model.dart';
import 'learning_activity.dart';

class LearnerProfile {
  LearnerProfile(
    this.id,
    this.name, {
    this.onboarded = false,
    this.interests = const [],
    this.dailyMinutes = 10,
    this.mode = 'device',
  });
  final String id, mode;
  String name;
  bool onboarded;
  List<String> interests;
  int dailyMinutes;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'onboarded': onboarded,
    'interests': interests,
    'dailyMinutes': dailyMinutes,
    'mode': mode,
  };
  factory LearnerProfile.fromJson(Map<String, dynamic> data) => LearnerProfile(
    data['id'] as String,
    data['name'] as String,
    onboarded: data['onboarded'] == true,
    mode: data['mode'] as String? ?? 'device',
    interests: List<String>.from(data['interests'] as List? ?? []),
    dailyMinutes: (data['dailyMinutes'] as num?)?.toInt() ?? 10,
  );
}

class CompletionReceipt {
  const CompletionReceipt(this.ownerId, this.awarded, this.record);
  final String ownerId;
  final bool awarded;
  final Map<String, dynamic> record;
}

/// Local-first durable learning state, isolated by profile. No credentials live here.
class LearningStore extends ChangeNotifier {
  LearningStore(this.preferences, {this.writeSnapshot}) {
    _read();
  }
  final SharedPreferences preferences;
  final Future<bool> Function(String key, String value)? writeSnapshot;
  static const storageKey = 'nary:journey:v3';
  final Map<String, LearnerProfile> _profiles = {};
  final Map<String, Map<String, dynamic>> _learning = {};
  String? _activeId;
  Future<void>? _writes;
  bool _disposed = false;
  String? saveError;
  List<LearnerProfile> get profiles => List.unmodifiable(_profiles.values);
  LearnerProfile? get profile => _profiles[_activeId];
  bool get hasSession => profile != null;
  Map<String, dynamic> get _current =>
      _learning[_activeId] ?? <String, dynamic>{};
  Map<String, dynamic> _for(String id) => _learning.putIfAbsent(
    id,
    () => {
      'completed': <String, dynamic>{},
      'drafts': <String, dynamic>{},
      'history': <dynamic>[],
    },
  );
  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
  Set<String> get completed => _map(_current['completed']).keys.toSet();
  Set<String> completedExperimentIds(String courseId) =>
      (_map(_map(_current['completed'])[courseId])['experimentIds'] as List? ??
              [])
          .whereType<String>()
          .toSet();
  int get points => completed.length * 30;
  List<Map<String, dynamic>> get history => (_current['history'] as List? ?? [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList()
      .reversed
      .toList();
  String? get lastCourse => _current['lastCourse'] as String?;
  List<String> get inProgress => _map(_current['drafts']).keys.toList();
  Map<String, dynamic> _dailyFor(Map<String, dynamic> data) {
    if (data['dailyActivity'] is Map) return _map(data['dailyActivity']);
    // Existing completion dates are known; their cross-day foreground time is
    // not recoverable, so leave that field absent instead of inventing it.
    final result = <String, dynamic>{};
    for (final record in (data['history'] as List? ?? []).whereType<Map>()) {
      final date = DateTime.tryParse(record['finishedAt'] as String? ?? '');
      if (date == null) continue;
      final key = activityDay(date);
      final row = _map(result[key]);
      row['sessions'] = ((row['sessions'] as num?)?.toInt() ?? 0) + 1;
      row['xp'] =
          ((row['xp'] as num?)?.toInt() ?? 0) +
          ((record['xp'] as num?)?.toInt() ?? 0);
      result[key] = row;
    }
    return result;
  }

  DailyLearningActivity activityOn(DateTime date) {
    final row = _map(_dailyFor(_current)[activityDay(date)]);
    return DailyLearningActivity(
      activeMs: (row['activeMs'] as num?)?.toInt(),
      sessions: (row['sessions'] as num?)?.toInt() ?? 0,
      xp: (row['xp'] as num?)?.toInt() ?? 0,
    );
  }

  void _accountDaily(
    Map<String, dynamic> data,
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    final daily = _dailyFor(data);
    final before = _map(previous['activeMsByDay']);
    final after = _map(next['activeMsByDay']);
    for (final entry in after.entries) {
      final delta =
          ((entry.value as num?)?.toInt() ?? 0) -
          ((before[entry.key] as num?)?.toInt() ?? 0);
      if (delta <= 0) continue;
      final row = _map(daily[entry.key]);
      row['activeMs'] = ((row['activeMs'] as num?)?.toInt() ?? 0) + delta;
      daily[entry.key] = row;
    }
    data['dailyActivity'] = daily;
  }

  Map<String, dynamic>? progress(String courseId) {
    final value = _map(_current['drafts'])[courseId];
    return value is Map ? _clone(Map<String, dynamic>.from(value)) : null;
  }

  Map<String, dynamic> _clone(Map<String, dynamic> data) =>
      (jsonDecode(jsonEncode(data)) as Map).cast<String, dynamic>();

  void _read() {
    try {
      final raw = preferences.getString(storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map;
        for (final entry in (data['profiles'] as List? ?? [])) {
          final profile = LearnerProfile.fromJson(
            Map<String, dynamic>.from(entry as Map),
          );
          _profiles[profile.id] = profile;
        }
        final learning = _map(data['learning']);
        for (final entry in learning.entries) {
          _learning[entry.key] = _map(entry.value);
        }
        _activeId = data['activeId'] as String?;
        if (!_profiles.containsKey(_activeId)) _activeId = null;
      } else {
        // Preserve XP from the previous app without accepting old exercise answers.
        final old = preferences.getStringList('completed') ?? [];
        final drafts = preferences.getKeys().where(
          (key) => key.startsWith('progress:'),
        );
        if (old.isNotEmpty || drafts.isNotEmpty) {
          const id = 'migrated-device-profile';
          _profiles[id] = LearnerProfile(id, 'Nhà khám phá', onboarded: true);
          _learning[id] = {
            'completed': {
              for (final key in old) key: {'legacy': true},
            },
            'drafts': {
              for (final key in drafts)
                key.substring(9): {
                  'version': 3,
                  'step': 0,
                  'states': <String, dynamic>{},
                  'touched': <String>[],
                  'checked': <String>[],
                  'attempts': 0,
                  'hints': <String>[],
                  'seconds': 0,
                },
            },
            'history': <dynamic>[],
          };
          // The entry page offers this preserved profile; it does not claim cloud authentication.
          unawaited(_persist());
        }
      }
    } catch (_) {
      saveError =
          'Không đọc được phiên cũ. Dữ liệu gốc vẫn được giữ trên thiết bị.';
      _profiles.clear();
      _learning.clear();
      _activeId = null;
    }
  }

  Future<bool> _persist() {
    final payload = jsonEncode({
      'version': 3,
      'activeId': _activeId,
      'profiles': _profiles.values.map((p) => p.toJson()).toList(),
      'learning': _learning,
    });
    // Capture the full snapshot before queuing. A logout cannot redirect a pending write.
    Future<bool> write() async {
      try {
        final saved =
            await (writeSnapshot?.call(storageKey, payload) ??
                preferences.setString(storageKey, payload));
        if (!saved) throw StateError('preference write rejected');
        if (saveError != null) {
          saveError = null;
          _emit();
        }
        return true;
      } catch (_) {
        saveError = 'Chưa lưu được thay đổi. Giữ app mở và thử lưu lại.';
        _emit();
        return false;
      }
    }

    final previous = _writes;
    final attempt = previous == null ? write() : previous.then((_) => write());
    final barrier = attempt.then<void>((_) {});
    _writes = barrier;
    unawaited(
      barrier.then((_) {
        if (identical(_writes, barrier)) _writes = null;
      }),
    );
    return attempt;
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> flush() async {
    await _persist();
  }

  Future<void> createDeviceProfile(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 40) {
      throw ArgumentError('Tên cần từ 1 đến 40 ký tự.');
    }
    final id =
        'device-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 30)}';
    _profiles[id] = LearnerProfile(id, clean);
    _for(id);
    _activeId = id;
    _emit();
    await _persist();
  }

  Future<void> activateProfile(String id) async {
    if (!_profiles.containsKey(id)) throw ArgumentError('Hồ sơ không tồn tại.');
    _activeId = id;
    _for(id);
    _emit();
    await _persist();
  }

  Future<void> signOut() async {
    await flush();
    _activeId = null;
    _emit();
    await _persist();
  }

  Future<void> finishOnboarding(List<String> interests, int minutes) async {
    final learner = profile;
    if (learner == null) return;
    learner.interests = List<String>.from(interests);
    learner.dailyMinutes = minutes.clamp(5, 30);
    learner.onboarded = true;
    _emit();
    await _persist();
  }

  Future<void> rename(String name) async {
    if (profile == null || name.trim().isEmpty || name.trim().length > 40) {
      return;
    }
    profile!.name = name.trim();
    _emit();
    await _persist();
  }

  Future<void> saveProgress(String courseId, Map<String, dynamic> value) async {
    final id = _activeId;
    if (id == null) return;
    final data = _for(id);
    final drafts = _map(data['drafts']);
    _accountDaily(data, _map(drafts[courseId]), value);
    drafts[courseId] = _clone({
      ...value,
      'version': 3,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    data['drafts'] = drafts;
    data['lastCourse'] = courseId;
    _emit();
    await _persist();
  }

  Future<CompletionReceipt> finish(
    String courseId, {
    required List<ExperimentSpec> experiments,
    required Map<String, dynamic> draft,
    String? expectedProfileId,
  }) async {
    final id = _activeId;
    if (id == null) throw StateError('Cần mở hồ sơ trước.');
    if (expectedProfileId != null && id != expectedProfileId) {
      throw StateError('Phiên học thuộc hồ sơ khác.');
    }
    final states = _map(draft['states']);
    final previousIds = completedExperimentIds(courseId);
    final credited = experiments.any((s) => !previousIds.contains(s.id))
        ? previousIds
        : <String>{};
    if (!experiments.every(
      (spec) => states[spec.id] is Map
          ? spec.isCorrect(_map(states[spec.id]))
          : credited.contains(spec.id),
    )) {
      throw StateError('Cần hoàn thành tất cả thí nghiệm trước khi kết thúc.');
    }
    final data = _for(id);
    final before = _clone(data);
    _accountDaily(data, _map(_map(data['drafts'])[courseId]), draft);
    final daily = _dailyFor(data);
    final day = activityDay(DateTime.now());
    final today = _map(daily[day]);
    today['sessions'] = ((today['sessions'] as num?)?.toInt() ?? 0) + 1;
    final done = _map(data['completed']);
    final awarded = !done.containsKey(courseId);
    today['xp'] = ((today['xp'] as num?)?.toInt() ?? 0) + (awarded ? 30 : 0);
    daily[day] = today;
    data['dailyActivity'] = daily;
    final record = {
      'course': courseId,
      'finishedAt': DateTime.now().toUtc().toIso8601String(),
      'seconds': draft['seconds'] ?? 0,
      'attempts': draft['attempts'] ?? 0,
      'hints': (draft['hints'] as List? ?? []).length,
      'xp': awarded ? 30 : 0,
      'experimentIds': experiments.map((e) => e.id).toList(),
    };
    done[courseId] = record;
    data['completed'] = done;
    data['history'] = [
      ...(data['history'] as List? ?? []),
      record,
    ].reversed.take(100).toList().reversed.toList();
    final drafts = _map(data['drafts'])..remove(courseId);
    data['drafts'] = drafts;
    if (data['lastCourse'] == courseId) data.remove('lastCourse');
    _emit();
    final saved = await _persist();
    if (!saved) {
      _learning[id] = before;
      _emit();
      throw StateError('Chưa lưu được kết quả. Có thể thử lại.');
    }
    return CompletionReceipt(id, awarded, _clone(record));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
