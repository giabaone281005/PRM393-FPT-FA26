import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/models/app_failure.dart';
import 'package:brilliant_mobile/data/providers/password_recovery_controller.dart';
import 'package:brilliant_mobile/data/repositories/password_recovery_repository.dart';
import 'package:brilliant_mobile/features/account/password_recovery_page.dart';
import 'package:brilliant_mobile/features/account/cloud_account_page.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learning_sync_test.dart' show SyncTestAuth, SyncTestBackups;

class _Recovery implements PasswordRecoveryRepository {
  final requests = <String>[], codes = <String>[], passwords = <String>[];
  Object? error;
  Completer<void>? pending;
  bool disposed = false;
  @override
  Future<void> requestCode(String email) async {
    requests.add(email);
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
  }

  @override
  Future<void> verifyCode(String email, String code) async {
    codes.add(code);
    if (error != null) throw error!;
  }

  @override
  Future<void> updatePassword(String password) async {
    if (error != null) throw error!;
    passwords.add(password);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

Map<String, dynamic> _session(String id, String email) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  return {
    'access_token':
        '${encode({'alg': 'HS256'})}.${encode({'exp': expiry, 'sub': id})}.fixture',
    'refresh_token': 'fixture-refresh',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': id,
      'aud': 'authenticated',
      'email': email,
      'created_at': '2026-10-27T00:00:00Z',
      'app_metadata': {},
      'user_metadata': {},
    },
  };
}

void main() {
  test('received recovery code can be entered after reopening without sending another email', () async {
    final repository = _Recovery();
    final controller = PasswordRecoveryController(repository);
    addTearDown(controller.dispose);
    controller.enterExistingCode('learner@example.test');
    expect(controller.step, RecoveryStep.code);
    expect(repository.requests, isEmpty);
    await controller.verifyCode('00123456');
    expect(controller.step, RecoveryStep.password);
    expect(repository.codes.single, '00123456');
  });
  testWidgets(
    'forgot password route returns to the auth gate without opening a learning account',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      await store.createDeviceProfile('Local learner');
      final before = jsonEncode(store.exportProfile(store.profile!.id));
      final auth = SyncTestAuth()..owner = null;
      final recovery = _Recovery();
      final cloud = CloudBackupController(
        store: store,
        auth: auth,
        repository: SyncTestBackups(),
        createPasswordRecovery: () => recovery,
      );
      await tester.pumpWidget(
        CloudScope(
          controller: cloud,
          child: LearnApp(store: store),
        ),
      );
      await tester.pumpAndSettle();
      final forgot = find.byKey(const ValueKey('cloud-forgot-password'));
      await tester.ensureVisible(forgot);
      await tester.tap(forgot);
      await tester.pumpAndSettle();
      expect(find.byType(PasswordRecoveryPage), findsOneWidget);
      expect(cloud.signedIn, isFalse);
      expect(find.byType(HomeShell), findsNothing);
      await tester.ensureVisible(find.byKey(const ValueKey('recovery-back')));
      await tester.tap(find.byKey(const ValueKey('recovery-back')));
      await tester.pumpAndSettle();
      expect(find.byType(CloudAccountPage), findsOneWidget);
      expect(recovery.disposed, isTrue);
      expect(jsonEncode(store.exportProfile(store.profile!.id)), before);
      await tester.pumpWidget(const SizedBox.shrink());
      cloud.dispose();
      store.dispose();
      await auth.events.close();
    },
  );
  test('recovery follows real Auth wire types without changing the learning client', () async {
    final mainSession = _session('account-a', 'a@example.test');
    final main = SupabaseClient(
      'https://auth.example',
      'fixture-key',
      httpClient: MockClient(
        (_) async => http.Response(jsonEncode(mainSession), 200),
      ),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await main.auth.signInWithPassword(
      email: 'a@example.test',
      password: 'original-password',
    );
    final calls = <String>[];
    final recoverySession = _session('account-b', 'b@example.test');
    final repository = SupabasePasswordRecoveryRepository(
      'https://auth.example',
      'fixture-key',
      httpClient: MockClient((request) async {
        calls.add(request.url.path);
        final body = request.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(request.body) as Map;
        switch (request.url.path) {
          case '/auth/v1/recover':
            expect(body['email'], 'b@example.test');
            expect(body['code_challenge'], isNull);
            return http.Response('{}', 200);
          case '/auth/v1/verify':
            expect(body['type'], 'recovery');
            expect(body['token'], '00123456');
            return http.Response(jsonEncode(recoverySession), 200);
          case '/auth/v1/user':
            expect(
              request.headers['Authorization'],
              'Bearer ${recoverySession['access_token']}',
            );
            expect(body['password'], 'new-password');
            return http.Response(jsonEncode(recoverySession['user']), 200);
          case '/auth/v1/logout':
            expect(request.url.queryParameters['scope'], 'local');
            expect(
              request.headers['Authorization'],
              'Bearer ${recoverySession['access_token']}',
            );
            return http.Response('', 204);
          default:
            throw StateError('Unexpected auth path');
        }
      }),
    );
    await expectLater(
      repository.updatePassword('new-password'),
      throwsA(isA<AppFailure>()),
    );
    await repository.requestCode('b@example.test');
    await repository.verifyCode('b@example.test', '00123456');
    await repository.updatePassword('new-password');
    expect(main.auth.currentUser!.id, 'account-a');
    await repository.dispose();
    expect(main.auth.currentUser!.id, 'account-a');
    expect(calls, [
      '/auth/v1/recover',
      '/auth/v1/verify',
      '/auth/v1/user',
      '/auth/v1/logout',
    ]);
    await main.dispose();
  });

  test('unknown email does not expose account existence', () async {
    final repository = SupabasePasswordRecoveryRepository(
      'https://auth.example',
      'fixture-key',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({'code': 'user_not_found', 'msg': 'private user detail'}),
          404,
          headers: {'x-supabase-api-version': '2024-01-01'},
        ),
      ),
    );
    await repository.requestCode('unknown@example.test');
    await repository.dispose();
  });

  test(
    'expired code and failed password update remain retryable with safe errors',
    () async {
      final repository = _Recovery();
      final controller = PasswordRecoveryController(repository);
      addTearDown(controller.dispose);
      await controller.updatePassword('new-password');
      expect(repository.passwords, isEmpty);
      await controller.sendCode(' learner@example.test ');
      expect(repository.requests.single, 'learner@example.test');
      expect(controller.message, contains('Nếu email có tài khoản'));
      repository.error = const AuthException(
        'PRIVATE diagnostic',
        code: 'otp_expired',
      );
      await controller.verifyCode('00123456');
      expect(controller.step, RecoveryStep.code);
      expect(controller.message, contains('hết hạn'));
      expect(controller.message, isNot(contains('PRIVATE')));
      repository.error = null;
      await controller.verifyCode('00123456');
      expect(repository.codes.last, '00123456');
      expect(controller.step, RecoveryStep.password);
      repository.error = http.ClientException('private transport details');
      await controller.updatePassword('new-password');
      expect(controller.step, RecoveryStep.password);
      expect(controller.noticeKind, NoticeKind.error);
      repository.error = null;
      await controller.updatePassword('new-password');
      expect(controller.step, RecoveryStep.complete);
      expect(repository.passwords.single, 'new-password');
    },
  );

  test(
    'validation, duplicate suppression and cooldown survive changing email',
    () async {
      var now = DateTime.utc(2026, 10, 27);
      final repository = _Recovery();
      final controller = PasswordRecoveryController(
        repository,
        clock: () => now,
      );
      addTearDown(controller.dispose);
      await controller.sendCode('invalid');
      expect(repository.requests, isEmpty);
      repository.pending = Completer<void>();
      final sending = controller.sendCode('learner@example.test');
      await controller.sendCode('other@example.test');
      expect(repository.requests.length, 1);
      repository.pending!.complete();
      await sending;
      await controller.verifyCode('123');
      expect(repository.codes, isEmpty);
      controller.changeEmail();
      await controller.sendCode('other@example.test');
      expect(repository.requests.length, 1);
      now = now.add(const Duration(seconds: 60));
      await controller.sendCode('other@example.test');
      expect(repository.requests.last, 'other@example.test');
    },
  );

  test(
    'disposed recovery ignores late results and disposes its repository',
    () async {
      final repository = _Recovery()..pending = Completer<void>();
      final controller = PasswordRecoveryController(repository);
      final sending = controller.sendCode('learner@example.test');
      controller.dispose();
      repository.pending!.complete();
      await sending;
      expect(repository.disposed, isTrue);
      expect(controller.step, RecoveryStep.email);
    },
  );

  testWidgets(
    'recovery form supports a small phone, mismatched passwords and retry',
    (tester) async {
      for (final family in ['CofoBrilliant', 'NotoSans']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
      final boundary = GlobalKey();
      final materialIcons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await materialIcons.load();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 1000);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repository = _Recovery();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: RepaintBoundary(
            key: boundary,
            child: PasswordRecoveryPage(
              createRepository: () => repository,
              initialEmail: 'learner@example.test',
            ),
          ),
        ),
      );
      Future<void> submit() async {
        final button = find.byKey(const ValueKey('recovery-submit'));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await submit();
      expect(repository.requests.length, 1);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('recovery-resend')),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('recovery-code')),
        '00123456',
      );
      repository.error = const AuthException('private', code: 'otp_expired');
      await submit();
      expect(find.textContaining('Mã chưa đúng'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('recovery-code')))
            .controller!
            .text,
        '00123456',
      );
      repository.error = null;
      await submit();
      await tester.enterText(
        find.byKey(const ValueKey('recovery-password')),
        'new-password',
      );
      await tester.enterText(
        find.byKey(const ValueKey('recovery-confirm')),
        'different-password',
      );
      await submit();
      expect(repository.passwords, isEmpty);
      expect(find.text('Hai mật khẩu chưa khớp.'), findsOneWidget);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('build/beta-recovery-preview.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.enterText(
        find.byKey(const ValueKey('recovery-confirm')),
        'new-password',
      );
      await submit();
      expect(repository.passwords.single, 'new-password');
      expect(find.textContaining('Đã đổi mật khẩu.'), findsOneWidget);
      expect(find.byKey(const ValueKey('recovery-password')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(repository.disposed, isTrue);
    },
  );
}
