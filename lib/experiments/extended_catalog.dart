import 'discovery_catalog.dart';
import 'experiment_model.dart';

bool _ints(dynamic value, List<int> expected) =>
    value is List &&
    value.length == expected.length &&
    List.generate(
      expected.length,
      (i) => value[i] == expected[i],
    ).every((v) => v);

ExperimentSpec _remove(
  String id,
  String title,
  int extra,
  int total,
) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Vận dụng',
  mechanism: 'removeBothSides',
  prompt:
      'Mô hình đang biểu diễn x + $extra = $total. Giữ cân bằng và cô lập x bằng cách bỏ cùng một lượng ở hai vế.',
  hint:
      'Quan sát lượng còn cộng với x. Mỗi thao tác phải giữ hai vế bằng nhau.',
  explanation:
      'Bớt $extra ở cả hai vế bảo toàn đẳng thức: x = ${total - extra}. Giá trị thay đổi, quy tắc cân bằng vẫn giữ nguyên.',
  config: {'extra': extra, 'total': total},
  initial: {'pairs': 0},
  validator: (d) => d['pairs'] == extra,
);

ExperimentSpec _paint(
  String id,
  String title,
  String goal,
  int count,
) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Vận dụng',
  mechanism: 'fractionPaint',
  prompt: '$goal Tự tô trên chiếc bánh chia 8 lát bằng nhau.',
  hint: 'Đổi về những phần có mẫu số 8. Có thể chạm lại để bỏ màu một lát.',
  explanation:
      'Phần tô là $count/8; phần chưa tô là ${8 - count}/8. Một tổng thể cho phép diễn tả cả phần và phần bù.',
  initial: {'painted': <int>[]},
  validator: (d) {
    final p = d['painted'] as List;
    return p.length == count &&
        p.toSet().length == count &&
        p.every((v) => v is int && v >= 0 && v < 8);
  },
);

ExperimentSpec _motion(
  String id,
  String title,
  String goal,
  ExperimentValidator rule,
) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Thử thách',
  mechanism: 'motionTimeline',
  prompt:
      '$goal Mỗi ô dài 2 giây; đi chậm 1 m/s, đi nhanh 2 m/s. Ghép thẻ rồi đọc đường đi.',
  hint: 'Quãng đường mỗi ô = tốc độ × 2. Thời gian nghỉ vẫn trôi, nhưng quãng đường không tăng.',
  explanation: 'Tổng quãng đường bằng tổng diện tích dưới từng đoạn tốc độ. Cùng một quãng đường có thể có nhiều lịch trình; các điều kiện phụ quyết định lịch trình phù hợp.',
  initial: {
    'segments': [-1, -1, -1],
  },
  validator: (d) {
    final v = d['segments'] as List;
    return v.length == 3 &&
        v.every((x) => x is int && x >= 0 && x <= 2) &&
        rule(d);
  },
);

ExperimentSpec _city(
  String id,
  String title,
  List<int> start,
  String goal,
  List<int> end,
) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Thử thách',
  mechanism: 'redistributeMean',
  prompt: '$goal Chuyển tầng giữa ba tòa; không được thêm hay bỏ tầng.',
  hint: 'Tổng số tầng được bảo toàn. Dùng tổng và quan hệ giữa các tòa để tìm mô hình phù hợp.',
  explanation:
      'Tổng ${start.reduce((a, b) => a + b)} tầng không đổi sau mỗi lần chuyển. Mô hình ${end.join(' – ')} thỏa đồng thời tổng và các quan hệ đề bài.',
  initial: {'heights': start},
  validator: (d) => _ints(d['heights'], end),
);

ExperimentSpec _rectangle(
  String id,
  String title,
  int area,
  int perimeter,
) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Thử thách',
  mechanism: 'polygonVertices',
  prompt:
      'Kéo bốn đỉnh thành hình chữ nhật có diện tích $area ô vuông và chu vi $perimeter đơn vị. Mỗi khoảng lưới dài 1 đơn vị.',
  hint:
      'Tìm hai cạnh vừa có tích bằng $area, vừa có tổng bằng ${perimeter ~/ 2}. Không chỉ kiểm tra diện tích.',
  explanation: 'Diện tích ràng buộc tích hai cạnh; chu vi ràng buộc tổng hai cạnh. Một mô hình phải đáp ứng cả hai điều kiện.',
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
    if (p.length != 4 ||
        p.any(
          (v) => v.length != 2 || v.any((c) => c is! int || c < 0 || c > 4),
        )) {
      return false;
    }
    final w = ((p[1][0] as int) - (p[0][0] as int)).abs();
    final h = ((p[3][1] as int) - (p[0][1] as int)).abs();
    return p[0][1] == p[1][1] &&
        p[1][0] == p[2][0] &&
        p[2][1] == p[3][1] &&
        p[3][0] == p[0][0] &&
        w * h == area &&
        2 * (w + h) == perimeter;
  },
);

ExperimentSpec _route(
  String id,
  String title, {
  int max = 6,
  List<int>? via,
  List<String> start = const [],
}) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Thử thách',
  mechanism: 'robotRoute',
  prompt:
      'Dẫn robot tới sao bằng tối đa $max lệnh, tránh đá và mép bản đồ.${via == null ? '' : ' Trước khi tới đích, phải qua cột ${via[0] + 1}, hàng ${via[1] + 1} (đếm từ góc trái trên).'}${start.isEmpty ? '' : ' Đường hiện tại có lỗi: dùng nút lùi để sửa.'}',
  hint: 'Mỗi bước chỉ thay đổi một tọa độ. Quan sát đường vẽ và loại các bước vòng lại không cần thiết.',
  explanation:
      'Thuật toán tốt vừa đi đúng, vừa tuân thủ giới hạn tài nguyên. Đường đi của bạn vượt qua đá, đến đích và đáp ứng giới hạn $max lệnh.',
  initial: {'commands': start},
  validator: (d) {
    final commands = d['commands'] as List;
    if (commands.isEmpty || commands.length > max) return false;
    int x = 0, y = 0;
    bool visited = via == null;
    for (final c in commands) {
      if (!['R', 'L', 'D', 'U'].contains(c)) return false;
      if (c == 'R') x++;
      if (c == 'L') x--;
      if (c == 'D') y++;
      if (c == 'U') y--;
      if (x < 0 || x > 3 || y < 0 || y > 3 || (x == 1 && y == 1)) return false;
      if (via != null && x == via[0] && y == via[1]) visited = true;
    }
    return x == 3 && y == 3 && visited;
  },
);

ExperimentSpec _light(
  String id,
  String title,
  String name,
  int color,
  List<int> rgb,
) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Vận dụng',
  mechanism: 'colorMixer',
  prompt:
      'Điều chỉnh ba nguồn sáng để khớp mẫu $name. Quan sát màu trộn khi tăng hoặc giảm từng nguồn.',
  hint: 'Thử bật từng cặp nguồn, rồi cả ba nguồn. Đây là pha ánh sáng cộng, không phải pha sơn.',
  explanation:
      'Mẫu $name được tạo bởi mức đỏ–lục–lam ${rgb.map((v) => v * 100).join('% – ')}%. Cộng các chùm sáng thay đổi cả sắc và độ sáng.',
  config: {'color': color, 'colorLabel': 'Mẫu $name'},
  initial: {
    'rgb': [0.0, 0.0, 0.0],
  },
  validator: (d) {
    final v = d['rgb'] as List;
    return v.length == 3 &&
        List.generate(
          3,
          (i) =>
              v[i] is num &&
              (v[i] as num) >= 0 &&
              (v[i] as num) <= 1 &&
              ((v[i] as num) - rgb[i]).abs() < .05,
        ).every((v) => v);
  },
);

ExperimentSpec _bag(
  String id,
  String title,
  int total,
  int blue,
  String goal,
) => ExperimentSpec(
  id: id,
  title: title,
  stage: 'Thử thách',
  mechanism: 'probabilityBag',
  prompt: '$goal Dựng túi gồm đúng $total viên bằng cách thêm hoặc lấy bi ra.',
  hint: 'Hai màu chia sẻ cùng một tổng. Chuyển điều kiện đề bài thành số viên của từng màu rồi kiểm tra lại cả túi.',
  explanation:
      'Có $blue viên xanh và ${total - blue} viên đỏ, nên P(xanh) = $blue/$total. Cơ hội thay đổi khi tỉ lệ các màu thay đổi.',
  config: {'capacity': total},
  initial: {'balls': <String>[]},
  validator: (d) {
    final b = d['balls'] as List;
    return b.length == total &&
        b.every((v) => v == 'B' || v == 'R') &&
        b.where((v) => v == 'B').length == blue;
  },
);

final extensionExperiments = <String, List<ExperimentSpec>>{
  'logic': [
    _remove('logic-invariant', 'Giữ nguyên sự cân bằng', 5, 9),
    ExperimentSpec(
      id: 'logic-hidden',
      title: 'Hiệu chuẩn hộp bí mật',
      stage: 'Thử thách',
      mechanism: 'balanceBlocks',
      prompt: 'Hộp mới có khối lượng khác trước. Thêm hoặc lấy khối đơn vị để tìm lúc cân nằm ngang.',
      hint: 'Dùng chiều nghiêng làm phản hồi; khi thêm quá nhiều, hãy lấy bớt.',
      explanation: 'Cân bằng cho thấy hai bên có cùng khối lượng: hộp này bằng 6 khối đơn vị.',
      config: {'target': 6},
      initial: {'blocks': 1},
      validator: (d) => d['blocks'] == 6,
    ),
  ],
  'math': [
    _paint(
      'math-equivalent',
      'Một phân số, hai cách viết',
      'Biểu diễn 3/4 chiếc bánh.',
      6,
    ),
    _paint(
      'math-complement',
      'Tìm phần còn lại',
      'Tô sao cho phần CHƯA tô chiếm 3/8 chiếc bánh.',
      5,
    ),
  ],
  'science': [
    _motion(
      'science-distance',
      'Cùng đích, khác hành trình',
      'Đi đúng 8 m và kết thúc bằng 2 giây nghỉ.',
      (d) => _ints(d['segments'], [2, 2, 0]),
    ),
    _motion(
      'science-return',
      'Chậm trước, nhanh sau',
      'Đi đúng 6 m, bắt đầu đi chậm và kết thúc đi nhanh.',
      (d) => _ints(d['segments'], [1, 0, 2]),
    ),
  ],
  'data': [
    _city(
      'data-outlier',
      'San đều sau một ngoại lệ',
      [1, 2, 9],
      'Làm ba tòa cao bằng nhau.',
      [4, 4, 4],
    ),
    _city(
      'data-distribution',
      'Cùng trung bình, khác phân bố',
      [4, 4, 4],
      'Giữ trung bình 4 tầng; tòa giữa cao 4 tầng, tòa phải gấp ba tòa trái.',
      [2, 4, 6],
    ),
  ],
  'geometry': [
    _rectangle('geometry-fence', 'Một mảnh vườn, hai điều kiện', 8, 12),
    _rectangle('geometry-square', 'Khi hình vuông xuất hiện', 9, 12),
  ],
  'coding': [
    _route('coding-shortest', 'Tiết kiệm từng lệnh'),
    _route('coding-checkpoint', 'Ghé trạm trước khi về', via: [0, 2]),
  ],
  'circuits': [
    _light('circuits-cyan', 'Trộn ra màu trời', 'lục lam', 0xFF00FFFF, [
      0,
      1,
      1,
    ]),
    _light('circuits-white', 'Từ ba màu thành trắng', 'trắng', 0xFFFFFFFF, [
      1,
      1,
      1,
    ]),
  ],
  'probability': [
    _bag(
      'probability-fair',
      'Thiết kế một túi công bằng',
      8,
      4,
      'Hai màu phải có cơ hội xuất hiện bằng nhau.',
    ),
    _bag(
      'probability-odds',
      'Cơ hội gấp ba',
      8,
      6,
      'Cơ hội rút xanh phải gấp ba cơ hội rút đỏ.',
    ),
  ],
  'algebra': [
    _remove('algebra-isolate', 'Ẩn số sau những khối', 2, 8),
    _remove('algebra-transfer', 'Thay số, giữ quy tắc', 4, 10),
    _city(
      'algebra-model',
      'Giải bằng một thành phố',
      [6, 3, 3],
      'Tòa giữa gấp đôi tòa trái; tòa phải gấp ba tòa trái. Tìm cả ba chiều cao.',
      [2, 4, 6],
    ),
  ],
  'optimization': [
    _route('optimization-debug', 'Gỡ lỗi đường đi', start: ['R', 'D']),
    ExperimentSpec(
      id: 'optimization-network',
      title: 'Sửa máy, không sửa đầu vào',
      stage: 'Thử thách',
      mechanism: 'sortingNetwork',
      prompt: 'Máy đã có ba bộ so sánh nhưng chưa sắp đúng mọi đầu vào. Chỉnh hoặc lắp thêm, tối đa 6 bộ; chạy kiểm tra cả 24 hoán vị.',
      hint: 'Một đầu vào chạy đúng chưa chứng minh máy đúng. Tìm cặp dây còn có thể đảo thứ tự sau mỗi lượt.',
      explanation: 'Máy được kiểm tra trên cả 24 hoán vị, không chỉ ví dụ đang hiển thị. Chuỗi bộ so sánh dùng lại được với mọi đầu vào.',
      initial: {
        'stages': [0, 1, 2],
        'result': <int>[],
      },
      validator: discoveryExperiments['coding']!.last.validator,
    ),
    _motion(
      'optimization-budget',
      'Ngân sách chuyển động',
      'Đi đúng 4 m với chỉ một ô đi nhanh; hai ô còn lại phải nghỉ.',
      (d) {
        final v = d['segments'] as List;
        return v.where((x) => x == 2).length == 1 &&
            v.where((x) => x == 0).length == 2;
      },
    ),
  ],
};
