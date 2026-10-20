import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mathlingo/data/models/commerce_models.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/demo_payment_repository.dart';
import 'package:mathlingo/features/subscriptions/demo_payment_screen.dart';
import 'package:mathlingo/features/subscriptions/widgets/demo_transaction_card.dart';

class DemoState extends AppStateProvider {
  bool unlocked = true, refreshFails = false;
  int refreshes = 0;
  @override
  bool get isParentUnlocked => unlocked;
  @override
  String? get parentToken => unlocked ? 'pin-proof' : null;
  @override
  Future<void> refreshFromCloud() async {}
  @override
  Future<void> refreshSubscription() async {
    refreshes++;
    if (refreshFails) throw StateError('offline after committed payment');
  }
}

LearningOrder order(String status) => LearningOrder(
  id: 'demo-order',
  parentId: 'parent',
  status: status,
  label: 'Plus tháng',
  isDemo: true,
  transactionId: status == 'paid' ? 'DEMO-transaction' : null,
  amountVnd: 99000,
  createdAt: DateTime.now(),
  expiresAt: DateTime.now().add(const Duration(minutes: 15)),
);

class FakeDemo extends DemoPaymentRepository {
  int calls = 0;
  bool fail = false;
  Completer<LearningOrder>? pending;
  @override
  Future<LearningOrder> confirm({
    required String transactionId,
    required String parentToken,
  }) async {
    calls++;
    expect(transactionId, 'demo-order');
    expect(parentToken, 'pin-proof');
    if (fail) throw StateError('not confirmed');
    return pending == null ? order('paid') : pending!.future;
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    DemoState state,
    FakeDemo repo,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppStateProvider>.value(
        value: state,
        child: MaterialApp(
          home: DemoPaymentScreen(order: order('pending'), repository: repo),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'demo remains pending until server confirms and prevents double tap',
    (tester) async {
      final state = DemoState(),
          repo = FakeDemo()..pending = Completer<LearningOrder>();
      await mount(tester, state, repo);
      expect(find.text('DEMO — không thu tiền thật'), findsOneWidget);
      await tester.tap(find.text('Giả lập thanh toán thành công'));
      await tester.pump();
      expect(find.text('Đã thanh toán mô phỏng thành công'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repo.pending!.complete(order('paid'));
      await tester.pumpAndSettle();
      expect(repo.calls, 1);
      expect(state.refreshes, 1);
      expect(find.text('Đã thanh toán mô phỏng thành công'), findsOneWidget);
      expect(find.text('Mã giao dịch: DEMO-transaction'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  testWidgets('server failure never displays paid and allows retry', (
    tester,
  ) async {
    final state = DemoState(), repo = FakeDemo()..fail = true;
    await mount(tester, state, repo);
    await tester.tap(find.text('Giả lập thanh toán thành công'));
    await tester.pumpAndSettle();
    expect(find.text('Đã thanh toán mô phỏng thành công'), findsNothing);
    expect(find.textContaining('Chưa xác nhận được.'), findsOneWidget);
    repo.fail = false;
    await tester.tap(find.text('Giả lập thanh toán thành công'));
    await tester.pumpAndSettle();
    expect(find.text('Đã thanh toán mô phỏng thành công'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
    'committed payment stays successful if entitlement refresh fails',
    (tester) async {
      final state = DemoState()..refreshFails = true;
      await mount(tester, state, FakeDemo());
      await tester.tap(find.text('Giả lập thanh toán thành công'));
      await tester.pumpAndSettle();
      expect(find.text('Đã thanh toán mô phỏng thành công'), findsOneWidget);
      expect(
        find.textContaining('Đã lưu thanh toán mô phỏng.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      state.dispose();
    },
  );

  testWidgets('locked parent cannot reach demo confirmation', (tester) async {
    final state = DemoState()..unlocked = false, repo = FakeDemo();
    await mount(tester, state, repo);
    expect(find.text('Giả lập thanh toán thành công'), findsNothing);
    expect(repo.calls, 0);
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets(
    'admin history labels demo and has no real refund or reconcile action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DemoTransactionCard(order: order('paid'), showParent: true),
          ),
        ),
      );
      expect(find.textContaining('không thu tiền thật'), findsOneWidget);
      expect(
        find.text('Đã thanh toán mô phỏng · Đã cấp quyền demo'),
        findsOneWidget,
      );
      expect(find.text('Hoàn tiền toàn phần'), findsNothing);
      expect(find.text('Đối soát VNPay'), findsNothing);
    },
  );
}
