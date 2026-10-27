import 'dart:convert';

import 'package:brilliant_mobile/data/engines/http_ai_engine.dart';
import 'package:brilliant_mobile/data/models/engine_config.dart';
import 'package:brilliant_mobile/data/models/learning_modules.dart';
import 'package:brilliant_mobile/data/repositories/engine_registry.dart';
import 'package:brilliant_mobile/data/repositories/engine_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Storage implements EngineStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String snapshot) async => value = snapshot;
}

EngineConfig config({
  String host = 'generativelanguage.googleapis.com',
  String model = 'gemini-3.5-flash-lite',
}) => EngineConfig(
  id: 'gemini-chat',
  name: 'Gemini',
  provider: EngineProvider.gemini,
  endpoint: Uri.parse('https://$host/v1beta'),
  model: model,
);

void main() {
  test('Gemini protocol uses header auth, native roles, system/canvas and visible text only', () async {
    final engine = HttpAiEngine(
      EngineSelection(config(), 'test-only-credential'),
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent',
        );
        expect(request.url.hasQuery, false);
        expect(request.headers['x-goog-api-key'], 'test-only-credential');
        expect(request.headers.containsKey('Authorization'), false);
        final body = jsonDecode(request.body) as Map;
        expect((body['contents'] as List).map((m) => m['role']), [
          'user',
          'model',
          'user',
        ]);
        expect(
          body['systemInstruction']['parts'][0]['text'],
          contains('Canvas'),
        );
        expect(body['generationConfig']['maxOutputTokens'], 2048);
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'internal', 'thought': true},
                    {'text': 'Visible answer'},
                    {'text': 'Second part'},
                  ],
                },
              },
            ],
          }),
          200,
        );
      }),
    );
    final result = await engine.respond(
      TutorRequest(
        messages: const [
          TutorMessage(TutorRole.user, 'Question'),
          TutorMessage(TutorRole.assistant, 'Hint'),
          TutorMessage(TutorRole.user, 'Explain'),
        ],
        canvas: SharedCanvasDocument(),
      ),
    );
    expect(result.text, 'Visible answer\nSecond part');
    engine.dispose();
  });

  test('missing Gemini credential fails before sending a request', () async {
    var sent = false;
    final engine = HttpAiEngine(
      EngineSelection(config(), null),
      client: MockClient((_) async {
        sent = true;
        return http.Response('{}', 200);
      }),
    );
    await expectLater(
      engine.respond(
        TutorRequest(messages: const [TutorMessage(TutorRole.user, 'Hi')]),
      ),
      throwsA(isA<EngineFailure>()),
    );
    expect(sent, false);
    engine.dispose();
  });

  test('blocked or malformed Gemini responses are safe and never expose provider body', () async {
    for (final response in [
      http.Response('{"error":"sensitive-provider-details"}', 403),
      http.Response('{"promptFeedback":{"blockReason":"SAFETY"}}', 200),
      http.Response(
        '{"candidates":[{"content":{"parts":[{"thought":true,"text":"private"}]}}]}',
        200,
      ),
    ]) {
      final engine = HttpAiEngine(
        EngineSelection(config(), 'test-key'),
        client: MockClient((_) async => response),
      );
      await expectLater(
        engine.respond(
          TutorRequest(messages: const [TutorMessage(TutorRole.user, 'Hi')]),
        ),
        throwsA(
          isA<EngineFailure>().having(
            (e) =>
                e.message.contains('sensitive-provider-details') ||
                e.message.contains('test-key') ||
                e.message.contains('private'),
            'no sensitive details',
            false,
          ),
        ),
      );
      engine.dispose();
    }
  });

  test('Gemini config only accepts the official host and a safe model ID', () {
    expect(
      () => config(host: 'other.example'),
      throwsA(isA<EngineConfigException>()),
    );
    expect(
      () => config(model: 'gemini-3.5-flash-lite/../../other'),
      throwsA(isA<EngineConfigException>()),
    );
    expect(config().kind, EngineKind.tutor);
    expect(
      EngineConfig.fromJson(config().toJson()).provider,
      EngineProvider.gemini,
    );
  });

  test(
    'saved Gemini selection and credential survive registry reopen',
    () async {
      final storage = _Storage();
      final registry = EngineRegistry(storage);
      await registry.initialize();
      await registry.register(config(), credential: 'test-key');
      await registry.activate(EngineKind.tutor, 'gemini-chat');
      final reopened = EngineRegistry(storage);
      await reopened.initialize();
      expect(reopened.active(EngineKind.tutor)?.model, 'gemini-3.5-flash-lite');
      expect(reopened.hasCredential('gemini-chat'), true);
      expect(config().toJson().values, isNot(contains('test-key')));
      registry.dispose();
      reopened.dispose();
    },
  );
}
