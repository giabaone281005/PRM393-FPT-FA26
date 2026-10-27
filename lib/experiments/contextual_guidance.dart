import 'experiment_model.dart';

/// Offline observations of the learner's model, without changing it.
/// These are deterministic rules, not a chat or AI service.
String contextualHint(ExperimentSpec spec, ExperimentData data) {
  if (spec.mechanism == 'reasonedChoice') {
    final result = spec.evaluate(data);
    if (result.feedbackKey == 'invalid-state') {
      return 'Chọn cả kết quả và lý do trước khi kiểm tra. ${spec.hint}';
    }
    if (result.feedbackKey == 'rethink-reason') {
      return 'Kết quả đã phù hợp. Hãy đối chiếu lý do với kiến thức và tình huống của bài. ${spec.hint}';
    }
    return spec.hint;
  }
  if (spec.stage != 'Khám phá') return spec.hint;
  switch (spec.mechanism) {
    case 'balanceBlocks':
      final blocks = data['blocks'];
      if (blocks is! int || blocks < 0) {
        return spec.hint;
      }
      if (blocks == 4) {
        return 'Hai đĩa đang cân bằng. Bạn đã làm hai bên nặng bằng nhau.';
      }
      return 'Đĩa của bạn có $blocks khối và đang ${blocks < 4 ? 'nhẹ' : 'nặng'} hơn hộp. Thử thay đổi số khối rồi quan sát cân.';
    case 'leverTorque':
      final position = data['position'];
      if (position is! int || position < 0) {
        return spec.hint;
      }
      final torque = position * 2;
      if (torque == 6) {
        return 'Hai bên đang có mômen bằng nhau nên đòn bẩy cân bằng.';
      }
      return 'Quả 2 kg đang cách trục $position m: mômen bên phải là $torque, ${torque < 6 ? 'nhỏ' : 'lớn'} hơn bên trái. Khoảng cách thay đổi tác dụng của quả nặng thế nào?';
    case 'fractionPaint':
      final painted = data['painted'];
      if (painted is! List ||
          painted.any((v) => v is! int || v < 0 || v >= 8) ||
          painted.toSet().length != painted.length) {
        return spec.hint;
      }
      final count = painted.length;
      return count == 3
          ? 'Bạn đã tô $count trong 8 lát bằng nhau. Phần tô khớp với phân số đề bài.'
          : 'Bạn đang tô $count trong 8 lát, tức $count/8 chiếc bánh. So sánh phần tô với phân số đề bài; chạm lại một lát để bỏ màu.';
    case 'robotRoute':
      final commands = data['commands'];
      if (commands is! List ||
          commands.length > 32 ||
          commands.any((c) => !const ['R', 'L', 'D', 'U'].contains(c))) {
        return spec.hint;
      }
      int x = 0, y = 0;
      for (int i = 0; i < commands.length; i++) {
        switch (commands[i]) {
          case 'R':
            x++;
          case 'L':
            x--;
          case 'D':
            y++;
          case 'U':
            y--;
        }
        if (x < 0 || x > 3 || y < 0 || y > 3) {
          return 'Lệnh thứ ${i + 1} đưa robot ra ngoài bản đồ. Xem lại lệnh này trước khi thêm đường đi.';
        }
        if (x == 1 && y == 1) {
          return 'Lệnh thứ ${i + 1} đưa robot vào ô đá. Đường đi bị chặn tại đây; thử chỉnh đoạn trước ô đá.';
        }
      }
      if (x == 3 && y == 3) {
        return 'Robot đã tới ngôi sao mà không chạm đá hay rời bản đồ.';
      }
      return 'Sau ${commands.length} lệnh, robot ở cột ${x + 1}, hàng ${y + 1}. Ngôi sao ở cột 4, hàng 4; quan sát vị trí còn cách đích.';
    case 'wireCircuit':
      final edges = data['edges'];
      if (edges is! List ||
          edges.any(
            (v) => v is! String || !RegExp(r'^[0-3]-[0-3]$').hasMatch(v),
          ) ||
          edges.toSet().length != edges.length) {
        return spec.hint;
      }
      if (edges.contains('0-3') || edges.contains('1-2')) {
        return 'Có dây nối tắt hai cực nguồn hoặc hai đầu đèn. Lần theo đường dây: dòng điện cần đi qua đèn rồi trở về nguồn.';
      }
      final connected = edges.where((v) => v == '0-1' || v == '2-3').length;
      if (connected == 2 && edges.length == 2) {
        return 'Đường dây đã khép kín qua đèn và nguồn.';
      }
      return 'Bạn đã nối ${edges.length} dây. ${connected == 1 ? 'Một phía của đèn đã nối với nguồn; phía còn lại chưa khép vòng.' : 'Hãy lần theo một vòng từ nguồn, qua đèn, rồi trở về nguồn.'}';
    case 'switchLogic':
      final switches = data['switches'];
      if (switches is! List ||
          switches.length != 3 ||
          switches.any((v) => v is! bool)) {
        return spec.hint;
      }
      final a = switches[0] as bool,
          b = switches[1] as bool,
          c = switches[2] as bool;
      if (a) {
        return 'Nhánh A đang đóng, trong khi nhánh này cần để mở khi bảo trì. Kiểm tra điều kiện bảo trì trước.';
      }
      if (!c) {
        return 'Công tắc chính C đang mở nên đường điện chưa kín, kể cả khi một nhánh song song đã đóng.';
      }
      if (!b) {
        return 'Công tắc chính đã đóng, nhưng cả hai nhánh song song đều đang mở. Quan sát nhánh còn dùng được khi A bảo trì.';
      }
      return 'Đèn có đường điện kín qua nhánh B và C, còn nhánh A vẫn mở để bảo trì.';
    case 'distributeObjects':
      final baskets = data['baskets'];
      if (baskets is! List ||
          baskets.length != 3 ||
          baskets.any((v) => v is! int || v < 0)) {
        return spec.hint;
      }
      final total = baskets.fold<int>(0, (sum, v) => sum + (v as int));
      if (total > 9) {
        return spec.hint;
      }
      if (total == 9 && baskets.toSet().length == 1) {
        return 'Cả ba giỏ có cùng số cam và không còn quả bên ngoài.';
      }
      return 'Ba giỏ đang có ${baskets.join(', ')} quả; còn ${9 - total} quả bên ngoài. So sánh các giỏ trước khi chuyển quả tiếp theo.';
    case 'tangramRotate':
      final turns = data['turns'], placed = data['placed'];
      if (turns is! List ||
          turns.length != 2 ||
          turns.any((v) => v is! int || v < 0 || v > 3) ||
          placed is! List ||
          placed.length != 2 ||
          placed.any((v) => v is! bool)) {
        return spec.hint;
      }
      final count = placed.where((v) => v == true).length;
      if (count < 2) {
        return 'Bạn đã đặt $count trong 2 mảnh vào khung. Xem hướng góc vuông và cạnh huyền trước khi đặt mảnh còn lại.';
      }
      return (turns[0] - turns[1]).abs() == 2
          ? 'Hai mảnh đã ghép kín khung, với hai góc vuông ở hai góc đối diện.'
          : 'Cả hai mảnh đã ở trong khung nhưng hướng xoay chưa khớp. Quan sát xem hai cạnh huyền có trùng nhau không.';
    default:
      return spec.hint;
  }
}
