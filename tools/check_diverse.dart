import 'dart:convert';
import 'dart:io';

import 'package:brilliant_mobile/experiments/diverse_catalog.dart';

void main() {
  var checks = 0;
  void check(bool value) {
    checks++;
    if (!value) throw StateError('Check $checks failed');
  }

  for (final spec in diverseExperiments.values.expand((v) => v)) {
    check(!spec.isCorrect(spec.initialData()));
    check(!spec.isCorrect({}));
  }
  final fraction = diverseExperiments['math']!.single;
  for (var n = -1; n <= 9; n++) {
    check(fraction.isCorrect({'position': n}) == (n == 6));
  }
  final logic = diverseExperiments['logic']!.single;
  for (final a in [false, true]) {
    for (final b in [false, true]) {
      check(logic.isCorrect({'a': a, 'b': b}) == (a && !b));
    }
  }
  final data = diverseExperiments['data']!.single;
  for (var n = 0; n <= 20; n++) {
    final state =
        jsonDecode(jsonEncode({'outlier': n})) as Map<String, dynamic>;
    check(data.isCorrect(state) == (n >= 10 && n <= 15));
  }
  for (final invalid in ['10', 10.0, null, true]) {
    check(!data.isCorrect({'outlier': invalid}));
    check(!fraction.isCorrect({'position': invalid}));
  }
  stdout.writeln(
    '$checks checks passed: domains, truth table, invalid types and JSON restoration.',
  );
}
