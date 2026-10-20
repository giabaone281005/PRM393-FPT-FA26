import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathlingo/data/models/study_session.dart';
import 'package:mathlingo/data/repositories/study_cache.dart';
import 'package:mathlingo/data/repositories/study_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mathlingo/data/models/question.dart';
import 'package:mathlingo/core/services/voice/speech_service.dart';
import 'package:mathlingo/features/learning_engine/widgets/voice_answer_widget.dart';
import 'package:mathlingo/features/learning_engine/widgets/multiplication_widget.dart';
import 'package:mathlingo/features/auth/auth_screen.dart';
import 'package:mathlingo/features/parent_portal/parent_area.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> session({bool expired = false}) => {
    'id': 'session',
    'kid_id': 'kid',
    'kind': 'lesson',
    'status': 'active',
    'question_index': 0,
    'remaining_seconds': 60,
    'updated_at': DateTime.now().toUtc().toIso8601String(),
    'offline_until': DateTime.now()
        .add(Duration(minutes: expired ? -1 : 15))
        .toIso8601String(),
    'questions': [
      {
        'id': 'question',
        'question_type': 'word_problem',
        'prompt': '3 + 2 = ?',
        'payload': {
          'options': [3, 4, 5, 6],
        },
      },
    ],
  };
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('temporary failures preserve retry while revoked rights cannot use fallback', () {
    expect(StudyRepository.isTransient(StateError('signed out')), isFalse);
    expect(
      StudyRepository.isTransient(const FormatException('bad response')),
      isFalse,
    );
    expect(
      StudyRepository.isTransient(const AuthException('session expired')),
      isFalse,
    );
    expect(
      StudyRepository.isTransient(
        const PostgrestException(message: 'revoked', code: 'P0001'),
      ),
      isFalse,
    );
    expect(
      StudyRepository.isTransient(
        const PostgrestException(message: 'forbidden', code: '42501'),
      ),
      isFalse,
    );
    expect(
      StudyRepository.isTransient(
        const PostgrestException(message: 'gateway', code: '503'),
      ),
      isTrue,
    );
    expect(
      StudyRepository.isTransient(
        const PostgrestException(message: 'retry transaction', code: '40001'),
      ),
      isTrue,
    );
  });
  test('public session contains no locally trusted correct answer', () {
    final s = StudySession(session());
    expect(s.currentQuestion!.correctAnswer, isNull);
    expect(s.quizDone, isFalse);
    expect(s.completed, isFalse);
  });
  test(
    'offline read expires and never extends the daily time budget',
    () async {
      await StudyCache.save(StudySession(session()));
      final cached = await StudyCache.read('session');
      expect(cached!.data['offline'], isTrue);
      expect(cached.remainingSeconds, lessThanOrEqualTo(60));
      await StudyCache.save(StudySession(session(expired: true)));
      expect(await StudyCache.read('session'), isNull);
    },
  );
  test(
    'saving offline heartbeats does not deduct elapsed time twice',
    () async {
      final data = session();
      data['updated_at'] = DateTime.now()
          .subtract(const Duration(seconds: 30))
          .toUtc()
          .toIso8601String();
      data['remaining_seconds'] = 90;
      await StudyCache.save(StudySession(data));
      final first = (await StudyCache.read('session'))!;
      expect(first.remainingSeconds, inInclusiveRange(59, 60));
      for (var i = 0; i < 3; i++) {
        await StudyCache.save((await StudyCache.read('session'))!);
      }
      final restored = (await StudyCache.read('session'))!;
      expect(restored.remainingSeconds, inInclusiveRange(58, 60));
      expect(restored.data['updated_at'], data['updated_at']);
      expect(restored.data['offline_until'], data['offline_until']);
    },
  );
  test(
    'malformed cache cannot prevent an online session from starting',
    () async {
      for (final raw in ['broken json', '[]', '{"remaining_seconds":"bad"}']) {
        SharedPreferences.setMockInitialValues({
          'study:signed_out:session:session': raw,
          'study:signed_out:last:kid:lesson:': 'session',
        });
        expect(await StudyCache.last('kid', 'lesson', null), isNull);
      }
    },
  );
  test(
    'answer outbox persists until acknowledgement, independently of grade',
    () async {
      await StudyCache.enqueue('session', {
        'p_request': 'same-id',
        'p_value': '5',
        'p_question': 'question',
      });
      expect((await StudyCache.pending('session'))!['p_request'], 'same-id');
      await StudyCache.acknowledge('session');
      expect(await StudyCache.pending('session'), isNull);
    },
  );
  test(
    'account cleanup removes that family cache without removing another family',
    () async {
      SharedPreferences.setMockInitialValues({
        'study:a:pending:one': jsonEncode({'p_value': '5'}),
        'family:a': 'cached',
        'study:b:pending:two': 'other',
      });
      await StudyCache.clearAccount('a');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('study:a:pending:one'), isFalse);
      expect(prefs.containsKey('family:a'), isFalse);
      expect(prefs.getString('study:b:pending:two'), 'other');
    },
  );
  testWidgets(
    'quiz sends the selected answer even when no correct answer exists locally',
    (tester) async {
      dynamic submitted;
      bool legacyCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MultiplicationWidget(
                data: const {
                  'formula': '3 + 2 = ?',
                  'options': [3, 4, 5, 6],
                },
                onAnswerSubmitted: (_) => legacyCalled = true,
                onAnswerValue: (v) => submitted = v,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('KIỂM TRA ĐÁP ÁN'));
      await tester.pump();
      expect(submitted, '5');
      expect(legacyCalled, isFalse);
    },
  );
  testWidgets('login remains usable on a small screen with large text', (
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
        home: const AuthScreen(),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNWidgets(2));
  });
  testWidgets('locked parent area exposes a PIN action and hides commerce', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ParentAreaLocked()));
    expect(find.text('Nhập PIN để tiếp tục'), findsOneWidget);
    expect(find.textContaining('VNPay'), findsNothing);
  });
  testWidgets(
    'voice answer submits candidate through question flow to grading',
    (tester) async {
      dynamic submitted;
      final mockSpeech = MockSpeechService();
      final question = Question(
        id: 'q_test',
        type: QuestionType.wordProblem,
        prompt: '3 + 2 = ?',
        data: const {
          'options': ['3', '4', '5', '6'],
        },
        correctAnswer: '5',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAnswerWidget(
              question: question,
              speechService: mockSpeech,
              onAnswerConfirmed: (v) => submitted = v,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      mockSpeech.simulateSpeech('bằng năm', isFinal: true);
      await tester.pump();
      expect(find.text('XÁC NHẬN GỬI'), findsOneWidget);
      await tester.tap(find.text('XÁC NHẬN GỬI'));
      await tester.pump();
      expect(submitted, '5');
    },
  );
}
