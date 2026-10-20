import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/repositories/commerce_repository.dart';
import 'package:mathlingo/features/subscriptions/payment_waiting_screen.dart';

void main() {
  final session = PaymentSession(
    orderId: 'order-a',
    provider: 'vnpay',
    payUrl: Uri.parse('https://sandbox.vnpayment.vn/paymentv2/vpcpay.html'),
  );

  Future<void> mount(
    WidgetTester tester,
    Future<String> Function(String) load, {
    Duration timeout = const Duration(minutes: 15),
    Future<void> Function()? refresh,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PaymentWaitingScreen(
          session: session,
          statusLoader: load,
          refreshEntitlements: refresh,
          waitTimeout: timeout,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('network error is visible; manual retry can recover', (
    tester,
  ) async {
    bool fail = true;
    await mount(tester, (_) async {
      if (fail) throw StateError('offline');
      return 'failed';
    });
    expect(
      find.textContaining('Chưa kiểm tra được thanh toán'),
      findsOneWidget,
    );
    expect(find.text('Thanh toán thành công!'), findsNothing);
    fail = false;
    await tester.scrollUntilVisible(find.text('Kiểm tra lại'), 250);
    await tester.tap(find.text('Kiểm tra lại'));
    await tester.pump();
    expect(find.text('Thanh toán không thành công.'), findsOneWidget);
    expect(find.textContaining('Chưa kiểm tra được thanh toán'), findsNothing);
  });

  testWidgets(
    'network timeout stops automatic polling and retains manual status check',
    (tester) async {
      int calls = 0;
      await mount(tester, (_) async {
        calls++;
        throw StateError('offline');
      }, timeout: const Duration(milliseconds: -1));
      expect(
        find.textContaining('Đã hết thời gian chờ xác nhận'),
        findsOneWidget,
      );
      expect(find.text('Mở trang thanh toán VNPay'), findsNothing);
      await tester.pump(const Duration(seconds: 9));
      expect(calls, 1);
      await tester.tap(find.text('Kiểm tra lại'));
      await tester.pump();
      expect(calls, 2);
    },
  );

  testWidgets('refund is shown as refund and terminal state stops polling', (
    tester,
  ) async {
    int calls = 0;
    await mount(tester, (_) async {
      calls++;
      return 'refunded';
    });
    expect(find.textContaining('Giao dịch đã được hoàn tiền'), findsOneWidget);
    expect(find.textContaining('hết thời gian'), findsNothing);
    await tester.pump(const Duration(seconds: 9));
    expect(calls, 1);
  });

  testWidgets('stalled order request times out and enables retry', (
    tester,
  ) async {
    final response = Completer<String>();
    await mount(tester, (_) => response.future);
    await tester.pump(const Duration(seconds: 21));
    await tester.pump();
    expect(
      find.textContaining('Chưa kiểm tra được thanh toán'),
      findsOneWidget,
    );
    response.complete('pending');
    await tester.pump();
  });

  testWidgets(
    'confirmed payment survives refresh failure without promising active Plus',
    (tester) async {
      await mount(
        tester,
        (_) async => 'paid',
        refresh: () async {
          throw StateError('entitlement refresh offline');
        },
      );
      await tester.pump();
      expect(find.text('Thanh toán thành công!'), findsOneWidget);
      expect(find.text('Gói Plus đã được kích hoạt.'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    },
  );
}
