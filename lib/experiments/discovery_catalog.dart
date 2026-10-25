import 'experiment_model.dart';

bool _same(List<dynamic> a, List<dynamic> b) =>
    a.length == b.length &&
    List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

/// Each comparator sends the smaller value to its upper wire.
List<int> runComparatorNetwork(List<int> stages, List<int> input) {
  final output = List<int>.from(input);
  for (final stage in stages) {
    if (stage < 0 || stage > 2) throw ArgumentError('Comparator ngoài bốn dây');
    if (output[stage] > output[stage + 1]) {
      final value = output[stage];
      output[stage] = output[stage + 1];
      output[stage + 1] = value;
    }
  }
  return output;
}

final comparatorTestInputs = <List<int>>[
  for (int a = 1; a <= 4; a++)
    for (int b = 1; b <= 4; b++)
      for (int c = 1; c <= 4; c++)
        for (int e = 1; e <= 4; e++)
          if ({a, b, c, e}.length == 4) [a, b, c, e],
];

final Map<String, List<ExperimentSpec>> discoveryExperiments = {
  'geometry': [
    ExperimentSpec(
      id: 'geometry-rectangle',
      title: 'Kéo ra diện tích',
      prompt: 'Di chuyển bốn đỉnh để tạo hình chữ nhật có diện tích 6 ô vuông.',
      hint: 'Thử một cạnh dài 3 ô và một cạnh dài 2 ô.',
      explanation:
          'Diện tích hình chữ nhật bằng chiều dài nhân chiều rộng: 3 × 2 = 6.',
      mechanism: 'polygonVertices',
      initial: {
        'points': [
          [0, 0],
          [4, 0],
          [4, 4],
          [0, 4],
        ],
      },
      validator: (d) {
        final p = (d['points'] as List).cast<List>();
        return p.length == 4 &&
            p.every(
              (v) =>
                  v.length == 2 && v.every((c) => c is int && c >= 0 && c <= 4),
            ) &&
            p[0][1] == p[1][1] &&
            p[1][0] == p[2][0] &&
            p[2][1] == p[3][1] &&
            p[3][0] == p[0][0] &&
            ((p[1][0] - p[0][0]) * (p[3][1] - p[0][1])).abs() == 6;
      },
    ),
    ExperimentSpec(
      id: 'geometry-mirror',
      title: 'Xưởng đối xứng',
      prompt: 'Chạm các ô bên phải để phản chiếu hình xanh qua trục giữa.',
      hint: 'Mỗi ô ảnh cách trục một khoảng bằng ô gốc.',
      explanation: 'Phép đối xứng giữ nguyên hàng và đảo vị trí cột qua trục.',
      mechanism: 'symmetryMirror',
      initial: {'cells': <int>[]},
      validator: (d) {
        final s = (d['cells'] as List).toSet();
        return (d['cells'] as List).length == 3 &&
            s.length == 3 &&
            s.containsAll([11, 16, 23]);
      },
    ),
    ExperimentSpec(
      id: 'geometry-tangram',
      title: 'Hai mảnh thành vuông',
      prompt: 'Xoay hai tam giác, rồi kéo từng mảnh vào khung để ghép thành hình vuông.',
      hint: 'Hai cạnh huyền phải trùng nhau, hai góc vuông nằm ở hai góc đối diện.',
      explanation: 'Hai tam giác vuông bằng nhau ghép dọc cạnh huyền tạo thành hình vuông.',
      mechanism: 'tangramRotate',
      initial: {
        'turns': [1, 1],
        'placed': [false, false],
      },
      validator: (d) {
        final turns = d['turns'] as List;
        return turns.length == 2 &&
            turns.every((v) => v is int && v >= 0 && v < 4) &&
            (turns[0] - turns[1]).abs() == 2 &&
            _same(d['placed'], [true, true]);
      },
    ),
  ],
  'coding': [
    ExperimentSpec(
      id: 'coding-route',
      title: 'Dẫn robot về nhà',
      prompt: 'Vuốt trên bản đồ hoặc thêm lệnh để dẫn robot từ góc trái trên tới ngôi sao. Tránh ô đá ở giữa.',
      hint: 'Đi theo mép trên rồi rẽ xuống. Bạn có thể xóa lệnh để thử lại.',
      explanation: 'Một thuật toán là chuỗi thao tác rõ ràng; thứ tự lệnh quyết định đường đi.',
      mechanism: 'robotRoute',
      initial: {'commands': <String>[]},
      validator: (d) {
        int x = 0, y = 0;
        if ((d['commands'] as List).length > 32) return false;
        for (final c in d['commands'] as List) {
          if (!['R', 'L', 'D', 'U'].contains(c)) return false;
          if (c == 'R') x++;
          if (c == 'L') x--;
          if (c == 'D') y++;
          if (c == 'U') y--;
          if (x < 0 || x > 3 || y < 0 || y > 3 || (x == 1 && y == 1)) {
            return false;
          }
        }
        return x == 3 && y == 3;
      },
    ),
    ExperimentSpec(
      id: 'coding-loop',
      title: 'Cầu thang vòng lặp',
      prompt: 'Lắp hai lệnh và đặt số lần lặp để robot đi đúng cầu thang: sang phải rồi xuống, ba lần.',
      hint: 'Khối lặp giúp dùng hai lệnh để tạo ra sáu bước.',
      explanation: 'Lặp [phải, xuống] ba lần tạo đường cầu thang tới ô (3, 3).',
      mechanism: 'loopBuilder',
      initial: {
        'body': ['D', 'R'],
        'repeat': 1,
      },
      validator: (d) => _same(d['body'], ['R', 'D']) && d['repeat'] == 3,
    ),
    ExperimentSpec(
      id: 'coding-sort',
      title: 'Thiết kế máy sắp xếp',
      prompt: 'Lắp tối đa 6 bộ so sánh giữa các dây kề nhau, rồi chạy máy. Mạng cần sắp đúng cả 24 thứ tự đầu vào.',
      hint: 'Mỗi bộ so sánh chỉ đổi chỗ khi số trên lớn hơn số dưới. Thử chuỗi 1–2, 2–3, 3–4, rồi xử lý ba dây đầu.',
      explanation: 'Một mạng sắp xếp dùng cùng chuỗi bộ so sánh cho mọi đầu vào. Mỗi bộ tự đưa số nhỏ lên trên; mạng này đã vượt qua cả 24 hoán vị.',
      mechanism: 'sortingNetwork',
      initial: {'stages': <int>[], 'result': <int>[]},
      validator: (d) {
        final stages = (d['stages'] as List).cast<int>();
        if (stages.isEmpty ||
            stages.length > 6 ||
            stages.any((s) => s < 0 || s > 2)) {
          return false;
        }
        return _same(d['result'], runComparatorNetwork(stages, [4, 1, 3, 2])) &&
            comparatorTestInputs.every(
              (input) =>
                  _same(runComparatorNetwork(stages, input), [1, 2, 3, 4]),
            );
      },
    ),
  ],
  'circuits': [
    ExperimentSpec(
      id: 'circuits-wire',
      title: 'Ánh sáng đầu tiên',
      prompt: 'Đèn và nguồn đã gắn sẵn. Kéo hai dây để nối cực dương nguồn tới đầu vào đèn, rồi nối đầu ra đèn về cực âm.',
      hint: 'Cần dây 1–2 và dây 3–4. Đừng nối trực tiếp hai cực nguồn hoặc nối tắt hai đầu đèn.',
      explanation:
          'Dòng điện cần một đường kín từ nguồn, qua tải và trở về nguồn.',
      mechanism: 'wireCircuit',
      initial: {'edges': <String>[]},
      validator: (d) =>
          (d['edges'] as List).length == 2 &&
          (d['edges'] as List).toSet().containsAll(['0-1', '2-3']),
    ),
    ExperimentSpec(
      id: 'circuits-logic',
      title: 'Đường điện dự phòng',
      prompt: 'Nhánh A đang bảo trì: giữ A mở. Bật đèn bằng nhánh B và công tắc chính C.',
      hint: 'A và B mắc song song, cả hai cùng đi qua C.',
      explanation:
          'Mạch sáng khi (A HOẶC B) VÀ C. Với A mở, B và C đều phải đóng.',
      mechanism: 'switchLogic',
      initial: {
        'switches': [false, false, false],
      },
      validator: (d) => _same(d['switches'], [false, true, true]),
    ),
    ExperimentSpec(
      id: 'circuits-light',
      title: 'Phòng pha ánh sáng',
      prompt: 'Điều chỉnh ba chùm sáng để tạo màu vàng của mẫu.',
      hint: 'Ánh sáng đỏ cộng ánh sáng lục tạo vàng; ánh sáng lam làm màu nhạt đi.',
      explanation:
          'Pha màu cộng: đỏ + lục = vàng. Đây là ánh sáng, khác pha sơn.',
      mechanism: 'colorMixer',
      initial: {
        'rgb': [0.0, 0.0, 1.0],
      },
      validator: (d) {
        final r = d['rgb'] as List;
        return r.length == 3 &&
            r.every((v) => v is num && v >= 0 && v <= 1) &&
            (r[0] as num) > .95 &&
            (r[1] as num) > .95 &&
            (r[2] as num) < .05;
      },
    ),
  ],
  'probability': [
    ExperimentSpec(
      id: 'probability-bag',
      title: 'Túi bí mật',
      prompt: 'Thả đủ 6 viên vào túi để xác suất rút một viên xanh là 1/3.',
      hint: 'Trong 6 viên, cần 2 viên xanh. Các viên còn lại màu đỏ.',
      explanation: 'Có 2 kết quả xanh trên 6 viên đồng khả năng: 2/6 = 1/3.',
      mechanism: 'probabilityBag',
      initial: {'balls': <String>[]},
      validator: (d) {
        final b = d['balls'] as List;
        return b.length == 6 &&
            b.where((v) => v == 'B').length == 2 &&
            b.where((v) => v == 'R').length == 4;
      },
    ),
    ExperimentSpec(
      id: 'probability-space',
      title: 'Bản đồ hai đồng xu',
      prompt: 'Ghép từng cặp mặt xu vào bảng để liệt kê đủ các kết quả khi tung hai đồng xu có thứ tự.',
      hint: 'SN khác NS vì đồng thứ nhất và đồng thứ hai được phân biệt.',
      explanation: 'Không gian mẫu gồm SS, SN, NS, NN. Bốn kết quả có xác suất bằng nhau với xu cân đối.',
      mechanism: 'sampleSpace',
      initial: {'outcomes': <String>[]},
      validator: (d) {
        final o = d['outcomes'] as List;
        return o.length == 4 && o.toSet().containsAll(['SS', 'SN', 'NS', 'NN']);
      },
    ),
    ExperimentSpec(
      id: 'probability-spinner',
      title: 'Thiết kế vòng quay',
      prompt: 'Kéo tay nắm để phần màu xanh chiếm 3/8 vòng quay.',
      hint: 'Vòng quay được chia thành 8 cung bằng nhau; cần 3 cung xanh.',
      explanation: 'Xác suất trúng màu xanh bằng phần góc xanh trên cả vòng: 3 × 45° / 360° = 3/8.',
      mechanism: 'probabilitySpinner',
      initial: {'sectors': 1},
      validator: (d) => d['sectors'] == 3,
    ),
  ],
};
