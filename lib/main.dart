import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'journey_app.dart';
import 'learning_store.dart';

export 'journey_app.dart';
export 'learning_store.dart';
export 'learning_catalog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = LearningStore(await SharedPreferences.getInstance());
  runApp(LearnApp(store: store));
}
