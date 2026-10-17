import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathlingo/data/models/email_verification_input.dart';
import 'package:mathlingo/data/repositories/auth_repository.dart';
import 'package:mathlingo/features/auth/email_verification_screen.dart';

void main() {
  const project = 'https://project.supabase.co';
  final hash = List.filled(64, 'a').join();
  EmailVerificationInput parse(String value, {bool recovery = false}) =>
      EmailVerificationInput.parse(
        value,
        projectUrl: project,
        recovery: recovery,
      );

  test(
    'accepts codes and original project email links without opening URLs',
    () {
      expect(parse(' 123456 ').code, '123456');
      expect(parse('12345678', recovery: true).code, '12345678');
      expect(
        parse('$project/auth/v1/verify?token=$hash&type=signup').tokenHash,
        hash,
      );
      expect(
        parse(
          '$project/auth/v1/verify?token_hash=$hash&type=recovery',
          recovery: true,
        ).tokenHash,
        hash,
      );
      final wrapped = Uri.https('www.google.com', '/url', {
        'q': '$project/auth/v1/verify?token=$hash&type=signup',
      });
      expect(parse(wrapped.toString()).tokenHash, hash);
    },
  );

  test('rejects other servers, flow confusion, duplicate tokens and session fragments', () {
    for (final invalid in [
      'https://attacker.test/auth/v1/verify?token=$hash&type=signup',
      'http://project.supabase.co/auth/v1/verify?token=$hash&type=signup',
      '$project/auth/v1/verify?token=$hash&type=recovery',
      '$project/auth/v1/verify?token=$hash&token=$hash&type=signup',
      '$project/auth/v1/verify?token=$hash&token_hash=$hash&type=signup',
      '$project/auth/v1/verify?token=$hash&type=signup&type=email',
      '$project/auth/v1/verify?token=$hash&type=signup#access_token=secret',
      'mathlingo://auth-callback#access_token=secret',
    ]) {
      expect(() => parse(invalid), throwsFormatException);
    }
    expect(
      () => parse(
        '$project/auth/v1/verify?token=$hash&type=signup',
        recovery: true,
      ),
      throwsFormatException,
    );
  });

  test('email quota and expired tokens show actionable errors', () {
    expect(
      AuthRepository.emailError(
        const AuthException('rate limit', code: 'over_email_send_rate_limit'),
      ),
      contains('giới hạn gửi email'),
    );
    expect(
      AuthRepository.emailError(
        const AuthException('expired', code: 'otp_expired'),
      ),
      contains('hết hạn'),
    );
  });

  testWidgets('verification remains usable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const EmailVerificationScreen(
          email: 'parent@example.test',
          recovery: false,
          initiallySent: true,
        ),
      ),
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Xác minh & tiếp tục'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(AuthRepository.verificationScreenOpen, isFalse);
  });
}
