import 'language_slide_engines.dart';
import 'extra_slide_engines.dart';

const extendedSlideEngines = <String, String>{
  ...extraSlideEngines,
  ...languageSlideEngines,
  'solid3D': 'Xưởng khối 3D',
  'polygonVertices': 'Đỉnh đa giác',
  'symmetryMirror': 'Gương đối xứng',
  'tangramRotate': 'Ghép hình Tangram',
  'causalLab': 'Phòng lab nhân quả',
  'balanceScale': 'Cân thăng bằng',
  'robotRoute': 'Đường đi robot',
  'loopBuilder': 'Xây vòng lặp',
  'sequenceTiles': 'Sắp xếp quy trình',
  'causalExperiment': 'Thí nghiệm khoa học',
  'strata3D': 'Địa tầng 3D',
  'globe3D': 'Quả địa cầu',
  'resourceBudget': 'Phân bổ tài nguyên',
  'evidenceBoard': 'Bảng bằng chứng',
  'categorySort': 'Phân loại thẻ',
  'clozeBank': 'Điền chỗ trống',
  'matchPairs': 'Kết nối ý tưởng',
};

Map<String, dynamic> newExtendedSlideConfig(String engine) => switch (engine) {
  final e when languageSlideEngines.containsKey(e) => languageSlideConfig(e),
  final e when extraSlideEngines.containsKey(e) => extraSlideConfig(e),
  'solid3D' => {'target_volume': 12},
  'polygonVertices' => {'target_area': 6},
  'balanceScale' => {'target_weight': 6},
  'robotRoute' => {'max_commands': 32},
  'loopBuilder' => {
    'target_repeat': 3,
    'target_body': ['R', 'D'],
  },
  'globe3D' => {'target_latitude': 30, 'target_longitude': 45},
  'causalLab' || 'causalExperiment' => {
    'target_product': 6,
    'axes': ['Lực tác động', 'Thời gian'],
  },
  'sequenceTiles' => {
    'items': ['Quan sát', 'Đặt giả thuyết', 'Kiểm chứng'],
    'answer_values': [0, 1, 2],
  },
  'resourceBudget' => {
    'items': ['Năng lượng', 'Nước', 'Dự phòng'],
    'minima': [3, 4, 1],
  },
  'evidenceBoard' => {
    'items': [
      'Thí nghiệm lặp lại cho cùng kết quả',
      'Một lời phỏng đoán',
      'Số liệu đo được',
    ],
    'answer_values': [0, 2],
  },
  'categorySort' || 'clozeBank' || 'matchPairs' => {
    'items': ['2 + 2', '3 + 3'],
    'choices': ['4', '6'],
    'answer_values': [0, 1],
  },
  _ => {},
};
bool _int(dynamic v, int min, int max) => v is int && v >= min && v <= max;
bool _strings(dynamic v, [int min = 2, int max = 8]) =>
    v is List &&
    v.length >= min &&
    v.length <= max &&
    v.every((x) => x is String && x.trim().isNotEmpty && x.length <= 1000);
bool _numbers(dynamic v, int min, int max) =>
    v is List && v.every((x) => _int(x, min, max));
bool _same(dynamic a, dynamic b) =>
    a is List &&
    b is List &&
    a.length == b.length &&
    a.indexed.every((x) => x.$2 == b[x.$1]);
bool validExtendedSlide(String engine, Map c) {
  if (languageSlideEngines.containsKey(engine)) {
    return validLanguageSlide(engine, c);
  }
  if (extraSlideEngines.containsKey(engine)) {
    return validExtraSlide(engine, c);
  }
  switch (engine) {
    case 'solid3D':
      return _int(c['target_volume'], 1, 125) &&
          [1, 2, 3, 4, 5].any(
            (w) => [1, 2, 3, 4, 5].any(
              (h) =>
                  [1, 2, 3, 4, 5].any((d) => w * h * d == c['target_volume']),
            ),
          );
    case 'polygonVertices':
      return _int(c['target_area'], 1, 16) &&
          [
            1,
            2,
            3,
            4,
          ].any((w) => [1, 2, 3, 4].any((h) => w * h == c['target_area']));
    case 'balanceScale':
      return _int(c['target_weight'], 0, 10);
    case 'robotRoute':
      return _int(c['max_commands'], 6, 32);
    case 'loopBuilder':
      return _int(c['target_repeat'], 1, 4) &&
          c['target_body'] is List &&
          (c['target_body'] as List).length == 2 &&
          (c['target_body'] as List).every(
            (x) => ['R', 'D', 'L', 'U'].contains(x),
          );
    case 'globe3D':
      return _int(c['target_latitude'], -90, 90) &&
          _int(c['target_longitude'], -180, 180) &&
          c['target_latitude'] % 15 == 0 &&
          c['target_longitude'] % 15 == 0;
    case 'causalLab':
    case 'causalExperiment':
      return _int(c['target_product'], 0, 9) &&
          [
            0,
            1,
            2,
            3,
          ].any((x) => [0, 1, 2, 3].any((y) => x * y == c['target_product'])) &&
          _strings(c['axes'], 2, 2);
    case 'symmetryMirror':
    case 'tangramRotate':
    case 'strata3D':
      return true;
    case 'resourceBudget':
      return _strings(c['items'], 2, 6) &&
          _numbers(c['minima'], 0, 10) &&
          (c['minima'] as List).length == (c['items'] as List).length &&
          (c['minima'] as List).cast<int>().fold<int>(0, (a, b) => a + b) <= 10;
    default:
      if (!extendedSlideEngines.containsKey(engine) ||
          !_strings(c['items']) ||
          !_numbers(c['answer_values'], 0, 7)) {
        return false;
      }
      final items = c['items'] as List, a = c['answer_values'] as List;
      if (engine == 'evidenceBoard') {
        return a.isNotEmpty &&
            a.length <= items.length &&
            a.toSet().length == a.length &&
            a.every((x) => x < items.length);
      }
      if (engine == 'sequenceTiles') {
        return a.length == items.length &&
            a.toSet().length == a.length &&
            a.every((x) => x < items.length);
      }
      return _strings(c['choices']) &&
          a.length == items.length &&
          a.every((x) => x < (c['choices'] as List).length) &&
          (engine != 'matchPairs' || a.toSet().length == a.length);
  }
}

Map<String, dynamic> initialExtendedSlide(
  String engine,
  Map c,
) => switch (engine) {
  final e when languageSlideEngines.containsKey(e) => initialLanguageSlide(e),
  final e when extraSlideEngines.containsKey(e) => initialExtraSlide(e, c),
  'solid3D' => {'width': 2, 'height': 2, 'depth': 2},
  'polygonVertices' => {
    'points': [
      [0, 0],
      [4, 0],
      [4, 4],
      [0, 4],
    ],
  },
  'symmetryMirror' => {'cells': <int>[]},
  'tangramRotate' => {
    'turns': [1, 1],
    'placed': [false, false],
  },
  'robotRoute' => {'commands': <String>[]},
  'loopBuilder' => {
    'body': ['D', 'R'],
    'repeat': 1,
  },
  'balanceScale' => {'weight': 0},
  'causalLab' || 'causalExperiment' => {
    'x': 0,
    'y': 0,
    'prediction': -1,
    'trials': <List<int>>[],
    'observed': <int>[],
  },
  'globe3D' => {'latitude': 0, 'longitude': 0},
  'strata3D' => {
    'layers': [30, 10, 20],
  },
  'evidenceBoard' => {'selected': <int>[]},
  'sequenceTiles' => {
    'values': List.generate(
      (c['items'] as List).length,
      (i) => i,
    ).reversed.toList(),
  },
  'resourceBudget' => {'values': List.filled((c['items'] as List).length, 0)},
  _ => {'values': List.filled((c['items'] as List).length, -1)},
};
bool extendedSlideCorrect(String engine, Map c, Map s) {
  if (languageSlideEngines.containsKey(engine)) {
    return correctLanguageSlide(engine, c, s);
  }
  if (extraSlideEngines.containsKey(engine)) {
    return correctExtraSlide(engine, c, s);
  }
  try {
    switch (engine) {
      case 'solid3D':
        return [
              s['width'],
              s['height'],
              s['depth'],
            ].every((v) => _int(v, 1, 5)) &&
            s['width'] * s['height'] * s['depth'] == c['target_volume'];
      case 'balanceScale':
        return _int(s['weight'], 0, 10) && s['weight'] == c['target_weight'];
      case 'polygonVertices':
        final p = s['points'];
        if (p is! List ||
            p.length != 4 ||
            !p.every((v) => _numbers(v, 0, 4) && (v as List).length == 2)) {
          return false;
        }
        return p[0][1] == p[1][1] &&
            p[1][0] == p[2][0] &&
            p[2][1] == p[3][1] &&
            p[3][0] == p[0][0] &&
            ((p[1][0] - p[0][0]) * (p[3][1] - p[0][1])).abs() ==
                c['target_area'];
      case 'symmetryMirror':
        return _numbers(s['cells'], 0, 35) &&
            (s['cells'] as List).length == 3 &&
            [11, 16, 23].every((x) => (s['cells'] as List).contains(x));
      case 'tangramRotate':
        return _numbers(s['turns'], 0, 3) &&
            (s['turns'] as List).length == 2 &&
            (s['turns'][0] - s['turns'][1]).abs() == 2 &&
            _same(s['placed'], [true, true]);
      case 'strata3D':
        return _same(s['layers'], [10, 20, 30]);
      case 'globe3D':
        return s['latitude'] == c['target_latitude'] &&
            s['longitude'] == c['target_longitude'];
      case 'loopBuilder':
        return s['repeat'] == c['target_repeat'] &&
            _same(s['body'], c['target_body']);
      case 'robotRoute':
        final commands = s['commands'];
        if (commands is! List || commands.length > c['max_commands']) {
          return false;
        }
        var x = 0, y = 0;
        for (final command in commands) {
          if (!['R', 'L', 'D', 'U'].contains(command)) return false;
          x += command == 'R'
              ? 1
              : command == 'L'
              ? -1
              : 0;
          y += command == 'D'
              ? 1
              : command == 'U'
              ? -1
              : 0;
          if (x < 0 || x > 3 || y < 0 || y > 3 || (x == 1 && y == 1)) {
            return false;
          }
        }
        return x == 3 && y == 3;
      case 'causalLab':
      case 'causalExperiment':
        return _int(s['x'], 0, 3) &&
            _int(s['y'], 0, 3) &&
            s['x'] * s['y'] == c['target_product'] &&
            s['prediction'] == c['target_product'] &&
            _same(s['observed'], [s['x'], s['y'], c['target_product']]);
      case 'resourceBudget':
        return _numbers(s['values'], 0, 10) &&
            (s['values'] as List).length == (c['items'] as List).length &&
            (s['values'] as List).cast<int>().fold<int>(0, (a, b) => a + b) ==
                10 &&
            (s['values'] as List).indexed.every(
              (x) => x.$2 >= c['minima'][x.$1],
            );
      case 'evidenceBoard':
        return _numbers(s['selected'], 0, 7) &&
            _same(
              (s['selected'] as List).cast<int>().toList()..sort(),
              (c['answer_values'] as List).cast<int>().toList()..sort(),
            );
      default:
        return extendedSlideEngines.containsKey(engine) &&
            _same(s['values'], c['answer_values']);
    }
  } catch (_) {
    return false;
  }
}
