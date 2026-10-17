import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/features/parent_portal/screens/parent_dashboard_view.dart';
import 'package:mathlingo/features/parent_portal/parent_area.dart';

void main() {
  Widget dashboard({
    Map<String, dynamic> report = const {},
    VoidCallback? onLimit,
  }) => MaterialApp(
    home: ParentDashboardView(
      report: report,
      limits: const {'a': 45},
      plus: false,
      maxKids: 1,
      loading: false,
      error: null,
      email: 'parent@example.test',
      sound: true,
      dark: false,
      onRefresh: () async {},
      onNotifications: () {},
      onExit: () {},
      onAdd: () {},
      onEdit: (_) {},
      onRestore: (_) {},
      onChoose: (_) {},
      onLimit: (_) => onLimit?.call(),
      onPlans: () {},
      onAccount: () {},
      onPin: () {},
      onSupport: () {},
      onSound: () {},
      onTheme: () {},
    ),
  );
  final report = {
    'entitlements': {'active_kid_id': 'a'},
    'kids': [
      {
        'id': 'a',
        'nickname': 'An',
        'grade': 2,
        'completed': 7,
        'today_seconds': 1080,
        'archived': false,
        'days': <dynamic>[],
        'skills': <dynamic>[],
      },
      {
        'id': 'b',
        'nickname': 'Linh',
        'grade': 1,
        'completed': 2,
        'today_seconds': 300,
        'archived': true,
        'days': <dynamic>[],
        'skills': <dynamic>[],
      },
    ],
  };

  testWidgets(
    'parent dashboard shows backend data and connects the limit action',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        dashboard(report: report, onLimit: () => calls++),
      );
      expect(find.text('7'), findsOneWidget);
      expect(find.text('18 / 45 phút'), findsOneWidget);
      expect(
        find.text('Chưa có thời lượng học trong 7 ngày qua.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Thời gian học'));
      await tester.tap(find.text('Thời gian học'));
      expect(calls, 1);
      await tester.tap(find.text('Các bé'));
      await tester.pump();
      expect(find.text('Khôi phục'), findsOneWidget);
      expect(find.text('Đang học với Basic'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('empty parent dashboard never invents progress', (tester) async {
    await tester.pumpWidget(dashboard());
    expect(find.text('Chưa có hồ sơ bé'), findsOneWidget);
    expect(find.text('Phút học hôm nay'), findsNothing);
    expect(find.text('Bài đã hoàn thành'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dashboard and PIN gate support small screens with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: dashboard(report: report),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const ParentAreaLocked(),
      ),
    );
    expect(find.text('Nhập PIN để tiếp tục'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
