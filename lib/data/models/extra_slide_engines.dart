const extraSlideEngines = <String, String>{
  'numberLine': 'Trục số',
  'fractionBoard': 'Tô phân số',
  'numberInput': 'Nhập kết quả',
  'quadraticGraph': 'Đồ thị bậc hai',
  'barChart': 'Dựng biểu đồ cột',
  'coordinatePoint': 'Tọa độ trên mặt phẳng',
  'vennDiagram': 'Sơ đồ Venn',
  'fractionCompare': 'So sánh phân số',
  'shapeMatch': 'Nhận diện hình SVG',
};
const slideShapes = ['circle', 'triangle', 'square', 'hexagon'];
Map<String, dynamic> extraSlideConfig(String e) => switch (e) {
  'numberLine' => {'min': -10, 'max': 10, 'start': 0, 'target': 4},
  'fractionBoard' => {'denominator': 6, 'numerator': 4},
  'numberInput' => {'target_value': 12},
  'quadraticGraph' => {'target_a': 1, 'target_b': 0, 'target_c': -1},
  'barChart' => {
    'labels': ['Nhóm A', 'Nhóm B', 'Nhóm C'],
    'target_values': [2, 5, 3],
  },
  'coordinatePoint' => {'target_x': 3, 'target_y': 2},
  'vennDiagram' => {
    'items': [
      'Chỉ thuộc A',
      'Chỉ thuộc B',
      'Thuộc cả hai',
      'Không thuộc tập nào',
    ],
    'answer_values': [1, 2, 3, 0],
  },
  'fractionCompare' => {
    'left_numerator': 2,
    'left_denominator': 3,
    'right_numerator': 3,
    'right_denominator': 4,
  },
  'shapeMatch' => {'target_shape': 'triangle'},
  _ => {},
};
bool _int(dynamic v, int min, int max) => v is int && v >= min && v <= max;
bool _nums(dynamic v, int min, int max) =>
    v is List && v.every((x) => _int(x, min, max));
bool _texts(dynamic v, int min, int max, int length) =>
    v is List &&
    v.length >= min &&
    v.length <= max &&
    v.every((x) => x is String && x.trim().isNotEmpty && x.length <= length);
bool _same(dynamic a, dynamic b) =>
    a is List &&
    b is List &&
    a.length == b.length &&
    a.indexed.every((x) => x.$2 == b[x.$1]);
bool validExtraSlide(String e, Map c) {
  switch (e) {
    case 'numberLine':
      return _int(c['min'], -100, 100) &&
          _int(c['max'], -100, 100) &&
          c['min'] < c['max'] &&
          c['max'] - c['min'] <= 100 &&
          _int(c['start'], c['min'], c['max']) &&
          _int(c['target'], c['min'], c['max']);
    case 'fractionBoard':
      return _int(c['denominator'], 2, 12) &&
          _int(c['numerator'], 0, c['denominator']);
    case 'numberInput':
      return _int(c['target_value'], -10000, 10000);
    case 'quadraticGraph':
      return _int(c['target_a'], -3, 3) &&
          c['target_a'] != 0 &&
          _int(c['target_b'], -5, 5) &&
          _int(c['target_c'], -5, 5);
    case 'barChart':
      return _texts(c['labels'], 2, 6, 100) &&
          _nums(c['target_values'], 0, 10) &&
          (c['target_values'] as List).length == (c['labels'] as List).length;
    case 'coordinatePoint':
      return _int(c['target_x'], -5, 5) && _int(c['target_y'], -5, 5);
    case 'vennDiagram':
      return _texts(c['items'], 2, 8, 1000) &&
          _nums(c['answer_values'], 0, 3) &&
          (c['answer_values'] as List).length == (c['items'] as List).length;
    case 'fractionCompare':
      return _int(c['left_denominator'], 2, 12) &&
          _int(c['right_denominator'], 2, 12) &&
          _int(c['left_numerator'], 0, c['left_denominator']) &&
          _int(c['right_numerator'], 0, c['right_denominator']);
    case 'shapeMatch':
      return slideShapes.contains(c['target_shape']);
    default:
      return false;
  }
}

Map<String, dynamic> initialExtraSlide(String e, Map c) => switch (e) {
  'numberLine' => {'position': c['start']},
  'fractionBoard' => {'selected': <int>[]},
  'numberInput' => {'value': ''},
  'quadraticGraph' => {'a': 0, 'b': 0, 'c': 0},
  'barChart' => {'values': List.filled((c['labels'] as List).length, 0)},
  'coordinatePoint' => {'x': 0, 'y': 0},
  'vennDiagram' => {'values': List.filled((c['items'] as List).length, -1)},
  'fractionCompare' => {'comparison': -1},
  'shapeMatch' => {'shape': ''},
  _ => {},
};
bool correctExtraSlide(String e, Map c, Map s) {
  switch (e) {
    case 'numberLine':
      return _int(s['position'], c['min'], c['max']) &&
          s['position'] == c['target'];
    case 'fractionBoard':
      return _nums(s['selected'], 0, c['denominator'] - 1) &&
          (s['selected'] as List).length == c['numerator'] &&
          (s['selected'] as List).toSet().length ==
              (s['selected'] as List).length;
    case 'numberInput':
      return s['value'] is String &&
          (s['value'] as String).length <= 6 &&
          RegExp(r'^-?\d+$').hasMatch(s['value'] as String) &&
          int.tryParse(s['value'] as String) == c['target_value'];
    case 'quadraticGraph':
      return s['a'] == c['target_a'] &&
          s['b'] == c['target_b'] &&
          s['c'] == c['target_c'];
    case 'barChart':
      return _nums(s['values'], 0, 10) &&
          _same(s['values'], c['target_values']);
    case 'coordinatePoint':
      return s['x'] == c['target_x'] && s['y'] == c['target_y'];
    case 'vennDiagram':
      return _nums(s['values'], 0, 3) && _same(s['values'], c['answer_values']);
    case 'fractionCompare':
      final l = c['left_numerator'] * c['right_denominator'],
          r = c['right_numerator'] * c['left_denominator'];
      return s['comparison'] ==
          (l < r
              ? 0
              : l == r
              ? 1
              : 2);
    case 'shapeMatch':
      return s['shape'] == c['target_shape'];
    default:
      return false;
  }
}
