enum InteractionKind { balance, fraction, sharing, motion, median, bars }

class Challenge {
  const Challenge(
    this.title,
    this.prompt,
    this.kind,
    this.target, {
    this.initial = 0,
    this.max = 10,
    this.total = 0,
    this.seconds = 2,
    this.speedControl = false,
    this.offset = 0,
    required this.hint,
    required this.explanation,
  });
  final String title, prompt, hint, explanation;
  final InteractionKind kind;
  final int target, initial, max, total, seconds, offset;
  final bool speedControl;

  int normalize(int value) => value.clamp(0, max);
  int quantity(int value) => kind == InteractionKind.fraction
      ? List.generate(4, (i) => (value >> i) & 1).reduce((a, b) => a + b)
      : value;
  bool accepts(int value) => quantity(value) == target;
}

const challenges = <String, List<Challenge>>{
  'logic': [
    Challenge(
      'Điều gì giữ cân thăng bằng?',
      'Bên trái có 5 khối. Kéo từng khối từ kho lên đĩa bên phải để cân thăng bằng.',
      InteractionKind.balance,
      5,
      initial: 3,
      max: 10,
      hint: 'Bên phải đang có 3 khối. Hãy thêm cho bằng 5 khối bên trái.',
      explanation:
          '5 khối ở mỗi bên tạo ra cùng khối lượng, nên cân thăng bằng.',
    ),
    Challenge(
      'Đến lượt bạn giữ cân bằng',
      'Bên trái có 3 khối. Thêm hoặc chuyển khối về kho để hai bên bằng nhau.',
      InteractionKind.balance,
      3,
      initial: 5,
      max: 10,
      hint: 'Kéo khối ở đĩa phải về kho để bớt đi.',
      explanation: 'Bớt 2 từ 5 khối bên phải, mỗi bên còn 3 khối.',
    ),
    Challenge(
      'Từ chiếc cân đến phương trình',
      'Đĩa trái là x + 3, đĩa phải là 10. Thêm khối vào vùng x để tìm giá trị làm cân thăng bằng.',
      InteractionKind.balance,
      7,
      max: 10,
      offset: 3,
      hint: 'Ba khối cố định cộng với bao nhiêu khối nữa thì được 10?',
      explanation: 'x = 7 vì 7 + 3 = 10. Cả hai đĩa có cùng khối lượng.',
    ),
  ],
  'math': [
    Challenge(
      'Một phần của cả chiếc bánh',
      'Chạm để tô hoặc bỏ tô từng miếng. Hãy biểu diễn một nửa chiếc bánh.',
      InteractionKind.fraction,
      2,
      max: 15,
      hint: 'Có 4 phần bằng nhau. Một nửa gồm 2 phần bất kỳ.',
      explanation: 'Bạn đã tô 2 trong 4 phần: 2/4 = 1/2.',
    ),
    Challenge(
      'Tự tạo ba phần tư',
      'Tô các miếng bánh để biểu diễn 3/4. Mỗi miếng đều có cùng diện tích.',
      InteractionKind.fraction,
      3,
      max: 15,
      hint: 'Tô 3 miếng và để lại 1 miếng chưa tô.',
      explanation: '3 phần được tô trên tổng 4 phần bằng nhau là 3/4.',
    ),
    Challenge(
      'Chia bánh công bằng',
      'Có 12 chiếc bánh. Kéo bánh từ người này sang người kia để chia đều cho hai người.',
      InteractionKind.sharing,
      6,
      initial: 2,
      max: 12,
      total: 12,
      hint: 'Chuyển từng chiếc từ người có nhiều hơn sang người có ít hơn.',
      explanation: 'Mỗi người nhận 6 chiếc: 12 ÷ 2 = 6.',
    ),
  ],
  'science': [
    Challenge(
      'Đi nhanh hơn, đi xa hơn',
      'Xe chạy 4 m/s trong 2 giây. Kéo cờ dự đoán đến vị trí xe sẽ tới, rồi chạy thử.',
      InteractionKind.motion,
      8,
      max: 12,
      hint: 'Mỗi giây xe đi 4 mét. Sau 2 giây là 4 + 4 mét.',
      explanation: 'Xe tới mốc 8 mét: 4 m/s × 2 s = 8 m.',
    ),
    Challenge(
      'Thử làm một nhà khoa học',
      'Kéo núm tốc độ để xe tới cờ 8 mét sau 2 giây. Chạy thử để quan sát.',
      InteractionKind.motion,
      4,
      initial: 1,
      max: 6,
      speedControl: true,
      hint: 'Tốc độ cần tìm bằng 8 mét chia cho 2 giây.',
      explanation: 'Tốc độ 4 m/s đưa xe đi 8 mét trong 2 giây.',
    ),
    Challenge(
      'Dự đoán quãng đường',
      'Xe chạy 3 m/s trong 4 giây. Kéo cờ đến điểm kết thúc dự đoán trên đường.',
      InteractionKind.motion,
      12,
      max: 16,
      seconds: 4,
      hint: 'Cộng 3 mét cho mỗi giây trong 4 giây.',
      explanation: '3 m/s × 4 s = 12 mét. Cờ của bạn ở đúng điểm xe tới.',
    ),
  ],
  'data': [
    Challenge(
      'Tìm trung vị trên trục số',
      'Ba bạn đọc 2, 3 và 4 cuốn sách. Kéo mốc trên trục số đến trung vị của nhóm.',
      InteractionKind.median,
      3,
      max: 6,
      hint: 'Dãy đã sắp xếp là 2, 3, 4. Trung vị nằm giữa hai giá trị còn lại.',
      explanation: 'Giá trị giữa dãy 2, 3, 4 là 3 cuốn: đó là trung vị.',
    ),
    Challenge(
      'Cân bằng hai nhóm',
      'Kéo đỉnh cột B cho tới khi nhóm B có cùng số sách với nhóm A.',
      InteractionKind.bars,
      3,
      initial: 1,
      max: 8,
      hint: 'Nhóm A có 3 cuốn. Đưa đỉnh cột B ngang đỉnh cột A.',
      explanation: 'Cả hai nhóm có 3 cuốn nên hai cột cao bằng nhau.',
    ),
    Challenge(
      'San đều để hiểu trung bình',
      'Hai bạn có 4 và 8 cuốn sách. Chuyển sách giữa hai bạn để mỗi bạn có số sách bằng nhau.',
      InteractionKind.sharing,
      6,
      initial: 4,
      max: 12,
      total: 12,
      hint: 'Giữ nguyên tổng 12 cuốn và san đều thành 2 nhóm.',
      explanation: 'Sau khi san đều mỗi bạn có 6 cuốn: (4 + 8) ÷ 2 = 6.',
    ),
  ],
};
