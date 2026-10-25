import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/experiments/diverse_catalog.dart';

void main() {
  late SharedPreferences prefs;
  late LearningStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = LearningStore(prefs);
    await store.createDeviceProfile('An');
  });
  tearDown(() => store.dispose());

  Future<void> tapLessonControl(WidgetTester tester, Finder finder) async {
    // ListView lazily builds its children. Scroll the lesson controller first
    // rather than calling ensureVisible on an element that does not exist yet.
    // Controller scrolling also avoids dragging the interactive 3D canvas.
    final list = tester.widget<ListView>(
      find
          .descendant(
            of: find.byType(LessonPage),
            matching: find.byType(ListView),
          )
          .first,
    );
    final controller = list.controller!;
    for (var i = 0; finder.evaluate().isEmpty && i < 40; i++) {
      final position = controller.position;
      final next = (position.pixels + 180).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next == position.pixels) {
        break;
      }
      controller.jumpTo(next);
      await tester.pumpAndSettle();
    }
    expect(
      finder,
      findsOneWidget,
      reason: 'Expected the lesson control to be built after scrolling',
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('Number-line lesson exposes three progressively revealed hints', (
    tester,
  ) async {
    final spec = diverseExperiments['math']!.single;
    final topic = topicById('math');
    // Use the existing topic runner at the matching activity index.
    final index = topic.experiments.indexWhere((s) => s.id == spec.id);
    await tester.runAsync(
      () => store.saveProgress('math', {'version': 3, 'step': index}),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LessonPage(topic: topic, store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tapLessonControl(tester, find.text('Gợi ý nhỏ'));
    expect(find.text('Mức gợi ý 1/3'), findsOneWidget);
    await tapLessonControl(
      tester,
      find.byKey(const ValueKey('reveal-next-hint')),
    );
    expect(find.text('Mức gợi ý 2/3'), findsOneWidget);
    expect((store.progress('math')!['hintLevels'] as Map)[spec.id], 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets(
    'Spatial hint depth survives save and reopening without inflating hint activity count',
    (tester) async {
      final topic = topicById('geography');
      Widget lesson(LearningStore current) => MaterialApp(
        theme: buildAppTheme(),
        home: LessonPage(topic: topic, store: current),
      );
      Future<void> tap(Finder finder) => tapLessonControl(tester, finder);

      await tester.pumpWidget(lesson(store));
      await tester.pumpAndSettle();
      await tap(find.text('Gợi ý nhỏ'));
      await tap(find.byKey(const ValueKey('reveal-next-hint')));
      expect(find.text('Mức gợi ý 2/3'), findsOneWidget);
      final saved = store.progress('geography')!;
      expect((saved['hintLevels'] as Map)['geography-globe-grid'], 2);
      expect(saved['hints'], ['geography-globe-grid']);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => store.saveProgress('geography', saved));
      final restored = LearningStore(prefs);
      await tester.pumpWidget(lesson(restored));
      await tester.pumpAndSettle();
      await tap(find.text('Gợi ý nhỏ'));
      expect(find.text('Mức gợi ý 2/3'), findsOneWidget);
      await tap(find.byKey(const ValueKey('reveal-next-hint')));
      expect(find.text('Mức gợi ý 3/3'), findsOneWidget);
      expect(find.byKey(const ValueKey('reveal-next-hint')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      restored.dispose();
    },
  );
}
