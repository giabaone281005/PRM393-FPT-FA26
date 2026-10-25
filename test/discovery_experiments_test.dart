import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/experiments/discovery_catalog.dart';
import 'package:brilliant_mobile/experiments/discovery_experiments.dart';

const discoverySolutionStates = <String, Map<String, dynamic>>{
  'geometry-rectangle': {
    'points': [
      [0, 0],
      [3, 0],
      [3, 2],
      [0, 2],
    ],
  },
  'geometry-mirror': {
    'cells': [11, 16, 23],
  },
  'geometry-tangram': {
    'turns': [0, 2],
    'placed': [true, true],
  },
  'coding-route': {
    'commands': ['R', 'R', 'R', 'D', 'D', 'D'],
  },
  'coding-loop': {
    'body': ['R', 'D'],
    'repeat': 3,
  },
  'coding-sort': {
    'stages': [0, 1, 2, 0, 1, 0],
    'result': [1, 2, 3, 4],
  },
  'circuits-wire': {
    'edges': ['0-1', '2-3'],
  },
  'circuits-logic': {
    'switches': [false, true, true],
  },
  'circuits-light': {
    'rgb': [1.0, 1.0, 0.0],
  },
  'probability-bag': {
    'balls': ['B', 'B', 'R', 'R', 'R', 'R'],
  },
  'probability-space': {
    'outcomes': ['SS', 'SN', 'NS', 'NN'],
  },
  'probability-spinner': {'sectors': 3},
};

void main() {
  testWidgets('Connect source to lamp and back, then reject source short', (
    tester,
  ) async {
    final spec = discoveryExperiments['circuits']![0];
    var data = spec.initialData();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 320,
              child: StatefulBuilder(
                builder: (context, update) => DiscoveryExperiment(
                  spec: spec,
                  data: data,
                  locked: false,
                  onChanged: (next) => update(() => data = next),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (final node in [0, 1, 2, 3]) {
      await tester.tap(find.byType(IconButton).at(node));
      await tester.pump();
    }
    expect(data['edges'], ['0-1', '2-3']);
    expect(spec.isCorrect(data), isTrue);
    for (final node in [0, 3]) {
      await tester.tap(find.byType(IconButton).at(node));
      await tester.pump();
    }
    expect(spec.isCorrect(data), isFalse);
  });
  test(
    'Comparator network computes real outputs and sorts all permutations',
    () {
      final spec = discoveryExperiments['coding']![2];
      const stages = [0, 1, 2, 0, 1, 0];
      expect(comparatorTestInputs.length, 24);
      for (final input in comparatorTestInputs) {
        expect(runComparatorNetwork(stages, input), [1, 2, 3, 4]);
      }
      expect(
        spec.isCorrect({
          'stages': [0, 1, 2],
          'result': [1, 2, 3, 4],
        }),
        isFalse,
      );
      expect(spec.isCorrect({'stages': stages, 'result': []}), isFalse);
    },
  );
  test(
    'Circuit needs two free wires and rejects shorting fixed components',
    () {
      final spec = discoveryExperiments['circuits']![0];
      expect(
        spec.isCorrect({
          'edges': ['0-1', '2-3'],
        }),
        isTrue,
      );
      for (final bad in [
        ['0-1'],
        ['0-3', '1-2'],
        ['0-1', '2-3', '0-3'],
        ['0-1', '2-3', '1-2'],
      ]) {
        expect(spec.isCorrect({'edges': bad}), isFalse);
      }
    },
  );
  testWidgets('Build comparator network then run computed output', (
    tester,
  ) async {
    final spec = discoveryExperiments['coding']![2];
    var data = spec.initialData();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, update) => DiscoveryExperiment(
                spec: spec,
                data: data,
                locked: false,
                onChanged: (next) => update(() => data = next),
              ),
            ),
          ),
        ),
      ),
    );
    for (final stage in [0, 1, 2, 0, 1, 0]) {
      await tester.tap(find.text('Nối ${stage + 1}–${stage + 2}'));
      await tester.pump();
    }
    expect(data['result'], isEmpty);
    await tester.tap(find.text('Chạy 24 đầu vào'));
    await tester.pump();
    expect(data['result'], [1, 2, 3, 4]);
    expect(spec.isCorrect(data), isTrue);
    expect(find.text('24/24 đầu vào được sắp đúng'), findsOneWidget);
  });
  test('Validators reject malformed geometry and colour state', () {
    expect(
      discoveryExperiments['geometry']![0].isCorrect({
        'points': [
          [0, 0],
          [6, 0],
          [6, 1],
          [0, 1],
        ],
      }),
      isFalse,
    );
    expect(
      discoveryExperiments['geometry']![2].isCorrect({
        'turns': [0, 2],
        'placed': [],
      }),
      isFalse,
    );
    expect(
      discoveryExperiments['circuits']![2].isCorrect({
        'rgb': [1, 1, -1],
      }),
      isFalse,
    );
    expect(
      discoveryExperiments['circuits']![0].isCorrect({
        'edges': ['0-1', '1-2', '2-3', '0-3', '0-2'],
      }),
      isFalse,
    );
  });
  testWidgets(
    'All discovery workspaces fit a narrow phone without emitting changes during build',
    (tester) async {
      tester.view.physicalSize = const Size(240, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final spec in discoveryExperiments.values.expand((v) => v)) {
        var changes = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: DiscoveryExperiment(
                  key: ValueKey(spec.id),
                  spec: spec,
                  data: spec.initialData(),
                  locked: false,
                  onChanged: (_) => changes++,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(changes, 0, reason: spec.id);
        expect(tester.takeException(), isNull, reason: spec.id);
      }
    },
  );

  test('Twelve distinct mechanisms with unsolved initial state and valid solutions', () {
    final specs = discoveryExperiments.values.expand((v) => v).toList();
    expect(specs.length, 12);
    expect(specs.map((s) => s.mechanism).toSet().length, 12);
    for (final s in specs) {
      expect(supportsDiscoveryExperiment(s.mechanism), isTrue, reason: s.id);
      expect(s.isCorrect(s.initialData()), isFalse, reason: s.id);
      expect(s.isCorrect(discoverySolutionStates[s.id]!), isTrue, reason: s.id);
    }
  });
  test('Route rejects collisions and leaving the board', () {
    final route = discoveryExperiments['coding']!.first;
    expect(
      route.isCorrect({
        'commands': ['R', 'D', 'R', 'R', 'D', 'D'],
      }),
      isFalse,
    );
    expect(
      route.isCorrect({
        'commands': ['L', 'R', 'R', 'R', 'R', 'D', 'D', 'D'],
      }),
      isFalse,
    );
  });
  test('Bag and sample space reject shortcuts using duplicates', () {
    expect(
      discoveryExperiments['probability']![0].isCorrect({
        'balls': ['B', 'B', 'R'],
      }),
      isFalse,
    );
    expect(
      discoveryExperiments['probability']![1].isCorrect({
        'outcomes': ['SS', 'SS', 'SN', 'NS'],
      }),
      isFalse,
    );
  });
  test(
    'Wire circuit needs return path and source, not just a lamp connection',
    () {
      expect(
        discoveryExperiments['circuits']![0].isCorrect({
          'edges': ['0-1', '1-2', '2-3'],
        }),
        isFalse,
      );
    },
  );
}
