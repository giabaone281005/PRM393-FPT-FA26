import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/kid_profile.dart';
import '../../practice_garden/practice_garden_screen.dart';

class HeartStatusSheet extends StatelessWidget {
  final KidProfile kid;

  const HeartStatusSheet({super.key, required this.kid});

  @override
  Widget build(BuildContext context) {
    final isFull = kid.currentHearts >= kid.maxHearts;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentRedLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.heart, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text('Trái Tim Năng Lượng', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hiển thị 5 Tim
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(kid.maxHearts, (index) {
              final isFilled = index < kid.currentHearts;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  isFilled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isFilled ? AppColors.heart : AppColors.textMuted,
                  size: 38,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            '${kid.currentHearts}/${kid.maxHearts} Tim khả dụng',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFBE123C)),
          ),
          const SizedBox(height: 16),

          // Giải thích cơ chế BR-03
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌱', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hồi Tim Miễn Phí Tại Vườn Luyện Tập (BR-03)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MathLingo cam kết không thu phí nạp Tim. Bé có thể vào Vườn Luyện Tập tính nhẩm thư giãn để nạp lại đầy 5 Tim bất kỳ lúc nào!',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11, color: const Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Nút Vào Vườn Luyện Tập
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PracticeGardenScreen()),
              );
            },
            icon: const Icon(Icons.spa_rounded, size: 20),
            label: Text(
              isFull ? 'LUYỆN TẬP THÊM TẠI VƯỜN' : 'VÀO VƯỜN HỒI PHỤC TIM NGAY',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
