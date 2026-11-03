import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/data/models/mobile_catalog.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/data/providers/learning_sync_controller.dart';
import 'package:brilliant_mobile/data/repositories/catalog_cache_repository.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'learning_sync_test.dart'
    show SyncTestAuth, SyncTestBackups, SyncTestRepository;

Map<String, dynamic> exportedCatalog() {
  final data = (jsonDecode(
    File('supabase/catalog.json').readAsStringSync(),
  ) as Map).cast<String, dynamic>();
  return {
    'release': {'id': '33333333-3333-4333-8333-333333333333'},
    'topics': [
      for (final t in data['topics']) {...t as Map, 'status': 'active'},
    ],
    'activities': [
      for (final a in data['activities']) {...a as Map, 'activity_id': a['id']},
    ],
  };
}

class CatalogTestRepository extends SyncTestRepository {
  Map<String, dynamic> current = exportedCatalog();
  @override
  Future<Map<String, dynamic>> catalog(String owner) async {
    if (offline) throw TimeoutException('offline');
    return current;
  }
}

void main() {
  test('JSONB integer serialization preserves all published mobile topics', () {
    dynamic jsonbNumbers(dynamic value) {
      if (value is Map) {
        return value.map((key, item) => MapEntry(key, jsonbNumbers(item)));
      }
      if (value is List) return value.map(jsonbNumbers).toList();
      if (value is double && value == value.toInt()) return value.toInt();
      return value;
    }

    final catalog = Map<String, dynamic>.from(
      jsonbNumbers(exportedCatalog()) as Map,
    );
    expect(decodeMobileCatalog(catalog), hasLength(20));
    expect(
      decodeMobileCatalog(catalog).expand((topic) => topic.experiments),
      hasLength(139),
    );
    final light = (catalog['activities'] as List).firstWhere(
      (activity) => activity['activity_id'] == 'circuits-light',
    );
    light['initial_state']['rgb'][2] = 0.5;
    expect(
      decodeMobileCatalog(catalog).map((topic) => topic.id),
      isNot(contains('circuits')),
    );
    light['initial_state']['rgb'][2] = '1';
    expect(
      decodeMobileCatalog(catalog).map((topic) => topic.id),
      isNot(contains('circuits')),
    );
  });

  test('published export matches every shipped activity; mismatched content is excluded', () {
    final catalog = exportedCatalog();
    expect(decodeMobileCatalog(catalog).length, 20);
    expect(
      decodeMobileCatalog(catalog).expand((t) => t.experiments).length,
      139,
    );
    (catalog['activities'] as List).first['config'] = {'unexpected': true};
    expect(
      decodeMobileCatalog(catalog).map((t) => t.id),
      isNot(contains('logic')),
    );
  });

  testWidgets(
    'admin metadata and visibility update mobile; empty catalog is safe',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      await store.createDeviceProfile('Test');
      final catalog = exportedCatalog();
      (catalog['topics'] as List).first['title'] = 'Server topic title';
      (catalog['topics'] as List).first['icon_key'] = 'terminal';
      (catalog['topics'] as List)[1]['status'] = 'archived';
      store.applyCatalog(catalog);
      expect(store.topicForId('logic').title, 'Server topic title');
      expect(store.topicForId('logic').icon, Icons.terminal);
      expect(store.topicAvailable('math'), false);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ListenableBuilder(
            listenable: store,
            builder: (_, _) => Scaffold(body: ExplorePage(store: store)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      store.applyCatalog({'topics': [], 'activities': []});
      await tester.pumpAndSettle();
      expect(
        find.text('Chưa có chủ đề phù hợp. Thử bộ lọc khác nhé.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    },
  );

  test(
    'sync refreshes metadata without queued lessons and caches it per owner',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = LearningStore(preferences, enableServerSync: true);
      await store.createDeviceProfile('Test');
      await store.finishOnboarding(['logic'], 10);
      final auth = SyncTestAuth();
      final cloud = CloudBackupController(
        store: store,
        auth: auth,
        repository: SyncTestBackups(),
      );
      final repo = CatalogTestRepository();
      final cache = CatalogCacheRepository(preferences);
      final sync = LearningSyncController(
        store: store,
        cloud: cloud,
        repository: repo,
        automatic: false,
        catalogCache: cache,
      );
      await Future<void>.delayed(Duration.zero);
      await sync.syncNow();
      expect(store.availableTopics.length, 20);
      (repo.current['topics'] as List).first['title'] = 'Updated on server';
      (repo.current['topics'] as List)[1]['status'] = 'archived';
      await sync.syncNow();
      expect(store.topicForId('logic').title, 'Updated on server');
      expect(store.topicAvailable('math'), false);
      repo.offline = true;
      await sync.syncNow();
      expect(store.topicAvailable('math'), false);
      expect(cache.read('owner-b'), isNull);
      expect(decodeMobileCatalog(cache.read('owner-a')!).length, 19);
      sync.dispose();
      final restarted = LearningSyncController(
        store: store,
        cloud: cloud,
        repository: repo,
        automatic: false,
        catalogCache: cache,
      );
      expect(store.topicForId('logic').title, 'Updated on server');
      expect(store.topicAvailable('math'), false);
      restarted.dispose();
      cloud.dispose();
      store.dispose();
      await auth.events.close();
    },
  );
}
