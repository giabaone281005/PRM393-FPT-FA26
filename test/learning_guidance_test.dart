import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/learning_guidance.dart';
import 'package:brilliant_mobile/learning_store.dart';

Future<LearningStore> fixture({
  List<String> completed = const [],
  List<String> interests = const [],
  List<Map<String, dynamic>> history = const [],
  Map<String, dynamic> drafts = const {},
  String? lastCourse,
}) async {
  SharedPreferences.setMockInitialValues({
    LearningStore.storageKey: jsonEncode({
      'version': 3,
      'activeId': 'a',
      'profiles': [
        {'id': 'a', 'name': 'An', 'interests': interests},
        {'id': 'b', 'name': 'Bình'},
      ],
      'learning': {
        'a': {
          'completed': {for (final id in completed) id: {}},
          'history': history,
          'drafts': drafts,
          'lastCourse': lastCourse,
        },
        'b': {
          'completed': {'math': {}},
          'history': [
            {'course': 'math', 'attempts': 8, 'hints': 3},
          ],
        },
      },
    }),
  });
  final store = LearningStore(await SharedPreferences.getInstance());
  addTearDown(store.dispose);
  return store;
}

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);

  test(
    'fresh suggestions follow interests and skip completed topics',
    () async {
      final store = await fixture(
        interests: ['unavailable', 'coding', 'geometry'],
        completed: ['coding'],
      );
      final result = recommendNext(store, now: now);
      expect(result.topic.id, 'geometry');
      expect(result.isReview, false);
      expect(result.reason, contains('bạn đã chọn'));
    },
  );

  test('resume saved work before reviews and ignore unknown drafts', () async {
    final store = await fixture(
      completed: ['logic'],
      history: [
        {'course': 'logic', 'attempts': 6, 'hints': 2},
      ],
      drafts: {
        'unknown': {'updatedAt': '2026-10-23T12:00:00Z'},
        'science': {'updatedAt': '2026-10-23T10:00:00Z'},
        'math': {'updatedAt': '2026-10-22T10:00:00Z'},
      },
      lastCourse: 'math',
    );
    expect(recommendNext(store, now: now).topic.id, 'math');
    expect(recommendNext(store, now: now).isReview, false);
  });

  test(
    'resume most recent valid draft when last course is unavailable',
    () async {
      final store = await fixture(
        drafts: {
          'logic': {'updatedAt': 'invalid'},
          'science': {'updatedAt': '2026-10-23T10:00:00Z'},
          'math': {'updatedAt': '2026-10-22T10:00:00Z'},
        },
        lastCourse: 'deleted-topic',
      );
      expect(recommendNext(store, now: now).topic.id, 'science');
    },
  );

  test('latest completed session determines extra practice', () async {
    final store = await fixture(
      completed: ['logic'],
      history: [
        {'course': 'logic', 'attempts': 8, 'hints': 2},
        {
          'course': 'logic',
          'attempts': 3,
          'hints': 0,
          'finishedAt': '2026-10-23T08:00:00Z',
        },
      ],
    );
    final activity = topicActivity(store, 'logic', now: now);
    expect(activity.practiceCount, 2);
    expect(activity.needsReview, false);
    expect(activity.lastPracticed, DateTime.utc(2026, 10, 23, 8));
  });

  test('review uses attempts or hints without inventing proficiency', () async {
    for (final record in [
      {'course': 'logic', 'attempts': 6, 'hints': 0},
      {'course': 'logic', 'attempts': 3, 'hints': 2},
    ]) {
      final store = await fixture(completed: ['logic'], history: [record]);
      final result = recommendNext(store, now: now);
      expect(result.topic.id, 'logic');
      expect(result.isReview, true);
      expect(topicActivity(store, 'logic', now: now).needsReview, true);
      expect(result.reason, contains('gợi ý'));
    }
  });

  test('seven-day review compares normalized UTC calendar days', () async {
    final store = await fixture(
      completed: ['math'],
      history: [
        {
          'course': 'math',
          'finishedAt': '2026-10-17T02:30:00+07:00',
          'attempts': 3,
        },
      ],
    );
    expect(
      topicActivity(
        store,
        'math',
        now: DateTime.utc(2026, 10, 22, 23, 59),
      ).needsReview,
      false,
    );
    expect(
      topicActivity(store, 'math', now: DateTime.utc(2026, 10, 23)).needsReview,
      true,
    );
    expect(recommendNext(store, now: now).topic.id, 'math');
  });

  test(
    'read-only suggestions preserve XP, history and profile isolation',
    () async {
      final store = await fixture(completed: ['logic']);
      final before = jsonEncode(store.history);
      final points = store.points;
      for (var i = 0; i < 10; i++) {
        recommendNext(store, now: now);
        topicActivity(store, 'math', now: now);
      }
      expect(store.points, points);
      expect(jsonEncode(store.history), before);
      expect(topicActivity(store, 'math', now: now).completed, false);
      expect(topicActivity(store, 'math', now: now).practiceCount, 0);
    },
  );

  test(
    'all completed suggests an older topic even with legacy dates',
    () async {
      final store = await fixture(completed: topics.map((t) => t.id).toList());
      final result = recommendNext(store, now: now);
      expect(result.isReview, true);
      expect(topics.contains(result.topic), true);
      expect(result.reason, contains('tất cả chủ đề'));
    },
  );
}
