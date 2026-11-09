import 'dart:async';

import 'package:brilliant_mobile/data/models/admin_dashboard.dart';
import 'package:brilliant_mobile/data/models/learning_journal.dart';
import 'package:brilliant_mobile/data/providers/admin_dashboard_controller.dart';
import 'package:brilliant_mobile/data/providers/cloud_backup_controller.dart';
import 'package:brilliant_mobile/data/providers/learning_sync_controller.dart';
import 'package:brilliant_mobile/data/repositories/admin_repository.dart';
import 'package:brilliant_mobile/data/repositories/learning_repository.dart';
import 'package:brilliant_mobile/features/admin/admin_app.dart';
import 'package:brilliant_mobile/journey_app.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_dashboard_test.dart' show TestAdminAuth, TestAdminRepository;
import 'learning_sync_test.dart'
    show SyncTestAuth, SyncTestBackups, SyncTestRepository;

/// Shared deterministic server contract. Real database authority is exercised by
/// supabase/tests/admin_content_smoke.sql with transaction-local fixtures.
class CmsAdminRepository extends TestAdminRepository
    implements AdminLessonGenerator {
  int generations = 0;
  Completer<Map<String, dynamic>>? delayedGeneration;
  @override
  Future<Map<String, dynamic>> generateLesson(
    String owner,
    String prompt,
    String topic,
  ) async {
    generations++;
    if (delayedGeneration != null) return delayedGeneration!.future;
    return lessonPayload();
  }

  final lessons = <String, Map<String, dynamic>>{};
  final catalogEvents = StreamController<void>.broadcast(sync: true);
  int release = 0;
  CmsAdminRepository() {
    topics.clear();
  }
  Map<String, dynamic> get catalog => {
    'release': {
      'id': '33333333-3333-4333-8333-${release.toString().padLeft(12, '0')}',
    },
    'topics': learningCopy({'items': topics})['items'],
    'activities': lessons.values
        .where((r) => r['editor_status'] == 'active')
        .map((r) => learningCopy(r))
        .toList(),
  };
  @override
  Future<Map<String, dynamic>> read(
    String owner,
    String section, {
    String search = '',
    int offset = 0,
  }) async {
    if (section.startsWith('lessons:')) {
      final rows = lessons.values
          .where((r) => r['topic_id'] == section.substring(8))
          .toList();
      return {'items': rows, 'total': rows.length};
    }
    return super.read(owner, section, search: search, offset: offset);
  }

  @override
  Future<void> mutate(
    String owner,
    String operationId,
    String type,
    Map<String, dynamic> payload,
  ) async {
    operations.add(operationId);
    if (failMutation) throw const AdminFailure('Test network failure');
    if (type == 'topic.save') {
      final index = topics.indexWhere((r) => r['id'] == payload['id']);
      final row = {...payload, 'activity_count': 0};
      if (index < 0) {
        topics.add(row);
      } else {
        topics[index] = row;
      }
    } else if (type == 'lesson.save') {
      final old = lessons[payload['id']];
      if ((old?['revision'] ?? 0) != payload['revision']) {
        throw const AdminFailure('Content revision conflict');
      }
      lessons[payload['id'] as String] = {
        ...payload,
        'activity_id': payload['id'],
        'content_version': (old?['content_version'] as int? ?? 0) + 1,
        'evaluator_version': 3,
        'mechanism': 'reasonedChoice',
        'mechanism_version': 1,
        'initial_state': {'answer': -1, 'reason': -1},
        'hint_levels': [payload['hint']],
        'position': payload['sort_order'],
        'editor_status': payload['status'],
        'revision': (old?['revision'] as int? ?? 0) + 1,
      };
      release++;
    }
    catalogEvents.add(null);
  }
}

class CmsLearningRepository extends SyncTestRepository
    implements CatalogRealtimeRepository {
  CmsLearningRepository(this.cms);
  final CmsAdminRepository cms;
  @override
  Future<Map<String, dynamic>> catalog(String owner) async {
    if (offline) throw TimeoutException('offline');
    return cms.catalog;
  }

  @override
  Stream<void> watchCatalog(String owner) => cms.catalogEvents.stream;
}

Map<String, dynamic> lessonPayload({
  int revision = 0,
  String status = 'active',
}) => {
  'id': 'cms-lesson',
  'topic_id': 'cms-topic',
  'revision': revision,
  'title': 'Một nửa của tám',
  'stage': 'Khám phá',
  'prompt': 'Một nửa của 8 là bao nhiêu?',
  'hint': 'Chia thành hai nhóm.',
  'explanation': '8 chia 2 bằng 4.',
  'status': status,
  'sort_order': 0,
  'config': {
    'knowledge': 'Chia đều',
    'source': 'QA',
    'choices': ['4', '8'],
    'reasons': ['Chia hai phần bằng nhau', 'Giữ nguyên'],
    'answer': 0,
    'reason': 0,
  },
};

void main() {
  testWidgets(
    'Gemini prompt fills an editable draft and never publishes automatically',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = TestAdminAuth(), cms = CmsAdminRepository();
      final controller = AdminDashboardController(auth: auth, repository: cms);
      await tester.pumpWidget(AdminApp(controller: controller));
      await tester.pumpAndSettle();
      await controller.saveTopic(
        const AdminTopic(
          id: 'cms-topic',
          title: 'CMS',
          subtitle: '',
          subject: 'Toán',
          status: 'active',
          sortOrder: 0,
        ),
      );
      controller.selectSection('topics');
      await tester.pumpAndSettle();
      Future<void> tap(Finder finder) async {
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            250,
            scrollable: find.byType(Scrollable).first,
          );
        }
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap(find.byKey(const ValueKey('lessons-cms-topic')));
      await tap(find.byKey(const ValueKey('admin-add-lesson')));
      await tap(find.byKey(const ValueKey('generate-lesson')));
      expect(cms.generations, 0);
      await tester.enterText(
        find.byKey(const ValueKey('lesson-ai-prompt')),
        'Tạo bài phân số cho học sinh lớp 4',
      );
      await tap(find.byKey(const ValueKey('generate-lesson')));
      expect(cms.generations, 1);
      expect(cms.lessons, isEmpty);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('lesson-title')))
            .controller!
            .text,
        'Một nửa của tám',
      );
      await tap(find.byKey(const ValueKey('publish-lesson')));
      expect(cms.lessons.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await auth.events.close();
      await cms.events.close();
      await cms.catalogEvents.close();
    },
  );

  test('late AI result is discarded after the admin changes account', () async {
    final auth = TestAdminAuth(), cms = CmsAdminRepository();
    final controller = AdminDashboardController(auth: auth, repository: cms);
    await Future<void>.delayed(Duration.zero);
    cms.delayedGeneration = Completer<Map<String, dynamic>>();
    final task = controller.generateLesson('Tạo bài phân số lớp 4', 'Toán');
    auth.change(null);
    cms.delayedGeneration!.complete(lessonPayload());
    expect(await task, isNull);
    expect(cms.lessons, isEmpty);
    controller.dispose();
    await auth.events.close();
    await cms.events.close();
    await cms.catalogEvents.close();
  });

  for (final width in [375.0, 1440.0]) {
    testWidgets('headless CMS CRUD and learner rendering at $width px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 1100);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = TestAdminAuth(), cms = CmsAdminRepository();
      final controller = AdminDashboardController(auth: auth, repository: cms);
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(
        await SharedPreferences.getInstance(),
        enableServerSync: true,
      );
      await store.createDeviceProfile('CMS learner');
      final learnerAuth = SyncTestAuth();
      final cloud = CloudBackupController(
        store: store,
        auth: learnerAuth,
        repository: SyncTestBackups(),
      );
      final sync = LearningSyncController(
        store: store,
        cloud: cloud,
        repository: CmsLearningRepository(cms),
        automatic: false,
      );
      var cleaned = false;
      Future<void> cleanup() async {
        if (cleaned) return;
        cleaned = true;
        sync.dispose();
        cloud.dispose();
        store.dispose();
        controller.dispose();
        await auth.events.close();
        await learnerAuth.events.close();
        await cms.events.close();
        await cms.catalogEvents.close();
      }

      addTearDown(cleanup);
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder.first);
        await tester.pumpAndSettle();
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
      }

      Future<void> enter(String key, String text) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.enterText(finder, text);
        await tester.pumpAndSettle();
      }

      await tester.pumpWidget(AdminApp(controller: controller));
      await tester.pumpAndSettle();
      controller.selectSection('topics');
      await tester.pumpAndSettle();
      await tap(find.byKey(const ValueKey('admin-add-topic')));
      await enter('topic-id', 'cms-topic');
      await enter('topic-title', 'Chủ đề CMS');
      await enter('topic-subject', 'Toán học');
      await tap(find.byType(DropdownButtonFormField<String>));
      await tap(find.text('Đang hoạt động').last);
      await tap(find.text('Lưu chủ đề'));
      await tap(find.byKey(const ValueKey('lessons-cms-topic')));
      await tap(find.byKey(const ValueKey('admin-add-lesson')));
      await tap(find.byKey(const ValueKey('publish-lesson')));
      expect(find.text('Vui lòng nhập Tên bài học.'), findsOneWidget);
      for (final entry in {
        'title': 'Một nửa của tám',
        'prompt': 'Một nửa của 8 là bao nhiêu?',
        'knowledge': 'Chia đều',
        'choices': '4\n8',
        'reasons': 'Chia hai phần bằng nhau\nGiữ nguyên',
        'hint': 'Chia thành hai nhóm.',
        'explanation': '8 chia 2 bằng 4.',
      }.entries) {
        await enter('lesson-${entry.key}', entry.value);
      }
      await tap(find.text('Chơi thử'));
      await tap(find.byKey(const ValueKey('answer-0')));
      await tap(find.byKey(const ValueKey('reason-0')));
      expect(find.text('Chính xác! 8 chia 2 bằng 4.'), findsOneWidget);
      await tap(find.text('Đóng xem thử'));
      await tap(find.byKey(const ValueKey('publish-lesson')));
      expect(cms.lessons.length, 1);
      final id = cms.lessons.keys.single;
      await sync.syncNow();
      expect(store.availableTopics.single.id, 'cms-topic');
      expect(
        store.availableTopics.single.experiments.single.prompt,
        'Một nửa của 8 là bao nhiêu?',
      );
      await tap(find.byKey(ValueKey('edit-lesson-$id')));
      await enter('lesson-title', 'Bài đã sửa');
      await enter('lesson-choices', '8\n4');
      await enter('lesson-answer', '2');
      await tap(find.byKey(const ValueKey('publish-lesson')));
      await sync.syncNow();
      final topic = store.availableTopics.single;
      final spec = topic.experiments.single;
      expect(spec.title, 'Bài đã sửa');
      expect(spec.isCorrect({'answer': 0, 'reason': 0}), false);
      expect(spec.isCorrect({'answer': 1, 'reason': 0}), true);
      expect(spec.contentVersion, 2);
      await tap(find.byKey(ValueKey('edit-lesson-$id')));
      await tap(find.byKey(const ValueKey('archive-lesson')));
      await tap(find.text('Hủy'));
      expect(cms.lessons[id]!['editor_status'], 'active');
      await tap(find.byKey(const ValueKey('archive-lesson')));
      await tap(find.text('Lưu trữ bài học'));
      await sync.syncNow();
      expect(store.availableTopics, isEmpty);
      await tap(find.byKey(ValueKey('edit-lesson-$id')));
      await tap(find.byKey(const ValueKey('publish-lesson')));
      await sync.syncNow();
      expect(
        store.availableTopics.single.experiments.single.title,
        'Bài đã sửa',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: LessonPage(topic: store.availableTopics.single, store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bài đã sửa'), findsWidgets);
      expect(find.byKey(const ValueKey('answer-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await cleanup();
    });
  }

  test(
    'catalog signal updates mobile and retains the in-flight lesson version',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(
        await SharedPreferences.getInstance(),
        enableServerSync: true,
      );
      await store.createDeviceProfile('CMS learner');
      final cms = CmsAdminRepository();
      final auth = SyncTestAuth();
      final cloud = CloudBackupController(
        store: store,
        auth: auth,
        repository: SyncTestBackups(),
      );
      final repo = CmsLearningRepository(cms);
      final sync = LearningSyncController(
        store: store,
        cloud: cloud,
        repository: repo,
      );
      addTearDown(() async {
        sync.dispose();
        cloud.dispose();
        store.dispose();
        await auth.events.close();
        await cms.events.close();
        await cms.catalogEvents.close();
      });
      await cms.mutate(
        'admin',
        'topic',
        'topic.save',
        const AdminTopic(
          id: 'cms-topic',
          title: 'CMS',
          subtitle: '',
          subject: 'QA',
          status: 'active',
          sortOrder: 0,
        ).toPayload(),
      );
      await cms.mutate('admin', 'create', 'lesson.save', lessonPayload());
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(store.availableTopics.single.experiments.single.contentVersion, 1);
      await store.saveProgress('cms-topic', {
        'step': 0,
        'attempts': 0,
        'states': {},
        'activeActivityId': 'cms-lesson',
      });
      await cms.mutate('admin', 'edit', 'lesson.save', {
        ...lessonPayload(revision: 1),
        'title': 'New lesson text',
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(store.availableTopics.single.experiments.single.contentVersion, 2);
      expect(
        store.topicForLearning('cms-topic').experiments.single.contentVersion,
        1,
      );
      expect(
        store.topicForLearning('cms-topic').experiments.single.title,
        'Một nửa của tám',
      );
      final session =
          learningMap(store.serverSyncFor(store.profile!.id)['sessions'])
                  .values
                  .single
              as Map;
      expect((session['versions'] as Map)['cms-lesson'], 1);
      await cms.mutate(
        'admin',
        'archive',
        'lesson.save',
        lessonPayload(revision: 2, status: 'archived'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(store.availableTopics, isEmpty);
      expect(store.topicForId('cms-topic').id, 'cms-topic');
    },
  );
}
