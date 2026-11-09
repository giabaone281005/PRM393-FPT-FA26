import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/data/models/learning_journal.dart';
import 'package:brilliant_mobile/data/models/slide_engine_contract.dart';
import 'package:brilliant_mobile/data/models/slide_lesson.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixtures = jsonDecode(
    File('supabase/tests/fixtures/studio_engines.json').readAsStringSync(),
  ) as List;
  for (final raw in fixtures) {
    final f = learningMap(raw),
        engine = f['engine'] as String,
        c = learningMap(f['config']);
    test(
      '$engine matches the shared CMS/PostgreSQL contract and forged-state rejection',
      () {
        final slide = {...newLessonSlide(engine), 'config': c},
            config = {
              'schema_version': 1,
              'slides': [slide],
            };
        expect(validSlideLesson(config), isTrue);
        expect(newExtendedSlideConfig(engine), c);
        expect(initialSlideState(config), {
          'index': 0,
          'slides': [f['initial']],
        });
        expect(slideIsCorrect(slide, learningMap(f['correct'])), isTrue);
        for (final wrong in f['wrong'] as List) {
          expect(
            slideIsCorrect(slide, learningMap(wrong)),
            isFalse,
            reason: jsonEncode(wrong),
          );
        }
      },
    );
  }
  test(
    'unreachable targets, malformed arrays and impossible budgets are rejected',
    () {
      final invalid = <String, Map<String, dynamic>>{
        'solid3D': {'target_volume': 7},
        'polygonVertices': {'target_area': 7},
        'globe3D': {'target_latitude': 1, 'target_longitude': 30},
        'causalLab': {
          'target_product': 5,
          'axes': ['x', 'y'],
        },
        'resourceBudget': {
          'items': ['a', 'b'],
          'minima': [9, 9],
        },
        'sequenceTiles': {
          'items': ['a', 'b'],
          'answer_values': [0, 0],
        },
        'evidenceBoard': {
          'items': ['a', 'b'],
          'answer_values': [0, 0],
        },
      };
      for (final entry in invalid.entries) {
        expect(
          validSlideLesson({
            'schema_version': 1,
            'slides': [
              {...newLessonSlide(entry.key), 'config': entry.value},
            ],
          }),
          isFalse,
          reason: entry.key,
        );
      }
    },
  );
}
