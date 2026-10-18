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

  testWidgets('canceling delete dialog preserves the record', (tester) async {
    const kidId = 'kid_cancel_del';
    final record = WrongAnswerRecord(
      questionId: 'q_keep',
      prompt: 'Câu hỏi giữ lại',
      questionType: QuestionType.wordProblem,
      userAnswer: '12',
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, record);

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    // Tap delete button
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Xóa câu sai'), findsOneWidget);

    // Cancel delete
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(find.text('Câu hỏi giữ lại'), findsOneWidget);
    final item = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_keep');
    expect(item, isNotNull);
  });

  testWidgets('mark all resolved updates all questions to resolved', (tester) async {
    const kidId = 'kid_mark_all_ui';
    final r1 = WrongAnswerRecord(
      questionId: 'q_all_1',
      prompt: 'Câu 1',
      questionType: QuestionType.multiplicationTable,
      userAnswer: '10',
      timestamp: DateTime.now(),
      isResolved: false,
    );
    final r2 = WrongAnswerRecord(
      questionId: 'q_all_2',
      prompt: 'Câu 2',
      questionType: QuestionType.wordProblem,
      userAnswer: '20',
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, r1);
    await WrongAnswerRepository.saveWrongAnswer(kidId, r2);

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);

    // Tap mark all resolved
    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Đánh dấu tất cả'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    // Both should now be marked resolved
    expect(find.text('Đã ôn tập (2)'), findsOneWidget);
    expect(find.text('Chưa ôn tập (0)'), findsOneWidget);

    final item1 = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_all_1');
    final item2 = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_all_2');
    expect(item1?.isResolved, isTrue);
    expect(item2?.isResolved, isTrue);
  });

  testWidgets('canceling mark all resolved dialog does nothing', (tester) async {
    const kidId = 'kid_cancel_mark_all';
    final r1 = WrongAnswerRecord(
      questionId: 'q_not_all',
      prompt: 'Câu hỏi chưa xong',
      questionType: QuestionType.multiplicationTable,
      userAnswer: '10',
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, r1);

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    // Tap mark all resolved
    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Đánh dấu tất cả'), findsOneWidget);

    // Cancel
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    final item = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_not_all');
    expect(item?.isResolved, isFalse);
  });

  testWidgets('clears resolved records after confirming dialog', (tester) async {
    const kidId = 'kid_clear_res';
    final r1 = WrongAnswerRecord(
      questionId: 'q_res_del',
      prompt: 'Câu đã ôn',
      questionType: QuestionType.wordProblem,
      userAnswer: '30',
      timestamp: DateTime.now(),
      isResolved: true,
    );
    final r2 = WrongAnswerRecord(
      questionId: 'q_unres_keep',
      prompt: 'Câu cần giữ',
      questionType: QuestionType.wordProblem,
      userAnswer: '40',
      timestamp: DateTime.now(),
      isResolved: false,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, r1);
    await WrongAnswerRepository.saveWrongAnswer(kidId, r2);
    await WrongAnswerRepository.markResolved(kidId, 'q_res_del');

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cleaning_services_rounded), findsOneWidget);

    // Tap clear resolved
    await tester.tap(find.byIcon(Icons.cleaning_services_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Dọn dẹp danh sách'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();

    expect(find.text('Câu cần giữ'), findsOneWidget);
    expect(find.text('Câu đã ôn'), findsNothing);

    final item1 = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_res_del');
    final item2 = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_unres_keep');
    expect(item1, isNull);
    expect(item2, isNotNull);
  });

  testWidgets('canceling clear resolved dialog preserves records', (tester) async {
    const kidId = 'kid_cancel_clear';
    final r1 = WrongAnswerRecord(
      questionId: 'q_keep_res',
      prompt: 'Câu giữ lại ôn',
      questionType: QuestionType.wordProblem,
      userAnswer: '50',
      timestamp: DateTime.now(),
      isResolved: true,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, r1);
    await WrongAnswerRepository.markResolved(kidId, 'q_keep_res');

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    // Tap clear resolved
    await tester.tap(find.byIcon(Icons.cleaning_services_rounded));
    await tester.pumpAndSettle();

    // Cancel
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    final item = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_keep_res');
    expect(item, isNotNull);
    expect(find.text('Câu giữ lại ôn'), findsOneWidget);
  });

  testWidgets('toggling resolved item back to unresolved updates status', (tester) async {
    const kidId = 'kid_toggle_back';
    final r = WrongAnswerRecord(
      questionId: 'q_back',
      prompt: 'Câu hỏi cần ôn lại lần 2',
      questionType: QuestionType.multiplicationTable,
      userAnswer: '9',
      timestamp: DateTime.now(),
      isResolved: true,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, r);
    await WrongAnswerRepository.markResolved(kidId, 'q_back');

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đã ôn tập'), findsOneWidget);
    expect(find.text('Đánh dấu cần ôn'), findsOneWidget);

    // Tap button to toggle back to needing review
    await tester.tap(find.text('Đánh dấu cần ôn'));
    await tester.pumpAndSettle();

    expect(find.text('Cần ôn tập'), findsOneWidget);
    expect(find.text('Đánh dấu đã ôn'), findsOneWidget);

    final item = await WrongAnswerRepository.getWrongAnswer(kidId, 'q_back');
    expect(item?.isResolved, isFalse);
  });

  testWidgets('displays friendly message when filtered tab is empty', (tester) async {
    const kidId = 'kid_empty_filter';
    final r = WrongAnswerRecord(
      questionId: 'q_only_res',
      prompt: 'Câu đã ôn xong duy nhất',
      questionType: QuestionType.wordProblem,
      userAnswer: '5',
      timestamp: DateTime.now(),
      isResolved: true,
    );

    await WrongAnswerRepository.saveWrongAnswer(kidId, r);
    await WrongAnswerRepository.markResolved(kidId, 'q_only_res');

    await tester.pumpWidget(
      wrapWithMaterial(const ReviewWrongAnswersScreen(kidId: kidId)),
    );
    await tester.pumpAndSettle();

    // Tap 'Chưa ôn tập (0)'
    await tester.tap(find.text('Chưa ôn tập (0)'));
    await tester.pumpAndSettle();

    expect(find.text('Em đã ôn tập xong tất cả các câu sai!'), findsOneWidget);
    expect(find.byIcon(Icons.task_alt_rounded), findsOneWidget);
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

      await tester.ensureVisible(find.text('Xem lại câu trả lời sai'));
      await tester.tap(find.text('Xem lại câu trả lời sai'));
      await tester.pumpAndSettle();

      expect(find.byType(ReviewWrongAnswersScreen), findsOneWidget);
      expect(find.text('Ôn tập câu trả lời sai'), findsOneWidget);
    },
  );
}
