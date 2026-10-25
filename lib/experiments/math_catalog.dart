import 'experiment_model.dart';
import 'fraction_evaluation.dart';

bool _balance(ExperimentData d) => d['blocks'] == 4;
bool _remove(ExperimentData d) => d['pairs'] == 3;
bool _gears(ExperimentData d) => d['turns'] == 2;
bool _paint(ExperimentData d) {
  final painted = d['painted'];
  return painted is List &&
      painted.length == 3 &&
      painted.toSet().length == 3 &&
      painted.every((v) => v is int && v >= 0 && v < 8);
}

bool _fold(ExperimentData d) => d['folds'] == 2;
bool _distribute(ExperimentData d) => _equal(d['baskets'], [3, 3, 3]);
bool _launch(ExperimentData d) =>
    ((d['angle'] as num? ?? 0) - 45).abs() <= 3 && d['launched'] == true;
bool _motion(ExperimentData d) => _equal(d['segments'], [2, 0, 1]);
bool _lever(ExperimentData d) => d['position'] == 3;
bool _sort(ExperimentData d) => _equal(d['order'], [1, 2, 3, 4]);
bool _bins(ExperimentData d) => _equal(d['bins'], [0, 0, 1, 1, 2, 2]);
bool _mean(ExperimentData d) => _equal(d['heights'], [4, 4, 4]);
bool _equal(dynamic a, List<int> b) =>
    a is List &&
    a.length == b.length &&
    List.generate(b.length, (i) => a[i] == b[i]).every((v) => v);

const mathExperiments = <String, List<ExperimentSpec>>{
  'logic': [
    ExperimentSpec(
      id: 'logic-balance',
      title: 'Chiếc cân bí mật',
      prompt: 'Một hộp nặng bằng 4 khối. Thả khối vào đĩa trống để cân bằng.',
      hint: 'Mỗi khối nặng 1 đơn vị. Quan sát độ nghiêng của cân.',
      explanation: 'Hai bên cùng nặng 4 đơn vị nên cân thăng bằng.',
      mechanism: 'balanceBlocks',
      initial: {'blocks': 0},
      validator: _balance,
    ),
    ExperimentSpec(
      id: 'logic-remove',
      title: 'Bóc từng lớp',
      prompt: 'x + 3 = 7. Vuốt bỏ từng cặp khối ở hai vế để tìm x.',
      hint: 'Mỗi lần bỏ cùng 1 khối ở cả hai bên, đẳng thức vẫn đúng.',
      explanation: 'Bỏ 3 ở cả hai vế: x = 4.',
      mechanism: 'removeBothSides',
      initial: {'pairs': 0},
      validator: _remove,
    ),
    ExperimentSpec(
      id: 'logic-gears',
      title: 'Truyền chuyển động',
      prompt: 'Bánh nhỏ có 12 răng, bánh lớn có 24 răng. Xoay bánh nhỏ để bánh lớn quay đúng một vòng.',
      hint: 'Bánh lớn cần số răng gấp đôi bánh nhỏ đi qua điểm tiếp xúc.',
      explanation: 'Bánh 12 răng quay 2 vòng thì bánh 24 răng quay 1 vòng, theo chiều ngược lại.',
      mechanism: 'gearRatios',
      initial: {'turns': 0},
      validator: _gears,
    ),
  ],
  'math': [
    ExperimentSpec(
      id: 'math-paint',
      skillIds: ['fractions.part-whole'],
      evaluator: evaluateFractionPaint,
      title: 'Miếng bánh của bạn',
      prompt: 'Tô đúng 3/8 chiếc bánh. Chạm vào các lát để bật hoặc tắt màu.',
      hint: 'Mẫu số 8 cho biết chiếc bánh có 8 phần bằng nhau.',
      explanation: 'Ba phần trong tám phần bằng nhau biểu diễn 3/8.',
      mechanism: 'fractionPaint',
      initial: {'painted': []},
      validator: _paint,
    ),
    ExperimentSpec(
      id: 'math-fold',
      skillIds: ['fractions.equal-parts'],
      title: 'Gấp để chia',
      prompt: 'Gấp tờ giấy thành những phần bằng nhau, để mỗi phần bằng 1/4 tờ ban đầu.',
      hint: 'Mỗi lần gấp đôi làm số phần tăng gấp đôi.',
      explanation: 'Hai lần gấp đôi tạo 4 phần bằng nhau: mỗi phần bằng 1/4.',
      mechanism: 'fractionFold',
      initial: {'folds': 0},
      validator: _fold,
    ),
    ExperimentSpec(
      id: 'math-share',
      skillIds: ['fractions.equal-parts'],
      title: 'Chuyến picnic',
      prompt: 'Chia đều 9 quả cam vào 3 giỏ. Kéo từng quả đến giỏ bạn muốn.',
      hint: 'Mọi giỏ phải có cùng số quả và không còn quả bên ngoài.',
      explanation: '9 chia 3 bằng 3: mỗi giỏ có 3 quả cam.',
      mechanism: 'distributeObjects',
      initial: {
        'baskets': [0, 0, 0],
      },
      validator: _distribute,
    ),
  ],
  'science': [
    ExperimentSpec(
      id: 'science-launch',
      title: 'Cú phóng qua sông',
      prompt: 'Xoay nòng pháo rồi phóng bóng đến cờ cách 10 m. Vận tốc cố định 10 m/s; g = 10 m/s².',
      hint: 'Tầm xa R = 10 × sin(2 × góc). Góc nào làm sin đạt 1?',
      explanation: 'Ở 45°, tầm xa đạt tối đa 10 m trên mặt đất ngang, khi bỏ qua sức cản.',
      mechanism: 'launchAngle',
      initial: {'angle': 20, 'launched': false},
      validator: _launch,
    ),
    ExperimentSpec(
      id: 'science-motion',
      title: 'Đạo diễn hành trình',
      prompt: 'Lập hành trình: đi nhanh 2 giây, nghỉ 2 giây, rồi đi chậm 2 giây. Kéo các thẻ vào đường thời gian.',
      hint: 'Đi nhanh: 2 m/s; nghỉ: 0 m/s; đi chậm: 1 m/s.',
      explanation: 'Quãng đường là 2×2 + 0×2 + 1×2 = 6 m.',
      mechanism: 'motionTimeline',
      initial: {
        'segments': [-1, -1, -1],
      },
      validator: _motion,
    ),
    ExperimentSpec(
      id: 'science-lever',
      title: 'Cân bằng mômen',
      prompt: 'Bên trái: 3 kg cách trục 2 m. Đặt quả nặng 2 kg ở bên phải để cân bằng.',
      hint: 'So sánh khối lượng × khoảng cách ở hai bên.',
      explanation: '3 × 2 = 2 × 3. Quả 2 kg phải cách trục 3 m.',
      mechanism: 'leverTorque',
      initial: {'position': 0},
      validator: _lever,
    ),
  ],
  'data': [
    ExperimentSpec(
      id: 'data-sort',
      title: 'Đường chân trời',
      prompt: 'Kéo các cột để sắp từ thấp đến cao, từ trái qua phải.',
      hint: 'Mỗi lần thả sẽ đổi chỗ hai cột.',
      explanation: 'Thứ tự tăng dần là 1, 2, 3, 4. Việc sắp xếp giúp nhìn ra phân bố dữ liệu.',
      mechanism: 'sortBars',
      initial: {
        'order': [3, 1, 4, 2],
      },
      validator: _sort,
    ),
    ExperimentSpec(
      id: 'data-bins',
      title: 'Bưu điện dữ liệu',
      prompt: 'Đưa các số 1, 2, 4, 5, 7, 8 vào đúng khoảng của biểu đồ.',
      hint: 'Khoảng đầu chứa 0–2, khoảng giữa chứa 3–5, khoảng cuối chứa 6–8.',
      explanation:
          'Mỗi khoảng có 2 điểm. Tổng tần số là 6, bằng số dữ liệu ban đầu.',
      mechanism: 'histogramBins',
      initial: {
        'bins': [-1, -1, -1, -1, -1, -1],
      },
      validator: _bins,
    ),
    ExperimentSpec(
      id: 'data-mean',
      title: 'San bằng thành phố',
      prompt: 'Chuyển từng tầng giữa các tòa nhà để cả ba cao bằng nhau. Không thêm hoặc bớt tầng.',
      hint: 'Tổng là 12 tầng. Chia đều cho 3 tòa nhà.',
      explanation: 'Trung bình của 2, 4, 6 là (2 + 4 + 6)/3 = 4. Mọi tòa nhà cùng cao 4 tầng.',
      mechanism: 'redistributeMean',
      initial: {
        'heights': [2, 4, 6],
      },
      validator: _mean,
    ),
  ],
};
