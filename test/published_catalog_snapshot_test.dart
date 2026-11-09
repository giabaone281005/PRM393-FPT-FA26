import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/data/models/mobile_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile decodes every lesson and newly authored topic in the hosted snapshot', () {
    final snapshot = jsonDecode(
      File('supabase/content/published_catalog_20261110.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final topics = decodeMobileCatalog(snapshot);
    expect(
      topics.map((t) => t.id).toSet(),
      (snapshot['topics'] as List).map((t) => t['id']).toSet(),
    );
    expect(
      topics.expand((t) => t.experiments).map((s) => s.id).toSet(),
      (snapshot['activities'] as List).map((a) => a['activity_id']).toSet(),
    );
  });
}
