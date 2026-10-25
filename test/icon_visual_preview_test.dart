import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/topic_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Visual review: flutter test test/icon_visual_preview_test.dart
void main() {
  testWidgets('Render home and the eight dimensional topic illustrations', (
    tester,
  ) async {
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
      'NotoSerif',
    )..addFont(rootBundle.load('assets/fonts/NotoSerif-Medium.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    SharedPreferences.setMockInitialValues({});
    final store = LearningStore(await SharedPreferences.getInstance());
    await store.createDeviceProfile('Bảo');
    await store.finishOnboarding(['probability'], 10);
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/$name.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: LearnApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('home-minimal');
    await tester.tap(find.byKey(const ValueKey('app-settings')));
    await tester.pumpAndSettle();
    await capture('settings-popup');
    await tester.tap(find.byKey(const ValueKey('menu-appearance')));
    await tester.pumpAndSettle();
    await capture('appearance-settings');
    Navigator.pop(tester.element(find.text('Giao diện ứng dụng')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-start')));
    await tester.pumpAndSettle();
    await capture('topics-grouped');

    // Verify grouped course tiles open the matching topic at narrow width.
    tester.view.physicalSize = const Size(320, 800);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('topic-logic')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('topic-logic')));
    await tester.pumpAndSettle();
    expect(find.text('Logic & quy luật'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(390, 1000);
    await tester.pumpAndSettle();
    await capture('aligned-topic');
    await tester.ensureVisible(find.text('Vào phòng thí nghiệm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vào phòng thí nghiệm'));
    await tester.pumpAndSettle();
    await capture('aligned-lesson');
    Navigator.pop(tester.element(find.byType(LessonPage)));
    await tester.pumpAndSettle();
    final topicContext = tester.element(find.byType(TopicPage));
    Navigator.push(
      topicContext,
      MaterialPageRoute<void>(
        builder: (_) => CompletionPage(
          topic: topicById('logic'),
          store: store,
          record: const {'attempts': 3, 'hints': 0},
          awarded: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('aligned-completion');
    Navigator.pop(tester.element(find.byType(CompletionPage)));
    await tester.pumpAndSettle();
    Navigator.pop(tester.element(find.byType(TopicPage)));
    await tester.pumpAndSettle();
    await store.saveProgress('coding', {'step': 1});
    tester.view.physicalSize = const Size(390, 1000);
    await tester.tap(find.text('Trang chủ'));
    await tester.pumpAndSettle();
    await capture('home-resume-minimal');
    await tester.ensureVisible(find.byKey(const ValueKey('home-chat')));
    await tester.pumpAndSettle();
    await capture('home-chat');
    await store.saveProgress('coding', {
      'step': 1,
      'activeMsByDay': {
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}':
            240000,
      },
    });
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    await capture('profile-daily');

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.runAsync(() => store.saveProgress('geometry', {'step': 3}));
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: LessonPage(topic: topicById('geometry'), store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ExperimentWorkspace>(find.byType(ExperimentWorkspace))
          .spec
          .id,
      'geometry-fence',
    );
    await capture('extended-geometry');
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: TopicPage(topic: topicById('optimization'), store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('extended-optimization');

    tester.view.physicalSize = const Size(1000, 600);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: Scaffold(
            backgroundColor: const Color(0xFFF7F8FC),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  for (final topic in topics)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TopicIllustration(
                            topicId: topic.id,
                            label: topic.subject,
                            height: 170,
                          ),
                          Text(
                            topic.subject,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture('topic-icon-sheet');
    await tester.pumpWidget(const SizedBox.shrink());
    store.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
