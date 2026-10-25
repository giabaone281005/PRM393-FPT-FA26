import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/main.dart';
import 'package:brilliant_mobile/experiments/diverse_catalog.dart';

void main() {
  testWidgets('Number-line lesson exposes three progressively revealed hints', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = LearningStore(await SharedPreferences.getInstance());
    await store.createDeviceProfile('An');
    final spec = diverseExperiments['math']!.single;
    final topic = topicById('math');
    // Use the existing topic runner at the matching activity index.
    final index = topic.experiments.indexWhere((s) => s.id == spec.id);
    await store.saveProgress('math', {'version': 3, 'step': index});
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: LessonPage(topic: topic, store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Gợi ý nhỏ'));
    await tester.tap(find.text('Gợi ý nhỏ'));
    await tester.pumpAndSettle();
    expect(find.text('Mức gợi ý 1/3'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('reveal-next-hint')));
    await tester.tap(find.byKey(const ValueKey('reveal-next-hint')));
    await tester.pumpAndSettle();
    expect(find.text('Mức gợi ý 2/3'), findsOneWidget);
    expect((store.progress('math')!['hintLevels'] as Map)[spec.id], 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    store.dispose();
  });

  testWidgets(
    'Spatial hint depth survives save and reopening without inflating hint activity count',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LearningStore(prefs);
      await store.createDeviceProfile('An');
      final topic = topicById('geography');
      Widget lesson(LearningStore current) => MaterialApp(
        theme: buildAppTheme(),
        home: LessonPage(topic: topic, store: current),
      );
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

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
      store.dispose();
      restored.dispose();
    },
  );
}
