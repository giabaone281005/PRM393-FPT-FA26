import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  timeout: const Duration(minutes: 15),
  responseDataCallback: (data) async {
    await writeResponseData(
      data,
      testOutputFilename: 'admin-web-result',
      destinationDirectory: Platform.environment['HEADED_WEB_RESULTS'],
    );
  },
);
