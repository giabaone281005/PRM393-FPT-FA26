import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:brilliant_mobile/data/models/app_failure.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/models/cloud_backup.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/data/repositories/auth_repository.dart';
import 'package:brilliant_mobile/data/repositories/backup_repository.dart';
import 'package:brilliant_mobile/features/account/cloud_account_page.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/entry_flow.dart';

class _Auth implements AuthRepository {
  final events = StreamController<String?>.broadcast(sync: true);
  String? owner;
  AuthException? verifyError;
  AuthException? resendError;
  AuthException? signInError;
  Completer<void>? authDelay;
  int signIns = 0, signUps = 0;
  bool requireConfirmation = false;
  int resends = 0;
  final verified = <(String, String)>[];
  @override
  String? get userId => owner;
  @override
  String? get email => owner == null ? null : 'learner@example.test';
  @override
  Stream<String?> get changes => events.stream;
  @override
  Future<void> signIn(String email, String password) async {
    signIns++;
    if (authDelay != null) await authDelay!.future;
    if (signInError != null) throw signInError!;
    if (requireConfirmation) {
      throw const AuthException(
        'Email not confirmed',
        code: 'email_not_confirmed',
      );
    }
    owner = 'user-a';
    events.add(owner);
  }

  @override
  Future<bool> signUp(String email, String password) async {
    signUps++;
    if (authDelay != null) await authDelay!.future;
    return false;
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    if (verifyError != null) throw verifyError!;
    verified.add((email, code));
    owner = 'user-a';
    events.add(owner);
  }

  @override
  Future<void> resendConfirmation(String email) async {
    resends++;
    if (resendError != null) throw resendError!;
  }

  @override
  Future<void> signOut() async {
    owner = null;
    events.add(null);
  }
}

class _Backups implements BackupRepository {
  final rows = <String, Map<String, CloudBackup>>{};
  bool offline = false;
  Completer<void>? delay;
  int writes = 0;
  @override
  Future<List<CloudBackup>> list(String owner) async => [
    ...?rows[owner]?.values,
  ];
  @override
  Future<CloudBackup> save(
    String owner,
    String key,
    int revision,
    Map<String, dynamic> payload,
  ) async {
    if (delay != null) await delay!.future;
    if (offline) throw http.ClientException('connection unavailable');
    final current = rows[owner]?[key];
    if (current != null && jsonEncode(current.payload) == jsonEncode(payload)) {
      return current;
    }
    if ((current?.revision ?? 0) != revision) throw const BackupConflict();
    final backup = CloudBackup(
      key: key,
      revision: revision + 1,
      payload: jsonDecode(jsonEncode(payload)) as Map<String, dynamic>,
      updatedAt: DateTime.utc(2026, 10, 26),
    );
    (rows[owner] ??= {})[key] = backup;
    writes++;
    return backup;
  }
}

void main() {
  late LearningStore store;
  late _Auth auth;
  late _Backups remote;
  late CloudBackupController cloud;
  late DateTime now;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LearningStore(await SharedPreferences.getInstance());
    await store.createDeviceProfile('An');
    await store.finishOnboarding(['logic'], 10);
    auth = _Auth();
    remote = _Backups();
    now = DateTime.utc(2026, 10, 26);
    cloud = CloudBackupController(
      store: store,
      auth: auth,
      repository: remote,
      clock: () => now,
    );
  });
  tearDown(() async {
    cloud.dispose();
    store.dispose();
    await auth.events.close();
  });

  Future<void> loadAuthFonts() async {
    for (final family in ['CofoBrilliant', 'NotoSans']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    await (FontLoader(
      'CofoRobert',
    )..addFont(rootBundle.load('assets/fonts/CofoRobert-Medium.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  }

  testWidgets(
    'invalid auth form reveals the first error and keyboard Next reaches password',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: CloudAccountPage(controller: cloud),
        ),
      );
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('cloud-auth-submit'));
      await tester.scrollUntilVisible(
        submit,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submit);
      await tester.pumpAndSettle();
      final email = find.byKey(const ValueKey('cloud-email'));
      final password = find.byKey(const ValueKey('cloud-password'));
      EditableText editable(Finder field) => tester.widget<EditableText>(
        find.descendant(of: field, matching: find.byType(EditableText)),
      );
      expect(editable(email).focusNode.hasFocus, isTrue);
      expect(tester.getRect(email).top, greaterThanOrEqualTo(64));
      await tester.enterText(email, 'learner@example.test');
      await tester.pumpAndSettle();
      expect(find.text('Nhập email hợp lệ.'), findsNothing);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(editable(password).focusNode.hasFocus, isTrue);
      await tester.enterText(password, 'test-password');
      auth.signInError = const AuthException(
        'private',
        code: 'invalid_credentials',
      );
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      final notice = find.textContaining('Email hoặc mật khẩu chưa đúng');
      expect(notice, findsOneWidget);
      expect(
        tester.getRect(notice).bottom,
        lessThan(tester.getRect(submit).top),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'login and registration have distinct headings and reset stale field errors',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: CloudAccountPage(controller: cloud),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chào bạn trở lại.'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('cloud-auth-submit')),
      );
      await tester.tap(find.byKey(const ValueKey('cloud-auth-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('cloud-email')),
        'learner@example.test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('cloud-password')),
        'old-password',
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('cloud-mode-register')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('cloud-mode-register')));
      await tester.pumpAndSettle();
      expect(find.text('Tạo tài khoản mới.'), findsOneWidget);
      expect(find.text('Chào bạn trở lại.'), findsNothing);
      expect(find.text('Dùng ít nhất 8 ký tự.'), findsOneWidget);
      expect(find.text('Nhập email hợp lệ.'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('cloud-email')))
            .controller!
            .text,
        'learner@example.test',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('cloud-password')))
            .controller!
            .text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final register in [false, true]) {
    testWidgets(
      '${register ? 'registration' : 'login'} shows animated pending state, blocks mode switches and recovers',
      (tester) async {
        await loadAuthFonts();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 1100);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.4)),
                child: child!,
              ),
              home: CloudAccountPage(controller: cloud),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (register) {
          await tester.tap(find.byKey(const ValueKey('cloud-mode-register')));
          await tester.pumpAndSettle();
        }
        Future<void> preview(String suffix) async {
          await tester.runAsync(() async {
            final render =
                boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
              'build/auth-${register ? 'register' : 'login'}$suffix.png',
            ).writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }

        await preview('');
        auth.authDelay = Completer<void>();
        if (!register) {
          auth.signInError = const AuthException(
            'private error',
            code: 'invalid_credentials',
          );
        }
        await tester.enterText(
          find.byKey(const ValueKey('cloud-email')),
          'learner@example.test',
        );
        await tester.enterText(
          find.byKey(const ValueKey('cloud-password')),
          'test-password',
        );
        final button = find.byKey(const ValueKey('cloud-auth-submit'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          find.text(register ? 'Đang tạo tài khoản…' : 'Đang đăng nhập…'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('cloud-auth-loading')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .value,
          isNull,
        );
        expect(tester.binding.hasScheduledFrame, isTrue);
        expect(tester.widget<FilledButton>(button).onPressed, isNull);
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const ValueKey('cloud-mode-register')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextButton>(
                find.byKey(const ValueKey('cloud-mode-login')),
              )
              .onPressed,
          isNull,
        );
        expect(
          tester
              .widget<TextFormField>(find.byKey(const ValueKey('cloud-email')))
              .enabled,
          isFalse,
        );
        await tester.tap(button);
        expect(register ? auth.signUps : auth.signIns, 1);
        await tester.pump();
        await preview('-loading');
        expect(tester.takeException(), isNull);
        auth.authDelay!.complete();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('cloud-auth-loading')), findsNothing);
        if (register) {
          expect(find.byKey(const ValueKey('cloud-otp')), findsOneWidget);
          expect(find.text('Xác nhận email'), findsOneWidget);
        } else {
          expect(
            find.textContaining('Email hoặc mật khẩu chưa đúng'),
            findsOneWidget,
          );
          expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
          await tester.ensureVisible(
            find.byKey(const ValueKey('cloud-mode-register')),
          );
          await tester.tap(find.byKey(const ValueKey('cloud-mode-register')));
          await tester.pumpAndSettle();
          expect(
            find.textContaining('Email hoặc mật khẩu chưa đúng'),
            findsNothing,
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets(
    'reduced motion keeps pending state readable without a looping animation',
    (tester) async {
      auth.authDelay = Completer<void>();
      auth.signInError = const AuthException(
        'private',
        code: 'invalid_credentials',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: CloudAccountPage(controller: cloud),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('cloud-email')),
        'learner@example.test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('cloud-password')),
        'test-password',
      );
      final button = find.byKey(const ValueKey('cloud-auth-submit'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.text('Đang đăng nhập…'), findsOneWidget);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .value,
        .65,
      );
      auth.authDelay!.complete();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('registration opens verification without claiming an authenticated session or backup', () async {
    await cloud.signIn(' learner@example.test ', 'password', register: true);
    expect(cloud.verificationEmail, 'learner@example.test');
    expect(cloud.signedIn, isFalse);
    expect(remote.writes, 0);
    expect(cloud.resendSecondsRemaining, 60);
    expect(cloud.noticeKind, NoticeKind.info);
  });

  test('expired code remains retryable and a valid code signs in and automatically saves', () async {
    cloud.beginEmailVerification('learner@example.test');
    await cloud.verifyEmailCode('123');
    expect(auth.verified, isEmpty);
    auth.verifyError = const AuthException(
      'private provider diagnostic',
      code: 'otp_expired',
    );
    await cloud.verifyEmailCode('00123456');
    expect(cloud.signedIn, isFalse);
    expect(cloud.verificationEmail, 'learner@example.test');
    expect(cloud.noticeKind, NoticeKind.error);
    expect(cloud.message, contains('hết hạn'));
    expect(cloud.message, isNot(contains('private provider')));
    auth.verifyError = null;
    await cloud.verifyEmailCode('00123456');
    expect(auth.verified.single, ('learner@example.test', '00123456'));
    expect(cloud.signedIn, isTrue);
    expect(cloud.verificationEmail, isNull);
    expect(remote.writes, 1);
    expect(cloud.noticeKind, NoticeKind.success);
  });

  test('resend respects cooldown on success and server rate limit', () async {
    await cloud.signIn('learner@example.test', 'password', register: true);
    await cloud.resendConfirmation();
    expect(auth.resends, 0);
    now = now.add(const Duration(seconds: 61));
    await cloud.resendConfirmation();
    expect(auth.resends, 1);
    expect(cloud.noticeKind, NoticeKind.success);
    await cloud.resendConfirmation();
    expect(auth.resends, 1);
    now = now.add(const Duration(seconds: 61));
    auth.resendError = const AuthException(
      'private limit',
      code: 'over_email_send_rate_limit',
    );
    await cloud.resendConfirmation();
    expect(auth.resends, 2);
    expect(cloud.noticeKind, NoticeKind.error);
    expect(cloud.message, contains('giới hạn gửi email'));
    expect(cloud.resendSecondsRemaining, 60);
  });

  test(
    'unsupported backup explains compatibility without changing local profiles',
    () async {
      await cloud.signIn('learner@example.test', 'password');
      final before = store.profiles.length;
      await cloud.restore(
        CloudBackup(
          key: 'invalid',
          revision: 1,
          updatedAt: now,
          payload: {
            'version': 999,
            'profile': <String, dynamic>{},
            'learning': <String, dynamic>{},
          },
        ),
      );
      expect(store.profiles.length, before);
      expect(cloud.noticeKind, NoticeKind.error);
      expect(cloud.message, contains('Định dạng bản sao lưu'));
      expect(cloud.message, isNot(contains('mạng')));
    },
  );

  test(
    'unconfirmed login offers code entry while cancel preserves local learning',
    () async {
      auth.requireConfirmation = true;
      await store.saveProgress('logic', {'step': 2});
      await cloud.signIn('learner@example.test', 'password');
      expect(cloud.verificationEmail, 'learner@example.test');
      expect(cloud.message, contains('chưa được xác nhận'));
      cloud.cancelEmailVerification();
      expect(cloud.verificationEmail, isNull);
      expect(store.progress('logic')!['step'], 2);
      expect(remote.writes, 0);
    },
  );

  test(
    'login automatically backs up current profile and isolates account changes',
    () async {
      await cloud.signIn('a@example.test', 'password');
      expect(remote.writes, 1);
      expect(cloud.currentBinding, isNotNull);
      auth.owner = 'user-b';
      auth.events.add('user-b');
      expect(cloud.currentBinding, isNull);
      await cloud.saveCurrent(automatic: true);
      expect(remote.rows['user-b'], isNull);
      expect(cloud.profiles, isEmpty);
    },
  );

  test('first offline save claims the profile for its account', () async {
    remote.offline = true;
    await cloud.signIn('a@example.test', 'password');
    final id = store.profile!.id;
    expect(cloud.currentBinding?['owner'], 'user-a');
    expect(remote.writes, 0);
    auth.owner = 'user-b';
    auth.events.add('user-b');
    await Future<void>.delayed(Duration.zero);
    expect(cloud.canUseProfile(id), isFalse);
    remote.offline = false;
    await store.activateProfile(id);
    await cloud.saveCurrent();
    expect(remote.rows['user-b'], isNull);
  });

  test(
    'profile created after login automatically saves without a manual link',
    () async {
      await store.signOut();
      await cloud.signIn('a@example.test', 'password');
      expect(remote.writes, 0);
      await store.createDeviceProfile('Bình');
      await store.finishOnboarding(['math'], 5);
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(remote.writes, 1);
      expect(cloud.backups.single.name, 'Bình');
      expect(cloud.currentBinding, isNotNull);
    },
  );

  test(
    'changes made during an upload are automatically saved afterward',
    () async {
      await cloud.signIn('a@example.test', 'password');
      remote.delay = Completer<void>();
      await store.saveProgress('logic', {'step': 1});
      final save = cloud.saveCurrent();
      await Future<void>.delayed(Duration.zero);
      await store.saveProgress('logic', {'step': 2});
      remote.delay!.complete();
      await save;
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(
        (cloud.backups.single.payload['learning']
            as Map)['drafts']['logic']['step'],
        2,
      );
    },
  );

  testWidgets('fresh configured install opens login before profile creation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final freshStore = LearningStore(await SharedPreferences.getInstance());
    final freshCloud = CloudBackupController(
      store: freshStore,
      auth: auth,
      repository: remote,
    );
    try {
      await tester.pumpWidget(
        CloudScope(
          controller: freshCloud,
          child: LearnApp(store: freshStore),
        ),
      );
      await tester.pumpAndSettle();
      expect(freshStore.profiles, isEmpty);
      expect(find.byType(CloudAccountPage), findsOneWidget);
      expect(find.byType(EntryPage), findsNothing);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.text('Đăng ký'), findsOneWidget);
      expect(find.byKey(const ValueKey('entry-create')), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox());
      freshCloud.dispose();
      freshStore.dispose();
    }
  });

  for (final onboarding in [false, true]) {
    testWidgets(
      '${onboarding ? 'onboarding' : 'profile picker'} exposes account logout without leaking saved profiles',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.4;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final originalId = store.profile!.id;
        await store.saveProgress('logic', {'step': 1});
        await tester.runAsync(() => cloud.signIn('a@example.test', 'password'));
        if (onboarding) {
          await tester.runAsync(() => store.createDeviceProfile('New learner'));
        } else {
          await tester.runAsync(store.signOut);
        }
        final original = jsonEncode(store.exportProfile(originalId));
        final count = store.profiles.length;
        await tester.pumpWidget(
          CloudScope(
            controller: cloud,
            child: LearnApp(store: store),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(onboarding ? OnboardingPage : EntryPage),
          findsOneWidget,
        );
        expect(find.textContaining('learner@example.test'), findsOneWidget);
        final logout = find.byKey(const ValueKey('entry-account-logout'));
        expect(tester.getSize(logout).height, greaterThanOrEqualTo(48));
        await tester.tap(logout);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
        expect(cloud.signedIn, isFalse);
        expect(find.byType(CloudAccountPage), findsOneWidget);
        expect(store.profiles.length, count);
        expect(jsonEncode(store.exportProfile(originalId)), original);

        // Simulate the SDK restoring a different authenticated account.
        auth.owner = 'user-b';
        auth.events.add('user-b');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EntryPage), findsOneWidget);
        expect(cloud.profiles, isEmpty);
        expect(find.text('An'), findsNothing);
        expect(jsonEncode(store.exportProfile(originalId)), original);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'configured app requires login and removes open routes on logout',
    (tester) async {
      await tester.pumpWidget(
        CloudScope(
          controller: cloud,
          child: LearnApp(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CloudAccountPage), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      await tester.runAsync(() => cloud.signIn('a@example.test', 'password'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      final context = tester.element(find.byType(HomeShell));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Private route')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Private route'), findsOneWidget);
      await tester.runAsync(cloud.signOut);
      await tester.pumpAndSettle();
      expect(find.byType(CloudAccountPage), findsOneWidget);
      expect(find.text('Private route'), findsNothing);
      expect(find.byType(EntryPage), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('cloud backup survives a new install and restores without replacing unsent local work', () async {
    final original = store.profile!.id;
    await store.saveProgress('logic', {
      'step': 2,
      'states': <String, dynamic>{},
    });
    await cloud.signIn('a@example.test', 'password');
    await cloud.saveCurrent();
    final backup = cloud.backups.single;
    await store.saveProgress('logic', {'step': 3});
    await cloud.restore(backup);
    expect(store.profile!.id, original);
    expect(store.progress('logic')!['step'], 3);
    final restored = store.profiles.singleWhere((p) => p.id != original);
    await store.activateProfile(restored.id);
    expect(store.progress('logic')!['step'], 2);
    await store.rename('An mới');
    await cloud.saveCurrent();
    expect(remote.rows['user-a']!.length, 1);
    expect((cloud.backups.single.payload['profile'] as Map)['name'], 'An mới');
    // A separate preferences instance represents a fresh app install.
    SharedPreferences.setMockInitialValues({});
    final other = LearningStore(await SharedPreferences.getInstance());
    final id = await other.restoreProfile(cloud.backups.single.payload);
    await other.activateProfile(id);
    expect(other.profile!.name, 'An mới');
    expect(other.progress('logic')!['step'], 2);
    other.dispose();
  });

  test(
    'offline failure keeps draft durable and retry saves latest progress',
    () async {
      await cloud.signIn('a@example.test', 'password');
      await cloud.saveCurrent();
      remote.offline = true;
      await store.saveProgress('geometry', {'step': 3});
      await cloud.saveCurrent();
      expect(cloud.message, contains('kiểm tra mạng'));
      final reopened = LearningStore(store.preferences);
      expect(reopened.progress('geometry')!['step'], 3);
      reopened.dispose();
      remote.offline = false;
      await cloud.saveCurrent();
      expect(
        (cloud.backups.single.payload['learning']
            as Map)['drafts']['geometry']['step'],
        3,
      );
    },
  );

  test(
    'linked profile automatically saves subsequent learning changes',
    () async {
      await cloud.signIn('a@example.test', 'password');
      await cloud.saveCurrent();
      await store.saveProgress('logic', {'step': 4});
      expect(cloud.message, contains('đang chờ'));
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      expect(remote.writes, 2);
      expect(
        (cloud.backups.single.payload['learning']
            as Map)['drafts']['logic']['step'],
        4,
      );
    },
  );

  test('stale device cannot silently overwrite newer cloud backup', () async {
    await cloud.signIn('a@example.test', 'password');
    await cloud.saveCurrent();
    final first = cloud.backups.single;
    final newer = jsonDecode(jsonEncode(first.payload)) as Map<String, dynamic>;
    (newer['profile'] as Map)['name'] = 'Máy khác';
    await remote.save('user-a', first.key, first.revision, newer);
    await store.rename('Chưa gửi');
    await cloud.saveCurrent();
    expect(cloud.conflict, isTrue);
    expect(store.profile!.name, 'Chưa gửi');
    expect(remote.rows['user-a']![first.key]!.name, 'Máy khác');
  });

  test(
    'response from previous account is not bound to newly signed in account',
    () async {
      await cloud.signIn('a@example.test', 'password');
      remote.delay = Completer<void>();
      final save = cloud.saveCurrent();
      await Future<void>.delayed(Duration.zero);
      auth.owner = 'user-b';
      auth.events.add('user-b');
      remote.delay!.complete();
      await save;
      expect(cloud.currentBinding, isNull);
      expect(cloud.backups, isEmpty);
    },
  );

  testWidgets(
    'OTP screen validates pasted codes, explains expiry, and confirms on a small phone',
    (tester) async {
      for (final family in ['CofoBrilliant', 'NotoSans']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
      await (FontLoader(
        'CofoRobert',
      )..addFont(rootBundle.load('assets/fonts/CofoRobert-Medium.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(
        () => cloud.signIn('learner@example.test', 'password', register: true),
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: CloudAccountPage(controller: cloud),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('cloud-otp'));
      await tester.scrollUntilVisible(
        input,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const ValueKey('cloud-resend')))
            .onPressed,
        isNull,
      );
      await tester.enterText(input, '123');
      await tester.ensureVisible(find.byKey(const ValueKey('cloud-verify')));
      await tester.tap(find.byKey(const ValueKey('cloud-verify')));
      await tester.pumpAndSettle();
      expect(auth.verified, isEmpty);
      expect(find.textContaining('6–10 chữ số'), findsOneWidget);
      auth.verifyError = const AuthException(
        'private reason',
        code: 'otp_expired',
      );
      await tester.ensureVisible(input);
      await tester.enterText(input, '00123456');
      await tester.ensureVisible(find.byKey(const ValueKey('cloud-verify')));
      await tester.tap(find.byKey(const ValueKey('cloud-verify')));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(cloud.signedIn, isFalse);
      await tester.scrollUntilVisible(
        find.textContaining('Mã chưa đúng'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Mã chưa đúng'), findsOneWidget);
      expect(find.textContaining('private reason'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/email-verification-preview.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      auth.verifyError = null;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('cloud-verify')),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('cloud-verify')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(cloud.signedIn, isTrue);
      expect(find.byKey(const ValueKey('cloud-otp')), findsNothing);
      expect(remote.writes, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('menu logout ends cloud authentication and returns to login', (
    tester,
  ) async {
    await tester.runAsync(() => cloud.signIn('a@example.test', 'password'));
    await tester.pumpWidget(
      CloudScope(
        controller: cloud,
        child: LearnApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('app-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-logout')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    expect(cloud.signedIn, isFalse);
    expect(auth.owner, isNull);
    expect(find.byType(CloudAccountPage), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'account UI validates login and fits a small phone with large text',
    (tester) async {
      final boundary = GlobalKey();
      for (final family in ['CofoBrilliant', 'NotoSans']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
      await (FontLoader(
        'CofoRobert',
      )..addFont(rootBundle.load('assets/fonts/CofoRobert-Medium.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.4)),
              child: child!,
            ),
            home: CloudAccountPage(controller: cloud),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final login = find.widgetWithText(FilledButton, 'Đăng nhập');
      await tester.ensureVisible(login);
      await tester.pumpAndSettle();
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(find.text('Nhập email hợp lệ.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => cloud.signIn('a@example.test', 'password'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('cloud-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(remote.writes, 1);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, 1200));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = File('build/cloud-account-preview.png');
        await output.parent.create(recursive: true);
        await output.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    },
  );
}
