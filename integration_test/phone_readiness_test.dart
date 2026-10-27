import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/data/providers/learning_sync_controller.dart';
import 'package:brilliant_mobile/data/repositories/auth_repository.dart';
import 'package:brilliant_mobile/data/repositories/backup_repository.dart';
import 'package:brilliant_mobile/data/repositories/learning_repository.dart';
import 'package:brilliant_mobile/features/account/cloud_account_page.dart';
import 'package:brilliant_mobile/features/account/learning_sync_scope.dart';
import 'package:brilliant_mobile/features/engines/engine_scope.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/data/models/learning_journal.dart';

// Only public answer fixtures are imported; credentials come from an ignored
// local config and must never be passed to the distributable release build.
import '../test/math_experiments_test.dart' show mathSolutionStates;
import '../test/extended_solutions.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  const email = String.fromEnvironment('E2E_EMAIL');
  const password = String.fromEnvironment('E2E_PASSWORD');
  const id = String.fromEnvironment('E2E_ID');

  testWidgets(
    'Android real Auth, UI lesson, verified XP, durable reopen and backup restore',
    (tester) async {
      // Keep the native IME from replaying an older editing value over tester
      // input. Real platform persistence/network remain enabled in this test.
      tester.testTextInput.register();
      expect(
        email.isNotEmpty && password.isNotEmpty && id.isNotEmpty,
        true,
        reason:
            'Use an isolated readiness fixture; do not use a personal account.',
      );
      // Use a separate real SharedPreferences namespace. Existing app profiles and
      // the user's persisted Auth session are never cleared or overwritten.
      SharedPreferences.setPrefix('matlingo.e2e.$id.');
      final preferences = await SharedPreferences.getInstance();
      final client = SupabaseClient(
        url,
        key,
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      await client.auth.signInWithPassword(email: email, password: password);
      expect(
        client.auth.currentUser?.id,
        id,
        reason: 'SDK credential preflight failed',
      );
      await client.auth.signOut(scope: SignOutScope.local);
      final store = LearningStore(preferences, enableServerSync: true);
      final cloud = CloudBackupController(
        store: store,
        auth: SupabaseAuthRepository(client),
        repository: SupabaseBackupRepository(client),
      );
      final repository = SupabaseLearningRepository(
        client: client,
        url: url,
        publishableKey: key,
      );
      final sync = LearningSyncController(
        store: store,
        cloud: cloud,
        repository: repository,
        automatic: false,
      );

      Future<void> waitFor(bool Function() ready, {int seconds = 45}) async {
        final deadline = DateTime.now().add(Duration(seconds: seconds));
        while (!ready() && DateTime.now().isBefore(deadline)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          ready(),
          true,
          reason:
              'App state timeout: signedIn=${cloud.signedIn}, busy=${cloud.busy}, notice=${cloud.message}',
        );
        await tester.pumpAndSettle();
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(
          CloudScope(
            controller: cloud,
            child: LearningSyncScope(
              controller: sync,
              child: EngineHost(child: LearnApp(store: store)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).at(0), email);
        await tester.enterText(
          find.byType(TextFormField).at(1),
          'intentionally-wrong-password',
        );
        await tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await waitFor(() => !cloud.busy);
        expect(cloud.signedIn, false);
        expect(cloud.message, contains('Email hoặc mật khẩu'));
        await tester.enterText(find.byType(TextFormField).at(1), password);
        expect(
          tester
                  .widget<TextFormField>(find.byType(TextFormField).at(1))
                  .controller!
                  .text ==
              password,
          true,
          reason: 'Password editor did not retain the provided test input',
        );
        expect(
          tester
                  .widget<TextFormField>(find.byType(TextFormField).at(0))
                  .controller!
                  .text
                  .trim() ==
              email,
          true,
          reason: 'Email editor changed after the first login attempt',
        );
        await tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
        await waitFor(() => cloud.signedIn && !cloud.busy);
        expect(client.auth.currentUser?.id, id);
        await tester.enterText(
          find.byKey(const ValueKey('entry-name')),
          'APK readiness',
        );
        await tap(find.byKey(const ValueKey('entry-create')));
        await waitFor(() => store.profile != null);
        await tap(find.byKey(const ValueKey('interest-logic')));
        await tap(find.byKey(const ValueKey('onboarding-continue')));
        await tap(find.byKey(const ValueKey('minutes-10')));
        await tap(find.byKey(const ValueKey('onboarding-continue')));
        expect(find.byType(HomeShell), findsOneWidget);
        final topic = topics.first;
        openTopic(tester.element(find.byType(HomeShell)), topic, store);
        await tester.pumpAndSettle();
        // The topic details page retains the existing REA navigation.
        if (find.byType(LessonPage).evaluate().isEmpty) {
          final start = find.text('Vào phòng thí nghiệm');
          await tap(start);
        }
        final solutions = {...mathSolutionStates, ...extendedSolutions};
        for (var i = 0; i < topic.experiments.length; i++) {
          final spec = topic.experiments[i];
          final workspace = tester.widget<ExperimentWorkspace>(
            find.byType(ExperimentWorkspace),
          );
          expect(workspace.spec.id, spec.id);
          workspace.onChanged(solutions[spec.id]!);
          await tester.pumpAndSettle();
          await tap(find.text('Kiểm tra'));
          await tap(
            find.text(
              i == topic.experiments.length - 1
                  ? 'Hoàn thành hành trình'
                  : 'Khám phá tiếp',
            ),
          );
        }
        expect(find.byType(CompletionPage), findsOneWidget);
        expect(store.pendingServerSessions, 1);
        await sync.syncNow();
        await tester.pumpAndSettle();
        expect(store.pendingServerSessions, 0, reason: sync.message);
        expect(store.verifiedPoints, 30, reason: sync.message);
        await sync.syncNow();
        expect(store.verifiedPoints, 30);
        final remoteProfileId =
            learningMap(store.serverSyncFor(store.profile!.id)['profile'])['id']
                as String;
        final remoteProfile = (await repository.profile(id, remoteProfileId))!;
        await repository.mutate(id, learningUuid(), 'profile.update', {
          'id': remoteProfileId,
          'expected_revision': '${remoteProfile['revision']}',
          'name': 'Other device',
          'daily_minutes': 15,
          'interest_topic_ids': ['logic'],
          'onboarded': true,
        });
        await store.rename('Phone choice');
        await sync.syncNow();
        expect(sync.hasProfileConflict, true, reason: 'notice=${sync.message}; pending=${learningMap(learningMap(store.serverSyncFor(store.profile!.id)['profile'])['pending'])['kind']}');
        await tester.pumpAndSettle();
        await tap(find.text('Xử lý thông tin hồ sơ khác nhau'));
        await waitFor(() => find.byType(AlertDialog).evaluate().isNotEmpty);
        await tap(find.text('Dùng bản trên máy'));
        await waitFor(() => !sync.busy && !sync.hasProfileConflict);
        expect(
          (await repository.profile(id, remoteProfileId))!['name'],
          'Phone choice',
        );
        expect(store.verifiedPoints, 30);
        final localId = store.profile!.id;
        await store.flush();
        final reopened = LearningStore(preferences, enableServerSync: true);
        expect(reopened.profile!.id, localId);
        expect(reopened.completed, contains(topic.id));
        expect(reopened.verifiedPoints, 30);
        reopened.dispose();
        await waitFor(() => !cloud.busy);
        await cloud.saveCurrent();
        expect(cloud.conflict, false);
        expect(cloud.backups, isNotEmpty);
        final backup = cloud.backups.first;
        await cloud.restore(backup);
        expect(store.profiles.length, 2);
        await store.activateProfile(store.profiles.last.id);
        await sync.syncNow();
        expect(store.verifiedPoints, 30);
        expect(store.completed, contains(topic.id));
        await cloud.signOut();
        await tester.pumpAndSettle();
        expect(cloud.signedIn, false);
        expect(find.byType(CloudAccountPage), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        sync.dispose();
        cloud.dispose();
        store.dispose();
        repository.dispose();
        await client.dispose();
        // Only keys in the isolated namespace are visible to this instance.
        for (final name in preferences.getKeys()) {
          await preferences.remove(name);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
