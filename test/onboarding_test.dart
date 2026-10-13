import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mathlingo/features/onboarding/onboarding_screen.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';

void main() {
  testWidgets('OnboardingScreen renders and pumps without layout exception', (tester) async {
    // Set a typical mobile/tablet test size
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('TIẾP THEO'), findsOneWidget);

    // Simulate mouse move / hover
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(const Offset(400, 600));
    await tester.pump();
    await gesture.removePointer();
  });
}
