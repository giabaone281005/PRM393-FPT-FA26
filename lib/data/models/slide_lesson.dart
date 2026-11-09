import 'slide_engine_contract.dart';
import 'learning_journal.dart';

const slideEngineNames = <String, String>{
  'story': 'Văn bản / hình ảnh',
  'quiz': 'Trắc nghiệm',
  'pairs': 'Kéo thả ghép cặp',
  'graph': 'Đồ thị và thanh trượt',
  ...extendedSlideEngines,
};

Map<String, dynamic> newLessonSlide(String engine) => {
  'id': 'slide-${learningUuid()}',
  'engine': engine,
  'locked': true,
  'title': slideEngineNames[engine] ?? '',
  'prompt': engine == 'story' ? '' : 'Nhập yêu cầu cho người học.',
  'hint': 'Quan sát mô hình và thử lại.',
  'explanation': 'Giải thích kết quả ở đây.',
  'config': switch (engine) {
    'story' => {
      'text': 'Nhập nội dung dẫn dắt bài học.',
      'image_url': '',
      'image_alt': '',
    },
    'quiz' => {
      'choices': ['Đáp án A', 'Đáp án B', 'Đáp án C'],
      'answer': 0,
    },
    'pairs' => {
      'pairs': [
        {'left': 'Một nửa', 'right': '1/2'},
        {'left': 'Một phần tư', 'right': '1/4'},
      ],
    },
    'graph' => {
      'min_a': -5,
      'max_a': 5,
      'min_b': -5,
      'max_b': 5,
      'start_a': 0,
      'start_b': 0,
      'target_a': 2,
      'target_b': 1,
    },
    _ => newExtendedSlideConfig(engine),
  },
};

bool _text(dynamic value, int max, {bool empty = false}) =>
    value is String &&
    value.length <= max &&
    (empty || value.trim().isNotEmpty);
bool _integer(dynamic value, int min, int max) =>
    value is int && value >= min && value <= max;

/// The same declarative contract is used by CMS, preview and mobile. No code or
/// arbitrary formulas can be downloaded through this catalog.
bool validSlideLesson(Map config, {bool requireInteractive = true}) {
  final slides = config['slides'];
  if (config['schema_version'] != 1 ||
      slides is! List ||
      slides.isEmpty ||
      slides.length > 12) {
    return false;
  }
  final ids = <String>{};
  var interactive = false;
  for (final raw in slides) {
    if (raw is! Map ||
        !_text(raw['id'], 80) ||
        !RegExp(r'^[a-z][a-z0-9-]*$').hasMatch(raw['id'] as String) ||
        !ids.add(raw['id'] as String) ||
        !slideEngineNames.containsKey(raw['engine']) ||
        !_text(raw['title'], 160) ||
        !_text(raw['prompt'], 10000, empty: raw['engine'] == 'story') ||
        !_text(raw['hint'], 3000, empty: true) ||
        !_text(raw['explanation'], 10000, empty: true) ||
        raw['config'] is! Map) {
      return false;
    }
    final c = raw['config'] as Map;
    switch (raw['engine']) {
      case 'story':
        if (!_text(c['text'], 10000) ||
            !_text(c['image_url'], 2000, empty: true) ||
            !_text(c['image_alt'], 500, empty: true)) {
          return false;
        }
        if ((c['image_url'] as String).isNotEmpty) {
          final uri = Uri.tryParse(c['image_url'] as String);
          if (uri == null ||
              uri.scheme != 'https' ||
              uri.host.isEmpty ||
              uri.userInfo.isNotEmpty ||
              (c['image_alt'] as String).trim().isEmpty) {
            return false;
          }
        }
      case 'quiz':
        interactive = true;
        final choices = c['choices'];
        if (choices is! List ||
            choices.length < 2 ||
            choices.length > 8 ||
            choices.any((s) => !_text(s, 2000)) ||
            !_integer(c['answer'], 0, choices.length - 1)) {
          return false;
        }
      case 'pairs':
        interactive = true;
        final pairs = c['pairs'];
        if (pairs is! List ||
            pairs.length < 2 ||
            pairs.length > 6 ||
            pairs.any(
              (p) =>
                  p is! Map ||
                  !_text(p['left'], 1000) ||
                  !_text(p['right'], 1000),
            )) {
          return false;
        }
      case 'graph':
        interactive = true;
        if ([
          'min_a',
          'max_a',
          'min_b',
          'max_b',
          'start_a',
          'start_b',
          'target_a',
          'target_b',
        ].any((k) => !_integer(c[k], -10, 10))) {
          return false;
        }
        if (c['min_a'] >= c['max_a'] ||
            c['min_b'] >= c['max_b'] ||
            !_integer(c['start_a'], c['min_a'] as int, c['max_a'] as int) ||
            !_integer(c['target_a'], c['min_a'] as int, c['max_a'] as int) ||
            !_integer(c['start_b'], c['min_b'] as int, c['max_b'] as int) ||
            !_integer(c['target_b'], c['min_b'] as int, c['max_b'] as int)) {
          return false;
        }
      default:
        interactive = true;
        if (!validExtendedSlide(raw['engine'] as String, c)) {
          return false;
        }
    }
  }
  return !requireInteractive || interactive;
}

Map<String, dynamic> initialSlideState(Map config) => {
  'index': 0,
  'slides': [
    for (final s in config['slides'] as List)
      switch (s['engine']) {
        'story' => {'ack': false},
        'quiz' => {'answer': -1},
        'pairs' => {
          'values': List.filled((s['config']['pairs'] as List).length, -1),
        },
        'graph' => {'a': s['config']['start_a'], 'b': s['config']['start_b']},
        _ => initialExtendedSlide(s['engine'] as String, s['config'] as Map),
      },
  ],
};

bool slideIsCorrect(Map slide, Map state) {
  final c = slide['config'] as Map;
  return switch (slide['engine']) {
    'story' => state['ack'] == true,
    'quiz' => state['answer'] is int && state['answer'] == c['answer'],
    'pairs' =>
      state['values'] is List &&
          (state['values'] as List).length == (c['pairs'] as List).length &&
          (state['values'] as List).indexed.every(
            (e) => e.$2 is int && e.$1 == e.$2,
          ),
    'graph' =>
      state['a'] is int &&
          state['b'] is int &&
          state['a'] == c['target_a'] &&
          state['b'] == c['target_b'],
    _ => extendedSlideCorrect(slide['engine'] as String, c, state),
  };
}

bool slideLessonIsCorrect(Map config, Map state) {
  final slides = config['slides'] as List, states = state['slides'];
  return states is List &&
      states.length == slides.length &&
      slides.indexed.every(
        (entry) =>
            states[entry.$1] is Map &&
            slideIsCorrect(entry.$2 as Map, states[entry.$1] as Map),
      );
}
