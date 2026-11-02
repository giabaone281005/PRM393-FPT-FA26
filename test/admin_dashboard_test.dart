import 'dart:async';

import 'package:brilliant_mobile/data/models/admin_dashboard.dart';
import 'package:brilliant_mobile/data/providers/admin_dashboard_controller.dart';
import 'package:brilliant_mobile/data/repositories/admin_repository.dart';
import 'package:brilliant_mobile/data/repositories/auth_repository.dart';
import 'package:brilliant_mobile/features/admin/admin_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAdminAuth implements AuthRepository {
  TestAdminAuth([this.owner = 'admin']) {
    signInOwner = owner ?? 'admin';
  }
  late String signInOwner;
  String? owner;
  final events = StreamController<String?>.broadcast(sync: true);
  @override
  String? get userId => owner;
  @override
  String? get email => owner == null ? null : '$owner@example.test';
  @override
  Stream<String?> get changes => events.stream;
  void change(String? id) {
    owner = id;
    events.add(id);
  }

  @override
  Future<void> signIn(String email, String password) async =>
      change(signInOwner);
  @override
  Future<void> signOut() async => change(null);
  @override
  Future<bool> signUp(String email, String password) async => false;
  @override
  Future<void> verifyEmailCode(String email, String code) async {}
  @override
  Future<void> resendConfirmation(String email) async {}
}

class TestAdminRepository implements AdminRepository {
  AdminAccess permission = const AdminAccess('admin', 'active');
  final events = StreamController<AdminRealtimeEvent>.broadcast(sync: true);
  final operations = <String>[];
  int reads = 0, users = 2;
  bool failMutation = false;
  Completer<Map<String, dynamic>>? delayed;
  final topics = <Map<String, dynamic>>[
    {
      'id': 'logic',
      'title': 'Logic & quy luật',
      'subject': 'Tư duy',
      'subtitle': 'Cân và thử',
      'status': 'active',
      'sort_order': 0,
      'icon_key': 'hub_outlined',
      'activity_count': 6,
    },
  ];
  @override
  Future<AdminAccess> access(String owner) async => permission;
  @override
  Future<Map<String, dynamic>> read(
    String owner,
    String section, {
    String search = '',
    int offset = 0,
  }) async {
    reads++;
    if (delayed != null) return delayed!.future;
    if (section == 'overview') {
      return {
        'users': users,
        'topics': topics.length,
        'active_users': users,
        'suspended_users': 0,
        'verified_completions': 1,
      };
    }
    final items = section == 'topics'
        ? topics
        : [
            {
              'id': 'user-1',
              'display_name': 'Người học thử',
              'email': 'learner@example.test',
              'created_at': '2026-10-31T00:00:00Z',
              'status': 'active',
            },
          ];
    return {'items': items, 'total': items.length};
  }

  @override
  Future<void> mutate(
    String owner,
    String operationId,
    String type,
    Map<String, dynamic> payload,
  ) async {
    operations.add(operationId);
    if (failMutation) throw const AdminFailure('Test network failure');
    if (type == 'topic.save') topics.add({...payload, 'activity_count': 0});
  }

  @override
  Stream<AdminRealtimeEvent> watch(String owner) => events.stream;
}

void main() {
  testWidgets('denied role renders safely', (tester) async {
    final auth = TestAdminAuth('user'),
        repo = TestAdminRepository()
          ..permission = const AdminAccess('user', 'active');
    final controller = AdminDashboardController(auth: auth, repository: repo);
    await tester.pumpWidget(AdminApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Tài khoản chưa có quyền quản trị'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await auth.events.close();
    await repo.events.close();
  });
  test(
    'non-admin never reads dashboard data or subscribes to realtime',
    () async {
      final auth = TestAdminAuth('user'),
          repo = TestAdminRepository()
            ..permission = const AdminAccess('user', 'active');
      final controller = AdminDashboardController(auth: auth, repository: repo);
      await Future<void>.delayed(Duration.zero);
      expect(controller.allowed, false);
      expect(repo.reads, 0);
      expect(repo.events.hasListener, false);
      controller.dispose();
      await auth.events.close();
      await repo.events.close();
    },
  );

  test(
    'a late read from the previous account cannot repopulate dashboard',
    () async {
      final auth = TestAdminAuth(),
          repo = TestAdminRepository()
            ..delayed = Completer<Map<String, dynamic>>();
      final controller = AdminDashboardController(auth: auth, repository: repo);
      await Future<void>.delayed(Duration.zero);
      repo.permission = const AdminAccess('user', 'active');
      auth.change('other');
      repo.delayed!.complete({'items': [], 'total': 0});
      await Future<void>.delayed(Duration.zero);
      expect(controller.allowed, false);
      expect(controller.accounts, isEmpty);
      expect(controller.overview, isEmpty);
      controller.dispose();
      await auth.events.close();
      await repo.events.close();
    },
  );

  testWidgets(
    'realtime invalidation reloads; mutation retry preserves operation ID',
    (tester) async {
      final auth = TestAdminAuth(), repo = TestAdminRepository();
      final controller = AdminDashboardController(auth: auth, repository: repo);
      await tester.pump();
      expect(controller.overview['users'], 2);
      repo.users = 3;
      repo.events.add(const AdminRealtimeEvent(connected: true, changed: true));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(controller.overview['users'], 3);
      final account = controller.accounts.first;
      repo.failMutation = true;
      expect(await controller.setAccountStatus(account, 'suspended'), false);
      repo.failMutation = false;
      expect(await controller.setAccountStatus(account, 'suspended'), true);
      expect(repo.operations[0], repo.operations[1]);
      controller.dispose();
      await auth.events.close();
      await repo.events.close();
    },
  );

  for (final width in [375.0, 1440.0]) {
    testWidgets('admin dashboard is usable at $width px and large text', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = TestAdminAuth(), repo = TestAdminRepository();
      final controller = AdminDashboardController(auth: auth, repository: repo);
      await tester.pumpWidget(AdminApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Người học thử'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Người học thử'), findsOneWidget);
      expect(tester.takeException(), isNull);
      controller.selectSection('topics');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Logic & quy luật'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Logic & quy luật'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('admin-add-topic')));
      await tester.tap(find.byKey(const ValueKey('admin-add-topic')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu chủ đề'));
      await tester.pumpAndSettle();
      expect(find.text('Nhập tên chủ đề.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('topic-id')),
        'topic-test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('topic-title')),
        'Chủ đề thử',
      );
      await tester.enterText(
        find.byKey(const ValueKey('topic-subject')),
        'Toán',
      );
      await tester.tap(find.text('Lưu chủ đề'));
      await tester.pumpAndSettle();
      expect(repo.topics.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await auth.events.close();
      await repo.events.close();
    });
  }

  testWidgets('revoked admin role clears the dashboard and open dialogs', (
    tester,
  ) async {
    final auth = TestAdminAuth(), repo = TestAdminRepository();
    final controller = AdminDashboardController(auth: auth, repository: repo);
    await tester.pumpWidget(AdminApp(controller: controller));
    await tester.pumpAndSettle();
    controller.selectSection('topics');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-add-topic')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('admin-add-topic')));
    await tester.pumpAndSettle();
    repo.permission = const AdminAccess('admin', 'suspended');
    unawaited(controller.refresh());
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Tài khoản chưa có quyền quản trị'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await auth.events.close();
    await repo.events.close();
  });
}
