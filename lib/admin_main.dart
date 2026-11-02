import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';
import 'data/providers/admin_dashboard_controller.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'features/admin/admin_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || key.isEmpty) {
    runApp(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(
          body: Center(
            child: Text('Cần cấu hình kết nối máy chủ để mở Matlingo Admin.'),
          ),
        ),
      ),
    );
    return;
  }
  await Supabase.initialize(url: url, publishableKey: key, debug: false);
  final client = Supabase.instance.client;
  runApp(
    AdminApp(
      controller: AdminDashboardController(
        auth: SupabaseAuthRepository(client),
        repository: SupabaseAdminRepository(client),
      ),
    ),
  );
}
