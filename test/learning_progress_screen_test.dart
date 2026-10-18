import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/learning_statistics.dart';
import 'package:mathlingo/data/repositories/learning_statistics_repository.dart';
import 'package:mathlingo/features/learning_engine/screens/learning_progress_screen.dart';
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

  group('LearningProgressScreen - Empty statistics and zero accuracy', () {
    testWidgets('renders zero metrics safely without NaN or infinity', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const LearningProgressScreen(
            statistics: LearningStatistics.empty(),
            streakCount: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('Tiến độ học tập'), findsOneWidget);

      // Streak banner and metrics display '0' (streak: 0, total: 0, correct: 0, incorrect: 0)
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
      expect(find.text('0'), findsNWidgets(4));
      expect(find.text('Ngày liên tiếp'), findsOneWidget);

      // 4 Metric cards labels
      expect(find.text('Tổng số câu'), findsOneWidget);
      expect(find.text('Đã trả lời đúng'), findsOneWidget);
      expect(find.text('Trả lời sai'), findsOneWidget);
      expect(find.text('Độ chính xác'), findsOneWidget);

      // Values
      expect(find.text('0%'), findsOneWidget);

      // Verify no NaN or Infinity exists in widget tree
      expect(find.textContaining('NaN'), findsNothing);
      expect(find.textContaining('Infinity'), findsNothing);

      // Empty state prompt
      expect(find.text('Chưa có dữ liệu học tập'), findsOneWidget);
      expect(
        find.text(
          'Hãy hoàn thành các câu hỏi luyện tập để theo dõi độ chính xác và chuỗi rèn luyện của bé!',
        ),
        findsOneWidget,
      );
    });
  });

  group('LearningProgressScreen - Populated statistics and streak', () {
    testWidgets('renders all learning statistics, accuracy, and streak properly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const stats = LearningStatistics(
        correctAnswers: 12,
        incorrectAnswers: 3,
      );

      await tester.pumpWidget(
        wrapWithMaterial(
          const LearningProgressScreen(
            statistics: stats,
            streakCount: 7,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Streak
      expect(find.text('7'), findsOneWidget);
      expect(find.text('Ngày liên tiếp'), findsOneWidget);
      expect(
        find.text('Bé đang duy trì thói quen học tập rất tốt!'),
        findsOneWidget,
      );

      // Metrics
      expect(find.text('15'), findsOneWidget); // Total
      expect(find.text('12'), findsOneWidget); // Correct
      expect(find.text('3'), findsOneWidget);  // Incorrect
      expect(find.text('80%'), findsAtLeastNWidgets(1)); // Accuracy

      // Distribution and Bar chart
      expect(find.text('Biểu đồ phân phối kết quả'), findsOneWidget);
      expect(find.text('Đúng'), findsOneWidget);
      expect(find.text('Sai'), findsOneWidget);

      // Action buttons
      expect(find.text('Vào vườn luyện tập'), findsOneWidget);
      expect(find.text('Xem lại câu trả lời sai'), findsOneWidget);
    });
  });

  group('LearningProgressScreen - Storage-backed data loading', () {
    testWidgets('loads persisted statistics from repository for specific kidId', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const kidId = 'kid_progress_test';
      const stats = LearningStatistics(
        correctAnswers: 9,
        incorrectAnswers: 1,
      );
      await LearningStatisticsRepository.saveStatistics(stats, kidId: kidId);

      await tester.pumpWidget(
        wrapWithMaterial(
          const LearningProgressScreen(
            kidId: kidId,
            streakCount: 4,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget); // Total
      expect(find.text('9'), findsOneWidget);  // Correct
      expect(find.text('1'), findsOneWidget);  // Incorrect
      expect(find.text('90%'), findsAtLeastNWidgets(1)); // Accuracy
      expect(find.text('4'), findsOneWidget);  // Streak
    });

    testWidgets('shows loading state while fetching statistics', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrapWithMaterial(
          const LearningProgressScreen(kidId: 'async_kid'),
        ),
      );

      // Prior to pumpAndSettle, loading indicator should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Đang tải dữ liệu tiến độ...'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('PracticeGardenScreen - Navigation to LearningProgressScreen', () {
    testWidgets('PracticeGardenScreen contains button navigating to LearningProgressScreen', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: PracticeGardenScreen()));
      await tester.pumpAndSettle();

      final progressButton = find.widgetWithText(
        OutlinedButton,
        'Tiến độ học tập',
      );
      expect(progressButton, findsOneWidget);

      await tester.ensureVisible(progressButton);
      await tester.tap(progressButton);
      await tester.pumpAndSettle();

      expect(find.byType(LearningProgressScreen), findsOneWidget);
      expect(find.text('Tiến độ học tập'), findsOneWidget);
    });
  });
}
