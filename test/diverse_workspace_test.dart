import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/experiments/diverse_catalog.dart';
import 'package:brilliant_mobile/experiments/diverse_workspace.dart';

void main() {
  testWidgets(
    'Counterexample controls fit a 320px lesson with large text and update the model',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final spec = diverseExperiments['logic']!.single;
      var data = spec.initialData();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.6),
              ),
              child: StatefulBuilder(
                builder: (context, update) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    DiverseWorkspace(
                      spec: spec,
                      data: data,
                      locked: false,
                      onChanged: (next) => update(() => data = next),
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
      final control = find.byKey(const ValueKey('condition-a'));
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(data['a'], isTrue);
      expect(data['b'], isFalse);
      expect(spec.isCorrect(data), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
