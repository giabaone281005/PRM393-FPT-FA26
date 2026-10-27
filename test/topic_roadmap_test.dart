import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/app_motion.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/lesson_theme.dart';
import 'package:brilliant_mobile/experiments/math_experiments.dart';
import 'package:brilliant_mobile/experiments/diverse_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LearningStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LearningStore(await SharedPreferences.getInstance());
    await store.createDeviceProfile('An');
  });
  tearDown(() => store.dispose());

  testWidgets(
    'checkpoints validate completion; preview never skips the saved lesson',
    (tester) async {
      await store.saveProgress('logic', {
        'version': 3,
        'step': 1,
        'states': {
          'logic-balance': {'blocks': 4},
        },
        'checked': ['logic-balance'],
        'touched': ['logic-balance'],
      });
      final before = store.progress('logic');
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TopicPage(topic: topicById('logic'), store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1/'), findsOneWidget);
      final future = find.byKey(
        ValueKey('checkpoint-${topicById('logic').experiments.last.id}'),
      );
      await tester.scrollUntilVisible(future, 200);
      await tester.pumpAndSettle();
      await tester.tap(future);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Xem trước · Phiên học tiếp tục từ checkpoint 2.'),
        findsOneWidget,
      );
      expect(store.progress('logic'), before);
      expect(store.points, 0);
      await tester.tap(find.text('Tiếp tục phiên học'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExperimentWorkspace>(find.byType(ExperimentWorkspace))
            .spec
            .id,
        topicById('logic').experiments[1].id,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'forged checked state does not mark a roadmap checkpoint completed',
    (tester) async {
      final spec = topicById('logic').experiments.first;
      await store.saveProgress('logic', {
        'version': 3,
        'step': 0,
        'states': {spec.id: spec.initialData()},
        'checked': [spec.id],
        'touched': [spec.id],
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: TopicPage(topic: topicById('logic'), store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          '0/${topicById('logic').experiments.length} checkpoint',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Đã hoàn thành'), findsNothing);
    },
  );

  testWidgets(
    'roadmap fits large text, keeps CTA visible and respects reduced motion',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final width in [280.0, 390.0]) {
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.3),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: TopicPage(topic: topicById('coding'), store: store),
          ),
        );
        await tester.pumpAndSettle();
        final button = find.text('Vào phòng thí nghiệm');
        expect(tester.getRect(button).bottom, lessThan(900));
        final last = find.byKey(
          ValueKey('checkpoint-${topicById('coding').experiments.last.id}'),
        );
        await tester.scrollUntilVisible(last, 300);
        await tester.pumpAndSettle();
        await tester.tap(last);
        await tester.pump();
        expect(AppMotion.reduced(tester.element(last)), true);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'legacy interactive buttons, drag tokens and sliders use subject colors',
    (tester) async {
      for (final topicId in ['logic', 'science']) {
        final visual = LessonTheme(topicId, 0, buildAppTheme());
        await tester.pumpWidget(
          MaterialApp(
            theme: visual.canvasTheme,
            home: Scaffold(
              body: MathExperiment(
                spec: topicById('logic').experiments.first,
                data: {'blocks': 0},
                locked: false,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final button = tester.widget<OutlinedButton>(
          find.byType(OutlinedButton).first,
        );
        final context = tester.element(find.byType(MathExperiment));
        final token =
            tester
                    .widget<Draggable<int>>(find.byType(Draggable<int>).first)
                    .child
                as Container;
        expect(
          (token.decoration as BoxDecoration).color,
          visual.canvasTheme.colorScheme.primaryContainer,
        );
        final style = OutlinedButtonTheme.of(context).style!;
        expect(
          style.backgroundColor!.resolve({}),
          visual.canvasTheme.colorScheme.primaryContainer,
        );
        expect(
          style.foregroundColor!.resolve({}),
          visual.canvasTheme.colorScheme.onPrimaryContainer,
        );
        expect(button.onPressed, isNotNull);
        expect(
          style.backgroundColor!.resolve({WidgetState.disabled}),
          isNot(visual.canvasTheme.colorScheme.primaryContainer),
        );
        final spec = topicById('math').experiments
            .firstWhere((s) => s.mechanism == 'fractionNumberLine');
        await tester.pumpWidget(
          MaterialApp(
            theme: visual.canvasTheme,
            home: Scaffold(
              body: DiverseWorkspace(
                spec: spec,
                data: spec.initialData(),
                locked: false,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final sliderContext = tester.element(find.byType(Slider));
        expect(
          SliderTheme.of(sliderContext).thumbColor,
          visual.canvasTheme.colorScheme.primary,
        );
      }
    },
  );

  testWidgets('render actual roadmap with real fonts', (tester) async {
    for (final family in ['CofoBrilliant', 'NotoSans']) {
      final loader = FontLoader(family);
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
      }
      await loader.load();
    }
    for (final family in ['CofoRobert', 'NotoSerif']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family-Medium.ttf'))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: TopicPage(topic: topicById('coding'), store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('checkpoint-coding-loop')),
      150,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/topic-roadmap-preview.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
