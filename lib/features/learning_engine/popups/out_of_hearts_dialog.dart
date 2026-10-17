import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../practice_garden/practice_garden_screen.dart';

class OutOfHeartsDialog extends StatelessWidget {
  const OutOfHeartsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentRedLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.heart,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Bé Đã Hết Tim! (BR-03)',
            style: AppTypography.titleLarge.copyWith(fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đừng lo lắng! MathLingo không yêu cầu nạp tiền để mua tim. Bé có thể vào "Vườn Luyện Tập" giải toán tính nhẩm nhẹ nhàng để nạp lại đầy 5 Tim hoàn toàn miễn phí!',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Text('🌱', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mỗi câu tính nhẩm đúng = hồi phục 1 Tim năng lượng ❤️',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Đóng dialog
            Navigator.pop(context); // Thoát bài học về trang chủ
          },
          child: const Text('Về Trang Chủ'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PracticeGardenScreen()),
            );
          },
          icon: const Icon(Icons.spa_rounded, size: 18),
          label: const Text('Vào Vườn Hồi Tim'),
        ),
      ],
    );
  }
}
