const languageSlideEngines = <String, String>{
  'listeningChoice': 'Nghe và chọn',
  'speechPractice': 'Luyện nói tiếng Anh',
  'textEntry': 'Viết câu tiếng Anh',
};
String normaliseEnglish(String s) =>
    s.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), ' ').trim();
Map<String, dynamic> languageSlideConfig(String e) => switch (e) {
  'listeningChoice' => {
    'text': 'I go to school at eight.',
    'choices': ['At seven.', 'At eight.', 'At nine.'],
    'answer': 1,
  },
  'speechPractice' => {'text': 'I can ride a bike.'},
  _ => {
    'accepted_answers': ['My name is Mia.', 'I am Mia.'],
  },
};
bool _text(dynamic v, int max) =>
    v is String && v.length <= max && normaliseEnglish(v).isNotEmpty;
bool validLanguageSlide(String e, Map c) {
  if (e == 'textEntry') {
    return c['accepted_answers'] is List &&
        (c['accepted_answers'] as List).isNotEmpty &&
        (c['accepted_answers'] as List).length <= 6 &&
        (c['accepted_answers'] as List).every((v) => _text(v, 500));
  }
  if (!_text(c['text'], 500)) return false;
  return e == 'speechPractice' ||
      (c['choices'] is List &&
          (c['choices'] as List).length >= 2 &&
          (c['choices'] as List).length <= 8 &&
          (c['choices'] as List).every(
            (v) => v is String && v.trim().isNotEmpty && v.length <= 1000,
          ) &&
          c['answer'] is int &&
          c['answer'] >= 0 &&
          c['answer'] < (c['choices'] as List).length);
}

Map<String, dynamic> initialLanguageSlide(String e) => e == 'listeningChoice'
    ? {'answer': -1, 'experienced': false}
    : {'response': ''};
bool correctLanguageSlide(String e, Map c, Map s) {
  if (e == 'listeningChoice') {
    return s['experienced'] == true &&
        s['answer'] is int &&
        s['answer'] == c['answer'];
  }
  final response = s['response'];
  return response is String &&
      response.length <= 500 &&
      (e == 'speechPractice' ? [c['text']] : c['accepted_answers'] as List).any(
        (v) => normaliseEnglish(response) == normaliseEnglish(v as String),
      );
}
