import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/support_repository.dart';
import 'package:mathlingo/features/parent_portal/screens/support_screen.dart';
import 'package:provider/provider.dart';

class SupportState extends AppStateProvider {
  bool unlocked = true, admin = false;
  @override
  bool get isParentUnlocked => unlocked;
  @override
  bool get isAdmin => admin;
  @override
  String? get accountId => 'parent-a';
  @override
  String? get parentToken => unlocked ? 'parent-proof' : null;
  @override
  Future<void> refreshFromCloud() async {}
  void lock() {
    unlocked = false;
    notifyListeners();
  }
}

class TestSupport extends SupportRepository {
  int loads = 0;
  bool fail = false;
  final keys = <String>[];
  final messages = <String>[];
  @override
  Future<List<Map<String, dynamic>>> fetch({
    bool admin = false,
    String? orderId,
    int page = 0,
  }) async {
    loads++;
    return [];
  }

  @override
  Future<void> request({
    required String message,
    required String requestId,
    required String parentToken,
    String? orderId,
  }) async {
    keys.add(requestId);
    messages.add(message);
    if (fail) throw StateError('offline');
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    SupportState state,
    TestSupport repository, {
    bool admin = false,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppStateProvider>.value(
        value: state,
        child: MaterialApp(
          home: SupportScreen(admin: admin, repository: repository),
        ),
      ),
    );
    await tester.pump();
  }

  test(
    'message validation rejects whitespace and enforces server length limits',
    () {
      expect(SupportRepository.validateMessage('    '), isNotNull);
      expect(SupportRepository.validateMessage('abcd'), isNotNull);
      expect(SupportRepository.validateMessage('  abcde  '), isNull);
      expect(SupportRepository.validateMessage('a' * 2001), isNotNull);
    },
  );

  testWidgets('locked parent and non-admin perform no support queries', (
    tester,
  ) async {
    final repository = TestSupport();
    await mount(tester, SupportState()..unlocked = false, repository);
    expect(repository.loads, 0);
    expect(find.text('Nhập PIN để tiếp tục'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await mount(tester, SupportState(), repository, admin: true);
    expect(repository.loads, 0);
    expect(find.text('Cần quyền admin để xử lý hỗ trợ.'), findsOneWidget);
  });

  testWidgets(
    'invalid submission keeps form open; failed send retains draft and retry key',
    (tester) async {
      final repository = TestSupport()..fail = true;
      await mount(tester, SupportState(), repository);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gửi yêu cầu mới'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.tap(find.text('Gửi'));
      await tester.pumpAndSettle();
      expect(find.text('Nội dung cần từ 5 đến 2000 ký tự.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(repository.messages, isEmpty);
      await tester.enterText(
        find.byType(TextFormField),
        'Xin kiểm tra giúp thanh toán',
      );
      await tester.tap(find.text('Gửi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa gửi được'), findsOneWidget);
      await tester.tap(find.text('Gửi yêu cầu mới'));
      await tester.pumpAndSettle();
      expect(find.text('Xin kiểm tra giúp thanh toán'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('Gửi'));
      await tester.pumpAndSettle();
      expect(repository.keys, hasLength(2));
      expect(repository.keys.first, repository.keys.last);
      expect(find.textContaining('Chưa gửi được'), findsNothing);
    },
  );

  testWidgets('locking gate closes an open private support draft', (
    tester,
  ) async {
    final state = SupportState();
    final repository = TestSupport();
    await mount(tester, state, repository);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi yêu cầu mới'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Nội dung riêng tư');
    state.lock();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Nội dung riêng tư'), findsNothing);
    expect(repository.messages, isEmpty);
  });
}
