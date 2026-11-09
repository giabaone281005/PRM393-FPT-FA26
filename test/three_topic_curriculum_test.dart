import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/data/models/slide_lesson.dart';
import 'package:brilliant_mobile/discovery_paths.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'new Admin topic IDs appear in discovery routes in catalogue order',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      addTearDown(store.dispose);
      final data = jsonDecode(
        File('cms/content/three-topic-curriculum.json').readAsStringSync(),
      ) as Map;
      store.applyCatalog({
        'topics': data['topics'],
        'activities': [
          for (final lesson in data['lessons'] as List)
            {
              ...lesson as Map,
              'activity_id': lesson['id'],
              'content_version': 1,
              'evaluator_version': 4,
              'position': lesson['sort_order'],
              'hint_levels': [lesson['hint']],
            },
        ],
      });
      expect(store.availableTopics.map((t) => t.experiments.length), [4, 3, 3]);
      final paths = catalogPaths(store);
      expect(paths.expand((p) => p.topicIds), [
        'studio-math',
        'studio-english',
        'studio-coding',
      ]);
      expect(paths.map((p) => p.title), ['Toán học', 'Tiếng Anh', 'Lập trình']);
    },
  );
  test(
    'all 60 curriculum parts are valid and scored consistently on mobile',
    () {
      final data = jsonDecode(
        File('cms/content/three-topic-curriculum.json').readAsStringSync(),
      ) as Map;
      expect((data['topics'] as List).length, 3);
      expect((data['lessons'] as List).length, 10);
      for (final lesson in data['lessons'] as List) {
        final config = lesson['config'] as Map;
        expect(
          validSlideLesson(config),
          isTrue,
          reason: lesson['id'] as String,
        );
        final slides = config['slides'] as List;
        expect(slides.length, 6);
        final answers = data['solutions'][lesson['id']] as Map;
        for (final slide in slides) {
          expect(
            slideIsCorrect(slide as Map, answers[slide['id']] as Map),
            isTrue,
            reason: slide['id'] as String,
          );
          expect(slideIsCorrect(slide, {}), isFalse);
        }
        expect(
          slideLessonIsCorrect(config, {
            'index': 5,
            'slides': [for (final slide in slides) answers[slide['id']]],
          }),
          isTrue,
        );
      }
    },
  );
}
