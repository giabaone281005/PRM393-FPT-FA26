import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/repositories/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late SupabaseClient client;
  late NotificationRepository repository;
  HttpOverrides? overrides;
  late Future<void> Function(HttpRequest) respond;
  const uid = '11111111-1111-4111-8111-111111111111';

  setUp(() async {
    overrides = HttpOverrides.current;
    HttpOverrides.global = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/auth/v1/token') {
        String part(Object data) =>
            base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
        final token =
            '${part({'alg': 'HS256', 'typ': 'JWT'})}.${part({'sub': uid, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test';
        request.response.write(
          jsonEncode({
            'access_token': token,
            'refresh_token': 'test-only',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': uid,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'parent@example.test',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-10-20T00:00:00Z',
            },
          }),
        );
        await request.response.close();
      } else {
        await respond(request);
      }
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
    repository = NotificationRepository(client: client);
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
    HttpOverrides.global = overrides;
  });

  Future<void> signIn() => client.auth.signInWithPassword(
    email: 'parent@example.test',
    password: 'test-only',
  );

  test('signed-out access fails before any notification request', () async {
    respond = (_) async => fail('must not access the API');
    await expectLater(repository.fetch(), throwsStateError);
    await expectLater(repository.markRead('foreign'), throwsStateError);
  });

  test(
    'fetch scopes pagination to the signed-in family and maps read state',
    () async {
      await signIn();
      respond = (request) async {
        expect(request.uri.path, '/rest/v1/notifications');
        expect(request.uri.queryParameters['parent_id'], 'eq.$uid');
        expect(request.uri.queryParameters['offset'], '20');
        expect(request.uri.queryParameters['limit'], '20');
        request.response.write(
          jsonEncode([
            {
              'id': 'n-a',
              'title': 'Đã xác nhận',
              'body': 'Nội dung',
              'created_at': '2026-10-20T01:00:00Z',
              'read_at': '2026-10-20T02:00:00Z',
            },
          ]),
        );
        await request.response.close();
      };
      final rows = await repository.fetch(page: 1);
      expect(rows.single.title, 'Đã xác nhận');
      expect(rows.single.readAt, DateTime.utc(2026, 10, 20, 2));
    },
  );

  test(
    'read acknowledgement updates only read_at and rejects zero-row result',
    () async {
      await signIn();
      respond = (request) async {
        expect(request.method, 'PATCH');
        expect(request.uri.queryParameters['parent_id'], 'eq.$uid');
        expect(request.uri.queryParameters['id'], 'eq.foreign');
        final data = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
        expect(data.keys, ['read_at']);
        request.response.statusCode = 406;
        request.response.write(
          jsonEncode({'code': 'PGRST116', 'message': '0 rows'}),
        );
        await request.response.close();
      };
      await expectLater(
        repository.markRead('foreign'),
        throwsA(isA<PostgrestException>()),
      );
    },
  );
}
