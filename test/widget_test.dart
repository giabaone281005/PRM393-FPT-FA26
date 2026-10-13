import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mathlingo/main.dart';
import 'package:mathlingo/data/providers/app_state_provider.dart';

void main() {
  testWidgets('MathLingo smoke test - renders header and title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ],
        child: const MathLingoApp(),
      ),
    );

    // Verify MathLingo title is found on splash
    expect(find.text('MathLingo'), findsOneWidget);

    // Advance splash timer to complete navigation cleanly
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();
  });
}
