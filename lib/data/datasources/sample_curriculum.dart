import '../models/lesson.dart';
import '../models/question.dart';

class SampleCurriculum {
  /// Sinh danh sách 30 bài học cho mỗi khối lớp từ 1 đến 5:
  /// - Lý thuyết dẫn dắt dài, chuẩn SGK với định nghĩa, bảng thuật ngữ, đơn vị đo, mẹo tính nhanh.
  /// - 10 câu hỏi trắc nghiệm/bài kết hợp cả toán hàn lâm (biểu thức, công thức) lẫn toán thực tế đời sống.
  /// - Tự luận có hướng dẫn chi tiết.
  /// - Mini game gắn liền 100% với đề tài bài học.
  static List<Lesson> getLessonsForGrade(int grade) {
    final gradeLessonsMetadata = _getGradeMetadata(grade);

    return List.generate(30, (index) {
      final lessonNum = index + 1;
      final meta = gradeLessonsMetadata[index % gradeLessonsMetadata.length];

      LessonStatus status;
      int stars = 0;
      if (lessonNum < 14) {
        status = LessonStatus.completed;
        stars = 3;
      } else if (lessonNum == 14) {
        status = LessonStatus.inProgress;
        stars = 0;
      } else {
        status = LessonStatus.locked;
        stars = 0;
      }

      final title = 'Bài $lessonNum: ${meta['title']}';
      final subtitle = meta['subtitle'] ?? 'Lộ trình chuẩn kiến thức 3–5 phút';
      final theory = meta['theory'] ?? _generateExtendedTheory(grade, lessonNum, meta['title']);
      final essayPrompt = meta['essayPrompt'] ??
          'Một bác nông dân thu hoạch được 120 kg thóc. Bác đem biếu người thân 1/4 số thóc đó, phần còn lại đem bán. Hỏi bác nông dân đã bán được bao nhiêu ki-lô-gam thóc?';
      final essayGuidance = meta['essayGuidance'] ??
          'Bước 1: Tìm số thóc đem biếu (Lấy 120 chia cho 4). Bước 2: Tìm số thóc còn lại đem bán (Lấy 120 trừ đi số thóc đã biếu).';
      final miniGameType = meta['miniGameType'] ?? 'number';

      return Lesson(
        id: 'grade-$grade-lesson-$lessonNum',
        grade: grade,
        lessonNumber: lessonNum,
        title: title,
        subtitle: subtitle,
        estimatedMinutes: meta['minutes'] ?? 5,
        xpReward: 30 + (lessonNum * 2),
        starReward: 3,
        status: status,
        starsEarned: stars,
        theory: theory,
        essayPrompt: essayPrompt,
        essayGuidance: essayGuidance,
        miniGameType: miniGameType,
        questions: _generateTenQuestionsForLesson(grade, lessonNum, meta),
      );
    });
  }

  /// Sinh lý thuyết dài và sâu: gồm Khái niệm SGK, Đơn vị đo, Bảng thuật ngữ và Mẹo tính nhanh
  static String _generateExtendedTheory(int grade, int lessonNum, String title) {
    return '📚 BÁC CÚ DẪN DẮT LÝ THUYẾT SGK CHI TIẾT:\n\n'
        '1. ĐẶT VẤN ĐỀ & BẢN CHẤT KHÁI NIỆM:\n'
        'Trong đời sống hàng ngày, chúng ta luôn cần giải quyết các bài toán liên quan đến "$title".\n'
        '• Để phân chia đồ vật chính xác, người ta dùng Phân số.\n'
        '• Để đo lường các đại lượng nhỏ hơn đơn vị chuẩn, người ta dùng Số thập phân.\n'
        '• Để tính toán thời gian đi lại của các phương tiện, ta sử dụng Công thức chuyển động đều.\n\n'
        '2. CÁC THUẬT NGỮ TOÁN HỌC CỐT LÕI:\n'
        '• Tử số / Mẫu số: Tử số thể hiện phần được nhận, mẫu số là tổng phần bằng nhau.\n'
        '• Phân số tối giản: Phân số không thể rút gọn được nữa (ƯCLN của tử và mẫu bằng 1).\n'
        '• Mẫu số chung nhỏ nhất (MSCNN): Số nhỏ nhất chia hết cho tất cả các mẫu số.\n'
        '• Đại lượng tỉ lệ thuận: Khi một đại lượng tăng gấp bao nhiêu lần thì đại lượng kia cũng tăng bấy nhiêu lần.\n\n'
        '3. BẢNG QUY ĐỔI ĐƠN VỊ ĐO CẦN NHỚ:\n'
        '• Đơn vị độ dài: 1 km = 1.000 m = 10.000 dm = 100.000 cm\n'
        '• Đơn vị khối lượng: 1 tấn = 10 tạ = 1.000 kg; 1 kg = 1.000 g\n'
        '• Đơn vị thời gian: 1 giờ = 60 phút = 3.600 giây; 1 ngày = 24 giờ\n'
        '• Đơn vị diện tích: 1 m² = 100 dm² = 10.000 cm²\n\n'
        '4. BÍ KÍP & MẸO TÍNH NHANH CỦA CÚ:\n'
        '★ Mẹo 1: Khi nhân một số với 10, 100, 1000 chỉ việc dịch chuyển dấu phẩy sang phải 1, 2, 3 chữ số.\n'
        '★ Mẹo 2: Khi chia cho 10, 100, 1000 dịch chuyển dấu phẩy sang trái tương ứng.\n'
        '★ Mẹo 3: Nhân một số với 0.5 chính là chia số đó cho 2! Nhân với 0.25 chính là chia cho 4!\n'
        '★ Mẹo 4: Trong bài toán chuyển động ngược chiều, hãy tính "Tổng vận tốc" (v1 + v2).\n'
        '★ Mẹo 5: Trong bài toán chuyển động cùng chiều đuổi nhau, hãy tính "Hiệu vận tốc" (v1 - v2).\n\n'
        'Hãy chuẩn bị giấy nháp và sẵn sàng chinh phục bộ 10 câu trắc nghiệm thú vị phía dưới nhé!';
  }

  /// Sinh đúng 10 CÂU HỎI TRẮC NGHIỆM xen kẽ giữa Toán Hàn Lâm (Công thức, Biểu thức) & Toán Thực Tế (Bánh pizza, xe lửa, quả táo, đời sống)
  static List<Question> _generateTenQuestionsForLesson(int grade, int lessonNum, Map<String, dynamic> meta) {
    final title = meta['title'] as String;

    if (title.contains('Phân số') || title.contains('phân số')) {
      return [
        Question(
          id: 'q-$grade-$lessonNum-1',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 1 [Toán thực tế 🍕]: Một chiếc bánh pizza được cắt thành 8 miếng bằng nhau. Nam ăn hết 3 miếng. Phân số chỉ số phần bánh Nam đã ăn là:',
          subtitle: 'Quan sát hình ảnh chiếc bánh cắt 8 phần',
          data: {'formula': 'Nam ăn 3 trong số 8 miếng pizza', 'options': ['3/8', '5/8', '3/5', '8/3'], 'correctAnswer': '3/8'},
          correctAnswer: '3/8',
        ),
        Question(
          id: 'q-$grade-$lessonNum-2',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 2 [Toán hàn lâm]: Trong phân số 7/12, tử số là bao nhiêu và mẫu số là bao nhiêu?',
          subtitle: 'Nhận diện định nghĩa tử số và mẫu số',
          data: {'formula': 'Phân số 7/12', 'options': ['Tử số 7, mẫu số 12', 'Tử số 12, mẫu số 7', 'Tử số 7, mẫu số 5', 'Tử số 5, mẫu số 12'], 'correctAnswer': 'Tử số 7, mẫu số 12'},
          correctAnswer: 'Tử số 7, mẫu số 12',
        ),
        Question(
          id: 'q-$grade-$lessonNum-3',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 3 [Toán hàn lâm]: Rút gọn phân số 15/25 về dạng tối giản nhất:',
          subtitle: 'Chia cả tử và mẫu cho ước số chung',
          data: {'formula': '15/25 = ?', 'options': ['3/5', '5/3', '1/5', '3/25'], 'correctAnswer': '3/5'},
          correctAnswer: '3/5',
        ),
        Question(
          id: 'q-$grade-$lessonNum-4',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 4 [Toán thực tế 🍎]: Trong giỏ có 20 quả táo, có 1/4 số táo là táo xanh, còn lại là táo đỏ. Hỏi trong giỏ có bao nhiêu quả táo xanh?',
          subtitle: 'Tìm phân số của một số',
          data: {'formula': '20 × 1/4 = ?', 'options': ['5 quả', '4 quả', '15 quả', '6 quả'], 'correctAnswer': '5 quả'},
          correctAnswer: '5 quả',
        ),
        Question(
          id: 'q-$grade-$lessonNum-5',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 5 [Toán hàn lâm]: Thực hiện phép tính cộng cùng mẫu: 2/7 + 3/7 = ?',
          subtitle: 'Cộng tử số giữ nguyên mẫu',
          data: {'formula': '2/7 + 3/7 = ?', 'options': ['5/7', '5/14', '6/7', '1/7'], 'correctAnswer': '5/7'},
          correctAnswer: '5/7',
        ),
        Question(
          id: 'q-$grade-$lessonNum-6',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 6 [Toán hàn lâm]: Quy đồng mẫu số và tính: 1/2 + 1/4 = ?',
          subtitle: 'Đưa về cùng mẫu số chung là 4',
          data: {'formula': '1/2 + 1/4 = 2/4 + 1/4 = ?', 'options': ['3/4', '2/6', '1/3', '5/8'], 'correctAnswer': '3/4'},
          correctAnswer: '3/4',
        ),
        Question(
          id: 'q-$grade-$lessonNum-7',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 7 [Toán thực tế 💧]: Một bình nước chứa 3/4 lít nước, người ta rót ra 1/2 lít nước. Hỏi trong bình còn lại bao nhiêu lít nước?',
          subtitle: 'Thực hiện phép trừ phân số khác mẫu',
          data: {'formula': '3/4 - 1/2 = 3/4 - 2/4 = ?', 'options': ['1/4 lít', '2/2 lít', '1/2 lít', '2/4 lít'], 'correctAnswer': '1/4 lít'},
          correctAnswer: '1/4 lít',
        ),
        Question(
          id: 'q-$grade-$lessonNum-8',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 8 [Toán hàn lâm]: Phép tính nhân hai phân số: 2/3 × 3/5 = ?',
          subtitle: 'Lấy tử nhân tử, mẫu nhân mẫu rồi rút gọn',
          data: {'formula': '(2 × 3) / (3 × 5) = ?', 'options': ['2/5', '6/15', '5/8', '1/3'], 'correctAnswer': '2/5'},
          correctAnswer: '2/5',
        ),
        Question(
          id: 'q-$grade-$lessonNum-9',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 9 [Toán hàn lâm]: Muốn chia hai phân số ta làm thế nào?',
          subtitle: 'Ghi nhớ quy tắc SGK',
          data: {'formula': 'Quy tắc chia phân số', 'options': ['Nhân với phân số nghịch đảo', 'Cộng chéo tử và mẫu', 'Lấy mẫu chia tử', 'Trừ tử cho mẫu'], 'correctAnswer': 'Nhân với phân số nghịch đảo'},
          correctAnswer: 'Nhân với phân số nghịch đảo',
        ),
        Question(
          id: 'q-$grade-$lessonNum-10',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 10 [Toán thực tế 🏃]: An chạy 2/5 vòng sân trường, Bình chạy được 3/10 vòng sân trường. Ai là người chạy được quãng đường nhiều hơn?',
          subtitle: 'Quy đồng để so sánh 2 phân số 4/10 và 3/10',
          data: {'formula': 'So sánh 4/10 và 3/10', 'options': ['Bạn An chạy nhiều hơn', 'Bạn Bình chạy nhiều hơn', 'Hai bạn bằng nhau', 'Không so sánh được'], 'correctAnswer': 'Bạn An chạy nhiều hơn'},
          correctAnswer: 'Bạn An chạy nhiều hơn',
        ),
      ];
    } else if (title.contains('Vận tốc') || title.contains('chuyển động') || title.contains('Quãng đường')) {
      return [
        Question(
          id: 'q-$grade-$lessonNum-1',
          type: QuestionType.wordProblem,
          prompt: 'Câu 1 [Toán thực tế 🚗]: Một ô tô đi từ Hà Nội về Hải Phòng quãng đường 120 km trong thời gian 2 giờ. Vận tốc ô tô là:',
          subtitle: 'Áp dụng công thức v = s : t',
          data: {'given': 's = 120 km, t = 2 giờ', 'action': '120 : 2', 'target': 'Vận tốc ô tô', 'options': ['60 km/h', '50 km/h', '240 km/h', '70 km/h'], 'correctAnswer': '60 km/h'},
          correctAnswer: '60 km/h',
        ),
        Question(
          id: 'q-$grade-$lessonNum-2',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 2 [Toán hàn lâm]: Công thức tính quãng đường khi biết vận tốc (v) và thời gian (t) là:',
          subtitle: 'Nhớ chính xác công thức toán SGK',
          data: {'formula': 'Công thức tính quãng đường s', 'options': ['s = v × t', 's = v : t', 's = t : v', 's = v + t'], 'correctAnswer': 's = v × t'},
          correctAnswer: 's = v × t',
        ),
        Question(
          id: 'q-$grade-$lessonNum-3',
          type: QuestionType.wordProblem,
          prompt: 'Câu 3 [Toán thực tế 🏍️]: Bác Nam đi xe máy với vận tốc 40 km/h trong 2 giờ 30 phút (2,5 giờ). Quãng đường bác Nam đi được là:',
          subtitle: 'Đổi thời gian ra số thập phân rồi tính',
          data: {'given': 'v = 40 km/h, t = 2.5 giờ', 'action': '40 × 2.5', 'target': 'Quãng đường', 'options': ['100 km', '80 km', '90 km', '120 km'], 'correctAnswer': '100 km'},
          correctAnswer: '100 km',
        ),
        Question(
          id: 'q-$grade-$lessonNum-4',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 4 [Toán hàn lâm]: Muốn tính thời gian (t) chuyển động ta làm phép tính gì?',
          subtitle: 'Công thức t = s : v',
          data: {'formula': 't = ?', 'options': ['t = s : v', 't = s × v', 't = v : s', 't = s - v'], 'correctAnswer': 't = s : v'},
          correctAnswer: 't = s : v',
        ),
        Question(
          id: 'q-$grade-$lessonNum-5',
          type: QuestionType.wordProblem,
          prompt: 'Câu 5 [Toán thực tế 🏃]: Một vận động viên chạy cự ly 100 mét hết 10 giây. Vận tốc chạy của vận động viên là:',
          subtitle: 'Đơn vị đo mét trên giây (m/s)',
          data: {'given': 's = 100 m, t = 10 s', 'action': '100 : 10', 'target': 'Vận tốc m/s', 'options': ['10 m/s', '100 m/s', '10 km/h', '1 m/s'], 'correctAnswer': '10 m/s'},
          correctAnswer: '10 m/s',
        ),
        Question(
          id: 'q-$grade-$lessonNum-6',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 6 [Toán thực tế ✈️]: Máy bay bay với vận tốc 800 km/h từ Hà Nội vào TP.HCM (khoảng cách 1.600 km). Thời gian bay là:',
          subtitle: 'Tính thời gian t = s : v',
          data: {'formula': '1.600 : 800 = ?', 'options': ['2 giờ', '3 giờ', '1.5 giờ', '4 giờ'], 'correctAnswer': '2 giờ'},
          correctAnswer: '2 giờ',
        ),
        Question(
          id: 'q-$grade-$lessonNum-7',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 7 [Toán hàn lâm]: Hai xe chuyển động NGƯỢC CHIỀU gặp nhau. Công thức tính vận tốc gặp nhau là:',
          subtitle: 'Tổng vận tốc hai xe',
          data: {'formula': 'Chuyển động ngược chiều', 'options': ['Vận tốc = v1 + v2', 'Vận tốc = v1 - v2', 'Vận tốc = v1 × v2', 'Vận tốc = v1 : v2'], 'correctAnswer': 'Vận tốc = v1 + v2'},
          correctAnswer: 'Vận tốc = v1 + v2',
        ),
        Question(
          id: 'q-$grade-$lessonNum-8',
          type: QuestionType.wordProblem,
          prompt: 'Câu 8 [Toán thực tế 🚲]: Một người đi xe đạp với vận tốc 15 km/h. Sau 4 giờ người đó đi được bao nhiêu ki-lô-mét?',
          subtitle: 'Áp dụng s = v × t',
          data: {'given': 'v = 15 km/h, t = 4 giờ', 'action': '15 × 4', 'target': 'Quãng đường', 'options': ['60 km', '45 km', '50 km', '75 km'], 'correctAnswer': '60 km'},
          correctAnswer: '60 km',
        ),
        Question(
          id: 'q-$grade-$lessonNum-9',
          type: QuestionType.multiplicationTable,
          prompt: 'Câu 9 [Toán hàn lâm]: Đổi đơn vị đo: 1 giờ 15 phút bằng bao nhiêu giờ?',
          subtitle: '15 phút = 15/60 giờ = 0.25 giờ',
          data: {'formula': '1 giờ 15 phút = ? giờ', 'options': ['1.25 giờ', '1.15 giờ', '1.5 giờ', '1.3 giờ'], 'correctAnswer': '1.25 giờ'},
          correctAnswer: '1.25 giờ',
        ),
        Question(
          id: 'q-$grade-$lessonNum-10',
          type: QuestionType.wordProblem,
          prompt: 'Câu 10 [Toán thực tế 🚂]: Đoàn tàu hỏa dài 200m chạy qua một cây cầu dài 800m với vận tốc 20 m/s. Thời gian tàu chạy qua cầu là:',
          subtitle: 'Tổng quãng đường = Chiều dài tàu + Chiều dài cầu',
          data: {'given': 's = 200 + 800 = 1000m, v = 20 m/s', 'action': '1000 : 20', 'target': 'Thời gian giây', 'options': ['50 giây', '40 giây', '10 giây', '60 giây'], 'correctAnswer': '50 giây'},
          correctAnswer: '50 giây',
        ),
      ];
    } else {
      // 10 câu hỏi hình học / số học chuẩn
      return List.generate(10, (i) {
        final qNum = i + 1;
        final factor = (qNum * 2) + 4;
        final isRealistic = i % 2 == 0;

        return Question(
          id: 'q-$grade-$lessonNum-$qNum',
          type: QuestionType.multiplicationTable,
          prompt: isRealistic
              ? 'Câu $qNum [Toán thực tế 📦]: Một thùng hàng hình chữ nhật có kích thước $qNum cm × 5 cm. Diện tích đáy thùng là:'
              : 'Câu $qNum [Toán hàn lâm]: Tìm kết quả của biểu thức tính nhanh: $factor × 10 = ?',
          subtitle: isRealistic ? 'Áp dụng công thức tính diện tích' : 'Quy tắc nhân nhẩm với 10',
          data: {
            'formula': isRealistic ? '$qNum × 5 = ?' : '$factor × 10 = ?',
            'options': isRealistic
                ? ['${qNum * 5} cm²', '${qNum * 5 - 2} cm²', '${qNum * 5 + 3} cm²', '${qNum * 5 + 5} cm²']
                : ['${factor * 10}', '${factor * 10 + 2}', '${factor * 10 - 5}', '${factor * 100}'],
            'correctAnswer': isRealistic ? '${qNum * 5} cm²' : '${factor * 10}',
          },
          correctAnswer: isRealistic ? '${qNum * 5} cm²' : '${factor * 10}',
        );
      });
    }
  }

  static List<Map<String, dynamic>> _getGradeMetadata(int grade) {
    return [
      {
        'title': 'Khái niệm Phân số',
        'subtitle': 'Tử số, mẫu số và phần bánh pizza',
        'type': QuestionType.multiplicationTable,
        'miniGameType': 'fraction',
      },
      {
        'title': 'Tính chất cơ bản của Phân số',
        'subtitle': 'Nhân và chia cùng một số tự nhiên',
        'type': QuestionType.multiplicationTable,
        'miniGameType': 'fraction',
      },
      {
        'title': 'Cộng phân số khác mẫu số',
        'subtitle': 'Quy đồng mẫu số và tính toán',
        'type': QuestionType.multiplicationTable,
        'miniGameType': 'fraction',
      },
      {
        'title': 'Vận tốc trong Chuyển động đều',
        'subtitle': 'Công thức v = s / t',
        'type': QuestionType.wordProblem,
        'miniGameType': 'speed',
      },
      {
        'title': 'Quãng đường trong Chuyển động đều',
        'subtitle': 'Công thức s = v × t',
        'type': QuestionType.wordProblem,
        'miniGameType': 'speed',
      },
    ];
  }
}
