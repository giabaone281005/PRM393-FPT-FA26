import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brilliant_mobile/data/models/app_failure.dart';

void main() {
  const fallback = 'Chưa hoàn tất thao tác. Bạn có thể thử lại.';
  test('unknown errors use neutral guidance and never invent a network or password cause', () {
    for (final error in [
      StateError('secret-token'),
      const FormatException('raw SQL'),
      const AuthException(
        'private SMTP diagnostic',
        code: 'unexpected_failure',
      ),
      const PostgrestException(message: 'raw SQL with secret', code: 'XX000'),
    ]) {
      expect(friendlyError(error, fallback: fallback), fallback);
    }
  });
  test('network, timeout, credentials, OTP and email limits remain distinguishable', () {
    expect(
      friendlyError(http.ClientException('sensitive host'), fallback: fallback),
      contains('kiểm tra mạng'),
    );
    expect(
      friendlyError(TimeoutException('private timeout'), fallback: fallback),
      contains('thời gian chờ'),
    );
    expect(
      friendlyError(
        const AuthException('private', code: 'invalid_credentials'),
        fallback: fallback,
      ),
      contains('Email hoặc mật khẩu'),
    );
    expect(
      friendlyError(
        const AuthException('private', code: 'otp_expired'),
        fallback: fallback,
      ),
      contains('hết hạn'),
    );
    expect(
      friendlyError(
        const AuthException('private', code: 'request_timeout'),
        fallback: fallback,
      ),
      contains('thời gian chờ'),
    );
    expect(
      friendlyError(
        const AuthException('private', code: 'otp_disabled'),
        fallback: fallback,
      ),
      isNot(contains('hết hạn')),
    );
    expect(
      friendlyError(
        const AuthException('private', code: 'over_email_send_rate_limit'),
        fallback: fallback,
      ),
      contains('giới hạn gửi email'),
    );
    expect(
      friendlyError(
        const AuthException('private', code: 'email_address_not_authorized'),
        fallback: fallback,
      ),
      contains('chưa được cấu hình'),
    );
  });
  test('permission denied does not claim suspension and service outage does not blame credentials', () {
    final permission = friendlyError(
      const PostgrestException(message: 'private', code: '42501'),
      fallback: fallback,
    );
    expect(permission, contains('chưa được phép'));
    expect(permission, isNot(contains('bị khóa')));
    final outage = friendlyError(
      AuthRetryableFetchException(statusCode: '503'),
      fallback: fallback,
    );
    expect(outage, contains('Dịch vụ tài khoản'));
    expect(outage, isNot(contains('mật khẩu')));
  });
  test('engine HTTP statuses have actionable, distinct messages without raw diagnostics', () {
    expect(engineHttpMessage(401), contains('Khóa hoặc token'));
    expect(engineHttpMessage(403), contains('chưa có quyền'));
    expect(engineHttpMessage(404), contains('endpoint'));
    expect(engineHttpMessage(429), contains('hạn mức'));
    expect(engineHttpMessage(503), contains('Dịch vụ đang gặp sự cố'));
    expect(engineHttpMessage(307), contains('chuyển hướng'));
    expect(engineHttpMessage(413), contains('quá lớn'));
  });
  test('authored local learning failures keep StateError compatibility and safe guidance', () {
    final error = LocalLearningFailure('Kết quả chưa lưu được. Hãy thử lại.');
    expect(error, isA<StateError>());
    expect(
      friendlyError(error, fallback: fallback),
      'Kết quả chưa lưu được. Hãy thử lại.',
    );
  });
}
