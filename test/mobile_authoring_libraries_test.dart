import 'dart:convert';

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/models/slide_lesson.dart';
import 'package:brilliant_mobile/data/models/learning_journal.dart';
import 'package:brilliant_mobile/experiments/slide_lesson_workspace.dart';
import 'package:brilliant_mobile/experiments/lesson_rich_text.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final engine in [
    'numberInput',
    'fractionBoard',
    'quadraticGraph',
    'barChart',
    'shapeMatch',
  ]) {
    testWidgets(
      '$engine uses the bundled mobile renderer, updates answers, restores JSON and respects locked state',
      (tester) async {
        final slide = newLessonSlide(engine);
        var state = learningMap(
          (initialSlideState({
                    'slides': [slide],
                  })['slides']
                  as List)
              .first,
        );
        var locked = false;
        var changes = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, set) => Column(
                    children: [
                      SlideEngineWorkspace(
                        slide: slide,
                        state: state,
                        locked: locked,
                        onChanged: (next) => set(() {
                          state = next;
                          changes++;
                        }),
                      ),
                      TextButton(
                        onPressed: () => set(() => locked = true),
                        child: const Text('Lock'),
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
        switch (engine) {
          case 'numberInput':
            await tester.enterText(find.byType(TextFormField), '12');
            expect(slideIsCorrect(slide, state), isTrue);
          case 'fractionBoard':
            expect(find.byType(SvgPicture), findsOneWidget);
            for (var i = 1; i <= 4; i++) {
              await tester.tap(find.widgetWithText(FilterChip, 'Phần $i'));
              await tester.pump();
            }
            expect(slideIsCorrect(slide, state), isTrue);
          case 'quadraticGraph':
            expect(find.byType(LineChart), findsOneWidget);
            expect(find.byType(Math), findsOneWidget);
            await tester.drag(
              find.byKey(const ValueKey('extra-a')),
              const Offset(180, 0),
            );
            await tester.pump();
            expect(changes, greaterThan(0));
          case 'barChart':
            expect(find.byType(BarChart), findsOneWidget);
            await tester.drag(
              find.byKey(const ValueKey('bar-0')),
              const Offset(40, 0),
            );
            await tester.pump();
            expect(changes, greaterThan(0));
          case 'shapeMatch':
            expect(find.byType(SvgPicture), findsNWidgets(5));
            await tester.tap(find.byType(OutlinedButton).at(1));
            await tester.pump();
            expect(slideIsCorrect(slide, state), isTrue);
        }
        final restored = learningMap(jsonDecode(jsonEncode(state)));
        expect(slideIsCorrect(slide, restored), slideIsCorrect(slide, state));
        await tester.ensureVisible(find.text('Lock'));
        await tester.tap(find.text('Lock'));
        await tester.pump();
        expect(locked, isTrue);
        expect(tester.takeException(), isNull);
        if (engine == 'numberInput') {
          expect(
            tester.widget<TextFormField>(find.byType(TextFormField)).enabled,
            isFalse,
          );
        }
        if (engine == 'barChart' || engine == 'quadraticGraph') {
          expect(
            tester
                .widgetList<Slider>(find.byType(Slider))
                .every((s) => s.onChanged == null),
            isTrue,
          );
        }
        if (engine == 'shapeMatch') {
          expect(
            tester
                .widgetList<OutlinedButton>(find.byType(OutlinedButton))
                .every((b) => b.onPressed == null),
            isTrue,
          );
        }
      },
    );
  }
  testWidgets(
    'math renderer handles valid, invalid and oversized formulas at phone width',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const LessonRichText(r'Phân số $\frac{2}{3}$ và $x^2+1$'),
                  const LessonRichText(r'$\unknowncommand{$'),
                  LessonRichText('\$${'x' * 501}\$'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Math), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
