import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_failure.dart';

abstract interface class PasswordRecoveryRepository {
  Future<void> requestCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> updatePassword(String password);
  Future<void> dispose();
}

/// Owns an ephemeral Auth client. Recovery must never switch the learning
/// account, persist a recovery session, or trigger learning uploads.
class SupabasePasswordRecoveryRepository implements PasswordRecoveryRepository {
  SupabasePasswordRecoveryRepository(
    String url,
    String publishableKey, {
    http.Client? httpClient,
  }) {
    _transport = _RecoveryTransport(httpClient ?? http.Client());
    _client = SupabaseClient(
      url,
      publishableKey,
      httpClient: _transport,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        autoRefreshToken: false,
      ),
    );
  }

  late final SupabaseClient _client;
  late final _RecoveryTransport _transport;
  bool _verified = false;

  @override
  Future<void> requestCode(String email) async {
    _verified = false;
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (error) {
      // Do not reveal whether this address has an account.
      if (error.code != 'user_not_found') rethrow;
    }
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    _verified = false;
    final response = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.recovery,
    );
    if (response.session == null) {
      throw const AppFailure('Chưa xác nhận được mã. Hãy thử lại.');
    }
    _verified = true;
  }

  @override
  Future<void> updatePassword(String password) async {
    if (!_verified) {
      throw const AppFailure(
        'Hãy xác nhận mã khôi phục trước khi đổi mật khẩu.',
      );
    }
    await _client.auth.updateUser(UserAttributes(password: password));
    _verified = false;
  }

  @override
  Future<void> dispose() async {
    try {
      if (_client.auth.currentSession != null) {
        await _client.auth
            .signOut(scope: SignOutScope.local)
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Cleanup cannot change the reported result of an already saved password.
    } finally {
      _transport.close();
      await _client.dispose();
    }
  }
}

/// Timeout before Auth consumes a response, so a late response cannot replace
/// the ephemeral session after the UI has already allowed a retry.
class _RecoveryTransport extends http.BaseClient {
  _RecoveryTransport(this.inner);
  final http.Client inner;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await inner
        .send(request)
        .timeout(const Duration(seconds: 30));
    return http.StreamedResponse(
      response.stream.timeout(
        const Duration(seconds: 30),
        onTimeout: (sink) {
          sink.addError(TimeoutException('Recovery response timed out'));
          sink.close();
        },
      ),
      response.statusCode,
      headers: response.headers,
      request: request,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => inner.close();
}
