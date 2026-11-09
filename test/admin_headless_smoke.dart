import 'package:integration_test/integration_test.dart';

import 'admin_dashboard_test.dart' as dashboard;
import 'admin_content_test.dart' as content;
import 'slide_cms_test.dart' as studio;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.reportData = {
    'mode': 'headless',
    'backend': 'shared deterministic contract; live SQL tested separately',
  };
  dashboard.main();
  content.main();
  studio.main();
}
