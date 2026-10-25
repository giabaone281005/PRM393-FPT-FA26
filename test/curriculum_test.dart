import 'dart:convert';

import 'package:brilliant_mobile/curriculum.dart';
import 'package:brilliant_mobile/learning_catalog.dart';
import 'package:brilliant_mobile/experiments/experiment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pilot references existing experiments and a valid skill graph', () {
    final skills = {for (final skill in fractionSkills) skill.id: skill};
    expect(fractionChapter.lessonIds, contains(fractionLesson.id));
    expect(fractionLesson.chapterId, fractionChapter.id);
    for (final skill in skills.values) {
      for (final id in skill.prerequisiteIds) {
        expect(skills.containsKey(id), isTrue);
        expect(id, isNot(skill.id));
      }
    }
    for (final activity in fractionLesson.activities) {
      final spec = experimentCatalog['math']!.firstWhere(
        (s) => s.id == activity.experimentId,
      );
      expect(spec.skillIds, activity.skillIds);
      expect(activity.skillIds.every(skills.containsKey), isTrue);
      expect(spec.isCorrect(spec.initialData()), isFalse);
    }
  });

  test('fraction evaluator accepts every valid subset and restored state', () {
    final spec = experimentCatalog['math']!.first;
    for (var mask = 0; mask < 256; mask++) {
      final data = <String, dynamic>{
        'painted': [
          for (var i = 0; i < 8; i++)
            if (mask & (1 << i) != 0) i,
        ],
      };
      final result = spec.evaluate(data);
      expect(result.isCorrect, (data['painted'] as List).length == 3);
      expect(result.misconceptionCodes, isEmpty);
      expect(spec.isCorrect(jsonDecode(jsonEncode(data))), result.isCorrect);
    }
    for (final value in [
      null,
      '3',
      [0, 0, 1],
      [-1, 0, 1],
      [0, 1, 8],
      [0, 1, 2.0],
    ]) {
      final result = spec.evaluate({'painted': value});
      expect(result.isCorrect, isFalse);
      expect(result.feedbackKey, 'invalid-state');
    }
  });

  test('legacy validators retain safe behavior through evaluation adapter', () {
    final spec = ExperimentSpec(
      id: 'legacy',
      title: '',
      prompt: '',
      hint: '',
      explanation: '',
      mechanism: '',
      initial: const {},
      validator: (data) => (data['value'] as int) == 2,
    );
    expect(spec.evaluate({'value': 2}).isCorrect, isTrue);
    expect(spec.isCorrect({'value': 1}), isFalse);
    expect(spec.evaluate({'value': 'bad'}).feedbackKey, 'invalid-state');
  });
}
