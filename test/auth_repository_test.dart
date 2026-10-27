import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brilliant_mobile/data/repositories/auth_repository.dart';

void main() {
  test('email OTP uses email verification type and requires a real session response', () async {
    final transport = MockClient((request) async {
      expect(request.url.path, '/auth/v1/verify');
      final body = jsonDecode(request.body) as Map;
      expect(body['email'], 'learner@example.test');
      expect(body['token'], '00123456');
      expect(body['type'], 'email');
      // A protocol fixture only; never a real provider credential or live call.
      String encode(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      final expiry =
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000;
      final jwt =
          '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({'exp': expiry, 'sub': '00000000-0000-0000-0000-000000000001'})}.test';
      return http.Response(
        jsonEncode({
          'access_token': jwt,
          'refresh_token': 'test-refresh-token',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': '00000000-0000-0000-0000-000000000001',
            'aud': 'authenticated',
            'email': 'learner@example.test',
            'created_at': '2026-10-26T00:00:00Z',
            'app_metadata': {},
            'user_metadata': {},
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client = SupabaseClient(
      'https://auth.example',
      'test-publishable-key',
      httpClient: transport,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final repository = SupabaseAuthRepository(client);
    await repository.verifyEmailCode('learner@example.test', '00123456');
    expect(repository.userId, '00000000-0000-0000-0000-000000000001');
    await client.dispose();
  });

  test(
    'resend uses signup type without creating or signing in another account',
    () async {
      final transport = MockClient((request) async {
        expect(request.url.path, '/auth/v1/resend');
        final body = jsonDecode(request.body) as Map;
        expect(body['type'], 'signup');
        expect(body['email'], 'learner@example.test');
        expect(body.containsKey('password'), isFalse);
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = SupabaseClient(
        'https://auth.example',
        'test-publishable-key',
        httpClient: transport,
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final repository = SupabaseAuthRepository(client);
      await repository.resendConfirmation('learner@example.test');
      expect(repository.userId, isNull);
      await client.dispose();
    },
  );
}
