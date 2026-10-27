import 'dart:async';

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/home_chat_box.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brilliant_mobile/data/repositories/engine_registry.dart';

void main() {
  testWidgets(
    'chat explains a known engine failure while preserving the draft',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: HomeChatBox(
              onSend: (_) async => throw const EngineFailure(
                'Khóa hoặc token của kết nối chưa hợp lệ. Hãy cập nhật trong Engine học tập.',
              ),
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Giải thích hình này',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Khóa hoặc token'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-input')))
            .controller!
            .text,
        'Giải thích hình này',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Composer keeps a draft locally while no responder is connected',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const Scaffold(body: HomeChatBox()),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Giải thích phân số',
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('chat-send')))
            .onPressed,
        isNull,
      );
      expect(find.text('Giải thích phân số'), findsOneWidget);
      await tester.tap(find.text('Học lập trình'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-input')))
            .controller!
            .text,
        'Học lập trình',
      );
      expect(find.text('Trợ lý chưa được kết nối.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Responder receives history, prevents duplicate sends, and preserves failed draft',
    (tester) async {
      final pending = Completer<String>();
      var requests = 0;
      List<ChatMessage>? received;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: HomeChatBox(
              onSend: (history) {
                requests++;
                received = history;
                return requests == 1
                    ? pending.future
                    : Future.error(StateError('offline'));
              },
            ),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Cân hoạt động thế nào?',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pump();
      expect(requests, 1);
      expect(received!.single.text, 'Cân hoạt động thế nào?');
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('chat-send')))
            .onPressed,
        isNull,
      );
      pending.complete('Hai bên bằng nhau thì cân thăng bằng.');
      await tester.pumpAndSettle();
      expect(
        find.text('Hai bên bằng nhau thì cân thăng bằng.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('chat-input')),
        'Cho ví dụ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('chat-send')));
      await tester.pumpAndSettle();
      expect(received!.length, 3);
      expect(received![1].fromLearner, false);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-input')))
            .controller!
            .text,
        'Cho ví dụ',
      );
      expect(
        find.text('Chưa gửi được. Câu hỏi vẫn ở đây để bạn thử lại.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Topic tiles and chat controls stay inside 280px to desktop at large text',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      await store.createDeviceProfile('An');
      await store.finishOnboarding(['logic'], 10);
      tester.view.devicePixelRatio = 1;
      for (final width in [280.0, 320.0, 390.0, 1024.0]) {
        tester.view.physicalSize = Size(width, 1100);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        await tester.pumpWidget(LearnApp(key: ValueKey(width), store: store));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('home-chat')),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        final chat = tester.getRect(find.byKey(const ValueKey('home-chat')));
        expect(chat.left, greaterThanOrEqualTo(0));
        expect(chat.right, lessThanOrEqualTo(width));
        for (final chip
            in find
                .descendant(
                  of: find.byType(HomeChatBox),
                  matching: find.byType(ActionChip),
                )
                .evaluate()) {
          final rect = tester.getRect(find.byWidget(chip.widget));
          expect(rect.left, greaterThanOrEqualTo(chat.left));
          expect(rect.right, lessThanOrEqualTo(chat.right));
        }
        await tester.tap(find.text('Chủ đề'));
        await tester.pumpAndSettle();
        for (final id in ['math', 'logic', 'geometry']) {
          final rect = tester.getRect(find.byKey(ValueKey('topic-$id')));
          expect(rect.left, greaterThanOrEqualTo(20));
          expect(rect.right, lessThanOrEqualTo(width - 20));
        }
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
