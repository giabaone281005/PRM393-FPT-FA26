import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:brilliant_mobile/data/engines/engine_contracts.dart';
import 'package:brilliant_mobile/data/engines/http_ai_engine.dart';
import 'package:brilliant_mobile/data/engines/http_code_engine.dart';
import 'package:brilliant_mobile/data/models/engine_config.dart';
import 'package:brilliant_mobile/data/models/learning_modules.dart';
import 'package:brilliant_mobile/data/repositories/catalog_roadmaps.dart';
import 'package:brilliant_mobile/data/repositories/engine_registry.dart';
import 'package:brilliant_mobile/data/repositories/engine_runtime.dart';
import 'package:brilliant_mobile/data/repositories/engine_storage.dart';
import 'package:brilliant_mobile/learning_catalog.dart';

class MemoryEngineStorage implements EngineStorage {
  String? value;
  bool fail = false;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String snapshot) async {
    if (fail) throw StateError('private storage failure');
    value = snapshot;
  }
}

EngineConfig config(
  String id, {
  EngineProvider provider = EngineProvider.koji,
  String? endpoint,
}) => EngineConfig(
  id: id,
  name: id,
  provider: provider,
  model: provider.kind == EngineKind.tutor ? 'configured-model' : '',
  endpoint: Uri.parse(
    endpoint ??
        (provider == EngineProvider.pyodide
            ? 'embedded:pyodide'
            : 'https://engine.example/$id'),
  ),
);

class _Ai implements AiEngine {
  _Ai(this.reply);
  final Future<TutorReply> reply;
  int closes = 0;
  @override
  Future<TutorReply> respond(TutorRequest request) => reply;
  @override
  void dispose() {
    closes++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryEngineStorage storage;
  late EngineRegistry registry;
  setUp(() async {
    storage = MemoryEngineStorage();
    registry = EngineRegistry(storage);
    await registry.initialize();
  });
  tearDown(() => registry.dispose());

  test(
    'registry persists configs, credentials and independent active selections',
    () async {
      await registry.register(config('ai'), credential: 'private-key');
      await registry.register(config('code', provider: EngineProvider.docker));
      await registry.activate(EngineKind.tutor, 'ai');
      await registry.activate(EngineKind.code, 'code');
      final reopened = EngineRegistry(storage);
      await reopened.initialize();
      expect(reopened.active(EngineKind.tutor)!.id, 'ai');
      expect(reopened.active(EngineKind.code)!.id, 'code');
      expect(reopened.resolve(EngineKind.tutor).credential, 'private-key');
      expect(
        jsonEncode(reopened.engines.map((engine) => engine.toJson()).toList()),
        isNot(contains('private-key')),
      );
      expect(
        reopened.resolve(EngineKind.tutor).toString(),
        isNot(contains('private-key')),
      );
      reopened.dispose();
    },
  );

  test(
    'secure storage is isolated by account and does not use SharedPreferences',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      final a = SecureEngineStorage('account-a'),
          b = SecureEngineStorage('account-b');
      await a.write('encrypted-by-platform-in-production');
      expect(await a.read(), 'encrypted-by-platform-in-production');
      expect(await b.read(), isNull);
    },
  );

  test('concurrent registrations serialize and duplicate IDs cannot replace secrets', () async {
    await Future.wait([
      registry.register(config('a'), credential: 'a-key'),
      registry.register(config('b')),
    ]);
    await expectLater(
      registry.register(config('a'), credential: 'other-key'),
      throwsA(isA<EngineFailure>()),
    );
    await registry.activate(EngineKind.tutor, 'a');
    expect(registry.engines.length, 2);
    expect(registry.resolve(EngineKind.tutor).credential, 'a-key');
  });

  test(
    'failed persistence leaves selection unchanged and queue can retry',
    () async {
      await registry.register(config('a'));
      await registry.register(config('b'));
      await registry.activate(EngineKind.tutor, 'a');
      storage.fail = true;
      await expectLater(
        registry.activate(EngineKind.tutor, 'b'),
        throwsA(isA<EngineFailure>()),
      );
      expect(registry.active(EngineKind.tutor)!.id, 'a');
      storage.fail = false;
      await registry.activate(EngineKind.tutor, 'b');
      expect(registry.active(EngineKind.tutor)!.id, 'b');
    },
  );

  test(
    'credential rotation, deletion and endpoint change require explicit intent',
    () async {
      await registry.register(config('a'), credential: 'original-key');
      await registry.activate(EngineKind.tutor, 'a');
      final different = config('a', endpoint: 'https://other.example/chat');
      await expectLater(
        registry.update(different),
        throwsA(isA<EngineFailure>()),
      );
      expect(registry.resolve(EngineKind.tutor).credential, 'original-key');
      await registry.update(different, credential: 'new-key');
      expect(registry.resolve(EngineKind.tutor).credential, 'new-key');
      await registry.update(different, clearCredential: true);
      expect(registry.resolve(EngineKind.tutor).credential, isNull);
      await registry.remove('a');
      expect(registry.active(EngineKind.tutor), isNull);
      expect(storage.value, isNot(contains('new-key')));
    },
  );

  test(
    'corrupt/unknown snapshots fail closed without overwriting stored bytes',
    () async {
      for (final raw in [
        'not json',
        '{"version":999}',
        '{"version":1,"engines":[],"active":{"tutor":"missing"}}',
      ]) {
        storage.value = raw;
        await registry.initialize();
        expect(registry.loaded, isFalse);
        expect(registry.loadError, isNotNull);
        await expectLater(
          registry.register(config('a')),
          throwsA(isA<EngineFailure>()),
        );
        expect(storage.value, raw);
      }
    },
  );

  test('wrong category and unsafe endpoints are rejected', () async {
    await registry.register(config('a'));
    await expectLater(
      registry.activate(EngineKind.code, 'a'),
      throwsA(isA<EngineFailure>()),
    );
    for (final endpoint in [
      'http://remote.example/chat',
      'https://key@host.example/chat',
      'https://host.example/chat?token=secret',
      'https://host.example/chat#secret',
    ]) {
      expect(() => config('a', endpoint: endpoint), throwsFormatException);
    }
    expect(
      config(
        'local',
        provider: EngineProvider.ollama,
        endpoint: 'http://127.0.0.1:11434/api/chat',
      ).kind,
      EngineKind.tutor,
    );
  });

  test('hot swap affects new requests while in-flight request retains original selection', () async {
    await registry.register(config('a'), credential: 'a-key');
    await registry.register(config('b'), credential: 'b-key');
    await registry.activate(EngineKind.tutor, 'a');
    final runtime = EngineRuntime(registry);
    final pending = Completer<TutorReply>();
    final seen = <String?>[];
    final created = <_Ai>[];
    runtime.registerAiAdapter(EngineProvider.koji, (selection) {
      seen.add(selection.credential);
      final engine = _Ai(
        selection.config.id == 'a'
            ? pending.future
            : Future.value(const TutorReply('B')),
      );
      created.add(engine);
      return engine;
    });
    final request = TutorRequest(
      messages: [const TutorMessage(TutorRole.user, 'Help')],
    );
    final first = runtime.respond(request);
    await registry.activate(EngineKind.tutor, 'b');
    expect((await runtime.respond(request)).text, 'B');
    pending.complete(const TutorReply('A'));
    expect((await first).text, 'A');
    expect(seen, ['a-key', 'b-key']);
    expect(created.every((engine) => engine.closes == 1), isTrue);
    runtime.dispose();
  });

  test(
    'closing account runtime disposes work and rejects late results',
    () async {
      await registry.register(config('a'));
      await registry.activate(EngineKind.tutor, 'a');
      final runtime = EngineRuntime(registry),
          pending = Completer<TutorReply>();
      final engine = _Ai(pending.future);
      runtime.registerAiAdapter(EngineProvider.koji, (_) => engine);
      final result = runtime.respond(
        TutorRequest(messages: [const TutorMessage(TutorRole.user, 'Hi')]),
      );
      final check = expectLater(result, throwsA(isA<EngineFailure>()));
      runtime.dispose();
      pending.complete(const TutorReply('old account'));
      await check;
      expect(engine.closes, 1);
    },
  );

  test('Pyodide fails explicitly until a host bridge is attached', () async {
    await registry.register(config('py', provider: EngineProvider.pyodide));
    await registry.activate(EngineKind.code, 'py');
    final runtime = EngineRuntime(registry);
    final request = CodeRequest(source: 'print(1)', language: 'python');
    expect(() => runtime.execute(request), throwsA(isA<EngineFailure>()));
    runtime.attachPyodide(
      (request) async => const ExecutionResult(stdout: '1', exitCode: 0),
    );
    expect((await runtime.execute(request)).stdout, '1');
    runtime.dispose();
  });

  test('runtime timeout closes the request adapter', () async {
    await registry.register(
      EngineConfig(
        id: 'timeout',
        name: 'Timeout test',
        provider: EngineProvider.koji,
        endpoint: Uri.parse('https://engine.example/chat'),
        model: 'test',
        timeoutSeconds: 1,
      ),
    );
    await registry.activate(EngineKind.tutor, 'timeout');
    final runtime = EngineRuntime(registry);
    final engine = _Ai(Completer<TutorReply>().future);
    runtime.registerAiAdapter(EngineProvider.koji, (_) => engine);
    await expectLater(
      runtime.respond(
        TutorRequest(messages: [const TutorMessage(TutorRole.user, 'Hi')]),
      ),
      throwsA(
        isA<EngineFailure>().having(
          (error) => error.message,
          'timeout',
          contains('thời gian'),
        ),
      ),
    );
    expect(engine.closes, 1);
    runtime.dispose();
  });

  test(
    'Docker gateway receives requested limits and returns compiler errors',
    () async {
      final engine = HttpCodeEngine(
        EngineSelection(
          config('docker', provider: EngineProvider.docker),
          'token',
        ),
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map;
          expect(body['limits']['network'], isFalse);
          expect(body['limits']['memoryMb'], 128);
          expect(request.headers['Authorization'], 'Bearer token');
          return http.Response(
            '{"stdout":"","stderr":"syntax problem","exitCode":1,"error":"compile failed"}',
            200,
          );
        }),
      );
      final result = await engine.execute(
        CodeRequest(source: 'print(', language: 'python'),
      );
      expect(result.exitCode, 1);
      expect(result.stderr, 'syntax problem');
      expect(result.error, 'compile failed');
      engine.dispose();
    },
  );

  test('oversized engine response is rejected before JSON parsing', () async {
    final engine = HttpAiEngine(
      EngineSelection(config('a'), null),
      client: MockClient(
        (_) async => http.Response('x' * (1024 * 1024 + 1), 200),
      ),
    );
    await expectLater(
      engine.respond(
        TutorRequest(messages: [const TutorMessage(TutorRole.user, 'Hi')]),
      ),
      throwsA(
        isA<EngineFailure>().having(
          (error) => error.message,
          'size',
          contains('quá lớn'),
        ),
      ),
    );
    engine.dispose();
  });

  for (final provider in [
    EngineProvider.openai,
    EngineProvider.anthropic,
    EngineProvider.ollama,
    EngineProvider.koji,
  ]) {
    test(
      '${provider.name} adapter sends canvas and parses provider protocol',
      () async {
        final client = MockClient((request) async {
          expect(request.followRedirects, isFalse);
          expect(request.headers['Authorization'], 'Bearer private-key');
          final body = jsonDecode(request.body) as Map;
          expect(request.body, contains('strokes'));
          expect(body['model'], 'configured-model');
          switch (provider) {
            case EngineProvider.openai:
              expect(body['store'], isFalse);
              expect((body['input'] as List).first['role'], 'user');
              return http.Response(
                jsonEncode({
                  'output': [
                    {
                      'type': 'message',
                      'content': [
                        {'type': 'output_text', 'text': 'Hint'},
                      ],
                    },
                  ],
                }),
                200,
              );
            case EngineProvider.anthropic:
              expect(request.headers['anthropic-version'], '2023-06-01');
              return http.Response(
                '{"content":[{"type":"text","text":"Hint"}]}',
                200,
              );
            case EngineProvider.ollama:
              expect(body['stream'], false);
              return http.Response('{"message":{"content":"Hint"}}', 200);
            default:
              return http.Response('{"text":"Hint"}', 200);
          }
        });
        final engine = HttpAiEngine(
          EngineSelection(config('a', provider: provider), 'private-key'),
          client: client,
        );
        final result = await engine.respond(
          TutorRequest(
            messages: [const TutorMessage(TutorRole.user, 'Explain')],
            canvas: SharedCanvasDocument(
              strokes: [
                CanvasStroke([CanvasPoint(.2, .4)]),
              ],
            ),
          ),
        );
        expect(result.text, 'Hint');
        engine.dispose();
      },
    );
  }

  test(
    'HTTP redirect/error body cannot leak credentials through UI errors',
    () async {
      final engine = HttpAiEngine(
        EngineSelection(config('a'), 'private-key'),
        client: MockClient(
          (request) async => http.Response(
            'private-key error body',
            307,
            headers: {'location': 'https://evil.example'},
          ),
        ),
      );
      await expectLater(
        engine.respond(
          TutorRequest(messages: [const TutorMessage(TutorRole.user, 'Help')]),
        ),
        throwsA(
          isA<EngineFailure>().having(
            (error) => error.message,
            'message',
            isNot(contains('private-key')),
          ),
        ),
      );
      engine.dispose();
    },
  );

  test(
    'Judge0 submits base64, polls pending status and decodes results',
    () async {
      var calls = 0;
      final engine = HttpCodeEngine(
        EngineSelection(
          config('submissions', provider: EngineProvider.judge0),
          'token',
        ),
        wait: (_) async {},
        client: MockClient((request) async {
          calls++;
          expect(request.headers['X-Auth-Token'], 'token');
          if (calls == 1) {
            final body = jsonDecode(request.body) as Map;
            expect(
              utf8.decode(base64Decode(body['source_code'] as String)),
              'print(1)',
            );
            expect(body['enable_network'], false);
            return http.Response('{"token":"job-123"}', 201);
          }
          expect(request.method, 'GET');
          expect(request.url.path, '/submissions/job-123');
          if (calls == 2) return http.Response('{"status":{"id":2}}', 200);
          return http.Response(
            '{"status":{"id":3},"stdout":"MQo=","exit_code":0}',
            200,
          );
        }),
      );
      final result = await engine.execute(
        CodeRequest(
          source: 'print(1)',
          language: 'python',
          judge0LanguageId: 71,
        ),
      );
      expect(result.stdout, '1\n');
      expect(calls, 3);
      engine.dispose();
    },
  );

  test(
    'roadmaps reuse all catalog topics and pathway respects prerequisites',
    () {
      final roadmaps = catalogRoadmaps();
      expect(roadmaps.length, 5);
      expect(
        roadmaps
            .expand((roadmap) => roadmap.nodes)
            .map((node) => node.topicId)
            .toSet(),
        topics.map((topic) => topic.id).toSet(),
      );
      final roadmap = CourseRoadmap(
        id: 'math',
        domain: CourseDomain.math,
        nodes: [
          CourseNode('a'),
          CourseNode('b', prerequisites: ['a']),
        ],
      );
      final controller = MasteryPathwayController();
      expect(
        controller.next(roadmap, [
          MasteryMetric(topicId: 'a', correct: 4, total: 5),
        ])!.topicId,
        'b',
      );
      expect(
        controller.next(roadmap, [
          MasteryMetric(topicId: 'a', correct: 1, total: 3),
        ])!.review,
        isTrue,
      );
      expect(
        () => CourseRoadmap(
          id: 'cycle',
          domain: CourseDomain.math,
          nodes: [
            CourseNode('a', prerequisites: ['b']),
            CourseNode('b', prerequisites: ['a']),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => MasteryMetric(topicId: 'a', correct: -1, total: 1),
        throwsArgumentError,
      );
    },
  );
}
