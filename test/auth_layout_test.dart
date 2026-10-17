import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/features/auth/auth_screen.dart';
import 'package:mathlingo/features/auth/widgets/mascot_owl_3d.dart';

void main() {
  testWidgets(
    'owl responds to fields and password visibility preserves input',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
      final email = find.byType(TextField).first;
      final password = find.byType(TextField).last;
      await tester.ensureVisible(email);
      await tester.tap(email);
      await tester.pump();
      expect(
        tester.widget<MascotOwl3D>(find.byType(MascotOwl3D)).state,
        MascotState.typingEmail,
      );
      await tester.enterText(email, 'parent@example.test');
      await tester.ensureVisible(password);
      await tester.tap(password);
      await tester.enterText(password, 'Test-password-123');
      await tester.pump();
      expect(
        tester.widget<MascotOwl3D>(find.byType(MascotOwl3D)).state,
        MascotState.typingPassword,
      );
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      await tester.tap(find.byTooltip('Hiện mật khẩu'));
      await tester.pump();
      expect(tester.widget<TextField>(password).obscureText, isFalse);
      expect(
        tester.widget<TextField>(password).controller!.text,
        'Test-password-123',
      );
      expect(
        tester.widget<TextField>(email).controller!.text,
        'parent@example.test',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('owl announces validation without sending an invalid login', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    await tester.ensureVisible(find.byType(FilledButton));
    await tester.tap(find.byType(FilledButton));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Nhập email và mật khẩu ít nhất 8 ký tự.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
