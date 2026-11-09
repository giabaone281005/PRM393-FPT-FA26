import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:integration_test/integration_test.dart';

import 'admin_dashboard_test.dart' as dashboard_tests;

// Run the existing denied-role, realtime, form and responsive-layout regressions
// inside a real browser, with mock repositories and no backend credentials.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.reportData = {'platform': 'web', 'role': 'admin', 'mode': 'mock'};
  if (!kIsWeb) {
    throw StateError('Run Admin web smoke with flutter drive -d web-server.');
  }
  dashboard_tests.main();
}
