import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/learning_history.dart';
import 'package:mathlingo/data/repositories/learning_history_repository.dart';
import 'package:mathlingo/features/learning_engine/screens/learning_history_screen.dart';
import 'package:mathlingo/core/theme/app_theme.dart';

LearningHistoryEntry historyEntry({String status = 'paused'}) =>
    LearningHistoryEntry.fromMap({
      'id': 'session-a',
      'kid_id': 'kid-a',
      'lesson_id': 'lesson-a',
      'title': 'Cộng trong phạm vi 10',
      'kind': 'lesson',
      'status': status,
      'updated_at': '2026-10-20T01:00:00Z',
      'question_index': 1,
      'question_count': 2,
      'correct_count': 1,
      'attempt_count': 2,
      'duration_seconds': 75,
      'accuracy_percent': 50,
      'xp_earned': 30,
      'stars_awarded': 3,
    });

class HistoryFake extends LearningHistoryRepository {
  bool fail = false;
  String? lastKind, lastStatus;
  int lastPage = 0;
  bool completed = false;
  @override
  Future<List<LearningHistoryEntry>> fetch(
    String kidId, {
    String? kind,
    String? status,
    int page = 0,
  }) async {
    lastKind = kind;
    lastStatus = status;
    lastPage = page;
    if (fail) throw StateError('offline');
    return [historyEntry(status: completed ? 'completed' : 'paused')];
  }

  @override
  Future<List<LearningAttempt>> review(String sessionId) async => [
    LearningAttempt.fromMap({
      'id': 'a1',
      'prompt': '3 + 2 = ?',
      'answer': 4,
      'is_correct': false,
      'hints_used': 1,
      'hints': [
        {'hint_text': 'Đếm thêm hai từ ba.'},
      ],
    }),
    LearningAttempt.fromMap({
      'id': 'a2',
      'prompt': '3 + 2 = ?',
      'answer': 5,
      'is_correct': true,
    }),
  ];
}

void main() {
  testWidgets('history and review fit 320px with large text in both themes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: LearningHistoryScreen(
            kidId: 'kid-a',
            repository: HistoryFake(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Cộng trong phạm vi 10'), 200);
      await tester.ensureVisible(find.text('Cộng trong phạm vi 10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cộng trong phạm vi 10'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
  testWidgets(
    'history to attempts, wrong filter, explanation and exact-session resume',
    (tester) async {
      final repository = HistoryFake();
      String? resumed;
      await tester.pumpWidget(
        MaterialApp(
          home: LearningHistoryScreen(
            kidId: 'kid-a',
            repository: repository,
            studyBuilder: (entry, resume) {
              resumed = resume ? entry.id : null;
              return Scaffold(
                body: TextButton(
                  onPressed: () =>
                      Navigator.pop(tester.element(find.byType(Scaffold).last)),
                  child: const Text('Quay lại lịch sử'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1/2 câu'), findsOneWidget);
      await tester.tap(find.text('Cộng trong phạm vi 10'));
      await tester.pumpAndSettle();
      expect(find.text('Em đã trả lời: 4'), findsOneWidget);
      expect(find.text('Em đã trả lời: 5'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Em đã trả lời: 5'), findsNothing);
      await tester.tap(find.text('Cách suy nghĩ'));
      await tester.pumpAndSettle();
      expect(find.text('Đếm thêm hai từ ba.'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục phiên học'));
      await tester.pumpAndSettle();
      expect(resumed, 'session-a');
    },
  );

  testWidgets(
    'completed history can open a new attempt instead of resuming old ID',
    (tester) async {
      bool? resumeRequested;
      await tester.pumpWidget(
        MaterialApp(
          home: LearningHistoryScreen(
            kidId: 'kid-a',
            repository: HistoryFake()..completed = true,
            studyBuilder: (_, resume) {
              resumeRequested = resume;
              return const Scaffold(body: Text('Lần học mới'));
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cộng trong phạm vi 10'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luyện lại'));
      await tester.pumpAndSettle();
      expect(resumeRequested, isFalse);
      expect(find.text('Lần học mới'), findsOneWidget);
    },
  );

  testWidgets('filters reload actual query and failed history can retry', (
    tester,
  ) async {
    final repository = HistoryFake()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: LearningHistoryScreen(kidId: 'kid-a', repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa tải được lịch sử'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mọi trạng thái'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoàn thành').last);
    await tester.pumpAndSettle();
    expect(repository.lastStatus, 'completed');
    expect(repository.lastPage, 0);
  });
}
