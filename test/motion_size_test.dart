import 'package:brilliant_mobile/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final accessibleNavigation in [false, true]) {
    testWidgets(
      'reduced motion resizes hints without a zero-duration render animation; accessible=$accessibleNavigation',
      (tester) async {
        var expanded = false;
        late StateSetter change;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                disableAnimations: !accessibleNavigation,
                accessibleNavigation: accessibleNavigation,
              ),
              child: StatefulBuilder(
                builder: (context, setState) {
                  change = setState;
                  return Scaffold(
                    body: MotionSize(
                      child: SizedBox(width: 200, height: expanded ? 240 : 0),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        expect(
          find.descendant(
            of: find.byType(MotionSize),
            matching: find.byType(AnimatedSize),
          ),
          findsNothing,
        );
        for (var i = 0; i < 6; i++) {
          change(() => expanded = !expanded);
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  testWidgets('normal motion retains the existing finite size transition', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MotionSize(child: SizedBox(width: 100, height: 100)),
        ),
      ),
    );
    final animation = tester.widget<AnimatedSize>(find.byType(AnimatedSize));
    expect(animation.duration, const Duration(milliseconds: 240));
    expect(animation.alignment, Alignment.topCenter);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
