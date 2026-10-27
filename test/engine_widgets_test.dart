import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/engines/engine_contracts.dart';
import 'package:brilliant_mobile/data/models/engine_config.dart';
import 'package:brilliant_mobile/data/models/learning_modules.dart';
import 'package:brilliant_mobile/data/repositories/engine_registry.dart';
import 'package:brilliant_mobile/data/repositories/engine_runtime.dart';
import 'package:brilliant_mobile/features/assessment/mastery_widgets.dart';
import 'package:brilliant_mobile/features/coding/code_playground_page.dart';
import 'package:brilliant_mobile/features/engines/engine_scope.dart';
import 'package:brilliant_mobile/features/engines/engine_settings_page.dart';
import 'package:brilliant_mobile/features/tutor/shared_canvas.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_store.dart';

import 'engine_registry_test.dart' show MemoryEngineStorage, config;

class _Tutor implements AiEngine {
  TutorRequest? received;
  @override
  Future<TutorReply> respond(TutorRequest request) async {
    received = request;
    return const TutorReply('Koji: quan sát nét vẽ này.');
  }

  @override
  void dispose() {}
}

class _Code implements CodeExecutionEngine {
  CodeRequest? received;
  @override
  Future<ExecutionResult> execute(CodeRequest request) async {
    received = request;
    return const ExecutionResult(stdout: 'matrix result', exitCode: 0);
  }

  @override
  void dispose() {}
}

void main() {
  setUpAll(() async {
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
    await (FontLoader('SourceCodePro')
          ..addFont(rootBundle.load('assets/fonts/SourceCodePro-Regular.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  late EngineRegistry registry;
  late EngineRuntime runtime;
  setUp(() async {
    registry = EngineRegistry(MemoryEngineStorage());
    await registry.initialize();
    runtime = EngineRuntime(registry);
  });
  tearDown(() {
    runtime.dispose();
    registry.dispose();
  });

  testWidgets(
    'engine UI saves, selects and edits without displaying stored credentials',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
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
            home: EngineSettingsPage(runtime: runtime),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('add-engine')),
        250,
      );
      await tester.tap(find.byKey(const ValueKey('add-engine')));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Koji của tôi');
      await tester.enterText(fields.at(1), 'https://koji.example/chat');
      await tester.enterText(fields.at(2), 'configured-model');
      await tester.ensureVisible(fields.at(3));
      await tester.enterText(fields.at(3), 'private-key');
      final save = find.widgetWithText(FilledButton, 'Lưu kết nối');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(registry.engines.single.name, 'Koji của tôi');
      final id = registry.engines.single.id;
      await tester.ensureVisible(find.byKey(ValueKey('activate-$id')));
      await tester.tap(find.byKey(ValueKey('activate-$id')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(registry.active(EngineKind.tutor)!.id, id);
      expect(find.text('private-key'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/engine-settings-preview.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.ensureVisible(find.text('Chỉnh sửa'));
      await tester.tap(find.text('Chỉnh sửa'));
      await tester.pumpAndSettle();
      expect(
        (tester
                .widgetList<TextFormField>(find.byType(TextFormField))
                .last
                .controller!)
            .text,
        isEmpty,
      );
      expect(find.text('private-key'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'existing home chat uses active engine and sends canvas strokes',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late LearningStore store;
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        store = LearningStore(await SharedPreferences.getInstance());
        await store.createDeviceProfile('An');
        await store.finishOnboarding(['logic'], 10);
      });
      addTearDown(store.dispose);
      final tutor = _Tutor();
      runtime.registerAiAdapter(EngineProvider.koji, (_) => tutor);
      await tester.runAsync(() async {
        await registry.register(config('koji'));
        await registry.activate(EngineKind.tutor, 'koji');
      });
      await tester.pumpWidget(
        EngineScope(
          runtime: runtime,
          child: LearnApp(store: store),
        ),
      );
      await tester.pumpAndSettle();
      final toggle = find.text('Cùng Koji vẽ lời giải');
      await tester.scrollUntilVisible(
        toggle,
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('home-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final canvas = find.byType(SharedCanvas);
      await tester.ensureVisible(canvas);
      await tester.drag(canvas, const Offset(70, 40));
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('chat-input'));
      await tester.ensureVisible(input);
      await tester.enterText(input, 'Giải thích hình này');
      await tester.pump();
      final send = find.byKey(const ValueKey('chat-send'));
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(tutor.received!.canvas!.strokes, isNotEmpty);
      expect(tutor.received!.messages.single.text, 'Giải thích hình này');
      expect(find.text('Koji: quan sát nét vẽ này.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'code playground sends edited template only on Run and shows output',
    (tester) async {
      final code = _Code();
      runtime.registerCodeAdapter(EngineProvider.docker, (_) => code);
      await tester.runAsync(() async {
        await registry.register(
          config('sandbox', provider: EngineProvider.docker),
        );
        await registry.activate(EngineKind.code, 'sandbox');
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: CodePlaygroundPage(runtime: runtime),
        ),
      );
      await tester.pumpAndSettle();
      expect(code.received, isNull);
      final source = find.byKey(const ValueKey('code-source'));
      await tester.enterText(source, 'print("custom")');
      final run = find.widgetWithText(FilledButton, 'Chạy chương trình');
      await tester.scrollUntilVisible(
        run,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(run);
      await tester.pumpAndSettle();
      expect(code.received!.source, 'print("custom")');
      expect(code.received!.language, 'python');
      await tester.scrollUntilVisible(
        find.textContaining('matrix result'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('matrix result'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'quiz accepts one answer per question and dashboard distinguishes unknown mastery',
    (tester) async {
      final answers = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: ListView(
              children: [
                MasteryQuiz(
                  question: QuizQuestion(
                    id: 'q1',
                    topicId: 'math',
                    prompt: '1 + 1?',
                    choices: ['2', '3'],
                    answerIndex: 0,
                  ),
                  onAnswer: answers.add,
                ),
                MasteryDashboard(
                  metrics: [
                    MasteryMetric(topicId: 'math', correct: 4, total: 5),
                    MasteryMetric(topicId: 'coding', correct: 0, total: 0),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('2'));
      await tester.pump();
      await tester.tap(find.text('3'));
      await tester.pump();
      expect(answers, [0]);
      expect(find.text('coding · Chưa đánh giá'), findsOneWidget);
      expect(find.text('1 vững kiến thức · 0 cần luyện thêm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
