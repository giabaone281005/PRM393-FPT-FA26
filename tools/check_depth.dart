import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/experiments/diverse_catalog.dart';
import 'package:brilliant_mobile/experiments/lesson_guidance.dart';
import 'package:brilliant_mobile/experiments/math_catalog.dart';
import 'package:brilliant_mobile/experiments/solid_catalog.dart';
import 'package:brilliant_mobile/experiments/solid_model.dart';
import 'package:brilliant_mobile/experiments/space_guidance.dart';

void main() {
  var checks = 0;
  void check(bool ok, String message) {
    checks++;
    if (!ok) throw StateError(message);
  }

  for (final spec in solidExperiments.values.expand((v) => v)) {
    for (var level = 1; level <= 3; level++) {
      check(
        spaceHint(spec, spec.initialData(), level).isNotEmpty,
        'Missing hint',
      );
    }
    check(!spec.evaluate({}).isCorrect, 'Missing state accepted');
    check(
      spec.evaluate({}).feedbackKey == 'invalid-state',
      'Wrong invalid state feedback',
    );
    check(
      spaceFeedback(spec, spec.initialData()).isNotEmpty,
      'Missing feedback',
    );
  }
  final geometry = solidExperiments['geometry']!.single;
  final algebra = solidExperiments['algebra']!.single;
  for (var w = 1; w <= 5; w++) {
    for (var h = 1; h <= 5; h++) {
      for (var d = 1; d <= 5; d++) {
        final state = {'width': w, 'height': h, 'depth': d};
        final g = geometry.evaluate(state);
        check(
          g.satisfiedConstraints.contains('volume') == (w * h * d == 12),
          'Volume evidence',
        );
        check(
          g.satisfiedConstraints.contains('surface') ==
              (2 * (w * h + w * d + h * d) == 32),
          'Surface evidence',
        );
        check(
          g.isCorrect == (g.satisfiedConstraints.length == 2),
          'Geometry completion',
        );
        check(
          algebra.evaluate(state).isCorrect == (w == 4 && h == 2 && d == 2),
          'Algebra completion',
        );
        check(spaceFeedback(geometry, state).isNotEmpty, 'Geometry feedback');
        check(spaceFeedback(algebra, state).isNotEmpty, 'Algebra feedback');
        check(
          geometry.isCorrect(jsonDecode(jsonEncode(state))) == g.isCorrect,
          'Restored evaluation',
        );
      }
    }
  }
  final correctVolume = geometry.evaluate({
    'width': 1,
    'height': 3,
    'depth': 4,
  });
  check(
    correctVolume.feedbackKey == 'surface-mismatch',
    'Partial success must identify remaining surface',
  );
  final globe = solidExperiments['geography']!.first;
  check(
    globe.evaluate({'latitude': 15, 'longitude': 0}).feedbackKey ==
        'longitude-mismatch',
    'Preserve correct latitude',
  );
  check(
    globe.evaluate({'latitude': -15, 'longitude': 105}).feedbackKey ==
        'latitude-mismatch',
    'Preserve correct longitude',
  );
  for (final bad in [null, '3', 3.0, -4, 90]) {
    check(
      geometry.evaluate({'width': bad, 'height': 2, 'depth': 3}).feedbackKey ==
          'invalid-state',
      'Bad dimensions',
    );
  }
  check(savedHintLevel(null, previouslyUsed: true) == 1, 'Legacy hint usage');
  check(savedHintLevel(9) == 3 && savedHintLevel(-1) == 0, 'Bound hint level');
  final restored = jsonDecode(
    jsonEncode({
      'hintLevels': {geometry.id: 2},
    }),
  ) as Map;
  check(
    savedHintLevel(restored['hintLevels'][geometry.id]) == 2,
    'Restore hint depth',
  );
  check(
    solidVolume({'width': 2, 'height': 2, 'depth': 3}) == 12,
    'Volume reference',
  );
  final current = <String, dynamic>{'width': 2, 'height': 2, 'depth': 2};
  final reference = solidReference(current)!;
  current['depth'] = 3;
  check(reference['depth'] == 2, 'Reference must not alias the mutable model');
  final savedReference = jsonDecode(jsonEncode(reference));
  check(solidReference(savedReference)!['depth'] == 2, 'Reference restoration');
  check(
    compareSolids(current, reference).contains('tăng 4'),
    'Volume change should be observable',
  );
  check(
    compareSolids({
      'width': 1,
      'height': 3,
      'depth': 4,
    }, current).contains('cùng thể tích'),
    'Same volume, distinct surface',
  );
  check(
    compareSolids(
      {'width': 1, 'height': 1, 'depth': 5},
      {'width': 1, 'height': 2, 'depth': 3},
    ).contains('cùng diện tích'),
    'Same surface, distinct volume',
  );
  check(
    !geometry.isCorrect({
      'width': 2,
      'height': 2,
      'depth': 2,
      'comparisonReference': current,
    }),
    'Reference must not solve current model',
  );
  for (final raw in [
    null,
    'bad',
    [2, 2, 3],
    {'width': 2.0, 'height': 2, 'depth': 3},
    {1: 2},
  ]) {
    check(solidReference(raw) == null, 'Reject malformed reference');
  }
  final paint = mathExperiments['math']!.first;
  final line = diverseExperiments['math']!.single;
  for (var mask = 0; mask < 256; mask++) {
    final data = <String, dynamic>{
      'painted': [
        for (var i = 0; i < 8; i++)
          if (mask & (1 << i) != 0) i,
      ],
    };
    final before = jsonEncode(data);
    check(
      paint.isCorrect(data) == ((data['painted'] as List).length == 3),
      'Any valid painted subset',
    );
    check(lessonModelFeedback(paint, data).isNotEmpty, 'Fraction feedback');
    for (var level = 1; level <= 3; level++) {
      check(
        progressiveLessonHint(paint, data, level).isNotEmpty,
        'Fraction hint level',
      );
    }
    check(jsonEncode(data) == before, 'Guidance must not modify the model');
  }
  for (var position = -2; position <= 10; position++) {
    final data = <String, dynamic>{'position': position};
    check(line.isCorrect(data) == (position == 6), 'Line positions');
    check(lessonModelFeedback(line, data).isNotEmpty, 'Line feedback');
  }
  for (final value in [null, '6', 6.0, true, []]) {
    check(
      line.evaluate({'position': value}).feedbackKey == 'invalid-state',
      'Line rejects invalid state',
    );
  }
  check(
    supportsProgressiveGuidance(paint) && supportsProgressiveGuidance(line),
    'Fraction help enabled',
  );
  check(
    !supportsProgressiveGuidance(mathExperiments['logic']!.first),
    'Legacy guidance unchanged',
  );
  stdout.writeln('$checks lesson-depth checks passed.');
}
