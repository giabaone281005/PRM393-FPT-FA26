import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/home_owl_mascot.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/owl_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'owl has finite, depth-sorted geometry through a complete camera orbit',
    () {
      for (final size in [const Size(200, 236), const Size(320, 236)]) {
        for (var i = 0; i <= 12; i++) {
          for (final pose in [0.0, .34, .6, 1.0]) {
            final faces = OwlScene(
              yaw: -math.pi + i * math.pi / 6,
              reaction: pose,
            ).project(size);
            expect(faces.length, greaterThan(1000));
            for (var n = 0; n < faces.length; n++) {
              final face = faces[n];
              if (n > 0) {
                expect(face.depth, greaterThanOrEqualTo(faces[n - 1].depth));
              }
              for (final point in face.points) {
                expect(point.dx.isFinite && point.dy.isFinite, true);
                expect(point.dx, inInclusiveRange(0, size.width));
                expect(point.dy, inInclusiveRange(0, size.height));
              }
            }
          }
        }
      }
      expect(
        const OwlScene(yaw: double.nan).project(const Size(200, 236)),
        isEmpty,
      );
      expect(const OwlScene().project(Size.zero), isEmpty);
    },
  );

  testWidgets('owl greets, rotates with touch/buttons and resets its camera', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HomeOwlMascot()),
      ),
    );
    await tester.pumpAndSettle();
    OwlPainter painter() =>
        tester
                .widget<CustomPaint>(find.byKey(const ValueKey('owl-scene')))
                .painter!
            as OwlPainter;
    final initial = painter().yaw;
    await tester.tap(find.byKey(const ValueKey('owl-orbit')));
    await tester.pumpAndSettle();
    expect(find.text('Chào bạn! Cùng khám phá điều mới nào!'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('owl-orbit')),
      const Offset(90, 0),
    );
    await tester.pumpAndSettle();
    expect(painter().yaw, isNot(initial));
    await tester.tap(find.byKey(const ValueKey('owl-reset')));
    await tester.pumpAndSettle();
    expect(painter().yaw, initial);
    await tester.tap(find.byKey(const ValueKey('owl-left')));
    await tester.pumpAndSettle();
    expect(painter().yaw, closeTo(initial - .4, .001));
    await tester.tap(find.byKey(const ValueKey('owl-right')));
    await tester.pumpAndSettle();
    expect(painter().yaw, closeTo(initial, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion keeps greeting animation still but controls work',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: HomeOwlMascot()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('owl-greet')));
      await tester.pumpAndSettle();
      final painter =
          tester
                  .widget<CustomPaint>(find.byKey(const ValueKey('owl-scene')))
                  .painter!
              as OwlPainter;
      expect(painter.reaction, 0);
      expect(
        find.text('Chào bạn! Cùng khám phá điều mới nào!'),
        findsOneWidget,
      );
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'home owl fits large text and vertical drags still scroll the page',
    (tester) async {
      tester.view.physicalSize = const Size(280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      await store.createDeviceProfile('An');
      await store.finishOnboarding(['logic'], 10);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.4)),
            child: child!,
          ),
          home: Scaffold(
            body: TodayPage(store: store, onExplore: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('owl-orbit')));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final before = scrollable.position.pixels;
      await tester.drag(
        find.byKey(const ValueKey('owl-orbit')),
        const Offset(0, -180),
      );
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, greaterThan(before));
      await tester.ensureVisible(find.byKey(const ValueKey('owl-greet')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('owl-greet')));
      await tester.pumpAndSettle();
      expect(store.points, 0);
      expect(store.inProgress, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets('render home mascot and rotated geometry for visual review', (
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
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final boundary = GlobalKey();
    tester.view.physicalSize = const Size(390, 650);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: HomeOwlMascot(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) => tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await capture('home-owl-front');
    await tester.drag(
      find.byKey(const ValueKey('owl-orbit')),
      const Offset(80, 0),
    );
    await tester.pumpAndSettle();
    await capture('home-owl-rotated');
    expect(tester.takeException(), isNull);
  });
}
