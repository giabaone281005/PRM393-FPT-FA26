import 'dart:async';
import 'dart:convert';

import 'package:brilliant_mobile/admin_main.dart' as app;
import 'package:brilliant_mobile/data/models/learning_journal.dart';
import 'package:brilliant_mobile/data/providers/admin_dashboard_controller.dart';
import 'package:brilliant_mobile/data/repositories/admin_repository.dart';
import 'package:brilliant_mobile/features/admin/admin_app.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const email = String.fromEnvironment('E2E_EMAIL');
  const password = String.fromEnvironment('E2E_PASSWORD');
  const owner = String.fromEnvironment('E2E_ID');
  const adminEmail = String.fromEnvironment('E2E_ADMIN_EMAIL');
  const adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');
  const adminId = String.fromEnvironment('E2E_ADMIN_ID');
  const run = String.fromEnvironment('E2E_RUN');
  const topic = String.fromEnvironment('E2E_TOPIC');

  testWidgets('Headed Admin web: real entrypoint, Auth, roles and mutations', (
    tester,
  ) async {
    expect(kIsWeb, true, reason: 'Admin must run in a web browser.');
    expect(
      [
        url,
        key,
        email,
        password,
        owner,
        adminEmail,
        adminPassword,
        adminId,
        run,
        topic,
      ].every((value) => value.isNotEmpty),
      true,
      reason: 'Use the ignored disposable E2E config through the launcher.',
    );
    tester.testTextInput.register();
    final report = <String, dynamic>{
      'run': run,
      'platform': 'web',
      'role': 'admin',
      'phases': <String>[],
      'success': false,
    };
    AdminDashboardController? controller;
    SupabaseClient? adminClient;
    final learner = SupabaseClient(
      url,
      key,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    final observer = SupabaseClient(
      url,
      key,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    StreamSubscription<dynamic>? realtime;
    var phase = 'bootstrap';
    var restoreAccount = false;
    var initialized = false;
    AdminDashboardController dashboard() => controller!;

    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 150));
      for (var i = 0; i < 8 && tester.binding.hasScheduledFrame; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> waitFor(bool Function() ready) async {
      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (!ready() && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(ready(), true, reason: '$phase: ${controller?.message}');
      await settle();
    }

    Future<void> reveal(Finder finder) async {
      for (var i = 0; i < 25 && finder.evaluate().isEmpty; i++) {
        expect(find.byType(Scrollable), findsWidgets, reason: phase);
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -350));
        await settle();
      }
      expect(finder, findsWidgets, reason: phase);
      await tester.ensureVisible(finder.first);
      await settle();
    }

    Future<void> tap(Finder finder) async {
      await reveal(finder);
      await tester.tap(finder.first);
      await settle();
    }

    Future<void> type(String name, String value) async {
      final finder = find.byKey(ValueKey(name));
      await reveal(finder);
      await tester.enterText(finder, value);
      await settle();
    }

    void passed(String name) {
      (report['phases'] as List).add(name);
      debugPrint('ADMIN_WEB_PASS $name');
    }

    try {
      // Exercise the same Supabase initialization and role gate as the web app.
      await app.main();
      initialized = true;
      await waitFor(() => find.byType(AdminApp).evaluate().isNotEmpty);
      controller = tester.widget<AdminApp>(find.byType(AdminApp)).controller;
      adminClient = Supabase.instance.client;
      await waitFor(() => !dashboard().loading);
      phase = 'admin_login';
      await tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
      await type('admin-email', adminEmail);
      await type('admin-password', '$adminPassword-invalid');
      await tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await waitFor(() => !dashboard().busy);
      expect(dashboard().allowed, false);
      expect(dashboard().message, isNotNull);
      await type('admin-password', adminPassword);
      await tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await waitFor(
        () => dashboard().allowed && !dashboard().loading && dashboard().live,
      );
      expect(adminClient.auth.currentUser?.id, adminId);
      expect(find.text('Tổng quan'), findsOneWidget);
      expect(dashboard().overview, isNotEmpty);
      passed('production_web_bootstrap_login_validation_and_overview');

      phase = 'learner_search_and_suspend';
      await learner.auth.signInWithPassword(email: email, password: password);
      expect(learner.auth.currentUser?.id, owner);
      await observer.auth.signInWithPassword(
        email: adminEmail,
        password: adminPassword,
      );
      var events = 0;
      var connected = false;
      realtime = SupabaseAdminRepository(observer)
          .watch(adminId)
          .listen((event) {
            connected = event.connected;
            if (event.changed) events++;
          });
      await waitFor(() => connected);
      await type('admin-search-accounts', email);
      await waitFor(
        () =>
            !dashboard().loading &&
            dashboard().accounts.length == 1 &&
            dashboard().accounts.single.id == owner,
      );
      expect(dashboard().accounts.single.status, 'active');
      final initialEvents = events;
      await tap(find.text('Tạm khóa').last);
      restoreAccount = true;
      await tap(find.text('Xác nhận'));
      await waitFor(
        () =>
            !dashboard().busy &&
            dashboard().accounts.single.status == 'suspended',
      );
      var denied = false;
      try {
        await learner.rpc(
          'load_account_progress',
          params: {'expected_owner': owner},
        );
      } on PostgrestException catch (error) {
        denied = error.code == '42501';
      }
      expect(denied, true);
      await tap(find.text('Mở lại'));
      await tap(find.text('Xác nhận'));
      await waitFor(
        () =>
            !dashboard().busy && dashboard().accounts.single.status == 'active',
      );
      restoreAccount = false;
      await learner.rpc(
        'load_account_progress',
        params: {'expected_owner': owner},
      );
      await waitFor(() => events > initialEvents);
      passed('web_search_suspend_reactivate_rpc_and_realtime');

      phase = 'topic_crud';
      await tap(find.text('Chủ đề').last);
      await tap(find.byKey(const ValueKey('admin-add-topic')));
      await type('topic-id', topic);
      await type('topic-title', 'Headed web $run');
      await type('topic-subject', 'Kiểm thử');
      await tap(find.text('Lưu chủ đề'));
      await waitFor(() => !dashboard().busy && !dashboard().loading);
      await type('admin-search-topics', topic);
      await waitFor(
        () =>
            !dashboard().loading &&
            dashboard().topics.length == 1 &&
            dashboard().topics.single.id == topic,
      );
      await tap(
        find.byTooltip(
          RegExp(
            '^Sửa (chủ đề|${RegExp.escape(dashboard().topics.single.title)})\$',
          ),
        ),
      );
      await type('topic-title', 'Headed web updated $run');
      await tap(find.byType(DropdownButtonFormField<String>));
      await tap(find.text('Lưu trữ').last);
      await tap(find.text('Lưu chủ đề'));
      await waitFor(
        () =>
            !dashboard().busy &&
            !dashboard().loading &&
            dashboard().topics.single.status == 'archived',
      );
      expect(dashboard().topics.single.title, 'Headed web updated $run');
      passed('web_topic_create_edit_archive');

      phase = 'logout_and_learner_role_gate';
      await tap(find.byTooltip('Đăng xuất'));
      await waitFor(
        () => find.byKey(const ValueKey('admin-email')).evaluate().isNotEmpty,
      );
      expect(dashboard().allowed, false);
      await type('admin-email', email);
      await type('admin-password', password);
      await tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await waitFor(() => !dashboard().loading && dashboard().userId == owner);
      expect(find.text('Tài khoản chưa có quyền quản trị'), findsOneWidget);
      expect(find.byType(AdminDashboardPage), findsNothing);
      var rpcDenied = false;
      try {
        await learner.rpc(
          'admin_dashboard_read',
          params: {'section': 'overview'},
        );
      } on PostgrestException catch (error) {
        rpcDenied = error.code == '42501';
      }
      expect(rpcDenied, true);
      await tap(find.text('Đăng xuất'));
      await waitFor(
        () => find.byKey(const ValueKey('admin-email')).evaluate().isNotEmpty,
      );
      passed('web_logout_and_learner_ui_rpc_denial');
      expect(tester.takeException(), isNull);
      report['success'] = true;
    } catch (_) {
      report['failedPhase'] = phase;
      rethrow;
    } finally {
      // Restore only this disposable learner if a suspend step failed midway.
      if (restoreAccount && adminClient?.auth.currentUser?.id == adminId) {
        try {
          await SupabaseAdminRepository(adminClient!).mutate(
            adminId,
            learningUuid(),
            'account.status',
            {'id': owner, 'status': 'active'},
          );
          report['accountRestoredAfterFailure'] = true;
        } catch (_) {
          report['accountRestoredAfterFailure'] = false;
          debugPrint(
            'ADMIN_WEB_CLEANUP: reactivate the disposable learner manually.',
          );
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await realtime?.cancel();
      controller?.dispose();
      for (final client in [learner, observer, ?adminClient]) {
        try {
          await client.auth.signOut(scope: SignOutScope.local);
        } catch (_) {}
      }
      await learner.dispose();
      await observer.dispose();
      if (initialized) await Supabase.instance.dispose();
      binding.reportData = report;
      debugPrint('ADMIN_WEB_RESULT ${jsonEncode(report)}');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
