import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/question.dart';
import 'package:mathlingo/data/models/wrong_answer_record.dart';
import 'package:mathlingo/data/repositories/wrong_answer_repository.dart';
import 'package:mathlingo/features/learning_engine/screens/review_wrong_answers_screen.dart';
import 'package:mathlingo/features/practice_garden/screens/practice_garden_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders empty state when there are no wrong answers', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: 'kid_empty')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ôn tập câu trả lời sai'), findsOneWidget);
    expect(find.text('Không có câu sai nào!'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
  });

  testWidgets(
    'renders prompt and learner answer, and does not show fake correct answer',
    (tester) async {
      const kidId = 'kid_123';
      final record = WrongAnswerRecord(
        questionId: 'q_test_1',
        prompt:
            'Một rổ có 5 quả cam, thêm 3 quả cam. Hỏi có tất cả bao nhiêu quả?',
        questionType: QuestionType.wordProblem,
        userAnswer: '7 quả',
        timestamp: DateTime.now(),
        isResolved: false,
      );

      await WrongAnswerRepository.saveWrongAnswer(kidId, record);

      await tester.pumpWidget(
        wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
      );
      await tester.pumpAndSettle();

      // Verify prompt is displayed
      expect(
        find.text(
          'Một rổ có 5 quả cam, thêm 3 quả cam. Hỏi có tất cả bao nhiêu quả?',
        ),
        findsOneWidget,
      );
      // Verify user answer is displayed
      expect(find.text('7 quả'), findsOneWidget);
      expect(find.text('Câu trả lời của em:'), findsOneWidget);
      // Verify status
      expect(find.text('Cần ôn tập'), findsOneWidget);
      // Verify no fake correct answer is shown
      expect(find.textContaining('Đáp án đúng:'), findsNothing);
      expect(find.textContaining('8 quả'), findsNothing);
    },
  );

  testWidgets('formats map answer properly (e.g. clock rotation)', (
    tester,
  ) async {
    const kidId = 'kid_clock';
    final record = WrongAnswerRecord(
      questionId: 'q_clock_test',
      prompt: 'Xoay kim đồng hồ chỉ 10:15',
      questionType: QuestionType.clockRotation,
      userAnswer: const {'hour': 10, 'minute': 30},
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, record);

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('Xoay đồng hồ'), findsOneWidget);
  });

  testWidgets('filters records by unresolved and resolved tabs', (
    tester,
  ) async {
    const kidId = 'kid_filter';
    final r1 = WrongAnswerRecord(
      questionId: 'q_unresolved',
      prompt: 'Câu hỏi chưa ôn',
      questionType: QuestionType.wordProblem,
      userAnswer: 'Sai 1',
      timestamp: DateTime.now(),
      isResolved: false,
    );
    final r2 = WrongAnswerRecord(
      questionId: 'q_resolved',
      prompt: 'Câu hỏi đã ôn xong',
      questionType: QuestionType.multiplicationTable,
      userAnswer: 'Sai 2',
      timestamp: DateTime.now(),
      isResolved: true,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, r1);
    await WrongAnswerRepository.saveWrongAnswer(kidId, r2);
    // Ensure r2 is marked resolved in repository
    await WrongAnswerRepository.markResolved(kidId, 'q_resolved');

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    // Default 'Tất cả' shows both
    expect(find.text('Câu hỏi chưa ôn'), findsOneWidget);
    expect(find.text('Câu hỏi đã ôn xong'), findsOneWidget);

    // Tap 'Chưa ôn tập' chip
    await tester.tap(find.text('Chưa ôn tập (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Câu hỏi chưa ôn'), findsOneWidget);
    expect(find.text('Câu hỏi đã ôn xong'), findsNothing);

    // Tap 'Đã ôn tập' chip
    await tester.tap(find.text('Đã ôn tập (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Câu hỏi chưa ôn'), findsNothing);
    expect(find.text('Câu hỏi đã ôn xong'), findsOneWidget);
  });

  testWidgets('toggles resolved status when button is clicked', (tester) async {
    const kidId = 'kid_toggle';
    final record = WrongAnswerRecord(
      questionId: 'q_toggle',
      prompt: 'Phép tính cần ôn',
      questionType: QuestionType.multiplicationTable,
      userAnswer: '15',
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, record);

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cần ôn tập'), findsOneWidget);
    expect(find.text('Đánh dấu đã ôn'), findsOneWidget);

    // Tap button to mark resolved
    await tester.tap(find.text('Đánh dấu đã ôn'));
    await tester.pumpAndSettle();

    expect(find.text('Đã ôn tập'), findsOneWidget);
    expect(find.text('Đánh dấu cần ôn'), findsOneWidget);

    // Verify persisted in repo
    final item = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_toggle');
    expect(item?.isResolved, isTrue);
  });

  testWidgets('deletes record after confirming dialog', (tester) async {
    const kidId = 'kid_delete_ui';
    final record = WrongAnswerRecord(
      questionId: 'q_del_ui',
      prompt: 'Câu hỏi cần xóa',
      questionType: QuestionType.wordProblem,
      userAnswer: '99',
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, record);

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Câu hỏi cần xóa'), findsOneWidget);

    // Tap delete button
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Xóa câu sai'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);

    // Confirm delete
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();

    expect(find.text('Không có câu sai nào!'), findsOneWidget);
    expect(find.text('Câu hỏi cần xóa'), findsNothing);
  });

  testWidgets('isolates wrong answer records by kidId', (tester) async {
    final rKidA = WrongAnswerRecord(
      questionId: 'q_kid_A',
      prompt: 'Câu hỏi của bé A',
      questionType: QuestionType.wordProblem,
      userAnswer: '1',
      timestamp: DateTime.now(),
    );
    final rKidB = WrongAnswerRecord(
      questionId: 'q_kid_B',
      prompt: 'Câu hỏi của bé B',
      questionType: QuestionType.wordProblem,
      userAnswer: '2',
      timestamp: DateTime.now(),
    );

    await WrongAnswerRepository.saveWrongAnswer('kid_A', rKidA);
    await WrongAnswerRepository.saveWrongAnswer('kid_B', rKidB);

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: 'kid_A')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Câu hỏi của bé A'), findsOneWidget);
    expect(find.text('Câu hỏi của bé B'), findsNothing);
  });

  testWidgets(
    'PracticeGardenScreen has button navigating to ReviewWrongAnswersScreen',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeGardenScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Xem lại câu trả lời sai'), findsOneWidget);

      await tester.tap(find.text('Xem lại câu trả lời sai'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewWrongAnswersScreen), findsOneWidget);
      expect(find.text('Ôn tập câu trả lời sai'), findsOneWidget);
    },
  );
}
