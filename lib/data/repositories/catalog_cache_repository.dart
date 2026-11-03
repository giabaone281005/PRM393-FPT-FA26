import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CatalogCacheRepository {
  CatalogCacheRepository(this.preferences);
  final SharedPreferences preferences;

  Map<String, dynamic>? read(String owner) {
    try {
      final raw = preferences.getString('matlingo:catalog:$owner');
      return raw == null
          ? null
          : (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String owner, Map<String, dynamic> catalog) async {
    await preferences.setString('matlingo:catalog:$owner', jsonEncode(catalog));
  }
}
