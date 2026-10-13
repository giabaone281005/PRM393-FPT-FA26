import '../models/lesson.dart';
import '../models/question.dart';

class SampleCurriculum {
  static List<Lesson> getLessonsForGrade(int grade) {
    return [
      Lesson(
        id: 'lesson-1',
        grade: grade,
        lessonNumber: 1,
        title: 'Bài 1: Làm Quen & Đếm Trực Quan',
        subtitle: 'Kéo thả que tính và hoa quả vui nhộn',
        estimatedMinutes: 3,
        xpReward: 30,
        starReward: 3,
        status: LessonStatus.completed,
        starsEarned: 3,
        questions: [
          Question(
            id: 'q1-1',
            type: QuestionType.dragCounters,
            prompt: 'Kéo đúng 5 quả táo vào chiếc rổ phép thuật!',
            subtitle: 'Chạm và kéo từng quả táo vào rổ',
            data: {
              'itemIcon': '🍎',
              'targetCount': 5,
              'availableCount': 8,
            },
            correctAnswer: 5,
            socraticHints: [
              SocraticHint(
                step: 1,
                questionText: 'Trong rổ hiện đang có bao nhiêu quả táo?',
                hintText: 'Hãy đếm xem trong rổ đã có mấy quả rồi, chúng ta cần thêm cho đủ 5 quả nhé!',
              ),
              SocraticHint(
                step: 2,
                questionText: 'Nếu rổ có 3 quả, cần kéo thêm mấy quả nữa để được 5?',
                hintText: 'Thử lấy 5 trừ đi 3 xem nào bạn nhỏ ơi!',
              ),
            ],
          ),
        ],
      ),
      Lesson(
        id: 'lesson-2',
        grade: grade,
        lessonNumber: 2,
        title: 'Bài 2: Kim Đồng Hồ Tích Tắc',
        subtitle: 'Xoay kim giờ và kim phút chính xác',
        estimatedMinutes: 4,
        xpReward: 35,
        starReward: 3,
        status: LessonStatus.available,
        starsEarned: 0,
        questions: [
          Question(
            id: 'q2-1',
            type: QuestionType.clockRotation,
            prompt: 'Hãy xoay kim đồng hồ để chỉ đúng 3 giờ 30 phút!',
            subtitle: 'Chạm vào kim phút và xoay đến số 6',
            data: {
              'targetHour': 3,
              'targetMinute': 30,
            },
            correctAnswer: 30,
            socraticHints: [
              SocraticHint(
                step: 1,
                questionText: 'Mỗi khoảng giữa hai số trên mặt đồng hồ là bao nhiêu phút?',
                hintText: 'Cứ mỗi số cách nhau 5 phút. Hãy đếm từ số 12 nhé: 5, 10, 15...!',
              ),
              SocraticHint(
                step: 2,
                questionText: '30 phút thì kim dài phải chỉ vào số mấy?',
                hintText: 'Lấy 30 chia cho 5 sẽ ra số trên mặt đồng hồ!',
              ),
            ],
          ),
        ],
      ),
      Lesson(
        id: 'lesson-3',
        grade: grade,
        lessonNumber: 3,
        title: 'Bài 3: Mê Cung Bảng Cửu Chương',
        subtitle: 'Tính nhẩm thần tốc bảng nhân 7 và 8',
        estimatedMinutes: 4,
        xpReward: 40,
        starReward: 3,
        status: LessonStatus.locked,
        questions: [
          Question(
            id: 'q3-1',
            type: QuestionType.multiplicationTable,
            prompt: 'Điền số thích hợp: 7 × 8 = ?',
            subtitle: 'Chọn đáp án chính xác nhất',
            data: {
              'factorA': 7,
              'factorB': 8,
              'options': [48, 54, 56, 63],
            },
            correctAnswer: 56,
            socraticHints: [
              SocraticHint(
                step: 1,
                questionText: 'Em có nhớ 7 × 7 bằng bao nhiêu không?',
                hintText: '7 × 7 = 49. Vậy 7 × 8 sẽ bằng 49 cộng thêm mấy nữa nhỉ?',
              ),
              SocraticHint(
                step: 2,
                questionText: '49 + 7 bằng mấy?',
                hintText: 'Tính nhẩm: 49 + 1 = 50, 50 + 6 = ...',
              ),
            ],
          ),
        ],
      ),
      Lesson(
        id: 'lesson-4',
        grade: grade,
        lessonNumber: 4,
        title: 'Bài 4: Thám Tử Đo Lưới Ô Vuông',
        subtitle: 'Tính diện tích hình chữ nhật trên lưới',
        estimatedMinutes: 5,
        xpReward: 45,
        starReward: 3,
        status: LessonStatus.locked,
        questions: [
          Question(
            id: 'q4-1',
            type: QuestionType.areaGrid,
            prompt: 'Hình chữ nhật có chiều dài 5 ô, chiều rộng 3 ô. Diện tích là bao nhiêu ô vuông?',
            subtitle: 'Đếm hoặc tính số ô vuông được tô màu',
            data: {
              'rows': 3,
              'cols': 5,
            },
            correctAnswer: 15,
            socraticHints: [
              SocraticHint(
                step: 1,
                questionText: 'Mỗi hàng có bao nhiêu ô vuông?',
                hintText: 'Có 3 hàng, mỗi hàng có 5 ô vuông.',
              ),
              SocraticHint(
                step: 2,
                questionText: 'Công thức tính diện tích hình chữ nhật là gì?',
                hintText: 'Lấy chiều dài nhân với chiều rộng (5 × 3).',
              ),
            ],
          ),
        ],
      ),
      Lesson(
        id: 'lesson-5',
        grade: grade,
        lessonNumber: 5,
        title: 'Bài 5: Giải Đố Toán Lời Văn',
        subtitle: 'Phân tích từ khóa và tìm cách giải',
        estimatedMinutes: 5,
        xpReward: 50,
        starReward: 3,
        status: LessonStatus.locked,
        questions: [
          Question(
            id: 'q5-1',
            type: QuestionType.wordProblem,
            prompt: 'Một rổ có 24 quả cam. Mẹ đem chia đều cho 4 anh em. Hỏi mỗi người nhận được mấy quả cam?',
            subtitle: 'Đọc kỹ đề bài và tìm phép tính thích hợp',
            data: {
              'total': 24,
              'parts': 4,
              'options': ['24 + 4 = 28', '24 - 4 = 20', '24 × 4 = 96', '24 ÷ 4 = 6'],
            },
            correctAnswer: '24 ÷ 4 = 6',
            socraticHints: [
              SocraticHint(
                step: 1,
                questionText: 'Từ khóa "chia đều" báo hiệu phép tính nào?',
                hintText: 'Khi chia đều một số lượng cho nhiều phần bằng nhau, ta dùng phép chia.',
              ),
              SocraticHint(
                step: 2,
                questionText: '24 chia cho 4 bằng mấy?',
                hintText: 'Nhớ lại bảng nhân 4: 4 nhân mấy thì bằng 24?',
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
