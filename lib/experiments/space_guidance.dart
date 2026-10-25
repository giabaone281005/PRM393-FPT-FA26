import 'experiment_model.dart';
import 'solid_model.dart';

EvaluationResult evaluateSpace(String id, ExperimentData data) {
  if (id == 'geometry-solid-volume' || id == 'algebra-solid-relation') {
    if (!validSolidState(data)) {
      return const EvaluationResult(
        isCorrect: false,
        feedbackKey: 'invalid-state',
      );
    }
    final volume = solidVolume(data);
    final constraints = <String>[];
    if (id == 'geometry-solid-volume') {
      if (volume == 12) constraints.add('volume');
      if (solidSurface(data) == 32) constraints.add('surface');
      return EvaluationResult(
        isCorrect: constraints.length == 2,
        satisfiedConstraints: constraints,
        feedbackKey: constraints.length == 2
            ? 'solid-match'
            : constraints.contains('volume')
            ? 'surface-mismatch'
            : 'volume-mismatch',
      );
    }
    if (volume == 16) constraints.add('volume');
    if (data['width'] == 2 * data['height']) constraints.add('double-height');
    if (data['depth'] == data['height']) constraints.add('equal-depth');
    return EvaluationResult(
      isCorrect: constraints.length == 3,
      satisfiedConstraints: constraints,
      feedbackKey: constraints.length == 3
          ? 'solid-match'
          : constraints.contains('volume')
          ? 'relation-mismatch'
          : 'volume-mismatch',
    );
  }
  if (id == 'geography-globe-grid') {
    final lat = data['latitude'];
    final lon = data['longitude'];
    if (lat is! int ||
        lon is! int ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      return const EvaluationResult(
        isCorrect: false,
        feedbackKey: 'invalid-state',
      );
    }
    final constraints = [
      if (lat == 15) 'latitude',
      if (lon == 105) 'longitude',
    ];
    return EvaluationResult(
      isCorrect: constraints.length == 2,
      satisfiedConstraints: constraints,
      feedbackKey: constraints.length == 2
          ? 'coordinate-match'
          : lat != 15
          ? 'latitude-mismatch'
          : 'longitude-mismatch',
    );
  }
  final layers = data['layers'];
  if (id != 'geography-rock-layers' ||
      layers is! List ||
      layers.length != 3 ||
      layers.toSet().length != 3 ||
      layers.any((v) => v is! int || !const [10, 20, 30].contains(v))) {
    return const EvaluationResult(
      isCorrect: false,
      feedbackKey: 'invalid-state',
    );
  }
  final correct = validLayerOrder(layers);
  return EvaluationResult(
    isCorrect: correct,
    satisfiedConstraints: [
      for (var i = 0; i < 2; i++)
        if (layers[i] < layers[i + 1]) 'order-$i',
    ],
    feedbackKey: correct ? 'layers-match' : 'layer-order-mismatch',
  );
}

int savedHintLevel(dynamic value, {bool previouslyUsed = false}) => value is int
    ? value.clamp(0, 3)
    : previouslyUsed
    ? 1
    : 0;

String compareSolids(ExperimentData current, dynamic rawReference) {
  final reference = solidReference(rawReference);
  if (reference == null || !validSolidState(current)) {
    return 'Lưu một mẫu hợp lệ trước khi so sánh.';
  }
  final volumeDelta = solidVolume(current) - solidVolume(reference);
  final surfaceDelta = solidSurface(current) - solidSurface(reference);
  if (volumeDelta == 0 && surfaceDelta != 0) {
    return 'Hai khối cùng thể tích nhưng khác diện tích bề mặt. Cùng một lượng không gian có thể được bao bởi các diện tích khác nhau.';
  }
  if (surfaceDelta == 0 && volumeDelta != 0) {
    return 'Hai khối cùng diện tích bề mặt nhưng khác thể tích. So sánh các kích thước để tìm cách bao được nhiều không gian hơn.';
  }
  if (volumeDelta == 0 && surfaceDelta == 0) {
    return 'Thể tích và diện tích bề mặt đang bằng mẫu đã lưu. Thử đổi một cạnh rồi quan sát đại lượng nào thay đổi.';
  }
  String delta(int value) => value > 0 ? 'tăng $value' : 'giảm ${-value}';
  return 'So với mẫu: thể tích ${delta(volumeDelta)} đv³; bề mặt ${delta(surfaceDelta)} đv². Thử chỉ đổi một cạnh để tách tác dụng của cạnh đó.';
}

String spaceHint(ExperimentSpec spec, ExperimentData data, int level) {
  final hint = level.clamp(1, 3);
  switch (spec.id) {
    case 'geometry-solid-volume':
      if (hint == 1) {
        return 'Thử giữ hai cạnh không đổi, đổi cạnh còn lại rồi quan sát cả thể tích và bề mặt.';
      }
      if (hint == 2) {
        return 'Thể tích là tích ba cạnh. Bề mặt là 2 × (dài × cao + dài × sâu + cao × sâu). Cần thỏa cả hai điều kiện.';
      }
      return 'Thử các cạnh 2, 2 và 3 rồi kiểm tra sáu mặt. Có thể đổi chỗ ba kích thước mà không đổi thể tích hoặc bề mặt.';
    case 'algebra-solid-relation':
      if (hint == 1) {
        return 'Làm chiều cao và chiều sâu bằng nhau, rồi kiểm tra quan hệ với chiều dài.';
      }
      if (hint == 2) {
        return 'Gọi chiều cao là h: chiều sâu cũng là h, chiều dài là 2h. Thể tích là 2 × h × h × h.';
      }
      return 'Thử cao 2, sâu 2, dài 4. Đối chiếu từng quan hệ trước khi kiểm tra thể tích 16.';
    case 'geography-globe-grid':
      if (hint == 1) {
        return 'Tìm phía Bắc xích đạo trước. Xoay địa cầu chỉ đổi góc nhìn, chưa đổi điểm đã chọn.';
      }
      if (hint == 2) {
        return 'Vĩ độ điều khiển Bắc–Nam; kinh độ điều khiển Đông–Tây. Ở đây Bắc và Đông mang dấu dương.';
      }
      return 'Đặt vĩ độ +15° và kinh độ +105°. Dùng “Nhìn tới điểm đã chọn” để kiểm tra vị trí trên lưới.';
    case 'geography-rock-layers':
      if (hint == 1) {
        return 'So sánh tuổi hai lớp nằm cạnh nhau. Lớp nào đã hình thành trước?';
      }
      if (hint == 2) {
        return 'Tuổi lớn hơn nghĩa là hình thành sớm hơn. Với các lớp chưa bị đảo lộn, lớp cũ hơn nằm bên dưới.';
      }
      return 'Sắp từ trên xuống: 10, 20, 30 triệu năm. Đây là mô hình trầm tích chưa bị đảo lộn, không phải quy tắc cho mọi địa tầng.';
    default:
      return spec.hint;
  }
}

String spaceFeedback(ExperimentSpec spec, ExperimentData data) {
  final result = evaluateSpace(spec.id, data);
  if (result.feedbackKey == 'invalid-state') {
    return 'Trạng thái mô hình chưa hợp lệ. Dùng “Làm lại” rồi thử điều chỉnh từng bước.';
  }
  if (result.isCorrect) return spec.explanation;
  switch (spec.id) {
    case 'geometry-solid-volume':
      final v = solidVolume(data), s = solidSurface(data);
      return result.satisfiedConstraints.contains('volume')
          ? 'Thể tích $v đã đạt. Bề mặt hiện là $s, cần 32. Thử một bộ kích thước khác vẫn có tích bằng 12.'
          : 'Thể tích hiện là $v, cần 12. Bề mặt hiện là $s. So sánh tác dụng của từng cạnh trước khi kiểm tra cả hai điều kiện.';
    case 'algebra-solid-relation':
      final missing = [
        if (!result.satisfiedConstraints.contains('volume')) 'thể tích 16',
        if (!result.satisfiedConstraints.contains('double-height'))
          'dài gấp đôi cao',
        if (!result.satisfiedConstraints.contains('equal-depth'))
          'sâu bằng cao',
      ];
      return 'Thể tích hiện là ${solidVolume(data)}. Còn cần thỏa: ${missing.join('; ')}.';
    case 'geography-globe-grid':
      return result.satisfiedConstraints.contains('latitude')
          ? 'Vĩ độ 15° Bắc đã đúng. Kinh độ hiện là ${data['longitude']}°; kiểm tra hướng Đông và mốc 105°.'
          : 'Vĩ độ hiện là ${data['latitude']}°. Tìm 15° Bắc xích đạo trước, rồi đối chiếu kinh độ 105° Đông.';
    default:
      final layers = data['layers'] as List;
      final i = layers[0] > layers[1] ? 0 : 1;
      return 'Lớp ${i + 1} (${layers[i]} triệu năm) đang cũ hơn lớp ngay dưới (${layers[i + 1]} triệu năm). Với mô hình chưa đảo lộn, hãy đổi thứ tự cặp này.';
  }
}
