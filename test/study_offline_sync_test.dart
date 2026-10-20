import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathlingo/core/supabase/supabase_service.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/features/learning_engine/study_screen.dart';
import 'package:mathlingo/features/learning_engine/widgets/word_problem_widget.dart';

import 'learning_overview_test.dart' show OverviewState;

class OfflineAuditState extends OverviewState {
  @override
  bool get soundEnabled => false;
  @override
  Future<void> recordPracticeAnswer({
    required bool isCorrect,
    String? kidId,
    String? eventId,
    DateTime? timestamp,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'queued wrong and correct answers release their IDs after background sync',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final path = utf8.decode(message!.buffer.asUint8List());
            if (path == 'AssetManifest.bin') {
              return const StandardMessageCodec().encodeMessage({
                'fonts/PlusJakartaSans-Bold.ttf': [],
                'fonts/PlusJakartaSans-Medium.ttf': [],
              });
            }
            if (path.endsWith('.ttf')) return ByteData(0);
            return null;
          });
      for (final name in [
        'com.llfbandit.app_links/events',
        'com.llfbandit.app_links/messages',
      ]) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
      }
      final overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      late HttpServer server;
      var fail = false;
      var index = 0;
      var completed = false;
      final requests = <String, Map>{};
      final submissions = <Map>[];
      Map<String, dynamic> session() => {
        'id': 'audit-session',
        'kid_id': 'kid',
        'kind': 'lesson',
        'status': completed ? 'completed' : 'active',
        'title': 'Audit offline',
        'question_index': index,
        'remaining_seconds': 1800,
        'hearts': 5,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'offline_until': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 15))
            .toIso8601String(),
        'view_state': {'tab': 'quiz'},
        'questions': [
          {
            'id': 'q1',
            'question_type': 'word_problem',
            'prompt': '3 + 2 = ?',
            'payload': {
              'options': ['4', '5'],
            },
          },
          {
            'id': 'q2',
            'question_type': 'word_problem',
            'prompt': '4 + 2 = ?',
            'payload': {
              'options': ['5', '6'],
            },
          },
        ],
      };
      String encoded(Object data) =>
          base64Url.encode(utf8.encode(jsonEncode(data))).replaceAll('=', '');
      final jwt =
          '${encoded({'alg': 'HS256', 'typ': 'JWT'})}.${encoded({'sub': '11111111-1111-4111-8111-111111111111', 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.test';
      await tester.runAsync(() async {
        server = await HttpServer.bind(InternetAddress.loopbackIPv4, 49477);
        server.listen((req) async {
          final body = req.method == 'POST'
              ? await utf8.decoder.bind(req).join()
              : '';
          req.response.headers.contentType = ContentType.json;
          dynamic result;
          if (req.uri.path.contains('/auth/')) {
            result = {
              'access_token': jwt,
              'token_type': 'bearer',
              'expires_in': 3600,
              'refresh_token': 'audit-refresh',
              'user': {
                'id': '11111111-1111-4111-8111-111111111111',
                'email': 'offline@example.invalid',
                'aud': 'authenticated',
                'created_at': '2026-10-20T00:00:00Z',
              },
            };
          } else if (req.uri.path.endsWith('answer_learning_session')) {
            if (fail) {
              req.response.statusCode = 503;
              result = {'message': 'Temporary network failure', 'code': '503'};
            } else {
              final value = jsonDecode(body) as Map;
              submissions.add(value);
              if (!requests.containsKey(value['p_request'])) {
                requests[value['p_request']] = value;
                if ((value['p_question'] == 'q1' && value['p_value'] == '5') ||
                    (value['p_question'] == 'q2' && value['p_value'] == '6')) {
                  index++;
                }
              }
              result = {...session(), 'correct': value['p_value'] != '4'};
            }
          } else if (req.uri.path.endsWith('finish_learning_session')) {
            completed = true;
            result = session();
          } else {
            result = session();
          }
          req.response.write(jsonEncode(result));
          await req.response.close();
        });
        await SupabaseService.initialize();
        expect(SupabaseService.client, isNotNull);
        await SupabaseService.client!.auth.signInWithPassword(
          email: 'offline@example.invalid',
          password: 'audit-only',
        );
      });
      // The SDK keeps its loopback HTTP client. UI font loading uses Flutter's
      // network stub, so the test never fetches external fonts.
      HttpOverrides.global = overrides;
      final state = OfflineAuditState();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await SupabaseService.client?.dispose();
          await server.close(force: true);
        });
        state.dispose();
        HttpOverrides.global = overrides;
      });
      Future<void> until(bool Function() ready) async {
        for (var i = 0; i < 80 && !ready(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)),
          );
          await tester.pump();
        }
        expect(ready(), isTrue);
      }

      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: const MaterialApp(home: StudyScreen(lessonId: 'lesson')),
        ),
      );
      await until(() => find.byType(WordProblemWidget).evaluate().isNotEmpty);
      fail = true;
      tester
          .widget<WordProblemWidget>(find.byType(WordProblemWidget))
          .onAnswerValue!('4');
      await until(
        () => find
            .textContaining('Đã giữ câu trả lời trên máy.')
            .evaluate()
            .isNotEmpty,
      );
      fail = false;
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
      });
      await until(
        () => find.text('Đã đồng bộ câu trả lời.').evaluate().isNotEmpty,
      );
      expect(
        index,
        0,
        reason: 'A synchronized wrong answer must leave the same question open',
      );
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      fail = true;
      tester
          .widget<WordProblemWidget>(find.byType(WordProblemWidget))
          .onAnswerValue!('5');
      await until(
        () => find
            .textContaining('Đã giữ câu trả lời trên máy.')
            .evaluate()
            .isNotEmpty,
      );
      fail = false;
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
      });
      await until(() => find.text('4 + 2 = ?').evaluate().isNotEmpty);
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      });
      await until(() => find.byType(WordProblemWidget).evaluate().isNotEmpty);
      tester
          .widget<WordProblemWidget>(find.byType(WordProblemWidget))
          .onAnswerValue!('6');
      await until(() => submissions.length >= 3);
      await until(
        () => find.text('Chính xác! Em làm tốt lắm.').evaluate().isNotEmpty,
      );
      expect(submissions.last['p_question'], 'q2');
      expect(submissions[1]['p_question'], 'q1');
      expect(submissions[1]['p_value'], '5');
      expect(
        submissions[1]['p_request'],
        isNot(submissions.first['p_request']),
      );
      expect(
        submissions.last['p_request'],
        isNot(submissions.first['p_request']),
        reason:
            'A different question must not reuse the flushed answer request ID',
      );
      expect(submissions.last['p_value'], '6');
      expect(index, 2);
      await tester.ensureVisible(find.text('Lưu kết quả và nhận thưởng'));
      await tester.tap(find.text('Lưu kết quả và nhận thưởng'));
      await until(() => find.text('Hoàn thành!').evaluate().isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        SupabaseService.client!.auth.stopAutoRefresh();
        await Future<void>.delayed(const Duration(milliseconds: 400));
      });
      await tester.pump(const Duration(seconds: 20));
    },
    skip: SupabaseService.supabaseUrl != 'http://127.0.0.1:49477',
  );
}
