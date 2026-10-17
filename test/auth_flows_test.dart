import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/features/auth/account_screen.dart';
import 'package:mathlingo/features/auth/auth_screen.dart';
import 'package:mathlingo/features/auth/email_verification_screen.dart';
import 'package:mathlingo/data/repositories/auth_repository.dart';

void main() {
  testWidgets(
    'registration validates input and preserves fields when switching back to login',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.enterText(
        find.byType(TextField).first,
        'parent@example.test',
      );
      await tester.enterText(find.byType(TextField).last, 'short');
      await tester.ensureVisible(find.text('Đăng ký ngay'));
      await tester.tap(find.text('Đăng ký ngay'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Quên mật khẩu?'), findsNothing);
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Nhập email và mật khẩu ít nhất 8 ký tự.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Đăng nhập'));
      await tester.tap(find.text('Đăng nhập'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'parent@example.test',
      );
      expect(find.text('Quên mật khẩu?'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'forgot password validates email, opens recovery, and explains missing configuration',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      await tester.ensureVisible(find.text('Quên mật khẩu?'));
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Nhập email để nhận mã đặt lại mật khẩu.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextField).first,
        'parent@example.test',
      );
      await tester.ensureVisible(find.text('Quên mật khẩu?'));
      await tester.tap(find.text('Quên mật khẩu?'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(EmailVerificationScreen), findsOneWidget);
      expect(find.text('Lấy lại mật khẩu'), findsOneWidget);
      expect(find.textContaining('chưa có cấu hình kết nối'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Có thể gửi lại sau 60s'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField).last, 'bad-input');
      await tester.ensureVisible(find.text('Xác minh & tiếp tục'));
      await tester.tap(find.text('Xác minh & tiếp tục'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Dán liên kết gốc từ email MathLingo hoặc nhập mã xác minh.'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Quay lại đăng nhập'));
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Quay lại đăng nhập'),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.text('Quay lại đăng nhập'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(EmailVerificationScreen), findsNothing);
      expect(AuthRepository.verificationScreenOpen, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'new password rejects short or mismatched confirmation before contacting server',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AccountScreen(recovery: true)),
      );
      expect(find.text('Mật khẩu hiện tại'), findsNothing);
      for (final passwords in [
        ('short', 'short'),
        ('new-password-123', 'different-password'),
      ]) {
        await tester.enterText(find.byType(TextField).first, passwords.$1);
        await tester.enterText(find.byType(TextField).last, passwords.$2);
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.tap(find.byType(FilledButton));
        await tester.pump();
        expect(
          find.text('Mật khẩu mới cần ít nhất 8 ký tự và trùng phần xác nhận.'),
          findsOneWidget,
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
