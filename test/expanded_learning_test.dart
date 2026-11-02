import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/engines/language_audio.dart';
import 'package:brilliant_mobile/data/repositories/catalog_roadmaps.dart';
import 'package:brilliant_mobile/discovery_paths.dart';
import 'package:brilliant_mobile/experiments/curriculum_catalog.dart';
import 'package:brilliant_mobile/experiments/curriculum_engine.dart';
import 'package:brilliant_mobile/experiments/curriculum_workspace.dart';
import 'package:brilliant_mobile/experiments/experiment_model.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/lesson_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'curriculum_solutions.dart';

class FakeLanguageAudio implements LanguageAudio {
  bool unavailable = false;
  int stops = 0;
  Completer<void>? speaking;
  void Function(String)? words;
  void Function()? done;
  @override
  Future<void> speak(String text, {bool slow = false}) async {
    if (unavailable) throw StateError('No audio');
    if (speaking != null) await speaking!.future;
  }

  @override
  Future<bool> listen({
    required void Function(String) onWords,
    required void Function() onDone,
    required void Function() onError,
  }) async {
    words = onWords;
    done = onDone;
    return !unavailable;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

void main() {
  final specs = [
    ...expandedCurriculum.values.expand((v) => v),
    ...curriculumExtensions.values.expand((v) => v),
  ];
  ExperimentSpec spec(String id) => specs.firstWhere((s) => s.id == id);
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in ['CofoBrilliant', 'NotoSans']) {
      await (FontLoader(
        family,
      )..addFont(rootBundle.load('assets/fonts/$family-Regular.ttf'))).load();
    }
  });

  test(
    'all 68 additions have durable, initially unsolved models and distinct IDs',
    () {
      expect(specs.length, 68);
      expect(specs.map((s) => s.id).toSet().length, 68);
      for (final s in specs) {
        expect(s.isCorrect(s.initialData()), false, reason: s.id);
        expect(s.isCorrect({}), false, reason: s.id);
        final state = jsonDecode(
          jsonEncode(curriculumSolutionStates[s.id]),
        ) as Map<String, dynamic>;
        expect(s.isCorrect(state), true, reason: s.id);
        for (final field in state.keys.where((k) => k != 'trials')) {
          for (final invalid in [
            null,
            true,
            -100,
            'invalid',
            <String, dynamic>{},
          ]) {
            if (invalid == state[field]) continue;
            expect(
              s.isCorrect({...state, field: invalid}),
              false,
              reason: '${s.id} $field=$invalid',
            );
          }
        }
      }
      expect(specs.map((s) => s.mechanism).toSet(), curriculumMechanisms);
    },
  );
  test('all discovery paths and roadmaps cover each topic once; age guidance is explicit', () {
    final paths = discoveryPaths.expand((p) => p.topicIds).toList();
    final roadmaps = catalogRoadmaps()
        .expand((r) => r.nodes)
        .map((n) => n.topicId)
        .toList();
    expect(paths.length, 20);
    expect(paths.toSet(), topics.map((t) => t.id).toSet());
    expect(roadmaps.toSet(), paths.toSet());
    expect(roadmaps.length, 20);
    expect(topicById('english').suggestedAge, 6);
    expect(topicById('marxism').suggestedAge, 16);
    for (final entry in expandedCurriculum.entries) {
      expect(entry.value.length, 6);
      expect(
        entry.value.take(2).every((s) => s.stage == 'Nền tảng'),
        true,
        reason: entry.key,
      );
      expect(
        entry.value.skip(4).every((s) => s.stage == 'Thử thách'),
        true,
        reason: entry.key,
      );
    }
  });
  test('semantic answers and alternative budget/model solutions enforce real constraints', () {
    expect(
      spec('english-greetings').isCorrect({
        'values': [2, 0, 1],
      }),
      true,
    );
    expect(
      spec('english-greetings').isCorrect({
        'values': [0, 1, 2],
      }),
      false,
    );
    expect(
      spec('english-sentence').isCorrect({
        'values': [2, 1, 3, 0],
      }),
      true,
    );
    expect(
      spec('english-sentence').isCorrect({
        'values': [2, 1, 1, 0],
      }),
      false,
    );
    expect(
      spec('finance-budget').isCorrect({
        'values': [6, 3, 1],
      }),
      true,
    );
    expect(
      spec('finance-budget').isCorrect({
        'values': [4, 2, 4],
      }),
      true,
    );
    expect(
      spec('finance-budget').isCorrect({
        'values': [9, 1, 0],
      }),
      false,
    );
    expect(
      spec('finance-budget').isCorrect({
        'values': [8, 2, 1],
      }),
      false,
    );
    expect(
      spec('biology-control').isCorrect({
        'selected': [2, 0],
      }),
      true,
    );
    expect(
      spec('biology-control').isCorrect({
        'selected': [0, 0],
      }),
      false,
    );
    expect(
      spec('biology-control').isCorrect({
        'selected': [0, 1, 2],
      }),
      false,
    );
    final lab = spec('geometry-area-lab');
    expect(
      lab.isCorrect({
        'x': 2,
        'y': 3,
        'prediction': 6,
        'observed': [2, 3, 6],
      }),
      true,
    );
    expect(
      lab.isCorrect({
        'x': 3,
        'y': 2,
        'prediction': 6,
        'observed': [3, 2, 6],
      }),
      true,
    );
    expect(
      lab.isCorrect({
        'x': 3,
        'y': 2,
        'prediction': 6,
        'observed': [2, 3, 6],
      }),
      false,
    );
    expect(
      lab.isCorrect({
        'x': 2,
        'y': 3,
        'prediction': 5,
        'observed': [2, 3, 6],
      }),
      false,
    );
    expect(
      spec('english-listen').isCorrect({'answer': 1, 'experienced': false}),
      false,
    );
    expect(
      spec('english-listen').isCorrect({'answer': 1, 'experienced': true}),
      true,
    );
    expect(
      spec('english-introduce')
          .isCorrect({'response': 'HELLO, my name is Alex!'}),
      true,
    );
    expect(
      spec('english-introduce')
          .isCorrect({'response': 'hello name my is Alex'}),
      false,
    );
  });

  Future<ExperimentData Function()> mount(
    WidgetTester tester,
    String id, {
    FakeLanguageAudio? audio,
    bool locked = false,
  }) async {
    final s = spec(id);
    var state = s.initialData();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) => CurriculumWorkspace(
                key: ValueKey(id),
                spec: s,
                data: state,
                locked: locked,
                audio: audio ?? FakeLanguageAudio(),
                onChanged: (d) => setState(() => state = d),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => state;
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets(
    'touch controls solve matching, ordering and evidence without injected answers',
    (t) async {
      var state = await mount(t, 'english-greetings');
      for (final (i, j) in [2, 0, 1].indexed) {
        await tap(t, find.byKey(ValueKey('connect-$i-$j')));
      }
      expect(spec('english-greetings').isCorrect(state()), true);
      state = await mount(t, 'vietnamese-story');
      await tap(t, find.byKey(const ValueKey('move-up-2')));
      await tap(t, find.byKey(const ValueKey('move-up-1')));
      expect(spec('vietnamese-story').isCorrect(state()), true);
      state = await mount(t, 'biology-control');
      await tap(t, find.byKey(const ValueKey('evidence-0')));
      await tap(t, find.byKey(const ValueKey('evidence-2')));
      expect(spec('biology-control').isCorrect(state()), true);
    },
  );
  testWidgets(
    'budget permits correction and lab requires a fresh observation after changing settings',
    (t) async {
      var state = await mount(t, 'finance-budget');
      for (final (i, count) in [7, 2, 1].indexed) {
        for (int n = 0; n < count; n++) {
          await tap(t, find.byKey(ValueKey('budget-plus-$i')));
        }
      }
      expect(spec('finance-budget').isCorrect(state()), true);
      expect(
        t
            .widget<IconButton>(find.byKey(const ValueKey('budget-plus-0')))
            .onPressed,
        isNull,
      );
      await tap(t, find.byKey(const ValueKey('budget-minus-0')));
      await tap(t, find.byKey(const ValueKey('budget-plus-2')));
      expect(spec('finance-budget').isCorrect(state()), true);
      state = await mount(t, 'geometry-area-lab');
      t.widget<Slider>(find.byKey(const ValueKey('lab-x'))).onChanged!(2);
      await t.pump();
      t.widget<Slider>(find.byKey(const ValueKey('lab-y'))).onChanged!(3);
      await t.pump();
      await tap(t, find.widgetWithText(ChoiceChip, '6'));
      await tap(t, find.byKey(const ValueKey('run-lab')));
      expect(spec('geometry-area-lab').isCorrect(state()), true);
      t.widget<Slider>(find.byKey(const ValueKey('lab-x'))).onChanged!(3);
      await t.pump();
      expect(state()['observed'], isEmpty);
      expect(spec('geometry-area-lab').isCorrect(state()), false);
    },
  );
  testWidgets(
    'audio unavailable offers transcript; microphone denial still permits typing',
    (t) async {
      final audio = FakeLanguageAudio()..unavailable = true;
      var state = await mount(t, 'english-listen', audio: audio);
      await tap(t, find.byKey(const ValueKey('language-play')));
      expect(find.textContaining('Chưa phát được'), findsOneWidget);
      expect(state()['experienced'], false);
      await tap(t, find.byKey(const ValueKey('language-transcript')));
      await tap(t, find.byKey(const ValueKey('listen-answer-1')));
      expect(spec('english-listen').isCorrect(state()), true);
      state = await mount(t, 'english-introduce', audio: audio);
      await tap(t, find.byKey(const ValueKey('language-record')));
      expect(find.textContaining('Micro hoặc'), findsOneWidget);
      await t.enterText(
        find.byKey(const ValueKey('language-response')),
        'Hello my name is Alex',
      );
      await t.pump();
      expect(spec('english-introduce').isCorrect(state()), true);
    },
  );
  testWidgets(
    'recognition result is saved; leaving lesson cancels audio and ignores late callbacks',
    (t) async {
      final audio = FakeLanguageAudio();
      final state = await mount(t, 'english-introduce', audio: audio);
      await tap(t, find.byKey(const ValueKey('language-record')));
      audio.words!('Hello my name is Alex');
      await t.pump();
      expect(state()['response'], 'Hello my name is Alex');
      audio.speaking = Completer<void>();
      await t.tap(find.byKey(const ValueKey('language-play')));
      await t.pump();
      await t.pumpWidget(const SizedBox.shrink());
      expect(audio.stops, 1);
      audio.speaking!.complete();
      audio.words!('late result');
      await t.pump();
      expect(state()['response'], 'Hello my name is Alex');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'new activities fit 320px at large text in both themes without forced audio',
    (t) async {
      t.view.physicalSize = const Size(320, 1000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      for (final brightness in Brightness.values) {
        for (final s in specs) {
          await t.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness),
              home: Builder(
                builder: (context) => Theme(
                  data: LessonTheme(
                    s.id.split('-').first,
                    0,
                    Theme.of(context),
                  ).theme,
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
                    child: Scaffold(
                      body: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: CurriculumWorkspace(
                            key: ValueKey(s.id),
                            spec: s,
                            data: s.initialData(),
                            locked: false,
                            onChanged: (_) {},
                            audio: FakeLanguageAudio(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '${s.id} $brightness');
        }
      }
    },
  );
  testWidgets(
    'age suggestions filter topics and new language artwork renders',
    (t) async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      await store.createDeviceProfile('An');
      await t.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: ExplorePage(store: store)),
        ),
      );
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('age-filter-9')));
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('topic-search')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.enterText(
        find.byKey(const ValueKey('topic-search')),
        'Tiếng Anh',
      );
      await t.pumpAndSettle();
      expect(find.text('Tiếng Anh trong cuộc sống'), findsOneWidget);
      expect(find.text('Chủ nghĩa Mác–Lênin'), findsNothing);
      await t.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );
  testWidgets('capture curriculum lesson preview', (t) async {
    t.view.physicalSize = const Size(390, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final key = GlobalKey();
    final s = spec('english-introduce');
    await t.pumpWidget(
      MaterialApp(
        theme: LessonTheme('english', 0, buildAppTheme()).theme,
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            appBar: AppBar(title: const Text('Tiếng Anh • Vận dụng')),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(s.prompt),
                    const SizedBox(height: 24),
                    CurriculumWorkspace(
                      spec: s,
                      data: s.initialData(),
                      locked: false,
                      onChanged: (_) {},
                      audio: FakeLanguageAudio(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/curriculum-preview').createSync(recursive: true);
      File('build/curriculum-preview/english.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}
