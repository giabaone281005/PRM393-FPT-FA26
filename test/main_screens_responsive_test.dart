import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mathlingo/core/theme/app_theme.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/features/home/screens/home_screen.dart';
import 'package:mathlingo/features/kid_profile/screens/kid_profile_screen.dart';
import 'package:mathlingo/features/treasure_map/screens/treasure_map_screen.dart';

import 'learning_overview_test.dart' show OverviewState;

void main() {
  for (final entry in <String, Widget>{
    'home': const HomeScreen(),
    'kid profile': const KidProfileScreen(),
    'treasure map': const TreasureMapScreen(),
  }.entries) {
    testWidgets('${entry.key} at 320px with large text', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = OverviewState();
      addTearDown(state.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!,
            ),
            home: entry.value,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final error = tester.takeException();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(
        error,
        isNull,
        reason: 'Whole ${entry.key} must fit narrow large-text layout',
      );
    });
  }
}
