import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brilliant_mobile/data/models/cloud_backup.dart';
import 'package:brilliant_mobile/data/models/learning_journal.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/data/providers/learning_sync_controller.dart';
import 'package:brilliant_mobile/data/repositories/auth_repository.dart';
import 'package:brilliant_mobile/data/repositories/backup_repository.dart';
import 'package:brilliant_mobile/data/repositories/learning_repository.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';

import 'math_experiments_test.dart' show mathSolutionStates;
import 'extended_solutions.dart';

class SyncTestAuth implements AuthRepository {
  String? owner = 'owner-a';
  final events = StreamController<String?>.broadcast(sync: true);
  @override
  String? get userId => owner;
  @override
  String? get email => owner == null ? null : 'test@example.invalid';
  @override
  Stream<String?> get changes => events.stream;
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<bool> signUp(String email, String password) async => false;
  @override
  Future<void> verifyEmailCode(String email, String code) async {}
  @override
  Future<void> resendConfirmation(String email) async {}
  @override
  Future<void> signOut() async {
    owner = null;
    events.add(null);
  }
}

class SyncTestBackups implements BackupRepository {
  @override
  Future<List<CloudBackup>> list(String owner) async => [];
  @override
  Future<CloudBackup> save(
    String owner,
    String key,
    int revision,
    Map<String, dynamic> payload,
  ) async => CloudBackup.fromJson({
    'profile_key': key,
    'revision': revision + 1,
    'payload': payload,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
  });
}

class SyncTestRepository implements LearningRepository {
  final receipts = <String, Map<String, dynamic>>{};
  final payloads = <String, String>{};
  final operations = <String>[];
  final profiles = <String, Map<String, dynamic>>{};
  int draftRevision = 0, xp = 0, completions = 0;
  bool offline = false,
      loseDraftResponse = false,
      conflictProfileUpdate = false;
  Completer<void>? profileDelay;
  @override
  Future<Map<String, dynamic>?> profile(String owner, String id) async {
    if (profileDelay != null) await profileDelay!.future;
    if (offline) throw TimeoutException('offline');
    return profiles[id];
  }

  @override
  Future<Map<String, dynamic>> catalog(String owner) async => {
    'release': {'id': '33333333-3333-4333-8333-333333333333'},
    'activities': [
      for (final t in topics)
        for (final s in t.experiments)
          {
            'topic_id': t.id,
            'activity_id': s.id,
            'content_version': s.contentVersion,
            'mechanism': s.mechanism,
            'config': s.config,
            'initial_state': s.initial,
          },
    ],
  };
  Future<Map<String, dynamic>> apply(
    String owner,
    String op,
    String kind,
    Map<String, dynamic> payload,
  ) async {
    if (offline) throw TimeoutException('offline');
    operations.add('$owner/$kind');
    if (kind == 'profile.update' && conflictProfileUpdate) {
      throw const LearningApiFailure('revision_conflict', 'Profile conflict');
    }
    final encoded = jsonEncode(payload);
    if (receipts.containsKey(op)) {
      expect(payloads[op], encoded, reason: 'Retry changed immutable request');
      return learningCopy(receipts[op]!);
    }
    Map<String, dynamic> result = {};
    if (kind.startsWith('profile.')) {
      result = {...payload, 'revision': '1', 'owner_user_id': owner};
      profiles[payload['id'] as String] = result;
    } else if (kind == 'draft.save') {
      expect('${payload['expected_revision']}', '$draftRevision');
      draftRevision++;
      result = {
        'draft': {'revision': '$draftRevision'},
      };
    } else if (kind == 'attempt.submit') {
      final spec = topics
          .expand((t) => t.experiments)
          .firstWhere((s) => s.id == payload['activity_id']);
      result = {
        'attempt': {
          'evaluation_status': 'verified',
          'is_correct': spec.isCorrect(learningMap(payload['state'])),
        },
      };
    } else if (kind == 'session.complete') {
      completions++;
      result = {'xp_awarded': xp == 0 ? 30 : 0};
      xp = 30;
    }
    final receipt = {'revision': '${receipts.length + 1}', 'result': result};
    receipts[op] = learningCopy(receipt);
    payloads[op] = encoded;
    if (kind == 'draft.save' && loseDraftResponse) {
      loseDraftResponse = false;
      throw TimeoutException('response lost after commit');
    }
    return receipt;
  }

  @override
  Future<Map<String, dynamic>> mutate(
    String owner,
    String operation,
    String kind,
    Map<String, dynamic> payload,
  ) => apply(owner, operation, kind, payload);
  @override
  Future<Map<String, dynamic>> attempt(
    String owner,
    String operation,
    Map<String, dynamic> payload,
  ) => apply(owner, operation, 'attempt.submit', payload);
  @override
  Future<Map<String, dynamic>> progress(String owner, String profileId) async =>
      {'verified_xp': xp};
}

void main() {
  late LearningStore store;
  late SyncTestAuth auth;
  late CloudBackupController cloud;
  late LearningSyncController sync;
  late SyncTestRepository repository;
  final topic = topics.first;
  final solutions = {...mathSolutionStates, ...extendedSolutions};
  Map<String, dynamic> draft() => {
    'version': 3,
    'step': 0,
    'states': {
      for (final spec in topic.experiments) spec.id: solutions[spec.id],
    },
    'attempts': 1,
    'checked': [topic.experiments.first.id],
    'hints': <String>[],
    'activeActivityId': topic.experiments.first.id,
  };
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LearningStore(
      await SharedPreferences.getInstance(),
      enableServerSync: true,
    );
    await store.createDeviceProfile('Learner');
    await store.finishOnboarding(['logic'], 10);
    auth = SyncTestAuth();
    cloud = CloudBackupController(
      store: store,
      auth: auth,
      repository: SyncTestBackups(),
    );
    repository = SyncTestRepository();
    sync = LearningSyncController(
      store: store,
      cloud: cloud,
      repository: repository,
      automatic: false,
    );
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() async {
    sync.dispose();
    cloud.dispose();
    store.dispose();
    await auth.events.close();
  });

  test('local completion and journal commit together, then server confirms exactly once', () async {
    final value = draft();
    await store.saveProgress(topic.id, value);
    await store.finish(topic.id, experiments: topic.experiments, draft: value);
    expect(store.pendingServerSessions, 1);
    expect(store.verifiedPoints, 0);
    final durable = jsonDecode(
      store.preferences.getString(LearningStore.storageKey)!,
    );
    expect((durable['learning'] as Map).values.first['serverSync'], isNotNull);
    await sync.syncNow();
    expect(sync.message, 'Tiến độ đã được đồng bộ với máy chủ.');
    expect(store.verifiedPoints, 30);
    expect(store.pendingServerSessions, 0);
    expect(repository.completions, 1);
    await sync.syncNow();
    expect(repository.completions, 1);
  });
  test('lost draft response retries same payload before a newer edit, including restart', () async {
    await store.saveProgress(topic.id, draft());
    repository.loseDraftResponse = true;
    await sync.syncNow();
    expect(repository.draftRevision, 1);
    expect(store.pendingServerSessions, 1);
    final newer = draft()..['seconds'] = 7;
    await store.saveProgress(topic.id, newer);
    sync.dispose();
    cloud.dispose();
    store.dispose();
    store = LearningStore(
      await SharedPreferences.getInstance(),
      enableServerSync: true,
    );
    cloud = CloudBackupController(
      store: store,
      auth: auth,
      repository: SyncTestBackups(),
    );
    sync = LearningSyncController(
      store: store,
      cloud: cloud,
      repository: repository,
      automatic: false,
    );
    await sync.syncNow();
    await sync.syncNow();
    expect(repository.draftRevision, 2);
    expect(store.pendingServerSessions, 0);
  });
  test(
    'offline completion survives restart and is sent when connection returns',
    () async {
      final value = draft();
      await store.finish(
        topic.id,
        experiments: topic.experiments,
        draft: value,
      );
      repository.offline = true;
      await sync.syncNow();
      expect(store.pendingServerSessions, 1);
      expect(store.completed, contains(topic.id));
      expect(store.verifiedPoints, 0);
      repository.offline = false;
      await sync.syncNow();
      expect(store.verifiedPoints, 30);
    },
  );
  test(
    'restored backup forks session and attempt IDs while preserving answers',
    () async {
      await store.saveProgress(topic.id, draft());
      final old = store.serverSyncFor(store.profile!.id);
      final local = await store.restoreProfile(
        store.exportProfile(store.profile!.id),
      );
      final restored = store.serverSyncFor(local);
      final before = learningMap(old['sessions']);
      final after = learningMap(restored['sessions']);
      expect(before.keys.single, isNot(after.keys.single));
      expect(
        learningMap(before.values.single)['snapshot'],
        learningMap(after.values.single)['snapshot'],
      );
      expect(
        (learningMap(before.values.single)['attempts'] as List).first['id'],
        isNot(
          (learningMap(after.values.single)['attempts'] as List).first['id'],
        ),
      );
    },
  );
  test('account switch during HTTP does not acknowledge or send old profile with new owner', () async {
    await store.saveProgress(topic.id, draft());
    final profileId = store.profile!.id;
    repository.profileDelay = Completer<void>();
    final pending = sync.syncNow();
    await Future<void>.delayed(Duration.zero);
    auth.owner = 'owner-b';
    auth.events.add('owner-b');
    repository.profileDelay!.complete();
    await pending;
    expect(repository.operations, isEmpty);
    expect(
      learningMap(store.serverSyncFor(profileId)['sessions']).values
          .every((x) => learningMap(x)['verified'] != true),
      true,
    );
  });
  test('profile conflict can be reviewed and resolved without dropping lesson data', () async {
    await store.saveProgress(topic.id, draft());
    await sync.syncNow();
    final remoteId =
        learningMap(store.serverSyncFor(store.profile!.id)['profile'])['id']
            as String;
    repository.profiles[remoteId] = {
      ...repository.profiles[remoteId]!,
      'name': 'Other device',
      'revision': '2',
    };
    await store.rename('Phone choice');
    repository.conflictProfileUpdate = true;
    await sync.syncNow();
    expect(sync.hasProfileConflict, true, reason: sync.message);
    final remote = await sync.loadConflictProfile();
    repository.conflictProfileUpdate = false;
    await sync.resolveProfileConflict(remote, useDevice: true);
    expect(sync.hasProfileConflict, false);
    expect(repository.profiles[remoteId]!['name'], 'Phone choice');
    expect(store.progress(topic.id), isNotNull);
  });
  test(
    'journal and completion roll back together when local durable write fails',
    () async {
      final failing = LearningStore(
        store.preferences,
        enableServerSync: true,
        writeSnapshot: (_, _) async => false,
      );
      addTearDown(failing.dispose);
      await expectLater(
        failing.finish(
          topic.id,
          experiments: topic.experiments,
          draft: draft(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(failing.completed, isEmpty);
      expect(failing.serverSyncFor(failing.profile!.id), isEmpty);
    },
  );
}
