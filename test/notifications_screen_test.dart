import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/family_notification.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/notification_repository.dart';
import 'package:mathlingo/features/parent_portal/screens/notifications_screen.dart';
import 'package:provider/provider.dart';

class NotificationState extends AppStateProvider {
  bool unlocked = false;
  String uid = 'parent-a';
  @override
  bool get isParentUnlocked => unlocked;
  @override
  String? get accountId => uid;
  @override
  Future<void> refreshFromCloud() async {}
  void change({required bool open, String? account}) {
    unlocked = open;
    uid = account ?? uid;
    notifyListeners();
  }
}

class TestNotifications extends NotificationRepository {
  int loads = 0, writes = 0;
  bool read = false, fail = false;
  Completer<List<FamilyNotification>>? pending;
  @override
  Future<List<FamilyNotification>> fetch({int page = 0}) async {
    loads++;
    if (pending != null) return pending!.future;
    if (fail) throw StateError('offline');
    return [
      FamilyNotification(
        id: 'n-a',
        title: 'Thông báo riêng',
        body: 'Nội dung gia đình',
        createdAt: DateTime.utc(2026, 10, 20),
        readAt: read ? DateTime.utc(2026, 10, 20) : null,
      ),
    ];
  }

  @override
  Future<void> markRead(String id) async {
    writes++;
    if (fail) throw StateError('denied');
    read = true;
  }
}

void main() {
  Future<void> mount(
    WidgetTester tester,
    NotificationState state,
    TestNotifications repository,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppStateProvider>.value(
        value: state,
        child: MaterialApp(home: NotificationsScreen(repository: repository)),
      ),
    );
    await tester.pump();
  }

  testWidgets('locked gate performs no fetch; unlock loads and reads persist', (
    tester,
  ) async {
    final state = NotificationState();
    final repository = TestNotifications();
    await mount(tester, state, repository);
    expect(repository.loads, 0);
    expect(find.text('Nhập PIN để tiếp tục'), findsOneWidget);
    state.change(open: true);
    await tester.pumpAndSettle();
    expect(repository.loads, 1);
    await tester.tap(find.text('Thông báo riêng'));
    await tester.pumpAndSettle();
    expect(repository.writes, 1);
    expect(find.byIcon(Icons.drafts), findsOneWidget);
    await tester.tap(find.text('Thông báo riêng'));
    expect(repository.writes, 1);
    await tester.tap(find.byTooltip('Tải lại thông báo'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drafts), findsOneWidget);
    state.change(open: false);
    await tester.pump();
    expect(find.text('Thông báo riêng'), findsNothing);
  });

  testWidgets('failure stays distinct from empty state and refresh recovers', (
    tester,
  ) async {
    final state = NotificationState()..unlocked = true;
    final repository = TestNotifications()..fail = true;
    await mount(tester, state, repository);
    await tester.pumpAndSettle();
    expect(find.textContaining('Không tải được thông báo'), findsOneWidget);
    expect(find.text('Chưa có thông báo.'), findsNothing);
    repository.fail = false;
    await tester.tap(find.byTooltip('Tải lại thông báo'));
    await tester.pumpAndSettle();
    expect(find.text('Thông báo riêng'), findsOneWidget);
    repository.fail = true;
    await tester.tap(find.text('Thông báo riêng'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa đánh dấu đã đọc'), findsOneWidget);
    expect(find.byIcon(Icons.mark_email_unread), findsOneWidget);
  });

  testWidgets('late response is discarded after gate locks', (tester) async {
    final state = NotificationState()..unlocked = true;
    final repository = TestNotifications()
      ..pending = Completer<List<FamilyNotification>>();
    await mount(tester, state, repository);
    state.change(open: false);
    await tester.pump();
    repository.pending!.complete([
      FamilyNotification(
        id: 'late',
        title: 'Dữ liệu cũ',
        body: 'private',
        createdAt: DateTime.now(),
      ),
    ]);
    await tester.pump();
    expect(find.text('Dữ liệu cũ'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
