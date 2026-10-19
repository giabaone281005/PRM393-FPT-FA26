import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/theme/app_theme.dart';
import 'package:mathlingo/data/models/kid_profile.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';
import 'package:mathlingo/features/learning_engine/study_screen.dart';
import 'package:mathlingo/features/practice_garden/screens/practice_garden_screen.dart';
import 'package:mathlingo/features/shared/widgets/app_header.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GardenState extends AppStateProvider {
  @override
  Future<void> refreshFromCloud() async {}
  @override
  bool get hasKids => true;
  @override
  KidProfile get currentKid =>
      KidProfile(id: 'garden-kid', nickname: 'An', grade: 2, currentHearts: 2);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final dark in [false, true]) {
    testWidgets(
      'garden remains scrollable with large text in ${dark ? 'dark' : 'light'} mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.8)),
              child: child!,
            ),
            home: const PracticeGardenScreen(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final progress = find.widgetWithText(OutlinedButton, 'Tiến độ học tập');
        await tester.ensureVisible(progress);
        expect(progress.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'garden reuses the student header and preserves the practice destination',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = GardenState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppStateProvider>.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const PracticeGardenScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('2/5'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Luyện tập câu hỏi'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StudyScreen>(find.byType(StudyScreen)).kind,
        'practice',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      state.dispose();
    },
  );
}
