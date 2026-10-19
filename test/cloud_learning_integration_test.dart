import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/lesson.dart';
import 'package:mathlingo/data/repositories/learning_statistics_repository.dart';
import 'package:mathlingo/data/repositories/lesson_repository.dart';
import 'package:mathlingo/data/repositories/family_report_repository.dart';
import 'package:mathlingo/data/repositories/ai_tutor_repository.dart';
import 'package:mathlingo/data/repositories/wrong_answer_cloud_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('curriculum retains distinct lessons with the same display number', () {
    Map<String, dynamic> row(String id, bool completed) => {
      'id': id,
      'lesson_number': 1,
      'title': id,
      'estimated_minutes': 3,
      'xp_reward': 30,
      'star_reward': 3,
      'is_completed': completed,
      'can_start': true,
      'stars_earned': completed ? 3 : 0,
    };
    final lessons = LessonRepository.lessonsFromRows([
      row('original', true),
      row('new-topic', false),
      row('original', true),
    ], 5);

    expect(lessons.map((lesson) => lesson.id), ['original', 'new-topic']);
    expect(lessons.first.status, LessonStatus.completed);
    expect(lessons.last.status, LessonStatus.available);
    expect(lessons.first.starsEarned, 3);
  });

  group('server learning data', () {
    late HttpServer server;
    late SupabaseClient client;
    HttpOverrides? overrides;
    late void Function(HttpRequest) respond;

    setUp(() async {
      // Only this suite's loopback server uses real HTTP; no external service is called.
      overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      SharedPreferences.setMockInitialValues({});
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) => respond(request));
      client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
    });

    tearDown(() async {
      await client.dispose();
      await server.close(force: true);
      HttpOverrides.global = overrides;
    });

    test(
      'wrong answers page through server history and retain review state',
      () async {
        final pages = <int>[];
        respond = (request) async {
          expect(request.uri.path, '/rest/v1/rpc/wrong_answer_history');
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['p_kid'], 'kid-a');
          expect(body['p_lesson'], 'lesson-a');
          final page = body['p_page'] as int;
          pages.add(page);
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode(
              List.generate(
                page == 0 ? 100 : 1,
                (i) => {
                  'questionId': 'q-${page * 100 + i}',
                  'prompt': '3 + 2 = ?',
                  'questionType': 'word_problem',
                  'timestamp': '2026-10-18T01:00:00Z',
                  'userAnswer': '4',
                  'isResolved': true,
                  'reviewCount': 2,
                },
              ),
            ),
          );
          await request.response.close();
        };
        final rows = await WrongAnswerCloudRepository.fetch(
          'kid-a',
          lessonId: 'lesson-a',
          client: client,
        );
        expect(rows, hasLength(101));
        expect(rows.last.questionId, 'q-100');
        expect(rows.first.isResolved, isTrue);
        expect(rows.first.reviewCount, 2);
        expect(pages, [0, 1]);
      },
    );

    test(
      'review updates send only annotations and reject a missing attempt',
      () async {
        respond = (request) async {
          expect(request.uri.path, '/rest/v1/rpc/set_wrong_answer_review');
          final body = jsonDecode(await utf8.decoder.bind(request).join());
          expect(body, {
            'p_kid': 'kid-a',
            'p_question': 'q-a',
            'p_action': 'resolve',
            'p_lesson': null,
          });
          request.response.headers.contentType = ContentType.json;
          request.response.write('0');
          await request.response.close();
        };
        await expectLater(
          WrongAnswerCloudRepository.update(
            'kid-a',
            'resolve',
            question: 'q-a',
            client: client,
          ),
          throwsStateError,
        );
      },
    );

    test('disabled AI settings come from the server', () async {
      respond = (request) {
        expect(request.uri.path, '/rest/v1/ai_settings');
        expect(request.uri.queryParameters['select'], 'enabled');
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"enabled":false}');
        request.response.close();
      };
      expect(await AiTutorRepository.isEnabled(client: client), isFalse);
    });

    test(
      'AI validates responses instead of displaying fabricated hints',
      () async {
        respond = (request) async {
          expect(request.uri.path, '/functions/v1/ai-tutor');
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['kidId'], 'kid-a');
          expect(body['problem'], '3 + 2 = ?');
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"supported":true,"hints":[42]}');
          await request.response.close();
        };
        await expectLater(
          AiTutorRepository.request(
            kidId: 'kid-a',
            requestId: 'request-a',
            phase: 'hint',
            problem: ' 3 + 2 = ? ',
            client: client,
          ),
          throwsFormatException,
        );
      },
    );

    test('family report reads confirmed duration and per-child limits without lesson access', () async {
      final requests = <Uri>[];
      respond = (request) {
        requests.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        final Object data;
        if (request.uri.path.endsWith('/family_report')) {
          data = {
            'kids': [
              {
                'id': 'kid-a',
                'today_seconds': 125,
                'last_session': {'title': 'Phép cộng', 'lesson_id': 'lesson-a'},
              },
            ],
          };
        } else if (request.uri.path.endsWith('/kid_profiles')) {
          expect(request.uri.queryParameters['id'], 'in.("kid-a")');
          data = [
            {'id': 'kid-a', 'screen_time_limit_minutes': 45},
          ];
        } else {
          expect(request.uri.path, '/rest/v1/study_sessions');
          expect(request.uri.queryParameters['kid_id'], 'eq.kid-a');
          expect(request.uri.queryParameters['limit'], '1');
          data = {
            'id': 'session-a',
            'lesson_id': 'lesson-a',
            'kind': 'lesson',
            'duration_seconds': 125,
          };
        }
        request.response.write(jsonEncode(data));
        request.response.close();
      };
      final report = await FamilyReportRepository.fetch(client: client);
      final kid = (report['kids'] as List).single as Map;
      expect(kid['screen_time_limit_minutes'], 45);
      expect(kid['today_seconds'], 125);
      expect(kid['last_session']['duration_seconds'], 125);
      expect(kid['last_session']['title'], 'Phép cộng');
      expect(requests, hasLength(3));
    });

    test(
      'a new family report stays empty without querying unrelated children',
      () async {
        var requests = 0;
        respond = (request) {
          requests++;
          expect(request.uri.path, '/rest/v1/rpc/family_report');
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"kids":[]}');
          request.response.close();
        };
        final report = await FamilyReportRepository.fetch(client: client);
        expect(report['kids'], isEmpty);
        expect(requests, 1);
      },
    );

    test(
      'counts all server attempts beyond the API row limit for one kid',
      () async {
        final requests = <Uri>[];
        respond = (request) {
          requests.add(request.uri);
          expect(request.uri.path, '/rest/v1/question_attempts');
          expect(
            request.uri.queryParameters['select'],
            'id,study_sessions!inner(kid_id)',
          );
          expect(
            request.uri.queryParameters['study_sessions.kid_id'],
            'eq.kid-a',
          );
          expect(request.uri.queryParameters['limit'], '0');
          expect(request.headers.value('prefer'), contains('count=exact'));
          final count = request.uri.queryParameters['is_correct'] == 'eq.true'
              ? 2400
              : 600;
          request.response.headers.set('content-range', '*/$count');
          request.response.headers.contentType = ContentType.json;
          request.response.write('[]');
          request.response.close();
        };
        await LearningStatisticsRepository.recordAnswers(
          correct: 99,
          kidId: 'kid-a',
        );

        final stats = await LearningStatisticsRepository.getStatistics(
          kidId: 'kid-a',
          client: client,
        );

        expect(stats.correctAnswers, 2400);
        expect(stats.incorrectAnswers, 600);
        expect(stats.accuracyPercentage, 80);
        expect(requests, hasLength(2));
      },
    );

    test('server failure is surfaced instead of reporting local counts as verified', () async {
      respond = (request) {
        request.response.statusCode = 403;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'code': '42501', 'message': 'permission denied'}),
        );
        request.response.close();
      };
      await LearningStatisticsRepository.recordAnswers(
        correct: 99,
        kidId: 'kid-a',
      );

      await expectLater(
        LearningStatisticsRepository.getStatistics(
          kidId: 'kid-a',
          client: client,
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test(
      'server streak overrides local activity and uses the Vietnam date',
      () async {
        respond = (request) {
          expect(request.uri.path, '/rest/v1/kid_streaks');
          expect(request.uri.queryParameters['kid_id'], 'eq.kid-a');
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({'streak_count': 4, 'last_activity_date': '2026-10-18'}),
          );
          request.response.close();
        };
        final streak = await LearningStatisticsRepository.getStreak(
          kidId: 'kid-a',
          referenceDate: DateTime.utc(2026, 10, 17, 18),
          client: client,
        );
        expect(streak.currentStreak, 4);
        expect(streak.hasStudiedToday, isTrue);
      },
    );

    test(
      'a family without a server streak starts at zero despite local activity',
      () async {
        respond = (request) {
          request.response.headers.contentType = ContentType.json;
          request.response.write('null');
          request.response.close();
        };
        await LearningStatisticsRepository.recordCorrectAnswer(kidId: 'kid-a');

        final streak = await LearningStatisticsRepository.getStreak(
          kidId: 'kid-a',
          client: client,
        );
        expect(streak.currentStreak, 0);
      },
    );
  });
}
