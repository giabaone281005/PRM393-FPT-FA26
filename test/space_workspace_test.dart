import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/experiments/solid_catalog.dart';
import 'package:brilliant_mobile/experiments/space_workspace.dart';

void main() {
  testWidgets(
    'Saved solid reference remains independent while dimensions change',
    (tester) async {
      final spec = solidExperiments['geometry']!.single;
      var state = spec.initialData();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, update) => SpaceWorkspace(
                  spec: spec,
                  data: state,
                  locked: false,
                  onChanged: (next) => update(() => state = next),
                ),
              ),
            ),
          ),
        ),
      );
      Future<void> tap(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.tap(finder);
        await tester.pump();
      }

      await tap('save-solid-reference');
      await tap('depth-more');
      expect(state['depth'], 3);
      expect((state['comparisonReference'] as Map)['depth'], 2);
      expect(spec.isCorrect(state), isTrue);
      await tap('clear-solid-reference');
      expect(state['comparisonReference'], isNull);
      expect(spec.isCorrect(state), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Solid controls change dimensions and are disabled when locked', (
    tester,
  ) async {
    final spec = solidExperiments['geometry']!.single;
    var state = spec.initialData();
    var locked = false;
    Future<void> render() => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpaceWorkspace(
              spec: spec,
              data: state,
              locked: locked,
              onChanged: (next) => state = next,
            ),
          ),
        ),
      ),
    );
    await render();
    final more = find.byKey(const ValueKey('depth-more'));
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pump();
    expect(state['depth'], 3);
    expect(spec.isCorrect(state), isTrue);
    locked = true;
    await render();
    expect(tester.widget<IconButton>(more).onPressed, isNull);
  });

  testWidgets('Layer controls reorder the actual geological model', (
    tester,
  ) async {
    final spec = solidExperiments['geography']!.firstWhere(
      (s) => s.mechanism == 'strataExplorer',
    );
    var state = spec.initialData();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, update) => SpaceWorkspace(
                spec: spec,
                data: state,
                locked: false,
                onChanged: (next) => update(() => state = next),
              ),
            ),
          ),
        ),
      ),
    );
    final down = find.byKey(const ValueKey('layer-0-down'));
    await tester.ensureVisible(down);
    await tester.tap(down);
    await tester.pump();
    expect(state['layers'], [10, 30, 20]);
    final nextDown = find.byKey(const ValueKey('layer-1-down'));
    await tester.ensureVisible(nextDown);
    await tester.tap(nextDown);
    await tester.pump();
    expect(spec.isCorrect(state), isTrue);
  });

  for (final spec in solidExperiments.values.expand((v) => v)) {
    testWidgets(
      '${spec.id}: fits 320px with large text and camera does not change lesson',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var changes = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 800),
                  textScaler: TextScaler.linear(1.6),
                  disableAnimations: true,
                ),
                child: SingleChildScrollView(
                  child: SpaceWorkspace(
                    spec: spec,
                    data: spec.initialData(),
                    locked: false,
                    onChanged: (_) => changes++,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(const ValueKey('space-scene')),
          const Offset(50, 25),
        );
        await tester.pump();
        expect(changes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
