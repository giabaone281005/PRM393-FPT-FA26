import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brilliant_mobile/data/engines/engine_contracts.dart';
import 'package:brilliant_mobile/data/models/learning_modules.dart';
import 'package:brilliant_mobile/data/models/learning_journal.dart';
import 'package:brilliant_mobile/data/providers/admin_dashboard_controller.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/data/providers/learning_sync_controller.dart';
import 'package:brilliant_mobile/data/repositories/admin_repository.dart';
import 'package:brilliant_mobile/data/repositories/auth_repository.dart';
import 'package:brilliant_mobile/data/repositories/backup_repository.dart';
import 'package:brilliant_mobile/data/repositories/learning_repository.dart';
import 'package:brilliant_mobile/data/repositories/supabase_tutor_repository.dart';
import 'package:brilliant_mobile/experiments/curriculum_engine.dart';
import 'package:brilliant_mobile/features/account/cloud_account_page.dart';
import 'package:brilliant_mobile/features/account/learning_sync_scope.dart';
import 'package:brilliant_mobile/features/admin/admin_app.dart';
import 'package:brilliant_mobile/features/engines/engine_scope.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';

import '../test/curriculum_solutions.dart';
import '../test/deep_solutions.dart';
import '../test/discovery_experiments_test.dart' show discoverySolutionStates;
import '../test/extended_solutions.dart';
import '../test/math_experiments_test.dart' show mathSolutionStates;

class _ObservedTutor implements AiEngine {
  _ObservedTutor(this.inner, this.replies);
  final AiEngine inner;
  final List<String> replies;
  @override
  Future<TutorReply> respond(TutorRequest request) async {
    final reply = await inner.respond(request);
    replies.add(reply.text);
    return reply;
  }

  @override
  void dispose() => inner.dispose();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const email = String.fromEnvironment('E2E_EMAIL');
  const password = String.fromEnvironment('E2E_PASSWORD');
  const owner = String.fromEnvironment('E2E_ID');
  const adminEmail = String.fromEnvironment('E2E_ADMIN_EMAIL');
  const adminPassword = String.fromEnvironment('E2E_ADMIN_PASSWORD');
  const adminId = String.fromEnvironment('E2E_ADMIN_ID');
  const run = String.fromEnvironment('E2E_RUN');
  const temporaryTopic = String.fromEnvironment('E2E_TOPIC');
  final solutions = {
    ...mathSolutionStates,
    ...discoverySolutionStates,
    ...extendedSolutions,
    ...deepSolutions,
    ...curriculumSolutionStates,
  };

  testWidgets(
    'Headed current mobile UI, real Auth/REST/Edge, account restore and Admin',
    (tester) async {
      tester.testTextInput.register();
      expect(
        run.isNotEmpty && owner.isNotEmpty && adminId.isNotEmpty,
        true,
        reason: 'Use the ignored config for disposable headed fixtures.',
      );
      final report = <String, dynamic>{
        'run': run,
        'phases': <String>[],
        'activities': 0,
        'gestureActivities': 0,
        'answerFixtureActivities': 0,
      };
      final prefixes = [
        'matlingo.headed.$run.device1.',
        'matlingo.headed.$run.device2.',
      ];
      final clients = <SupabaseClient>[];
      final replies = <String>[];
      LearningStore? store;
      CloudBackupController? cloud;
      LearningSyncController? sync;
      SupabaseLearningRepository? learning;
      AdminDashboardController? admin;
      StreamSubscription<dynamic>? realtime;
      String phase = 'initialize';
      AdminDashboardController dashboard() => admin!;
      SupabaseClient newClient() {
        final c = SupabaseClient(
          url,
          key,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        clients.add(c);
        return c;
      }

      var client = newClient();

      Future<void> settle() async {
        await tester.pump(const Duration(milliseconds: 100));
        // Network loading indicators intentionally keep animating. Wait for
        // transitions here; explicit predicates below await real HTTP results.
        for (
          var frame = 0;
          frame < 8 && tester.binding.hasScheduledFrame;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      Future<void> waitFor(bool Function() ready, {int seconds = 60}) async {
        final until = DateTime.now().add(Duration(seconds: seconds));
        while (!ready() && DateTime.now().isBefore(until)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          ready(),
          true,
          reason:
              'Timeout in $phase; cloud=${cloud?.message}; sync=${sync?.message}; admin=${admin?.message}',
        );
        await settle();
      }

      Future<Map<String, dynamic>> readProgress() async {
        for (var attempt = 0; attempt < 4; attempt++) {
          try {
            final row = await client
                .rpc('load_account_progress', params: {'expected_owner': owner})
                .timeout(const Duration(seconds: 15));
            return Map<String, dynamic>.from(row as Map);
          } on PostgrestException {
            rethrow;
          } catch (_) {
            if (attempt == 3) rethrow;
            debugPrint('HEADED_TRANSPORT_RETRY account_read ${attempt + 1}');
            await tester.pump(Duration(seconds: 2 * (attempt + 1)));
          }
        }
        throw StateError('Progress read did not finish');
      }

      Future<void> reveal(Finder finder, {bool upward = false}) async {
        for (var i = 0; i < 30 && finder.evaluate().isEmpty; i++) {
          expect(
            find.byType(Scrollable).evaluate().isNotEmpty,
            true,
            reason: 'Cannot reveal $finder in $phase',
          );
          await tester.drag(
            find.byType(Scrollable).last,
            Offset(0, upward ? 420 : -420),
          );
          await settle();
        }
        expect(
          finder.evaluate().isNotEmpty,
          true,
          reason: 'Missing control in $phase: $finder',
        );
        await tester.ensureVisible(finder.first);
        await settle();
      }

      Future<void> tap(Finder finder, {bool upward = false}) async {
        await reveal(finder, upward: upward);
        await tester.tap(finder.first);
        await settle();
      }

      Future<void> keyTap(String name, {bool upward = false}) =>
          tap(find.byKey(ValueKey(name)), upward: upward);
      Future<void> type(
        String name,
        String value, {
        bool upward = false,
      }) async {
        final finder = find.byKey(ValueKey(name));
        await reveal(finder, upward: upward);
        await tester.enterText(finder, value);
        await settle();
      }

      void passed(String name) {
        (report['phases'] as List).add(name);
        debugPrint('HEADED_PASS $name');
      }

      Future<void> mountLearner(int device) async {
        SharedPreferences.resetStatic();
        SharedPreferences.setPrefix(prefixes[device]);
        final preferences = await SharedPreferences.getInstance();
        store = LearningStore(preferences, enableServerSync: true);
        cloud = CloudBackupController(
          store: store!,
          auth: SupabaseAuthRepository(client),
          repository: SupabaseAccountProgressRepository(client),
          singleProfile: true,
        );
        learning = SupabaseLearningRepository(
          client: client,
          url: url,
          publishableKey: key,
        );
        sync = LearningSyncController(
          store: store!,
          cloud: cloud!,
          repository: learning!,
        );
        await tester.pumpWidget(
          CloudScope(
            controller: cloud!,
            child: LearningSyncScope(
              controller: sync!,
              child: EngineHost(
                createDefaultTutor: (id) => _ObservedTutor(
                  SupabaseTutorRepository(
                    client: client,
                    url: url,
                    publishableKey: key,
                    owner: id,
                  ),
                  replies,
                ),
                child: LearnApp(store: store!),
              ),
            ),
          ),
        );
        await settle();
      }

      Future<void> unmountLearner() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await settle();
        sync?.dispose();
        cloud?.dispose();
        await store?.flush();
        store?.dispose();
        learning?.dispose();
        sync = null;
        cloud = null;
        store = null;
        learning = null;
      }

      Future<void> login({bool wrong = false}) async {
        await type('cloud-email', email);
        if (wrong) {
          await type('cloud-password', 'deliberately-wrong-password');
          await keyTap('cloud-auth-submit');
          await waitFor(() => !cloud!.busy);
          expect(cloud!.signedIn, false);
          expect(cloud!.message, contains('Email hoặc mật khẩu'));
          passed('wrong_password_rejected');
        }
        await type('cloud-password', password);
        await keyTap('cloud-auth-submit');
        await waitFor(
          () =>
              cloud!.signedIn &&
              cloud!.accountLoaded &&
              !cloud!.preparingProfile &&
              !cloud!.busy,
        );
        expect(
          client.auth.currentUser?.id == owner,
          true,
          reason: 'Wrong fixture identity',
        );
      }

      Future<void> openLesson(LearningTopic topic) async {
        await tap(find.text('Chủ đề').last);
        await type('topic-search', topic.id, upward: true);
        await keyTap('topic-${topic.id}');
        final buttons = [
          'Tiếp tục phiên học',
          'Khám phá lại',
          'Khám phá bài mới',
          'Vào phòng thí nghiệm',
        ];
        final text = buttons.firstWhere(
          (v) => find.text(v).evaluate().isNotEmpty,
        );
        await tap(find.text(text));
        expect(find.byType(LessonPage), findsOneWidget);
      }

      ExperimentWorkspace workspace() =>
          tester.widget<ExperimentWorkspace>(find.byType(ExperimentWorkspace));
      Future<void> solveCurrent(int step, LearningTopic topic) async {
        final s = topic.experiments[step];
        final answer = solutions[s.id]!;
        var gesture = true;
        if (topic.id == 'logic' && step < 6) {
          switch (step) {
            case 0:
              await keyTap('balance-drop');
              await tap(find.text('Kiểm tra'));
              expect(find.text('Thử thêm một cách nhé'), findsOneWidget);
              await tap(find.text('Gợi ý nhỏ'));
              for (var n = 0; n < 3; n++) {
                await keyTap('balance-drop');
              }
            case 1:
              await reveal(find.byKey(const ValueKey('remove-swipe')));
              await tester.drag(
                find.byKey(const ValueKey('remove-swipe')),
                const Offset(140, 0),
              );
              await settle();
              for (var n = 0; n < 2; n++) {
                await keyTap('remove-pair');
              }
            case 2:
              await keyTap('gear-forward');
              await keyTap('gear-forward');
            case 3:
              for (var n = 0; n < 5; n++) {
                await keyTap('remove-pair');
              }
            case 4:
              for (var n = 0; n < 5; n++) {
                await keyTap('balance-drop');
              }
            case 5:
              await keyTap('condition-a');
          }
        } else if (s.mechanism == 'reasonedChoice') {
          await keyTap('answer-${answer['answer']}');
          await keyTap('reason-${answer['reason']}');
        } else if (supportsCurriculum(s.mechanism)) {
          switch (s.mechanism) {
            case 'matchPairs':
            case 'categorySort':
            case 'clozeBank':
              for (final (i, j) in (answer['values'] as List).indexed) {
                await keyTap('connect-$i-$j');
              }
            case 'sequenceTiles':
              for (final (i, wanted) in (answer['values'] as List).indexed) {
                var at = (workspace().data['values'] as List).indexOf(wanted);
                while (at > i) {
                  await keyTap('move-up-$at');
                  at--;
                }
              }
            case 'evidenceBoard':
              for (final i in answer['selected'] as List) {
                await keyTap('evidence-$i');
              }
            case 'resourceBudget':
              for (final (i, count) in (answer['values'] as List).indexed) {
                for (var n = 0; n < (count as int); n++) {
                  await keyTap('budget-plus-$i');
                }
              }
            case 'causalExperiment':
              for (final axis in ['x', 'y']) {
                final f = find.byKey(ValueKey('lab-$axis'));
                await reveal(f);
                final rect = tester.getRect(f);
                final fraction = (answer[axis] as int) / 3;
                await tester.tapAt(
                  Offset(
                    rect.left + 24 + (rect.width - 48) * fraction,
                    rect.center.dy,
                  ),
                );
                await settle();
                expect(
                  workspace().data[axis],
                  answer[axis],
                  reason: 'Native slider $axis',
                );
              }
              await tap(
                find.widgetWithText(ChoiceChip, '${answer['prediction']}'),
              );
              await keyTap('run-lab');
            case 'listeningChoice':
              if (report['tts_request'] == null) {
                await keyTap('language-play');
                report['tts_request'] = workspace().data['experienced'] == true
                    ? 'completed'
                    : 'fallback_required';
              }
              await keyTap('language-transcript');
              await keyTap('listen-answer-${answer['answer']}');
            case 'speechPractice':
              if (report['microphone_request'] == null) {
                await keyTap('language-record');
                await tester.pump(const Duration(seconds: 2));
                if (find.text('Dừng âm thanh').evaluate().isNotEmpty) {
                  await tap(find.text('Dừng âm thanh'));
                  report['microphone_request'] = 'requested_and_stopped';
                } else {
                  report['microphone_request'] = 'unavailable_or_finished';
                }
              }
              await type('language-response', answer['response'] as String);
          }
        } else {
          // Existing 47 model controls have independent gesture/unit tests. This
          // traversal uses public solution fixtures through the workspace callback
          // to exercise native rendering/check/save/complete for every activity.
          gesture = false;
          workspace().onChanged(answer);
          await settle();
        }
        expect(s.isCorrect(workspace().data), true, reason: 'Unsolved ${s.id}');
        await tap(find.text('Kiểm tra'));
        expect(find.text('Bạn đã tìm ra!'), findsOneWidget, reason: s.id);
        report['activities'] = (report['activities'] as int) + 1;
        final counter = gesture
            ? 'gestureActivities'
            : 'answerFixtureActivities';
        report[counter] = (report[counter] as int) + 1;
        await tap(
          find.text(
            step == topic.experiments.length - 1
                ? 'Hoàn thành hành trình'
                : 'Khám phá tiếp',
          ),
        );
      }

      try {
        await mountLearner(0);
        phase = 'auth_onboarding';
        await keyTap('cloud-auth-submit');
        expect(cloud!.signedIn, false);
        await login(wrong: true);
        await type('entry-name', 'Headed Learner');
        await keyTap('entry-create');
        await waitFor(() => store!.profile != null);
        await keyTap('interest-logic');
        await keyTap('onboarding-continue');
        await keyTap('minutes-10');
        await keyTap('onboarding-continue');
        await waitFor(() => find.byType(HomeShell).evaluate().isNotEmpty);
        expect(store!.profiles.length, 1);
        passed('auth_single_profile_onboarding');

        phase = 'real_tutor';
        await type('chat-input', 'App có bao nhiêu chủ đề?');
        await keyTap('chat-send');
        await waitFor(() => replies.isNotEmpty, seconds: 70);
        expect(replies.first, contains('20 chủ đề'));
        await type(
          'chat-input',
          'Giải thích vì sao một nửa bằng hai phần tư bằng một ví dụ ngắn.',
        );
        await keyTap('chat-send');
        await waitFor(() => replies.length == 2, seconds: 90);
        expect(replies.last.trim().length, greaterThan(15));
        passed('live_faq_and_gemini');

        phase = 'settings';
        await keyTap('app-settings');
        await keyTap('menu-appearance');
        await keyTap('accent-blue');
        await keyTap('text-size-1.15');
        await keyTap('reduce-motion');
        await tester.binding.handlePopRoute();
        await settle();
        passed('appearance_settings');

        for (final topic in topics) {
          phase = 'topic_${topic.id}';
          debugPrint('HEADED_TOPIC ${topic.id} ${topic.experiments.length}');
          await openLesson(topic);
          for (var step = 0; step < topic.experiments.length; step++) {
            await solveCurrent(step, topic);
          }
          expect(find.byType(CompletionPage), findsOneWidget);
          expect(store!.completed, contains(topic.id));
          await tap(find.text('Về trang chủ'));
          await waitFor(() => !cloud!.busy, seconds: 35);
          // Await an automatic save rather than adding a manual-sync UI action.
          await tester.pump(const Duration(seconds: 3));
          await waitFor(() => !cloud!.busy, seconds: 35);
          var completed = learningMap(
            learningMap(
              learningMap((await readProgress())['payload'])['learning'],
            )['completed'],
          );
          final saveDeadline = DateTime.now().add(const Duration(seconds: 40));
          while (!completed.containsKey(topic.id) &&
              DateTime.now().isBefore(saveDeadline)) {
            await tester.pump(const Duration(seconds: 2));
            completed = learningMap(
              learningMap(
                learningMap((await readProgress())['payload'])['learning'],
              )['completed'],
            );
          }
          expect(
            completed.containsKey(topic.id),
            true,
            reason: 'Automatic server save ${topic.id}',
          );
          passed('topic_${topic.id}');
        }
        expect(report['activities'], 139);
        expect(store!.points, 600);
        expect(store!.completed.length, 20);
        await waitFor(() => !cloud!.busy);
        await cloud!.saveCurrent(); // Backend assertion barrier; automatic UI saving is tested above.
        final remote = await readProgress();
        final payload = learningMap(remote['payload']);
        expect(
          learningMap(learningMap(payload['learning'])['completed']).length,
          20,
        );
        final revision = (remote['revision'] as num).toInt();
        final retry = Map<String, dynamic>.from(
          await client.rpc(
            'save_account_progress',
            params: {
              'expected_owner': owner,
              'expected_revision': revision,
              'backup_payload': payload,
            },
          ) as Map,
        );
        expect(retry['revision'], remote['revision']);
        var conflictDenied = false;
        try {
          await client.rpc(
            'save_account_progress',
            params: {
              'expected_owner': owner,
              'expected_revision': revision - 1,
              'backup_payload': {
                ...payload,
                'profile': {
                  ...learningMap(payload['profile']),
                  'name': 'Stale fixture write',
                },
              },
            },
          );
        } on PostgrestException catch (e) {
          conflictDenied = e.code == 'PT409';
        }
        expect(conflictDenied, true);
        passed('account_snapshot_retry_and_conflict');

        phase = 'canonical_verified_xp';
        await sync!.syncNow();
        await waitFor(() => store!.verifiedPoints == 600, seconds: 180);
        final remoteProfile =
            learningMap(
                  store!.serverSyncFor(store!.profile!.id)['profile'],
                )['id']
                as String;
        final catalog = await learning!.catalog(owner);
        final release = learningMap(catalog['release'])['id'];
        final sessionId = learningUuid();
        await learning!.mutate(owner, learningUuid(), 'session.start', {
          'id': sessionId,
          'profile_id': remoteProfile,
          'topic_id': 'logic',
          'release_id': release,
          'started_at': DateTime.now().toUtc().toIso8601String(),
        });
        for (final s in topicById('logic').experiments) {
          final result = await learning!.attempt(owner, learningUuid(), {
            'session_id': sessionId,
            'activity_id': s.id,
            'content_version': s.contentVersion,
            'state': solutions[s.id],
            'hint_level': 0,
          });
          expect(
            learningMap(
              learningMap(result['result'])['attempt'],
            )['evaluation_status'],
            'verified',
          );
        }
        final completeId = learningUuid();
        final completion = await learning!.mutate(
          owner,
          completeId,
          'session.complete',
          {'session_id': sessionId},
        );
        // All topics were already verified by automatic sync during traversal.
        // A second complete session must not award the topic reward again.
        expect(learningMap(completion['result'])['xp_awarded'], 0);
        final completionRetry = await learning!.mutate(
          owner,
          completeId,
          'session.complete',
          {'session_id': sessionId},
        );
        expect(completionRetry, completion);
        await sync!.syncNow();
        expect(store!.verifiedPoints, 600);
        passed('real_canonical_attempts_verified_xp_idempotency');

        phase = 'offline_save_retry';
        await openLesson(topicById('english'));
        debugPrint('HEADED_NETWORK_OFF');
        await tester.pump(const Duration(seconds: 3));
        await keyTap('connect-0-2');
        await tester.pump(const Duration(seconds: 3));
        await waitFor(
          () =>
              !cloud!.busy &&
              cloud!.message != null &&
              cloud!.noticeKind.name == 'error',
          seconds: 40,
        );
        expect(store!.progress('english'), isNotNull);
        debugPrint('HEADED_NETWORK_ON');
        await tester.pump(const Duration(seconds: 4));
        await waitFor(
          () => !cloud!.busy && cloud!.noticeKind.name == 'success',
          seconds: 75,
        );
        final offlineSaved = await readProgress();
        final savedLearning = learningMap(
          learningMap(offlineSaved['payload'])['learning'],
        );
        final savedEnglish = learningMap(
          learningMap(savedLearning['drafts'])['english'],
        );
        expect(
          (learningMap(savedEnglish['states'])['english-greetings']
              as Map)['values'],
          [2, -1, -1],
        );
        passed('offline_draft_then_automatic_server_retry');
        await tester.binding.handlePopRoute();
        await settle();
        if (find.byType(HomeShell).evaluate().isEmpty) {
          await tester.binding.handlePopRoute();
          await settle();
        }
        await tap(find.text('Hồ sơ').last);
        expect(store!.history.length, 20);
        passed('profile_history');
        await keyTap('app-settings');
        await keyTap('menu-logout');
        await waitFor(
          () =>
              !cloud!.signedIn &&
              find.byType(CloudAccountPage).evaluate().isNotEmpty,
        );
        passed('logout');

        phase = 'fresh_device_restore';
        await unmountLearner();
        await client.dispose();
        clients.remove(client);
        client = newClient();
        await mountLearner(1);
        expect(store!.profiles, isEmpty);
        await login();
        await waitFor(() => find.byType(HomeShell).evaluate().isNotEmpty);
        expect(store!.profiles.length, 1);
        expect(store!.points, 600);
        expect(store!.completed.length, 20);
        await openLesson(topicById('english'));
        expect(workspace().spec.id, 'english-greetings');
        expect(workspace().data['values'], [2, -1, -1]);
        passed('fresh_native_namespace_login_restores_server_progress');
        var crossOwnerDenied = false, adminDenied = false;
        try {
          await client.rpc(
            'load_account_progress',
            params: {'expected_owner': adminId},
          );
        } on PostgrestException catch (e) {
          crossOwnerDenied = e.code == '42501';
        }
        try {
          await client.rpc(
            'admin_dashboard_read',
            params: {'section': 'overview'},
          );
        } on PostgrestException catch (e) {
          adminDenied = e.code == '42501';
        }
        expect(crossOwnerDenied && adminDenied, true);
        passed('owner_isolation_and_admin_rpc_denial');
        await unmountLearner();

        phase = 'admin';
        final adminClient = newClient();
        admin = AdminDashboardController(
          auth: SupabaseAuthRepository(adminClient),
          repository: SupabaseAdminRepository(adminClient),
          pollInterval: const Duration(days: 1),
        );
        await tester.pumpWidget(AdminApp(controller: dashboard()));
        await settle();
        await type('admin-email', adminEmail);
        await type('admin-password', adminPassword);
        await tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await waitFor(
          () => dashboard().allowed && !dashboard().loading && dashboard().live,
        );
        var events = 0;
        realtime = SupabaseAdminRepository(adminClient)
            .watch(adminId)
            .listen((e) {
              if (e.changed) events++;
            });
        await tester.pump(const Duration(seconds: 2));
        final initialEvents = events;
        await type('admin-search-accounts', email);
        await waitFor(
          () =>
              !dashboard().loading &&
              dashboard().accounts.length == 1 &&
              dashboard().accounts.first.id == owner,
        );
        await tap(find.text('Tạm khóa').last);
        await tap(find.text('Xác nhận'));
        await waitFor(
          () =>
              !dashboard().busy &&
              dashboard().accounts.single.status == 'suspended',
        );
        var suspensionDenied = false;
        try {
          await client.rpc(
            'load_account_progress',
            params: {'expected_owner': owner},
          );
        } on PostgrestException catch (e) {
          suspensionDenied = e.code == '42501';
        }
        expect(suspensionDenied, true);
        await tap(find.text('Mở lại'));
        await tap(find.text('Xác nhận'));
        await waitFor(
          () =>
              !dashboard().busy &&
              dashboard().accounts.single.status == 'active',
        );
        await client.rpc(
          'load_account_progress',
          params: {'expected_owner': owner},
        );
        await waitFor(() => events > initialEvents);
        passed('admin_suspend_restore_and_real_database_broadcast');
        await tap(find.text('Chủ đề').last);
        await keyTap('admin-add-topic');
        await type('topic-id', temporaryTopic);
        await type('topic-title', 'Headed E2E $run');
        await type('topic-subject', 'Kiểm thử');
        await tap(find.text('Lưu chủ đề'));
        await waitFor(() => !dashboard().busy && !dashboard().loading);
        await type('admin-search-topics', temporaryTopic);
        await waitFor(
          () =>
              !dashboard().loading &&
              dashboard().topics.length == 1 &&
              dashboard().topics.first.id == temporaryTopic,
        );
        await tap(find.byTooltip('Sửa ${dashboard().topics.single.title}'));
        await type('topic-title', 'Headed E2E updated $run');
        await tap(find.byType(DropdownButtonFormField<String>));
        await tap(find.text('Lưu trữ').last);
        await tap(find.text('Lưu chủ đề'));
        await waitFor(
          () =>
              !dashboard().busy &&
              !dashboard().loading &&
              dashboard().topics.single.status == 'archived',
        );
        expect(
          dashboard().topics.single.title,
          startsWith('Headed E2E updated'),
        );
        passed('admin_topic_create_edit_archive');
        await realtime.cancel();
        realtime = null;
        dashboard().dispose();
        admin = null;
        final deniedController = AdminDashboardController(
          auth: SupabaseAuthRepository(client),
          repository: SupabaseAdminRepository(client),
        );
        admin = deniedController;
        await tester.pumpWidget(AdminApp(controller: dashboard()));
        await waitFor(() => !dashboard().loading);
        expect(find.text('Tài khoản chưa có quyền quản trị'), findsOneWidget);
        passed('learner_admin_ui_gate');
        report['success'] = true;
        expect(tester.takeException(), isNull);
      } catch (e) {
        report['success'] = false;
        report['failedPhase'] = phase;
        rethrow;
      } finally {
        debugPrint('HEADED_NETWORK_ON');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await realtime?.cancel();
        admin?.dispose();
        if (store != null) {
          await unmountLearner();
        }
        for (final c in clients) {
          try {
            await c.auth.signOut(scope: SignOutScope.local);
          } catch (_) {}
          await c.dispose();
        }
        for (final prefix in prefixes) {
          SharedPreferences.resetStatic();
          SharedPreferences.setPrefix(prefix);
          final p = await SharedPreferences.getInstance();
          for (final name in p.getKeys().toList()) {
            await p.remove(name);
          }
        }
        binding.reportData = report;
        debugPrint('HEADED_RESULT ${jsonEncode(report)}');
      }
    },
    timeout: const Timeout(Duration(minutes: 25)),
  );
}
