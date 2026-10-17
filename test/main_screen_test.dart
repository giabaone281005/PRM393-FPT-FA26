import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mathlingo/features/main/main_screen.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';

void main() {
  testWidgets('MainScreen renders and handles mouse events', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AppStateProvider())],
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gia đình MathLingo'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);

    // Simulate mouse move / hover
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(const Offset(200, 300));
    await tester.pump();
    await gesture.moveTo(const Offset(300, 500));
    await tester.pump();
    await gesture.removePointer();
  });
}
