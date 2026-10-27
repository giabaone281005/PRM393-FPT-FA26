import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'journey_app.dart';
import 'learning_store.dart';
import 'data/providers/cloud_backup_controller.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/backup_repository.dart';
import 'features/account/cloud_account_page.dart';
import 'features/engines/engine_scope.dart';
import 'data/providers/learning_sync_controller.dart';
import 'data/repositories/learning_repository.dart';
import 'features/account/learning_sync_scope.dart';

export 'journey_app.dart';
export 'learning_store.dart';
export 'learning_catalog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  final store = LearningStore(
    await SharedPreferences.getInstance(),
    enableServerSync: url.isNotEmpty && key.isNotEmpty,
  );
  if (url.isEmpty || key.isEmpty) {
    runApp(EngineHost(child: LearnApp(store: store)));
    return;
  }
  await Supabase.initialize(url: url, publishableKey: key, debug: false);
  final client = Supabase.instance.client;
  final cloud = CloudBackupController(
    store: store,
    auth: SupabaseAuthRepository(client),
    repository: SupabaseBackupRepository(client),
  );
  final sync = LearningSyncController(
    store: store,
    cloud: cloud,
    repository: SupabaseLearningRepository(
      client: client,
      url: url,
      publishableKey: key,
    ),
  );
  runApp(
    CloudScope(
      controller: cloud,
      child: LearningSyncScope(
        controller: sync,
        child: EngineHost(child: LearnApp(store: store)),
      ),
    ),
  );
}
