import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/data/models/kid_profile.dart';
import 'package:mathlingo/data/models/learning_statistics.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/features/learning_engine/screens/learning_progress_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learning_overview_test.dart' show OverviewState;

class ProgressState extends OverviewState {
  String kidId = 'first';
  @override
  KidProfile get currentKid => KidProfile(id: kidId, nickname: kidId, grade: 1);
  void select(String value) {
    kidId = value;
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'changing selected kid reloads even without a statistics revision',
    (tester) async {
      final state = ProgressState();
      addTearDown(state.dispose);
      final calls = <String>[];
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: MaterialApp(
            home: LearningProgressScreen(
              streakCount: 0,
              statisticsLoader: (id) async {
                calls.add(id);
                return LearningStatistics(
                  correctAnswers: id == 'first' ? 11 : 23,
                  incorrectAnswers: 0,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('11'), findsAtLeastNWidgets(1));
      final revision = state.statsRevision;
      state.select('second');
      await tester.pumpAndSettle();
      expect(state.statsRevision, revision);
      expect(calls, ['first', 'second']);
      expect(find.text('23'), findsAtLeastNWidgets(1));
      expect(find.text('11'), findsNothing);
    },
  );

  testWidgets('an older kid response cannot replace the latest widget kid', (
    tester,
  ) async {
    final first = Completer<LearningStatistics>();
    final second = Completer<LearningStatistics>();
    final calls = <String>[];
    Future<LearningStatistics> load(String id) {
      calls.add(id);
      return id == 'first' ? first.future : second.future;
    }

    Widget screen(String id) => MaterialApp(
      home: LearningProgressScreen(
        kidId: id,
        streakCount: 0,
        statisticsLoader: load,
      ),
    );
    await tester.pumpWidget(screen('first'));
    await tester.pumpWidget(screen('second'));
    second.complete(
      const LearningStatistics(correctAnswers: 23, incorrectAnswers: 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('23'), findsAtLeastNWidgets(1));
    first.complete(
      const LearningStatistics(correctAnswers: 11, incorrectAnswers: 0),
    );
    await tester.pumpAndSettle();
    expect(calls, ['first', 'second']);
    expect(find.text('11'), findsNothing);
    expect(find.text('23'), findsAtLeastNWidgets(1));
  });
}
