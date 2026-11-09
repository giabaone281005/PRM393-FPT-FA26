import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'features/admin/cms_redirect.dart' as cms;

/// The Admin application opens Matlingo Admin, including its authoring Studio.
/// Legacy editor files remain compatibility sources, never launched here.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const destination = String.fromEnvironment('CMS_URL', defaultValue: '/cms/');
  if (cms.openCms(destination)) return;
  runApp(
    MaterialApp(
      title: 'Matlingo Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SelectableText(
              'Mở Matlingo Admin bằng trình duyệt web.\nĐịa chỉ: $destination',
            ),
          ),
        ),
      ),
    ),
  );
}
