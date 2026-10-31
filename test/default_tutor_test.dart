import 'dart:async';
import 'dart:convert';

import 'package:brilliant_mobile/data/engines/engine_contracts.dart';
import 'package:brilliant_mobile/data/models/engine_config.dart';
import 'package:brilliant_mobile/data/models/learning_modules.dart';
import 'package:brilliant_mobile/data/repositories/engine_registry.dart';
import 'package:brilliant_mobile/data/repositories/engine_runtime.dart';
import 'package:brilliant_mobile/data/repositories/supabase_tutor_repository.dart';
import 'package:brilliant_mobile/features/engines/engine_scope.dart';
import 'package:brilliant_mobile/home_chat_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'engine_registry_test.dart' show MemoryEngineStorage, config;

class _Tutor implements AiEngine {
  _Tutor(this.reply);
  final Future<TutorReply> reply;
  bool closed = false;
  @override
  Future<TutorReply> respond(TutorRequest request) => reply;
  @override
  void dispose() => closed = true;
}

const owner = '11111111-1111-4111-8111-111111111111';
final question = TutorRequest(
  messages: const [TutorMessage(TutorRole.user, '2 + 2?')],
);

Future<SupabaseClient> signedInClient() async {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final token =
      '${encode({'alg': 'HS256'})}.${encode({'sub': owner, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.fixture';
  final client = SupabaseClient(
    'https://cloud.example',
    'publishable-test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': token,
      'refresh_token': 'fixture-refresh',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': owner,
        'aud': 'authenticated',
        'created_at': '2026-10-31T00:00:00Z',
        'app_metadata': {},
        'user_metadata': {},
      },
    }),
  );
  return client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'chat sends through the default tutor without registering an engine',
    (tester) async {
      final registry = EngineRegistry(MemoryEngineStorage());
      await registry.initialize();
      final tutor = _Tutor(
        Future.value(const TutorReply('Try counting two pairs.')),
      );
      final runtime = EngineRuntime(registry, createDefaultTutor: () => tutor);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EngineScope(
              runtime: runtime,
              child: Builder(
                builder: (context) => HomeChatBox(
                  onSend: EngineScope.maybeOf(context)!.chatResponder,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Trợ lý chưa được kết nối.'), findsNothing);
      await tester.enterText(find.byType(TextField), '2 + 2?');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(find.text('Try counting two pairs.'), findsOneWidget);
      expect(tutor.closed, isTrue);
      runtime.dispose();
      registry.dispose();
    },
  );

  test(
    'custom active tutor overrides default; removing it restores default',
    () async {
      final registry = EngineRegistry(MemoryEngineStorage());
      await registry.initialize();
      final runtime = EngineRuntime(
        registry,
        createDefaultTutor: () =>
            _Tutor(Future.value(const TutorReply('default'))),
      );
      await registry.register(config('custom'));
      await registry.activate(EngineKind.tutor, 'custom');
      runtime.registerAiAdapter(
        EngineProvider.koji,
        (_) => _Tutor(Future.value(const TutorReply('custom'))),
      );
      expect((await runtime.respond(question)).text, 'custom');
      await registry.remove('custom');
      expect((await runtime.respond(question)).text, 'default');
      runtime.dispose();
      registry.dispose();
    },
  );

  test(
    'disposing runtime rejects late default replies after account change',
    () async {
      final registry = EngineRegistry(MemoryEngineStorage());
      await registry.initialize();
      final pending = Completer<TutorReply>();
      final tutor = _Tutor(pending.future);
      final runtime = EngineRuntime(registry, createDefaultTutor: () => tutor);
      final result = runtime.respond(question);
      final assertion = expectLater(result, throwsA(isA<EngineFailure>()));
      runtime.dispose();
      pending.complete(const TutorReply('old account reply'));
      await assertion;
      expect(tutor.closed, isTrue);
      registry.dispose();
    },
  );

  test('cloud tutor sends user JWT and canvas to backend without provider credentials', () async {
    final client = await signedInClient();
    final repository = SupabaseTutorRepository(
      client: client,
      url: 'https://cloud.example',
      publishableKey: 'publishable-test',
      owner: owner,
      transport: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://cloud.example/functions/v1/tutor-chat',
        );
        expect(request.headers['Authorization'], startsWith('Bearer '));
        expect(request.headers['apikey'], 'publishable-test');
        expect(request.headers.containsKey('x-goog-api-key'), false);
        expect((jsonDecode(request.body) as Map).containsKey('canvas'), true);
        return http.Response('{"text":"A hint"}', 200);
      }),
    );
    expect(
      (await repository.respond(
        TutorRequest(
          messages: question.messages,
          canvas: SharedCanvasDocument(),
        ),
      )).text,
      'A hint',
    );
    repository.dispose();
    await client.dispose();
  });

  test(
    'cloud tutor blocks mismatched account and hides raw upstream failures',
    () async {
      final client = await signedInClient();
      var calls = 0;
      final transport = MockClient((_) async {
        calls++;
        return http.Response('sensitive upstream text', 429);
      });
      final wrong = SupabaseTutorRepository(
        client: client,
        url: 'https://cloud.example',
        publishableKey: 'test',
        owner: 'another-account',
        transport: transport,
      );
      await expectLater(wrong.respond(question), throwsA(isA<EngineFailure>()));
      expect(calls, 0);
      final correct = SupabaseTutorRepository(
        client: client,
        url: 'https://cloud.example',
        publishableKey: 'test',
        owner: owner,
        transport: transport,
      );
      await expectLater(
        correct.respond(question),
        throwsA(
          isA<EngineFailure>().having(
            (e) => e.message,
            'message',
            isNot(contains('sensitive')),
          ),
        ),
      );
      correct.dispose();
      await client.dispose();
    },
  );
}
