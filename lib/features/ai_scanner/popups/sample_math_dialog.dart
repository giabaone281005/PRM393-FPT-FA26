import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SampleMathDialog extends StatelessWidget {
  final Function(String problem, String title, int grade) onSelectProblem;

  const SampleMathDialog({super.key, required this.onSelectProblem});

  static const List<Map<String, dynamic>> sampleProblems = [
    {
      'grade': 1,
      'title': 'Toán Đố Thêm Bớt',
      'content': 'Trong rổ có 8 quả táo. Mẹ cho thêm 5 quả táo nữa. Hỏi trong rổ có tất cả bao nhiêu quả táo?',
      'icon': '🍎',
    },
    {
      'grade': 2,
      'title': 'Bảng Cửu Chương & Phép Nhân',
      'content': 'Một bàn học có 4 chân. Hỏi 6 bàn học như thế có tất cả bao nhiêu cái chân?',
      'icon': '🪑',
    },
    {
      'grade': 3,
      'title': 'Đọc Giờ Đồng Hồ Thực Tế',
      'content': 'Bé Nam bắt đầu học bài lúc 8 giờ 15 phút. Bé học xong lúc 9 giờ kém 15 phút. Hỏi bé Nam đã học bài trong bao nhiêu phút?',
      'icon': '⏰',
    },
    {
      'grade': 4,
      'title': 'Diện Tích & Chu Vi Hình Học',
      'content': 'Một mảnh vườn hình chữ nhật có chiều dài 12m và chiều rộng 8m. Tính diện tích và chu vi của mảnh vườn đó.',
      'icon': '📐',
    },
    {
      'grade': 5,
      'title': 'Toán Phân Số & Tỉ Số Phần Trăm',
      'content': 'Lớp 5A có 32 học sinh, trong đó số học sinh nữ chiếm 75%. Tính số học sinh nam của lớp 5A.',
      'icon': '📊',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Chọn Bài Toán Mẫu SGK',
            style: AppTypography.titleLarge.copyWith(fontSize: 18),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: sampleProblems.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (ctx, index) {
            final p = sampleProblems[index];
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(context);
                onSelectProblem(
                  p['content'] as String,
                  p['title'] as String,
                  p['grade'] as int,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['icon'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                p['title'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'LỚP ${p['grade']}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryHover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['content'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
