import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/theme/app_theme.dart';
import 'package:mathlingo/features/practice_garden/screens/math_flappy_game_screen.dart';

void main() {
  testWidgets('shows the difficulty selector before starting', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MathFlappyGameScreen(),
      ),
    );

    expect(find.text('Chọn độ khó'), findsOneWidget);
    expect(find.text('Dễ'), findsOneWidget);
    expect(find.text('Vừa'), findsOneWidget);
    expect(find.text('Khó'), findsOneWidget);
  });

  testWidgets('shows the Vietnamese difficulty label and HUD after starting', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MathFlappyGameScreen(),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Dễ'));
    await tester.pump();

    expect(find.text('Dễ'), findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('_GameMode'), findsNothing);
  });
}
