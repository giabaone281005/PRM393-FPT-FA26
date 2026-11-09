import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/app_theme.dart';
import 'package:brilliant_mobile/data/models/lesson_icon.dart';
import 'package:brilliant_mobile/data/models/mobile_catalog.dart';
import 'package:brilliant_mobile/learning_store.dart';
import 'package:brilliant_mobile/topic_roadmap.dart';
import 'package:brilliant_mobile/journey_app.dart' show TopicArtwork;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> catalogue() {
  final data = jsonDecode(
    File('cms/content/three-topic-curriculum.json').readAsStringSync(),
  ) as Map;
  final lesson = data['lessons'][0] as Map;
  return {
    'topics': [data['topics'][0]],
    'activities': [
      {
        ...lesson,
        'activity_id': lesson['id'],
        'content_version': 1,
        'evaluator_version': 4,
        'position': 0,
        'hint_levels': [lesson['hint']],
        'config': {...lesson['config'] as Map, 'lesson_icon': 'robot'},
      },
    ],
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('new CMS topics have visible fallback artwork', (tester) async {
    final topic = decodeMobileCatalog(catalogue()).single;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: TopicArtwork(topic: topic, height: 100)),
      ),
    );
    expect(find.byIcon(Icons.functions), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('known icons and safe engine fallback survive catalogue decoding', () {
    expect(lessonIcons.length, 24);
    final topic = decodeMobileCatalog(catalogue()).single;
    expect(
      lessonIcon(topic.experiments.single.config),
      Icons.smart_toy_outlined,
    );
    expect(
      lessonIconKey({
        'lesson_icon': '__proto__',
        'slides': [
          {'engine': 'resourceBudget'},
        ],
      }),
      'coins',
    );
    expect(
      lessonIconKey({
        'slides': [
          {'engine': 'story'},
          {'engine': 'robotRoute'},
        ],
      }),
      'robot',
    );
    expect(lessonIconKey({}), 'book');
  });
  testWidgets(
    'published lesson icon renders on the checkpoint at 320px and large text',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = LearningStore(await SharedPreferences.getInstance());
      addTearDown(store.dispose);
      store.applyCatalog(catalogue());
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 1.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TopicRoadmap(
                topic: store.availableTopics.single,
                store: store,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.byKey(const ValueKey('lesson-icon-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(store.points, 0);
    },
  );
}
