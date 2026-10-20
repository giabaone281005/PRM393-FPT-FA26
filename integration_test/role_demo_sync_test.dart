import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathlingo/core/supabase/supabase_service.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/commerce_repository.dart';
import 'package:mathlingo/data/repositories/demo_payment_repository.dart';
import 'package:mathlingo/features/subscriptions/demo_payment_screen.dart';
import 'package:mathlingo/features/subscriptions/learning_packages_screen.dart';
import 'package:mathlingo/features/admin/admin_commerce_screen.dart';

// Explicitly authorized development fixtures only; credentials come from ignored
// build/demo-qa.json. Never run against production or a real family account.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const email = String.fromEnvironment('QA_EMAIL');
  const pass = String.fromEnvironment('QA_PASSWORD');
  const kid = String.fromEnvironment('QA_KID');
  const adminEmail = String.fromEnvironment('QA_ADMIN_EMAIL');
  const adminPass = String.fromEnvironment('QA_ADMIN_PASSWORD');
  const otherEmail = String.fromEnvironment('QA_OTHER_EMAIL');
  const otherPass = String.fromEnvironment('QA_OTHER_PASSWORD');

  Future<void> until(
    WidgetTester tester,
    bool Function() condition,
    String label,
  ) async {
    for (var i = 0; i < 180 && !condition(); i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(condition(), isTrue, reason: label);
  }

  testWidgets(
    'parent multi-session realtime, demo paid persistence and admin history',
    (tester) async {
      expect(email, anyOf(endsWith('@example.invalid'), 'parent@demo.test'));
      expect(adminEmail, anyOf(startsWith('demo-admin-'), 'admin@demo.test'));
      expect(otherEmail, startsWith('demo-other-'));
      await SupabaseService.initialize();
      final cloud = SupabaseService.client!;
      await cloud.auth.signInWithPassword(email: email, password: pass);
      final state = AppStateProvider();
      await state.refreshFromCloud();
      expect(state.hasKids, isTrue);
      if (!state.hasParentPin) {
        expect(await state.updateParentPinCode('8426'), isTrue);
      } else {
        expect(await state.verifyParentPin('8426'), isTrue);
      }
      final observer = SupabaseClient(
        SupabaseService.supabaseUrl,
        SupabaseService.anonKey,
      );
      final admin = SupabaseClient(
        SupabaseService.supabaseUrl,
        SupabaseService.anonKey,
      );
      final foreign = SupabaseClient(
        SupabaseService.supabaseUrl,
        SupabaseService.anonKey,
      );
      await observer.auth.signInWithPassword(email: email, password: pass);
      await admin.auth.signInWithPassword(
        email: adminEmail,
        password: adminPass,
      );
      await foreign.auth.signInWithPassword(
        email: otherEmail,
        password: otherPass,
      );
      expect(await admin.rpc('is_admin'), isTrue);
      expect(await cloud.rpc('is_admin'), isFalse);
      await expectLater(
        cloud.rpc('admin_dashboard'),
        throwsA(isA<PostgrestException>()),
      );

      var parentPaidEvents = 0,
          adminPaidEvents = 0,
          foreignPaidEvents = 0,
          supportEvents = 0;
      final ready = <Completer<void>>[];
      final channels = <(SupabaseClient, RealtimeChannel)>[];
      for (final (client, role) in [
        (observer, 'parent'),
        (admin, 'admin'),
        (foreign, 'foreign'),
      ]) {
        final joined = Completer<void>();
        ready.add(joined);
        final channel = client
            .channel('qa-demo-$role')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'demo_payment_transactions',
              callback: (payload) {
                if (payload.newRecord['parent_id'] !=
                        cloud.auth.currentUser?.id ||
                    payload.newRecord['status'] != 'paid') {
                  return;
                }
                if (role == 'parent') parentPaidEvents++;
                if (role == 'admin') adminPaidEvents++;
                if (role == 'foreign') foreignPaidEvents++;
              },
            )
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'support_requests',
              callback: (payload) {
                if (role == 'parent' &&
                    payload.newRecord['status'] == 'resolved') {
                  supportEvents++;
                }
              },
            )
            .subscribe((status, error) {
              if (status == RealtimeSubscribeStatus.subscribed &&
                  !joined.isCompleted) {
                joined.complete();
              }
            });
        channels.add((client, channel));
      }
      await Future.wait(ready.map((c) => c.future))
          .timeout(const Duration(seconds: 30));
      final observerToken = await observer.rpc(
        'unlock_parent',
        params: {'p_pin': '8426'},
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: const MaterialApp(
            home: Scaffold(body: Text('Watching remote family changes')),
          ),
        ),
      );
      final renamed = 'QA sync ${DateTime.now().millisecondsSinceEpoch}';
      final clock = Stopwatch()..start();
      await observer.rpc(
        'manage_kid',
        params: {
          'p_id': kid,
          'p_name': renamed,
          'p_grade': 1,
          'p_archive': false,
          'p_token': observerToken,
        },
      );
      await until(
        tester,
        () => state.currentKid.nickname == renamed,
        'AppState receives remote kid change',
      );
      debugPrint(
        'QA remote kid update observed in ${clock.elapsedMilliseconds} ms',
      );

      final ticket = await cloud.rpc(
        'request_support',
        params: {
          'p_order': null,
          'p_message': 'QA demo: verify family support synchronization',
          'p_key': CommerceRepository.newRequestId(),
          'p_token': state.parentToken,
        },
      );
      await admin.rpc(
        'resolve_support',
        params: {'p_id': ticket, 'p_reply': 'QA admin reply persisted'},
      );
      await until(
        tester,
        () => supportEvents > 0,
        'parent receives admin support reply over realtime',
      );
      final persistedTicket = await observer
          .from('support_requests')
          .select()
          .eq('id', ticket)
          .single();
      expect(persistedTicket['reply'], 'QA admin reply persisted');
      expect(
        await foreign.from('support_requests').select().eq('id', ticket),
        isEmpty,
      );
      expect(
        await cloud
            .from('notifications')
            .select()
            .eq('dedupe_key', 'support:$ticket'),
        hasLength(1),
      );

      final prices = await CommerceRepository.fetchPrices();
      final repo = DemoPaymentRepository();
      final key = CommerceRepository.newRequestId();
      final pending = await repo.create(
        priceId: prices.first.id,
        requestId: key,
        parentToken: state.parentToken!,
      );
      expect(
        (await repo.create(
          priceId: prices.first.id,
          requestId: key,
          parentToken: state.parentToken!,
        )).id,
        pending.id,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: MaterialApp(home: DemoPaymentScreen(order: pending)),
        ),
      );
      await until(
        tester,
        () => find.text('Giả lập thanh toán thành công').evaluate().isNotEmpty,
        'demo confirmation visible',
      );
      await tester.tap(find.text('Giả lập thanh toán thành công'));
      await until(
        tester,
        () => find
            .text('Đã thanh toán mô phỏng thành công')
            .evaluate()
            .isNotEmpty,
        'server-confirmed success visible',
      );
      await until(
        tester,
        () => state.isPlusActive,
        'Plus refreshes after demo payment',
      );
      await until(
        tester,
        () => parentPaidEvents > 0 && adminPaidEvents > 0,
        'parent and admin receive payment event',
      );
      expect(foreignPaidEvents, 0);
      final subscription = await cloud
          .from('subscriptions')
          .select()
          .eq('parent_id', cloud.auth.currentUser!.id)
          .single();
      await repo.confirm(
        transactionId: pending.id,
        parentToken: state.parentToken!,
      );
      final unchanged = await cloud
          .from('subscriptions')
          .select()
          .eq('parent_id', cloud.auth.currentUser!.id)
          .single();
      expect(unchanged['expires_at'], subscription['expires_at']);
      expect(
        await foreign
            .from('demo_payment_transactions')
            .select()
            .eq('id', pending.id),
        isEmpty,
      );
      expect(
        (await DemoPaymentRepository(client: admin).history()).any(
          (o) => o.id == pending.id && o.isDemo && o.status == 'paid',
        ),
        isTrue,
      );

      // New authenticated client proves persistence independent of the app state.
      final fresh = SupabaseClient(
        SupabaseService.supabaseUrl,
        SupabaseService.anonKey,
      );
      await fresh.auth.signInWithPassword(email: email, password: pass);
      final saved = (await DemoPaymentRepository(
        client: fresh,
      ).history()).singleWhere((o) => o.id == pending.id);
      expect(saved.status, 'paid');
      expect(saved.transactionId, startsWith('DEMO-'));
      await fresh.auth.signOut(scope: SignOutScope.local);
      await fresh.dispose();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: const MaterialApp(home: LearningPackagesScreen()),
        ),
      );
      await until(
        tester,
        () => !state.isLoadingFromCloud,
        'family loads before history',
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.scrollUntilVisible(
        find.text('Lịch sử thanh toán mô phỏng'),
        450,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await until(
        tester,
        () => find
            .textContaining('Đã thanh toán mô phỏng ·')
            .evaluate()
            .isNotEmpty,
        'parent history shows persisted demo',
      );

      for (final (client, channel) in channels) {
        await client.removeChannel(channel);
      }
      for (final client in [observer, admin, foreign]) {
        await client.auth.signOut(scope: SignOutScope.local);
        await client.dispose();
      }
      await tester.pumpWidget(const SizedBox());
      state.dispose();
      await cloud.auth.signOut(scope: SignOutScope.local);
      await cloud.auth.signInWithPassword(
        email: adminEmail,
        password: adminPass,
      );
      final adminState = AppStateProvider();
      await adminState.refreshFromCloud();
      expect(adminState.isAdmin, isTrue);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: adminState,
          child: const MaterialApp(home: AdminCommerceScreen()),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.scrollUntilVisible(
        find.text('Lịch sử thanh toán mô phỏng'),
        450,
        scrollable: find
            .descendant(
              of: find.byType(ListView).first,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await until(
        tester,
        () => find
            .textContaining('Đã thanh toán mô phỏng ·')
            .evaluate()
            .isNotEmpty,
        'admin history shows demo',
      );
      expect(
        find.textContaining('không tính vào doanh thu merchant'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      adminState.dispose();
      await cloud.auth.signOut(scope: SignOutScope.local);
    },
    timeout: const Timeout(Duration(minutes: 7)),
  );
}
