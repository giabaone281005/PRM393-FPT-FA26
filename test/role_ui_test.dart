import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/theme/app_theme.dart';
import 'package:mathlingo/features/admin/admin_dashboard_view.dart';
import 'package:mathlingo/features/shared/widgets/role_ui.dart';

Widget adminDashboard({VoidCallback? onCommerce}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: AdminDashboardView(
    parents: const {},
    stats: const {},
    busy: false,
    error: null,
    page: 0,
    tier: '',
    email: 'admin@example.test',
    onRefresh: () async {},
    onSearch: (_) {},
    onTier: (_) {},
    onPage: (_) {},
    onFamily: (_) {},
    onSupportFamily: (_) {},
    onCommerce: onCommerce ?? () {},
    onContent: () {},
    onRoles: () {},
    onSupport: () {},
    onAi: () {},
    onLogout: () {},
  ),
);

void main() {
  testWidgets(
    'capsule navigation works at 320px with large text in both themes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        var selected = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              bottomNavigationBar: RoleNavigationBar(
                selectedIndex: 0,
                onSelected: (index) => selected = index,
                labels: const ['Tổng quan', 'Các bé', 'Gói học', 'Tài khoản'],
                icons: const [
                  Icons.home_rounded,
                  Icons.people_rounded,
                  Icons.star_rounded,
                  Icons.person_rounded,
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.text('Tài khoản'));
        expect(selected, 3);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('admin navigation switches sections on mobile and desktop', (
    tester,
  ) async {
    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(adminDashboard());
      await tester.tap(find.text('Gia đình').last);
      await tester.pumpAndSettle();
      expect(find.text('Gia đình & học viên'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
