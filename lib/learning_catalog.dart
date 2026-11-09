import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'experiments/experiment_model.dart';
import 'experiments/activity_catalog.dart';
export 'experiments/activity_catalog.dart' show experimentCatalog;

class LearningTopic {
  const LearningTopic(
    this.id,
    this.title,
    this.subtitle,
    this.subject,
    this.icon,
    this.color,
    this.action, {
    this.remoteExperiments,
  });
  final String id, title, subtitle, subject, action;
  final IconData icon;
  final Color color;
  final List<ExperimentSpec>? remoteExperiments;
  int get suggestedAge =>
      const {
        'math': 6,
        'english': 6,
        'vietnamese': 6,
        'biology': 8,
        'logic': 8,
        'science': 8,
        'geometry': 8,
        'painting': 8,
        'astronomy': 8,
        'data': 10,
        'coding': 10,
        'circuits': 10,
        'probability': 10,
        'geography': 10,
        'finance': 10,
        'digital': 10,
        'algebra': 12,
        'chemistry': 12,
        'optimization': 14,
        'marxism': 16,
      }[id] ??
      10;
  String get audience => 'Gợi ý từ $suggestedAge tuổi • Cơ bản → nâng cao';
  List<ExperimentSpec> get experiments =>
      remoteExperiments ?? experimentCatalog[id]!;
}

const topics = [
  LearningTopic(
    'logic',
    'Logic & quy luật',
    'Cân, phá khối và khám phá điều không đổi.',
    'Tư duy',
    Icons.hub_outlined,
    BrilliantPalette.successSurface,
    'Xoay để tìm quy luật',
  ),
  LearningTopic(
    'math',
    'Những phần bằng nhau',
    'Tô, gập, chia và tìm những phần tương đương.',
    'Toán học',
    Icons.pie_chart_outline,
    BrilliantPalette.successSurface,
    'Tự tay chia một nửa',
  ),
  LearningTopic(
    'science',
    'Phòng thí nghiệm chuyển động',
    'Phóng vật, lập hành trình và thử đòn bẩy.',
    'Khoa học',
    Icons.rocket_launch_outlined,
    BrilliantPalette.successSurface,
    'Chạm và thử một lực',
  ),
  LearningTopic(
    'data',
    'Dữ liệu biết kể chuyện',
    'Sắp xếp, phân nhóm và khám phá phân bố.',
    'Dữ liệu',
    Icons.stacked_bar_chart,
    BrilliantPalette.successSurface,
    'Biến số thành hình',
  ),
  LearningTopic(
    'geometry',
    'Xưởng hình học',
    'Nắn đỉnh, dựng đối xứng và kết hợp các điều kiện.',
    'Hình học',
    Icons.change_history,
    BrilliantPalette.successSurface,
    'Tạo hình bằng đôi tay',
  ),
  LearningTopic(
    'coding',
    'Lập trình bằng hành động',
    'Dẫn robot, xây vòng lặp và nối thuật toán.',
    'Lập trình',
    Icons.terminal,
    BrilliantPalette.successSurface,
    'Lập trình một hành trình',
  ),
  LearningTopic(
    'circuits',
    'Ánh sáng & mạch điện',
    'Nối dây, khám phá công tắc và pha ánh sáng.',
    'Mạch điện',
    Icons.lightbulb_outline,
    BrilliantPalette.successSurface,
    'Làm bừng sáng một ý tưởng',
  ),
  LearningTopic(
    'probability',
    'Điều gì sẽ xảy ra?',
    'Túi bi, không gian mẫu và thiết kế cơ hội.',
    'Xác suất',
    Icons.casino_outlined,
    BrilliantPalette.successSurface,
    'Thử vận may bằng toán',
  ),
  LearningTopic(
    'algebra',
    'Đại số bằng mô hình',
    'Cô lập ẩn số và dựng quan hệ bằng những khối thật.',
    'Đại số',
    Icons.balance,
    BrilliantPalette.successSurface,
    'Dựng một phương trình',
  ),
  LearningTopic(
    'optimization',
    'Thuật toán hiệu quả',
    'Gỡ lỗi, kiểm chứng và làm việc trong giới hạn.',
    'Thuật toán',
    Icons.route_outlined,
    BrilliantPalette.successSurface,
    'Sửa một thuật toán',
  ),
  LearningTopic(
    'geography',
    'Trái Đất trong tay bạn',
    'Xoay địa cầu, tìm tọa độ và đọc các lớp đất đá.',
    'Địa lý',
    Icons.public,
    BrilliantPalette.successSurface,
    'Xoay quả địa cầu',
  ),
  LearningTopic(
    'marxism',
    'Chủ nghĩa Mác–Lênin',
    'Tìm hiểu khái niệm, phân tích tình huống và đọc nguồn có đối chiếu.',
    'Triết học & xã hội',
    Icons.menu_book_outlined,
    BrilliantPalette.successSurface,
    'Đọc, phân tích và đối chiếu',
  ),
  LearningTopic(
    'painting',
    'Hội họa & ngôn ngữ thị giác',
    'Từ sắc độ, hình khối đến chiều sâu và phân tích bố cục.',
    'Nghệ thuật',
    Icons.palette_outlined,
    BrilliantPalette.successSurface,
    'Quan sát để hiểu một bức tranh',
  ),
  LearningTopic(
    'english',
    'Tiếng Anh trong cuộc sống',
    'Nghe, ghép câu và luyện nói từ lời chào đến yêu cầu lịch sự.',
    'Ngôn ngữ',
    Icons.record_voice_over_outlined,
    BrilliantPalette.successSurface,
    'Nghe và nói một câu mới',
  ),
  LearningTopic(
    'vietnamese',
    'Tiếng Việt & giao tiếp',
    'Kể chuyện, nối ý, viết rõ ràng và lập luận bằng bằng chứng.',
    'Ngôn ngữ',
    Icons.chat_bubble_outline,
    BrilliantPalette.successSurface,
    'Biến ý tưởng thành lời',
  ),
  LearningTopic(
    'biology',
    'Sự sống quanh ta',
    'Từ bộ phận cây đến hệ sinh thái và thiết kế thí nghiệm.',
    'Sinh học',
    Icons.eco_outlined,
    BrilliantPalette.successSurface,
    'Khám phá một hệ sống',
  ),
  LearningTopic(
    'chemistry',
    'Vật chất & biến đổi',
    'Phân loại vật chất, đếm nguyên tử và kiểm tra giả thuyết.',
    'Hóa học',
    Icons.science_outlined,
    BrilliantPalette.successSurface,
    'Thử trong phòng lab số',
  ),
  LearningTopic(
    'astronomy',
    'Bầu trời & vũ trụ',
    'Khám phá ngày đêm, pha Mặt Trăng và lập kế hoạch thám hiểm.',
    'Thiên văn',
    Icons.nightlight_round,
    BrilliantPalette.successSurface,
    'Theo dấu một thiên thể',
  ),
  LearningTopic(
    'finance',
    'Tiền & lựa chọn',
    'Từ nhu cầu, tiết kiệm đến phân bổ nguồn lực và đọc lời hứa.',
    'Kỹ năng sống',
    Icons.savings_outlined,
    BrilliantPalette.successSurface,
    'Lập ngân sách bằng mô hình',
  ),
  LearningTopic(
    'digital',
    'Công dân số thông minh',
    'Bảo vệ thông tin, kiểm chứng tin và dùng AI có trách nhiệm.',
    'Kỹ năng số',
    Icons.verified_user_outlined,
    BrilliantPalette.successSurface,
    'Điều tra một thông tin',
  ),
];
LearningTopic topicById(String id) =>
    topics.firstWhere((topic) => topic.id == id, orElse: () => topics.first);
