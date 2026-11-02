import 'dart:convert';

import 'package:brilliant_mobile/data/models/account_progress.dart';
import 'package:brilliant_mobile/data/models/cloud_backup.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/data/repositories/backup_repository.dart';
import 'package:brilliant_mobile/features/account/cloud_account_page.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_dashboard_test.dart' show TestAdminAuth;

class _Progress implements BackupRepository {
  final rows = <String, CloudBackup>{};
  int writes = 0;
  bool offline = false;
  @override
  Future<List<CloudBackup>> list(String owner) async {
    if (offline) throw StateError('offline');
    return rows[owner] == null ? [] : [rows[owner]!];
  }

  @override
  Future<CloudBackup> save(
    String owner,
    String key,
    int revision,
    Map<String, dynamic> payload,
  ) async {
    if (offline) throw StateError('offline');
    final old = rows[owner];
    final copy = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
    key = old?.key ?? 'account-$owner';
    (copy['profile'] as Map)['id'] = key;
    if (old != null && jsonEncode(old.payload) == jsonEncode(copy)) return old;
    if ((old?.revision ?? 0) != revision) throw const BackupConflict();
    writes++;
    return rows[owner] = CloudBackup(
      key: key,
      revision: revision + 1,
      payload: copy,
      updatedAt: DateTime.now(),
    );
  }
}

Future<void> ready(CloudBackupController cloud) async {
  await cloud.prepareAccount();
  for (var i = 0; i < 10 && cloud.preparingProfile; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('relogin and a fresh device automatically open the same saved account progress', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = _Progress(), auth = TestAdminAuth('user-a');
    final store = LearningStore(await SharedPreferences.getInstance());
    final cloud = CloudBackupController(
      store: store,
      auth: auth,
      repository: repo,
      singleProfile: true,
    );
    await ready(cloud);
    await store.createDeviceProfile('An');
    await store.finishOnboarding(['logic'], 10);
    await store.saveProgress('logic', {'step': 2});
    await cloud.saveCurrent(automatic: true);
    final original = store.profile!.id;
    await cloud.signOut();
    await cloud.signIn('a@example.test', 'test-password');
    await ready(cloud);
    expect(store.profile!.id, original);
    expect(store.profiles.length, 1);
    expect(store.progress('logic')!['step'], 2);
    final firstDevice = {
      for (final key in store.preferences.getKeys())
        key: store.preferences.get(key)!,
    };
    cloud.dispose();
    store.dispose();
    await auth.events.close();
    SharedPreferences.setMockInitialValues({});
    final next = LearningStore(await SharedPreferences.getInstance()),
        secondAuth = TestAdminAuth('user-a');
    final second = CloudBackupController(
      store: next,
      auth: secondAuth,
      repository: repo,
      singleProfile: true,
    );
    await ready(second);
    expect(next.profile!.name, 'An');
    expect(next.progress('logic')!['step'], 2);
    expect(next.profiles.length, 1);
    await next.saveProgress('logic', {'step': 3});
    await second.saveCurrent(automatic: true);
    second.dispose();
    next.dispose();
    await secondAuth.events.close();
    SharedPreferences.setMockInitialValues(firstDevice);
    final reopened = LearningStore(await SharedPreferences.getInstance());
    final returnedAuth = TestAdminAuth('user-a');
    final returned = CloudBackupController(
      store: reopened,
      auth: returnedAuth,
      repository: repo,
      singleProfile: true,
    );
    await ready(returned);
    expect(reopened.profile!.id, original);
    expect(reopened.profiles.length, 1);
    expect(reopened.progress('logic')!['step'], 3);
    returned.dispose();
    reopened.dispose();
    await returnedAuth.events.close();
  });

  testWidgets(
    'learning changes save automatically; offline draft is retained',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = _Progress(), auth = TestAdminAuth('user-a');
      final store = LearningStore(await SharedPreferences.getInstance());
      final cloud = CloudBackupController(
        store: store,
        auth: auth,
        repository: repo,
        singleProfile: true,
      );
      await tester.pump();
      await store.createDeviceProfile('An');
      await store.finishOnboarding(['logic'], 10);
      await store.saveProgress('logic', {'step': 3});
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(repo.writes, greaterThan(0));
      repo.offline = true;
      await store.saveProgress('logic', {'step': 4});
      await cloud.saveCurrent(automatic: true);
      expect(store.progress('logic')!['step'], 4);
      repo.offline = false;
      await cloud.saveCurrent(automatic: true);
      expect(
        (repo.rows['user-a']!.payload['learning']
            as Map)['drafts']['logic']['step'],
        4,
      );
      cloud.dispose();
      store.dispose();
      await auth.events.close();
    },
  );

  testWidgets(
    'single account UI has no profile picker, engine menu or manual sync controls',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = _Progress(), auth = TestAdminAuth('user-a');
      final store = LearningStore(await SharedPreferences.getInstance());
      final cloud = CloudBackupController(
        store: store,
        auth: auth,
        repository: repo,
        singleProfile: true,
      );
      await tester.pump();
      await store.createDeviceProfile('An');
      await store.finishOnboarding(['logic'], 10);
      await tester.pumpWidget(
        CloudScope(
          controller: cloud,
          child: LearnApp(store: store),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hồ sơ'));
      await tester.pumpAndSettle();
      expect(find.text('Đóng phiên & đổi hồ sơ'), findsNothing);
      expect(find.text('Lưu ngay'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('app-settings')));
      await tester.pumpAndSettle();
      expect(find.text('Engine học tập'), findsNothing);
      await tester.tap(find.text('Tài khoản'));
      await tester.pumpAndSettle();
      expect(find.text('Lưu lại ngay'), findsNothing);
      expect(find.text('Đồng bộ tiến độ ngay'), findsNothing);
      expect(
        find.textContaining('Một tài khoản, một tiến độ học'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      cloud.dispose();
      store.dispose();
      await auth.events.close();
    },
  );

  test('personal progress merge preserves both completed topics without multiplying history', () {
    final a = {
      'version': 3,
      'profile': {'id': 'a', 'name': 'An'},
      'learning': {
        'completed': {'logic': {}},
        'history': [
          {'course': 'logic', 'finishedAt': '2026-10-31'},
        ],
        'drafts': {
          'logic': {},
          'math': {'step': 2},
        },
      },
    };
    final b = jsonDecode(jsonEncode(a)) as Map<String, dynamic>;
    (b['learning'] as Map)['completed'] = {'science': {}};
    final merged = mergeAccountProgress(a, b),
        learning = merged['learning'] as Map;
    expect(
      (learning['completed'] as Map).keys,
      containsAll(['logic', 'science']),
    );
    expect(learning['history'], hasLength(1));
    expect((learning['drafts'] as Map).containsKey('logic'), false);
    final copy = jsonDecode(jsonEncode(a)) as Map<String, dynamic>;
    (copy['profile'] as Map)['id'] = 'other-device';
    (copy['learning'] as Map)['serverSync'] = {'verifiedXp': 30};
    expect(accountProgressHash(a), accountProgressHash(copy));
  });
}
