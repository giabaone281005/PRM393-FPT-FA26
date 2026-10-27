import 'dart:io';
import 'dart:ui' as ui;

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/experiments/reasoning_workspace.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/lesson_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

ThemeData baseTheme(Brightness brightness) => buildAppTheme().copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  ),
  brightness: brightness,
);

void main() {
  test('every topic has a distinct palette and every lesson varies with readable text', () {
    expect(
      LessonTheme.topicSeeds.keys.toSet(),
      topics.map((t) => t.id).toSet(),
    );
    for (final brightness in Brightness.values) {
      final base = baseTheme(brightness);
      final topicColors = <Color>{};
      for (final topic in topics) {
        final lessonColors = <Color>{};
        for (var i = 0; i < topic.experiments.length; i++) {
          final visual = LessonTheme(topic.id, i, base);
          final scheme = visual.theme.colorScheme;
          lessonColors.add(scheme.primary);
          if (i == 0) topicColors.add(scheme.primary);
          for (final (text, surface) in [
            (scheme.onSurface, scheme.surface),
            (scheme.onSurface, scheme.surfaceContainerLow),
            (scheme.primary, scheme.surfaceContainerLow),
            (scheme.onPrimary, scheme.primary),
            (scheme.onPrimaryContainer, scheme.primaryContainer),
            (scheme.onSecondaryContainer, scheme.secondaryContainer),
          ]) {
            expect(
              contrast(text, surface),
              greaterThanOrEqualTo(4.5),
              reason: '${topic.id}/$i/$brightness',
            );
          }
          expect(LessonTheme(topic.id, i, base).theme.colorScheme, scheme);
          expect(visual.canvasTheme.brightness, Brightness.light);
        }
        expect(lessonColors.length, topic.experiments.length, reason: topic.id);
      }
      expect(topicColors.length, topics.length);
    }
  });

  testWidgets(
    'lesson theme changes on next activity and stays scoped to the lesson',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      await store.createDeviceProfile('Test');
      final parentTheme = buildAppTheme();
      await tester.pumpWidget(
        MaterialApp(
          theme: parentTheme,
          home: LessonPage(topic: topicById('marxism'), store: store),
        ),
      );
      await tester.pumpAndSettle();
      Color primary() =>
          Theme.of(tester.element(find.byKey(const ValueKey('themed-lesson'))))
              .colorScheme
              .primary;
      final first = primary();
      final workspace = tester.widget<ReasoningWorkspace>(
        find.byType(ReasoningWorkspace),
      );
      workspace.onChanged({'answer': 1, 'reason': 0});
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kiểm tra'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khám phá tiếp'));
      await tester.pumpAndSettle();
      expect(primary(), isNot(first));
      expect(
        parentTheme.colorScheme.primary,
        buildAppTheme().colorScheme.primary,
      );
      expect(store.progress('marxism')!['step'], 1);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );

  testWidgets(
    'new lesson palettes fit small screens in both brightness modes',
    (tester) async {
      for (final family in ['CofoBrilliant', 'NotoSans']) {
        final loader = FontLoader(family);
        for (final weight in ['Regular', 'Medium', 'Bold']) {
          loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
        }
        await loader.load();
      }
      // The test runner's default monospace font is Ahem. Load a real font
      // under that alias for readable code in the exported visual previews.
      await (FontLoader(
            'monospace',
          )..addFont(rootBundle.load('assets/fonts/CofoBrilliant-Regular.ttf')))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      await store.createDeviceProfile('Preview');
      for (final brightness in Brightness.values) {
        for (final id in ['marxism', 'painting', 'coding']) {
          await tester.pumpWidget(const SizedBox());
          final boundary = GlobalKey();
          if (id == 'coding') await store.saveProgress(id, {'step': 5});
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: baseTheme(brightness),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: LessonPage(topic: topicById(id), store: store),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$id/$brightness');
          final rendered =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await rendered.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            await File('build/lesson-$id-${brightness.name}.png')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
