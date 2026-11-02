import 'experiment_model.dart';

const curriculumMechanisms = {
  'matchPairs',
  'sequenceTiles',
  'categorySort',
  'clozeBank',
  'evidenceBoard',
  'causalExperiment',
  'resourceBudget',
  'listeningChoice',
  'speechPractice',
};

bool supportsCurriculum(String mechanism) =>
    curriculumMechanisms.contains(mechanism);

String normalizeSpeech(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
    .replaceAll("'", '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

bool _indices(dynamic value, int length, int choices) =>
    value is List &&
    value.length == length &&
    value.every((v) => v is int && v >= 0 && v < choices);
bool _same(List<dynamic> a, List<dynamic> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

/// Deterministic local practice evaluation. Verified XP still belongs to the server.
EvaluationResult evaluateCurriculum(
  String mechanism,
  ExperimentData config,
  ExperimentData data,
) {
  bool correct = false;
  String feedback = 'complete-model';
  switch (mechanism) {
    case 'matchPairs':
    case 'categorySort':
    case 'clozeBank':
      final target = config['target'] as List;
      final values = data['values'];
      final choices = (config['choices'] as List).length;
      correct =
          _indices(values, target.length, choices) &&
          _same(values as List, target);
      feedback = 'check-connections';
    case 'sequenceTiles':
      final target = config['target'] as List;
      final values = data['values'];
      correct =
          _indices(values, target.length, target.length) &&
          (values as List).toSet().length == target.length &&
          _same(values, target);
      feedback = 'check-order';
    case 'evidenceBoard':
      final target = config['target'] as List;
      final selected = data['selected'];
      correct =
          _indices(selected, target.length, (config['items'] as List).length) &&
          selected is List &&
          selected.toSet().length == selected.length &&
          selected.every(target.contains);
      feedback = 'check-evidence';
    case 'listeningChoice':
      correct =
          data['experienced'] == true &&
          data['answer'] is int &&
          data['answer'] == config['target'];
      feedback = 'listen-and-compare';
    case 'speechPractice':
      final response = data['response'];
      correct =
          response is String &&
          response.length <= 500 &&
          (config['accepted'] as List).any(
            (s) => normalizeSpeech(s as String) == normalizeSpeech(response),
          );
      feedback = 'compare-phrase';
    case 'causalExperiment':
      final x = data['x'], y = data['y'], prediction = data['prediction'];
      if (x is int &&
          y is int &&
          x >= 0 &&
          x <= 3 &&
          y >= 0 &&
          y <= 3 &&
          prediction is int) {
        correct =
            x * y == config['goal'] &&
            prediction == x * y &&
            data['observed'] is List &&
            (data['observed'] as List).every((v) => v is int) &&
            _same(data['observed'] as List, [x, y, x * y]);
      }
      feedback = 'predict-run-compare';
    case 'resourceBudget':
      final values = data['values'];
      final minima = config['minima'] as List;
      if (_indices(values, minima.length, 11)) {
        final v = (values as List).cast<int>();
        correct =
            v.reduce((a, b) => a + b) == 10 &&
            List.generate(
              v.length,
              (i) => v[i] >= (minima[i] as int),
            ).every((v) => v);
      }
      feedback = 'check-resources';
  }
  return EvaluationResult(
    isCorrect: correct,
    feedbackKey: correct ? 'understood' : feedback,
    satisfiedConstraints: correct ? ['model-complete'] : const [],
    misconceptionCodes: correct ? const [] : [feedback],
  );
}

String curriculumFeedback(ExperimentSpec spec, ExperimentData data) {
  if (spec.isCorrect(data)) return spec.explanation;
  switch (spec.mechanism) {
    case 'resourceBudget':
      final values = data['values'];
      if (values is List && values.every((v) => v is int)) {
        final total = values.cast<int>().fold<int>(0, (a, b) => a + b);
        return 'Bạn đã phân bổ $total/10 đơn vị. Đủ tổng vẫn chưa đủ: đối chiếu mức tối thiểu của từng mục. ${spec.hint}';
      }
    case 'sequenceTiles':
      return 'Đọc lại thứ tự từ đầu: bước nào phải xảy ra trước để bước tiếp theo có nghĩa? ${spec.hint}';
    case 'evidenceBoard':
      return 'Chọn đủ bằng chứng trực tiếp, bỏ suy đoán và thông tin không kiểm chứng. ${spec.hint}';
    case 'causalExperiment':
      return 'Dự đoán trước, chạy mô hình rồi đối chiếu kết quả. Đổi tham số cần chạy lại. ${spec.hint}';
    case 'speechPractice':
      return 'So sánh các từ và thứ tự với câu mẫu; có thể nói lại hoặc nhập câu. Nhận dạng lời nói không chấm chất lượng phát âm.';
    case 'listeningChoice':
      return 'Nghe lại ở tốc độ chậm hoặc mở bản chữ, rồi đối chiếu ý chính thay vì một từ riêng lẻ. ${spec.hint}';
  }
  return 'Mô hình chưa khớp. Có thể thay lựa chọn mà không cần làm lại toàn bài. ${spec.hint}';
}
