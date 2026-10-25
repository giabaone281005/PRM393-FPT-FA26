import 'experiment_model.dart';
import 'space_guidance.dart';

bool supportsProgressiveGuidance(ExperimentSpec spec) => const {
  'geometry-solid-volume',
  'algebra-solid-relation',
  'geography-globe-grid',
  'geography-rock-layers',
  'math-paint',
  'math-number-line',
}.contains(spec.id);

String progressiveLessonHint(
  ExperimentSpec spec,
  ExperimentData data,
  int level,
) {
  final depth = level.clamp(1, 3);
  if (spec.id == 'math-paint') {
    if (depth == 1) {
      return 'Chiếc bánh là một toàn thể. So sánh số lát đang tô với toàn bộ các lát bằng nhau.';
    }
    if (depth == 2) {
      return 'Mẫu số 8 cho biết có 8 phần bằng nhau. Tử số 3 cho biết cần tô 3 phần.';
    }
    return 'Tô bất kỳ 3 lát khác nhau trong 8 lát. Chạm lại một lát để bỏ màu; vị trí các lát không đổi phân số được biểu diễn.';
  }
  if (spec.id == 'math-number-line') {
    if (depth == 1) {
      return 'Tìm một nửa đoạn từ 0 đến 1 trước. Ba phần tư nằm về phía nào so với một nửa?';
    }
    if (depth == 2) {
      return 'Mỗi phần tư gồm hai nấc một phần tám. Đi 3 phần tư tương đương đi 3 × 2 nấc.';
    }
    return '3/4 = 6/8. Đặt điểm ở nấc thứ 6 tính từ 0 rồi đối chiếu với mốc 1/2.';
  }
  return spaceHint(spec, data, depth);
}

String lessonModelFeedback(ExperimentSpec spec, ExperimentData data) {
  if (spec.id != 'math-paint' && spec.id != 'math-number-line') {
    return spaceFeedback(spec, data);
  }
  final result = spec.evaluate(data);
  if (result.feedbackKey == 'invalid-state') {
    return 'Trạng thái phân số chưa hợp lệ. Dùng “Làm lại” để tạo mô hình mới.';
  }
  if (result.isCorrect) return spec.explanation;
  if (spec.id == 'math-paint') {
    final count = (data['painted'] as List).length;
    return 'Bạn đang tô $count/8 chiếc bánh. Mục tiêu là 3/8. ${count < 3 ? 'Tô thêm' : 'Bỏ màu bớt'} rồi kiểm tra lại; không cần chọn một nhóm lát cố định.';
  }
  final position = data['position'] as int;
  return 'Điểm đang ở $position/8, ${position < 6 ? 'bên trái' : 'bên phải'} vị trí 3/4. Một phần tư có bao nhiêu nấc một phần tám?';
}
