import 'package:brilliant_mobile/app_motion.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Actions fit their label at phone and desktop widths and large text',
    (tester) async {
      for (final width in [320.0, 1000.0]) {
        for (final textScale in [1.0, 2.0]) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
                child: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryAction(
                          onPressed: () {},
                          child: const Text('Tiếp tục'),
                        ),
                        PrimaryAction(
                          onPressed: () {},
                          child: const Text('Hoàn thành hành trình'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final buttons = find.byType(FilledButton);
          final compact = tester.getSize(buttons.at(0));
          expect(compact.width, lessThanOrEqualTo((width - 40).clamp(0, 320)));
          if (textScale == 1) expect(compact.width, lessThan(width - 40));
          expect(compact.height, greaterThanOrEqualTo(48));
          expect(tester.getSize(buttons.at(1)).width, lessThanOrEqualTo(320));
          expect(tester.takeException(), isNull);
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );

  for (final reduced in [false, true]) {
    testWidgets('Routes open and close with reduced motion = $reduced', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  DiscoveryRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Trang bài học')),
                  ),
                ),
                child: const Text('Mở bài'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Mở bài'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Trang bài học'), findsOneWidget);
      final pageContext = tester.element(find.text('Trang bài học'));
      if (reduced) {
        expect(
          find.ancestor(
            of: find.text('Trang bài học'),
            matching: find.byType(SlideTransition),
          ),
          findsNothing,
        );
      } else {
        expect(
          find.ancestor(
            of: find.text('Trang bài học'),
            matching: find.byType(SlideTransition),
          ),
          findsWidgets,
        );
      }
      await tester.pumpAndSettle();
      Navigator.pop(pageContext);
      await tester.pumpAndSettle();
      expect(find.text('Mở bài'), findsOneWidget);
      expect(find.text('Trang bài học'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
