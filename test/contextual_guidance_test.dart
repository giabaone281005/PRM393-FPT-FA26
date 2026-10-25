import 'dart:convert';

import 'package:brilliant_mobile/experiments/contextual_guidance.dart';
import 'package:brilliant_mobile/experiments/discovery_catalog.dart';
import 'package:brilliant_mobile/experiments/experiment_model.dart';
import 'package:brilliant_mobile/experiments/math_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

final _specs = [
  ...mathExperiments.values.expand((v) => v),
  ...discoveryExperiments.values.expand((v) => v),
];
ExperimentSpec _spec(String mechanism) =>
    _specs.firstWhere((s) => s.mechanism == mechanism);

void main() {
  test('observes counts and torque without disclosing an extra solution', () {
    expect(
      contextualHint(_spec('balanceBlocks'), {'blocks': 2}),
      contains('2 khối'),
    );
    expect(
      contextualHint(_spec('balanceBlocks'), {'blocks': 6}),
      contains('nặng hơn'),
    );
    expect(
      contextualHint(_spec('fractionPaint'), {
        'painted': [0, 5],
      }),
      contains('2/8'),
    );
    expect(
      contextualHint(_spec('leverTorque'), {'position': 2}),
      contains('mômen bên phải là 4'),
    );
    expect(
      contextualHint(_spec('distributeObjects'), {
        'baskets': [1, 2, 3],
      }),
      contains('còn 3 quả'),
    );
  });

  test('robot identifies first obstructed command with one-based index', () {
    final spec = _spec('robotRoute');
    expect(
      contextualHint(spec, {
        'commands': ['R', 'D', 'R'],
      }),
      contains('Lệnh thứ 2'),
    );
    expect(
      contextualHint(spec, {
        'commands': ['R', 'D', 'R'],
      }),
      contains('ô đá'),
    );
    expect(
      contextualHint(spec, {
        'commands': ['U', 'R'],
      }),
      contains('Lệnh thứ 1'),
    );
    expect(
      contextualHint(spec, {
        'commands': ['R', 'R'],
      }),
      contains('cột 3, hàng 1'),
    );
  });

  test('circuit distinguishes short circuit and missing return path', () {
    final spec = _spec('wireCircuit');
    expect(
      contextualHint(spec, {
        'edges': ['0-3'],
      }),
      contains('nối tắt'),
    );
    expect(
      contextualHint(spec, {
        'edges': ['0-1'],
      }),
      contains('chưa khép vòng'),
    );
    expect(
      contextualHint(_spec('switchLogic'), {
        'switches': [true, true, true],
      }),
      contains('bảo trì'),
    );
    expect(
      contextualHint(_spec('switchLogic'), {
        'switches': [false, true, false],
      }),
      contains('C đang mở'),
    );
  });

  test('all recognized solved states give truthful success observations', () {
    final solved = <String, ExperimentData>{
      'balanceBlocks': {'blocks': 4},
      'leverTorque': {'position': 3},
      'fractionPaint': {
        'painted': [0, 1, 2],
      },
      'robotRoute': {
        'commands': ['R', 'R', 'R', 'D', 'D', 'D'],
      },
      'wireCircuit': {
        'edges': ['0-1', '2-3'],
      },
      'switchLogic': {
        'switches': [false, true, true],
      },
      'distributeObjects': {
        'baskets': [3, 3, 3],
      },
      'tangramRotate': {
        'turns': [0, 2],
        'placed': [true, true],
      },
    };
    for (final entry in solved.entries) {
      final spec = _spec(entry.key);
      expect(spec.isCorrect(entry.value), isTrue, reason: entry.key);
      expect(
        contextualHint(spec, entry.value),
        isNot(spec.hint),
        reason: entry.key,
      );
      expect(
        contextualHint(spec, entry.value),
        isNot(contains('chưa')),
        reason: entry.key,
      );
    }
  });

  test('malformed and unsupported models safely use authored hint', () {
    final bad = <String, ExperimentData>{
      'balanceBlocks': {'blocks': -1},
      'leverTorque': {'position': '2'},
      'fractionPaint': {
        'painted': [0, 0],
      },
      'robotRoute': {
        'commands': ['X'],
      },
      'wireCircuit': {
        'edges': [12],
      },
      'switchLogic': {
        'switches': [false],
      },
      'distributeObjects': {
        'baskets': [6, 6, 6],
      },
      'tangramRotate': {
        'turns': [0, 5],
        'placed': [true, true],
      },
    };
    for (final entry in bad.entries) {
      final spec = _spec(entry.key);
      expect(contextualHint(spec, entry.value), spec.hint, reason: entry.key);
      expect(contextualHint(spec, {}), spec.hint, reason: entry.key);
    }
    final other = _spec('gearRatios');
    expect(contextualHint(other, other.initialData()), other.hint);
  });

  test('guidance never mutates supplied model', () {
    for (final spec in _specs) {
      final data = spec.initialData();
      final before = jsonEncode(data);
      contextualHint(spec, data);
      expect(jsonEncode(data), before, reason: spec.id);
    }
  });
}
