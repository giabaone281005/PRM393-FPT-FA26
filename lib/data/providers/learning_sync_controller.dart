import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../learning_catalog.dart';
import '../../learning_store.dart';
import '../models/app_failure.dart';
import '../models/learning_journal.dart';
import '../repositories/learning_repository.dart';
import 'cloud_backup_controller.dart';

String learningStableId(String source) {
  final bytes = sha256.convert(utf8.encode(source)).bytes.take(16).toList();
  bytes[6] =
      (bytes[6] & 15) | 128; // UUIDv8: application-defined stable identifier.
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String _canonical(dynamic value) {
  dynamic sorted(dynamic x) {
    if (x is Map) {
      return {
        for (final key in x.keys.map((k) => k.toString()).toList()..sort())
          key: sorted(x[key]),
      };
    }
    if (x is List) return x.map(sorted).toList();
    return x;
  }

  return jsonEncode(sorted(value));
}

class _AccountChanged implements Exception {}

/// Sends durable local journal entries; server results never come from a client
/// score. Snapshot backups remain independently available during this rollout.
class LearningSyncController extends ChangeNotifier {
  LearningSyncController({
    required this.store,
    required this.cloud,
    required this.repository,
    this.automatic = true,
  }) {
    _owner = cloud.userId;
    store.addListener(_changed);
    cloud.addListener(_changed);
    if (automatic) {
      _retry = Timer.periodic(
        const Duration(seconds: 30),
        (_) => unawaited(syncNow()),
      );
      _changed();
    }
  }
  final LearningStore store;
  final CloudBackupController cloud;
  final LearningRepository repository;
  final bool automatic;
  String? _owner;
  Timer? _timer, _retry;
  Future<void>? _running;
  bool _disposed = false, _dirty = false;
  int _generation = 0;
  bool busy = false;
  String? message;
  NoticeKind noticeKind = NoticeKind.info;
  Map<String, dynamic>? _catalog;
  bool hasProfileConflict = false;

  Future<Map<String, dynamic>> loadConflictProfile() async {
    final owner = cloud.userId;
    final localId = store.profile?.id;
    if (owner == null || localId == null) {
      throw const AppFailure('Đăng nhập và mở lại hồ sơ để tiếp tục.');
    }
    final generation = _generation;
    final meta = learningMap(store.serverSyncFor(localId)['profile']);
    final remote = await repository.profile(owner, meta['id'] as String);
    _guard(owner, localId, generation);
    if (remote == null) {
      throw const AppFailure(
        'Hồ sơ trên cloud không còn khả dụng. Bản trên máy vẫn được giữ.',
      );
    }
    return remote;
  }

  Future<void> resolveProfileConflict(
    Map<String, dynamic> remote, {
    required bool useDevice,
  }) async {
    final localId = store.profile?.id;
    final owner = cloud.userId;
    if (busy || localId == null || owner == null) return;
    final root = store.serverSyncFor(localId);
    final meta = learningMap(root['profile']);
    if (meta['owner'] != owner ||
        remote['id'] != meta['id'] ||
        remote['owner_user_id'] != owner) {
      throw const AppFailure('Hồ sơ đã thay đổi. Hãy mở lại phần đồng bộ.');
    }
    final learner = store.profile!;
    final metadata = useDevice
        ? {
            'name': learner.name,
            'daily_minutes': learner.dailyMinutes,
            'interest_topic_ids': learner.interests,
            'onboarded': learner.onboarded,
          }
        : {
            'name': remote['name'],
            'daily_minutes': remote['daily_minutes'],
            'interest_topic_ids': remote['interest_topic_ids'],
            'onboarded': remote['onboarded_at'] != null,
          };
    final next = {...meta, 'revision': '${remote['revision']}'}
      ..remove('pending');
    if (useDevice) {
      next['pending'] = {
        'id': learningUuid(),
        'kind': 'profile.update',
        'payload': {
          'id': meta['id'],
          'expected_revision': '${remote['revision']}',
          ...metadata,
        },
        'metadata': _canonical(metadata),
      };
      await _rootPatch(localId, {'profile': next});
    } else {
      next['lastMetadata'] = _canonical(metadata);
      root['profile'] = next;
      await store.acceptServerProfile(localId, remote, root);
    }
    hasProfileConflict = false;
    await syncNow();
  }

  void _changed() {
    if (_disposed) return;
    if (_owner != cloud.userId) {
      _owner = cloud.userId;
      _generation++;
      _catalog = null;
      message = null;
      noticeKind = NoticeKind.info;
      hasProfileConflict = false;
    }
    _timer?.cancel();
    if (cloud.userId == null ||
        store.profile == null ||
        !cloud.canUseProfile(store.profile!.id)) {
      return;
    }
    if (_running != null) {
      _dirty = true;
      return;
    }
    if (automatic) {
      _timer = Timer(const Duration(seconds: 2), () => unawaited(syncNow()));
    }
  }

  void _guard(String owner, String localId, int generation) {
    if (_disposed ||
        cloud.userId != owner ||
        _generation != generation ||
        store.profile?.id != localId ||
        !cloud.canUseProfile(localId)) {
      throw _AccountChanged();
    }
  }

  Future<void> _rootPatch(String localId, Map<String, dynamic> patch) async {
    final current = store.serverSyncFor(localId);
    final next = {...current, ...patch};
    if (_canonical(current) != _canonical(next)) {
      await store.updateServerSync(localId, next);
    }
  }

  Future<void> _sessionPatch(
    String localId,
    String id,
    Map<String, dynamic> patch,
  ) async {
    final root = store.serverSyncFor(localId);
    final sessions = learningMap(root['sessions']);
    final row = learningMap(sessions[id]);
    sessions[id] = {...row, ...patch};
    root['sessions'] = sessions;
    await store.updateServerSync(localId, root);
  }

  Map<String, dynamic> _row(String localId, String id) =>
      learningMap(learningMap(store.serverSyncFor(localId)['sessions'])[id]);

  Future<void> syncNow() {
    if (_running != null) return _running!;
    final owner = cloud.userId;
    final localId = store.profile?.id;
    if (_disposed ||
        owner == null ||
        localId == null ||
        !cloud.canUseProfile(localId)) {
      return Future.value();
    }
    final task = _sync(owner, localId, _generation);
    _running = task;
    return task.whenComplete(() {
      _running = null;
      if (_dirty && automatic && !_disposed) {
        _dirty = false;
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 2), () => unawaited(syncNow()));
      }
    });
  }

  Future<void> _sync(String owner, String localId, int generation) async {
    busy = true;
    _dirty = false;
    if (!_disposed) notifyListeners();
    try {
      await store.flush();
      _guard(owner, localId, generation);
      if (store.saveError != null) throw LocalLearningFailure(store.saveError!);
      final sourceKey = cloud.currentBinding?['key'] as String? ?? localId;
      final profileId = learningStableId('$owner/profile/$sourceKey');
      var root = store.serverSyncFor(localId);
      var meta = learningMap(root['profile']);
      if (meta['owner'] != owner || meta['id'] != profileId) {
        meta = {'owner': owner, 'id': profileId};
        await _rootPatch(localId, {'profile': meta, 'verifiedXp': 0});
      }
      _guard(owner, localId, generation);
      final learner = store.profile!;
      final metadata = {
        'name': learner.name,
        'daily_minutes': learner.dailyMinutes,
        'interest_topic_ids': learner.interests,
        'onboarded': learner.onboarded,
      };
      if (meta['revision'] == null && meta['pending'] == null) {
        final remote = await repository.profile(owner, profileId);
        _guard(owner, localId, generation);
        if (remote != null) {
          // Restoring another device's snapshot must not silently overwrite its
          // newer profile settings. Subsequent explicit edits use this revision.
          meta = {
            ...meta,
            'revision': '${remote['revision']}',
            'lastMetadata': _canonical(metadata),
          };
        } else {
          meta['pending'] = {
            'id': learningUuid(),
            'kind': 'profile.create',
            'payload': {'id': profileId, ...metadata},
            'metadata': _canonical(metadata),
          };
        }
        await _rootPatch(localId, {'profile': meta});
      }
      if (meta['pending'] == null &&
          meta['lastMetadata'] != _canonical(metadata)) {
        meta['pending'] = {
          'id': learningUuid(),
          'kind': 'profile.update',
          'payload': {
            'id': profileId,
            'expected_revision': meta['revision'],
            ...metadata,
          },
          'metadata': _canonical(metadata),
        };
        await _rootPatch(localId, {'profile': meta});
      }
      if (meta['pending'] != null) {
        final pending = learningMap(meta['pending']);
        _guard(owner, localId, generation);
        final receipt = await repository.mutate(
          owner,
          pending['id'] as String,
          pending['kind'] as String,
          learningMap(pending['payload']),
        );
        _guard(owner, localId, generation);
        final saved = learningMap(receipt['result']);
        meta = {
          ...meta,
          'revision': '${saved['revision']}',
          'lastMetadata': pending['metadata'],
        }..remove('pending');
        await _rootPatch(localId, {'profile': meta});
      }
      final ids = learningMap(store.serverSyncFor(localId)['sessions']).keys
          .toList();
      var deferredLessons = 0;
      for (final id in ids) {
        _guard(owner, localId, generation);
        var row = _row(localId, id);
        if (row['verified'] == true) continue;
        final topic = topics.where((t) => t.id == row['topic']).firstOrNull;
        if (topic == null) {
          deferredLessons++;
          continue;
        }
        if (row['releaseId'] == null) {
          _catalog ??= await repository.catalog(owner);
          _guard(owner, localId, generation);
          final release = learningMap(_catalog!['release']);
          final activities = (_catalog!['activities'] as List? ?? [])
              .map(learningMap)
              .where((x) => x['topic_id'] == topic.id)
              .toList();
          final local = {for (final spec in topic.experiments) spec.id: spec};
          if (release['id'] == null ||
              activities.isEmpty ||
              activities.length != local.length ||
              activities.any((a) {
                final spec = local[a['activity_id']];
                return spec == null ||
                    a['content_version'] != spec.contentVersion ||
                    a['mechanism'] != spec.mechanism ||
                    _canonical(a['config']) != _canonical(spec.config) ||
                    _canonical(a['initial_state']) != _canonical(spec.initial);
              })) {
            // Keep unpublished/incompatible lessons durable without blocking
            // other sessions or sending content the release cannot evaluate.
            deferredLessons++;
            continue;
          }
          await _sessionPatch(localId, id, {
            'releaseId': release['id'],
            'versions': {
              for (final a in activities)
                a['activity_id'] as String: a['content_version'],
            },
          });
          row = _row(localId, id);
        }
        final versions = learningMap(row['versions']);
        final localActivities = topic.experiments
            .map((spec) => spec.id)
            .toSet();
        if (localActivities.length != versions.length ||
            topic.experiments.any(
              (spec) => versions[spec.id] != spec.contentVersion,
            )) {
          deferredLessons++;
          continue;
        }
        if (row['serverStarted'] != true) {
          _guard(owner, localId, generation);
          await repository.mutate(
            owner,
            learningStableId('$id/start'),
            'session.start',
            {
              'id': id,
              'profile_id': profileId,
              'topic_id': topic.id,
              'release_id': row['releaseId'],
              'started_at': row['startedAt'],
            },
          );
          _guard(owner, localId, generation);
          await _sessionPatch(localId, id, {'serverStarted': true});
        }
        row = _row(localId, id);
        // Freeze the exact draft request before network I/O. If a response is
        // lost while the user edits, retry the old revision before the new one.
        if (row['pendingDraft'] == null &&
            (row['draftVersion'] as int? ?? 0) >
                (row['sentDraftVersion'] as int? ?? 0)) {
          final snapshot = learningMap(row['snapshot']);
          final step = ((snapshot['step'] as num?)?.toInt() ?? 0).clamp(
            0,
            topic.experiments.length - 1,
          );
          await _sessionPatch(localId, id, {
            'pendingDraft': {
              'id': learningStableId('$id/draft/${row['draftVersion']}'),
              'version': row['draftVersion'],
              'payload': {
                'id': learningStableId('$id/draft'),
                'session_id': id,
                'activity_id': topic.experiments[step].id,
                'expected_revision': row['remoteDraftRevision'] ?? '0',
                'snapshot': snapshot,
              },
            },
          });
        }
        row = _row(localId, id);
        if (row['pendingDraft'] != null) {
          final pending = learningMap(row['pendingDraft']);
          _guard(owner, localId, generation);
          final receipt = await repository.mutate(
            owner,
            pending['id'] as String,
            'draft.save',
            learningMap(pending['payload']),
          );
          _guard(owner, localId, generation);
          final draft = learningMap(learningMap(receipt['result'])['draft']);
          await _sessionPatch(localId, id, {
            'pendingDraft': null,
            'sentDraftVersion': pending['version'],
            'remoteDraftRevision': '${draft['revision']}',
          });
        }
        row = _row(localId, id);
        var sent = (row['sentAttempts'] as int?) ?? 0;
        final attempts = (row['attempts'] as List? ?? [])
            .map(learningMap)
            .toList();
        while (sent < attempts.length) {
          final attempt = attempts[sent];
          _guard(owner, localId, generation);
          final result = await repository.attempt(
            owner,
            attempt['id'] as String,
            {
              'session_id': id,
              'activity_id': attempt['activity_id'],
              'content_version': learningMap(
                row['versions'],
              )[attempt['activity_id']],
              'state': attempt['state'],
              'hint_level': attempt['hint_level'],
            },
          );
          _guard(owner, localId, generation);
          final evaluation = learningMap(
            learningMap(result['result'])['attempt'],
          );
          if (evaluation['evaluation_status'] != 'verified') {
            throw const LearningApiFailure(
              'unsupported_activity',
              'Máy chủ chưa xác nhận được bài làm. Tiến độ vẫn được giữ.',
            );
          }
          sent++;
          await _sessionPatch(localId, id, {'sentAttempts': sent});
        }
        row = _row(localId, id);
        // Newly appended attempts/drafts are handled in the next pass; never
        // complete against an older in-flight snapshot.
        if (row['complete'] == true &&
            sent == (row['attempts'] as List? ?? []).length &&
            row['sentDraftVersion'] == row['draftVersion']) {
          _guard(owner, localId, generation);
          final receipt = await repository.mutate(
            owner,
            learningStableId('$id/complete'),
            'session.complete',
            {'session_id': id},
          );
          _guard(owner, localId, generation);
          final result = learningMap(receipt['result']);
          await _sessionPatch(localId, id, {
            'verified': true,
            'xpAwarded': result['xp_awarded'] ?? 0,
            'snapshot': null,
            'attempts': [],
            'pendingDraft': null,
          });
        }
      }
      _guard(owner, localId, generation);
      final report = await repository.progress(owner, profileId);
      _guard(owner, localId, generation);
      await _rootPatch(localId, {'verifiedXp': report['verified_xp'] ?? 0});
      if (deferredLessons > 0) _catalog = null;
      noticeKind = deferredLessons > 0 ? NoticeKind.info : NoticeKind.success;
      hasProfileConflict = false;
      message = deferredLessons > 0
          ? 'Một số bài đang chờ phiên bản máy chủ hỗ trợ. Bài làm vẫn được giữ trên thiết bị; bạn có thể tiếp tục học.'
          : store.pendingServerSessions == 0
          ? 'Tiến độ đã được đồng bộ với máy chủ.'
          : 'Đã đồng bộ một phần; thay đổi mới đang chờ gửi tiếp.';
    } on _AccountChanged {
      // No stale UI updates or acknowledgements after logout/profile switching.
    } catch (failure) {
      _dirty = false;
      if (!_disposed && cloud.userId == owner && store.profile?.id == localId) {
        if (failure is LearningApiFailure &&
            failure.code == 'revision_conflict' &&
            learningMap(
                  learningMap(
                    store.serverSyncFor(localId)['profile'],
                  )['pending'],
                )['kind'] ==
                'profile.update') {
          hasProfileConflict = true;
        }
        noticeKind = NoticeKind.error;
        message = friendlyError(
          failure,
          fallback: 'Chưa đồng bộ được kết quả. Tiến độ vẫn được giữ trên máy và sẽ thử lại khi có mạng.',
        );
      }
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _timer?.cancel();
    _retry?.cancel();
    store.removeListener(_changed);
    cloud.removeListener(_changed);
    super.dispose();
  }
}
