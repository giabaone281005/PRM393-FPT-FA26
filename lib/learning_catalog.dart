import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'experiments/experiment_model.dart';
import 'experiments/math_catalog.dart';
import 'experiments/discovery_catalog.dart';
import 'experiments/extended_catalog.dart';
import 'experiments/diverse_catalog.dart';
import 'experiments/solid_catalog.dart';

class LearningTopic {
  const LearningTopic(
    this.id,
    this.title,
    this.subtitle,
    this.subject,
    this.icon,
    this.color,
    this.action,
  );
  final String id, title, subtitle, subject, action;
  final IconData icon;
  final Color color;
  List<ExperimentSpec> get experiments => experimentCatalog[id]!;
}

final experimentCatalog = <String, List<ExperimentSpec>>{
  for (final entry in {...mathExperiments, ...discoveryExperiments}.entries)
    entry.key: [
      ...entry.value,
      ...(extensionExperiments[entry.key] ?? []),
      ...(diverseExperiments[entry.key] ?? []),
      ...(solidExperiments[entry.key] ?? []),
    ],
  'algebra': [
    ...extensionExperiments['algebra']!,
    ...solidExperiments['algebra']!,
  ],
  'geography': solidExperiments['geography']!,
  'optimization': extensionExperiments['optimization']!,
};
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
];
LearningTopic topicById(String id) =>
    topics.firstWhere((topic) => topic.id == id, orElse: () => topics.first);
