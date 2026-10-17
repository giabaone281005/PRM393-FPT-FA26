import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/features/subscriptions/learning_packages_screen.dart';
import 'package:mathlingo/features/admin/admin_commerce_screen.dart';

void main() {
  testWidgets(
    'packages fail visibly without a session and never activate a fake trial',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(),
          child: const MaterialApp(home: LearningPackagesScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Gia đình đang dùng Basic'), findsOneWidget);
      expect(
        find.text(
          'Chưa tải được gói hoặc lịch sử. Kiểm tra kết nối và thử lại.',
        ),
        findsOneWidget,
      );
      expect(find.text('Kích Hoạt Dùng Thử 30 Ngày'), findsNothing);
      expect(find.text('Chọn gói'), findsNothing);
    },
  );
  testWidgets(
    'admin commerce shows failure instead of mock accounts or sales',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AdminCommerceScreen()));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Không tải được dữ liệu. Kiểm tra quyền admin, migration và kết nối.',
        ),
        findsOneWidget,
      );
      expect(find.text('phuhuynh@mathlingo.vn'), findsNothing);
    },
  );
}
