import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/theme/app_theme.dart';
import 'package:mathlingo/data/models/kid_profile.dart';
import 'package:mathlingo/data/models/learning_history.dart';
import 'package:mathlingo/data/models/learning_overview.dart';
import 'package:mathlingo/data/models/lesson.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/repositories/learning_history_repository.dart';
import 'package:mathlingo/data/repositories/lesson_repository.dart';
import 'package:mathlingo/features/home/screens/home_screen.dart';
import 'package:mathlingo/features/learning_engine/screens/topic_learning_screen.dart';
import 'package:mathlingo/features/learning_engine/study_screen.dart';
import 'package:mathlingo/features/learning_engine/widgets/student_learning_overview.dart';
import 'package:mathlingo/features/treasure_map/screens/treasure_map_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Lesson> sampleLessons() => [
  Lesson(
    id: 'a1',
    grade: 1,
    lessonNumber: 1,
    title: 'Cộng trong phạm vi 10',
    subtitle: '',
    topicId: 'a',
    topicTitle: 'Phép cộng',
    questions: [],
    status: LessonStatus.completed,
  ),
  Lesson(
    id: 'a2',
    grade: 1,
    lessonNumber: 2,
    title: 'Cộng trong phạm vi 20',
    subtitle: '',
    topicId: 'a',
    topicTitle: 'Phép cộng',
    questions: [],
    status: LessonStatus.available,
  ),
  Lesson(
    id: 'b1',
    grade: 1,
    lessonNumber: 1,
    title: 'Đọc giờ',
    subtitle: '',
    topicId: 'b',
    topicTitle: 'Đồng hồ',
    questions: [],
    status: LessonStatus.locked,
  ),
];

class OverviewHistory extends LearningHistoryRepository {
  bool fail = false;
  final calls = <String>[];
  @override
  Future<List<LearningHistoryEntry>> fetch(
    String kidId, {
    String? kind,
    String? status,
    int page = 0,
  }) async {
    calls.add(kidId);
    if (fail) throw StateError('offline');
    return [];
  }
}

class OverviewState extends AppStateProvider {
  final lessons = sampleLessons();
  @override
  bool get hasKids => true;
  @override
  KidProfile get currentKid => KidProfile(id: 'kid', nickname: 'An', grade: 1);
  @override
  List<Lesson> get currentLessons => lessons;
  @override
  Future<void> refreshFromCloud() async {}
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('curriculum preserves topic identity and completion never merges repeated numbers', () {
    final lessons = LessonRepository.lessonsFromRows([
      for (final entry in [
        ('one', 'a', 'Phép cộng', true),
        ('two', 'b', 'Đồng hồ', false),
      ])
        {
          'id': entry.$1,
          'topic_id': entry.$2,
          'topic_title': entry.$3,
          'lesson_number': 1,
          'title': entry.$1,
          'estimated_minutes': 3,
          'xp_reward': 30,
          'star_reward': 3,
          'is_completed': entry.$4,
          'can_start': true,
        },
    ], 1);
    final topics = TopicProgress.group([...lessons, lessons.first]);
    expect(topics.map((t) => t.id), ['a', 'b']);
    expect(topics.map((t) => t.fraction), [1, 0]);
    expect(topics.first.lessons, hasLength(1));
  });

  test('daily usage uses UTC+7 dates, includes zero days and excludes future/old data', () {
    final days = LearningDay.week([
      {'study_date': '2026-10-20', 'total_seconds': 45},
      {'study_date': '2026-10-19', 'total_seconds': 125},
      {'study_date': '2026-10-13', 'total_seconds': 999},
      {'study_date': '2026-10-21', 'total_seconds': 999},
    ], now: DateTime.parse('2026-10-19T18:00:00Z'));
    expect(days, hasLength(7));
    expect(days.first.date, DateTime.utc(2026, 10, 14));
    expect(days.last.date, DateTime.utc(2026, 10, 20));
    expect(days.map((d) => d.seconds), [0, 0, 0, 0, 0, 125, 45]);
    expect(days.last.duration, '0 phút 45 giây');
  });

  testWidgets(
    'actual topic progress and daily usage fit 320px and large text in both themes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
        final now = DateTime.now().toUtc().add(const Duration(hours: 7));
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudentLearningOverview(
                  kidId: 'kid',
                  lessons: sampleLessons(),
                  days: [
                    {
                      'study_date': now.toIso8601String().substring(0, 10),
                      'total_seconds': 125,
                    },
                  ],
                  historyRepository: OverviewHistory(),
                  onRefresh: () async {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('1/3 bài đã hoàn thành'), findsOneWidget);
        expect(
          find.text('7 ngày qua: 2 phút 5 giây đã ghi nhận'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(find.text('Phép cộng'), 200);
        expect(find.text('1/2 bài · 50% hoàn thành'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets(
    'activity failures retry and switching child reloads without old activities',
    (tester) async {
      final history = OverviewHistory()..fail = true;
      Widget page(String kid) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentLearningOverview(
              kidId: kid,
              lessons: const [],
              days: const [],
              historyRepository: history,
              onRefresh: () async {},
            ),
          ),
        ),
      );
      await tester.pumpWidget(page('kid-a'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Thử tải lại hoạt động'), 200);
      history.fail = false;
      await tester.tap(find.text('Thử tải lại hoạt động'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có phiên học.'), findsOneWidget);
      await tester.pumpWidget(page('kid-b'));
      await tester.pumpAndSettle();
      expect(history.calls, ['kid-a', 'kid-a', 'kid-b']);
    },
  );

  testWidgets(
    'topic navigation keeps lesson identity and explains locked prerequisites',
    (tester) async {
      final state = OverviewState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: const MaterialApp(
            home: TopicLearningScreen(topicId: 'b', title: 'Đồng hồ'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Cộng trong phạm vi'), findsNothing);
      await tester.tap(find.text('Bài 1: Đọc giờ'));
      await tester.pumpAndSettle();
      expect(
        find.text('Hãy hoàn thành các bài trước trong chủ đề để mở bài này.'),
        findsOneWidget,
      );
      expect(find.text('Bắt đầu / học tiếp'), findsNothing);
    },
  );

  testWidgets('map topic filter limits lesson nodes to the chosen real topic', (
    tester,
  ) async {
    final state = OverviewState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AppStateProvider>.value(
        value: state,
        child: const MaterialApp(home: TreasureMapScreen()),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Tất cả chủ đề'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Đồng hồ').last);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Đọc giờ'), findsWidgets);
    expect(find.text('Cộng trong phạm vi 20'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets(
    'home continue action opens the selected lesson after intro confirmation',
    (tester) async {
      final state = OverviewState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('TIẾP TỤC HỌC NGAY'));
      await tester.tap(find.text('TIẾP TỤC HỌC NGAY'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu / học tiếp'));
      await tester.pumpAndSettle();
      expect(find.byType(StudyScreen), findsOneWidget);
      expect(
        tester.widget<StudyScreen>(find.byType(StudyScreen)).lessonId,
        'a2',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
