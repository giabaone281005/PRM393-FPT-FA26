import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/services/app_route_observer.dart';
import 'package:mathlingo/data/models/study_session.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/data/providers/study_heartbeat_queue.dart';
import 'package:mathlingo/features/parent_portal/screens/parent_portal_screen.dart';
import 'package:provider/provider.dart';

class ReportState extends AppStateProvider {
  ReportState(Future<Map<String, dynamic>> Function() load)
    : super(familyReportLoader: load);
  String? uid = 'parent-a';
  bool unlocked = true;
  @override
  String? get accountId => uid;
  @override
  bool get isParentUnlocked => unlocked;
  @override
  Future<void> refreshFromCloud() async {}
}

Map<String, dynamic> report(int seconds) => {
  'kids': [
    {
      'id': 'kid-a',
      'nickname': 'An',
      'grade': 1,
      'archived': false,
      'completed': 1,
      'today_seconds': seconds,
      'screen_time_limit_minutes': 45,
      'days': <dynamic>[],
      'skills': <dynamic>[],
      'last_session': {
        'title': 'Phép cộng',
        'status': 'active',
        'last_active': true,
        'last_heartbeat_at': '2026-01-01T00:00:00Z',
        'duration_seconds': seconds,
      },
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'report refresh shares an in-flight request and updates summaries',
    () async {
      final response = Completer<Map<String, dynamic>>();
      var calls = 0;
      final state = ReportState(() {
        calls++;
        return response.future;
      });
      final first = state.refreshFamilyReport();
      final second = state.refreshFamilyReport();
      expect(calls, 1);
      expect(state.isLoadingFamilyReport, isTrue);
      response.complete(report(125));
      await Future.wait([first, second]);
      expect(state.summaryFor('kid-a').todayMinutes, 2);
      expect(state.familyReportSyncedAt, isNotNull);
      expect(state.isLoadingFamilyReport, isFalse);
      state.dispose();
    },
  );

  test(
    'response from the previous account or locked gate is discarded',
    () async {
      final response = Completer<Map<String, dynamic>>();
      final state = ReportState(() => response.future);
      final pending = state.refreshFamilyReport();
      state.uid = 'parent-b';
      response.complete(report(125));
      await pending;
      expect(state.familyReport, isEmpty);
      state.unlocked = false;
      await state.refreshFamilyReport();
      expect(state.familyReport, isEmpty);
      state.dispose();
    },
  );

  test(
    'failed refresh preserves confirmed data and exposes stale-data notice',
    () async {
      var fail = false;
      final state = ReportState(() async {
        if (fail) throw StateError('unavailable');
        return report(125);
      });
      await state.refreshFamilyReport();
      fail = true;
      await state.refreshFamilyReport();
      expect(state.summaryFor('kid-a').todayMinutes, 2);
      expect(state.familyReportError, isNotNull);
      state.dispose();
    },
  );

  test(
    'completion after provider disposal does not notify or retain report',
    () async {
      final response = Completer<Map<String, dynamic>>();
      final state = ReportState(() => response.future);
      final pending = state.refreshFamilyReport();
      state.dispose();
      response.complete(report(125));
      await pending;
      expect(state.familyReport, isEmpty);
    },
  );

  test('pause is sent after an in-flight active heartbeat, including after failure', () async {
    final pending = Completer<StudySession>();
    final calls = <bool>[];
    final queue = StudyHeartbeatQueue(
      submit: (id, active, view) async {
        calls.add(active);
        if (active) return pending.future;
        return const StudySession({'id': 'session'});
      },
    );
    final active = queue.send('session', true, {});
    final pause = queue.send('session', false, {});
    final rejection = expectLater(active, throwsA(isA<StateError>()));
    await Future<void>.delayed(Duration.zero);
    expect(calls, [true]);
    pending.completeError(StateError('connection lost'));
    await rejection;
    await pause;
    expect(calls, [true, false]);
  });

  testWidgets(
    'parent dashboard fetches on entry, polls, and refreshes after returning',
    (tester) async {
      var calls = 0;
      final state = ReportState(() async {
        calls++;
        return report(calls * 60 + 5);
      });
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: MaterialApp(
            navigatorKey: nav,
            navigatorObservers: [appRouteObserver],
            home: const ParentPortalScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(calls, 1);
      expect(find.text('1 / 45 phút'), findsOneWidget);
      expect(
        find.textContaining('Thời lượng đã xác nhận: 1 phút 5 giây'),
        findsOneWidget,
      );
      expect(find.textContaining('Đang tạm dừng'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();
      expect(calls, 2);
      expect(find.text('2 / 45 phút'), findsOneWidget);
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Other screen')),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 30));
      expect(calls, 2);
      nav.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(calls, 3);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      state.dispose();
    },
  );
}
