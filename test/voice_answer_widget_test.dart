import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/services/voice/speech_service.dart';
import 'package:mathlingo/data/models/question.dart';
import 'package:mathlingo/features/learning_engine/widgets/voice_answer_widget.dart';

void main() {
  Question createTestQuestion({
    String id = 'q1',
    QuestionType type = QuestionType.dragCounters,
    List<dynamic>? options,
  }) {
    return Question(
      id: id,
      type: type,
      prompt: 'Có bao nhiêu quả táo trong giỏ?',
      data: {'targetCount': 3, 'options': ?options},
      correctAnswer: 3,
    );
  }

  group('VoiceAnswerWidget Tests', () {
    late MockSpeechService mockSpeech;

    setUp(() {
      mockSpeech = MockSpeechService();
    });

    testWidgets('renders initial idle state with mic button and guide text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAnswerWidget(
              question: createTestQuestion(),
              speechService: mockSpeech,
              onAnswerConfirmed: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.text('Trả lời bằng giọng nói'), findsOneWidget);
      expect(find.text('Bấm micro và nói đáp án của bé nhé!'), findsOneWidget);
    });

    testWidgets('tapping mic starts listening and shows listening state', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAnswerWidget(
              question: createTestQuestion(),
              speechService: mockSpeech,
              onAnswerConfirmed: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();

      expect(mockSpeech.isListening, isTrue);
      expect(find.text('Cú đang nghe bé nói nè...'), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    });

    testWidgets(
      'receiving speech resolves candidate answer and confirms submission',
      (tester) async {
        dynamic submittedAnswer;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VoiceAnswerWidget(
                question: createTestQuestion(type: QuestionType.dragCounters),
                speechService: mockSpeech,
                onAnswerConfirmed: (val) => submittedAnswer = val,
              ),
            ),
          ),
        );

        // Bắt đầu nghe
        await tester.tap(find.byIcon(Icons.mic_rounded));
        await tester.pump();

        // Giả lập giọng nói của bé: "ba quả"
        mockSpeech.simulateSpeech('ba quả', isFinal: true);
        await tester.pump();

        // Hiển thị kết quả nhận diện và đáp án
        expect(find.text('Cú đã nghe được rồi!'), findsOneWidget);
        expect(find.text('Cú nghe được: "ba quả"'), findsOneWidget);
        expect(find.text('Đáp án: 3'), findsOneWidget);
        expect(find.text('XÁC NHẬN GỬI'), findsOneWidget);

        // Bấm Xác nhận gửi
        await tester.tap(find.text('XÁC NHẬN GỬI'));
        await tester.pump();

        expect(submittedAnswer, 3);
        // Đã reset sau khi gửi
        expect(find.text('Trả lời bằng giọng nói'), findsOneWidget);
      },
    );

    testWidgets('word problem options matching via voice', (tester) async {
      dynamic submittedAnswer;
      final q = createTestQuestion(
        id: 'q_word',
        type: QuestionType.wordProblem,
        options: ['12 cm²', '15 cm²', '18 cm²', '20 cm²'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAnswerWidget(
              question: q,
              speechService: mockSpeech,
              onAnswerConfirmed: (val) => submittedAnswer = val,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();

      // Bé nói "chọn câu B"
      mockSpeech.simulateSpeech('chọn câu B', isFinal: true);
      await tester.pump();

      expect(find.text('Đáp án: 15 cm²'), findsOneWidget);

      await tester.tap(find.text('XÁC NHẬN GỬI'));
      await tester.pump();

      expect(submittedAnswer, '15 cm²');
    });

    testWidgets(
      'shows retry button when speech is ambiguous and not in options',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VoiceAnswerWidget(
                question: createTestQuestion(
                  type: QuestionType.wordProblem,
                  options: ['3 quả', '5 quả'],
                ),
                speechService: mockSpeech,
                onAnswerConfirmed: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.mic_rounded));
        await tester.pump();

        mockSpeech.simulateSpeech('con không biết câu này', isFinal: true);
        await tester.pump();

        expect(find.text('BÉ NÓI LẠI NHÉ'), findsOneWidget);
        expect(find.text('XÁC NHẬN GỬI'), findsNothing);
      },
    );

    testWidgets(
      'shows friendly error message and retry button when speech fails',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VoiceAnswerWidget(
                question: createTestQuestion(),
                speechService: mockSpeech,
                onAnswerConfirmed: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.mic_rounded));
        await tester.pump();

        mockSpeech.simulateError(
          const VoiceError(
            type: VoiceErrorType.noSpeech,
            message: 'Cú chưa nghe rõ âm thanh, bé bấm nói lại nhé!',
          ),
        );
        await tester.pump();

        expect(find.text('Chưa nghe rõ câu trả lời'), findsOneWidget);
        expect(
          find.text('Cú chưa nghe rõ âm thanh, bé bấm nói lại nhé!'),
          findsOneWidget,
        );
        expect(find.text('Thử lại'), findsOneWidget);
      },
    );

    testWidgets('resets voice state when switching to another question', (
      tester,
    ) async {
      final q1 = createTestQuestion(id: 'q1');
      final q2 = createTestQuestion(id: 'q2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAnswerWidget(
              question: q1,
              speechService: mockSpeech,
              onAnswerConfirmed: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      mockSpeech.simulateSpeech('ba quả', isFinal: true);
      await tester.pump();

      expect(find.text('Đáp án: 3'), findsOneWidget);

      // Chuyển sang câu hỏi q2
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAnswerWidget(
              question: q2,
              speechService: mockSpeech,
              onAnswerConfirmed: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Đáp án cũ biến mất, trở về trạng thái idle
      expect(find.text('Đáp án: 3'), findsNothing);
      expect(find.text('Trả lời bằng giọng nói'), findsOneWidget);
    });
  });
}
