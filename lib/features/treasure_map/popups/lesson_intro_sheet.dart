import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../learning_engine/learning_screen.dart';

class LessonIntroSheet extends StatelessWidget {
  final Lesson lesson;

  const LessonIntroSheet({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final isCompleted = lesson.status == LessonStatus.completed;
    final isLocked = lesson.status == LessonStatus.locked;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge + Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.accentGreenLight
                      : isLocked
                          ? const Color(0xFFFEF3C7)
                          : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted
                      ? 'ĐÃ HOÀN THÀNH'
                      : isLocked
                          ? '🔒 ĐANG KHÓA THEO LỘ TRÌNH'
                          : 'BÀI HỌC SỐ ${lesson.lessonNumber}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? const Color(0xFF15803D)
                        : isLocked
                            ? const Color(0xFFB45309)
                            : AppColors.primaryHover,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Subtitle
          Text(lesson.title, style: AppTypography.titleLarge.copyWith(fontSize: 20)),
          const SizedBox(height: 4),
          Text(lesson.subtitle, style: AppTypography.bodySmall),
          const SizedBox(height: 20),

          // Highlights Chips (Time, XP, Stars, Questions)
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.timer_outlined,
                  color: AppColors.primaryHover,
                  label: 'Thời gian',
                  value: '${lesson.estimatedMinutes} phút',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  icon: Icons.bolt_rounded,
                  color: AppColors.accentGold,
                  label: 'Kinh nghiệm',
                  value: '+${lesson.xpReward} XP',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetric(
                  icon: Icons.star_rounded,
                  color: AppColors.star,
                  label: 'Phần thưởng',
                  value: '+${lesson.starReward} Sao',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lesson overview description
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                const Text('🦉', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bộ bài tập tương tác trực quan 60 FPS, có trợ lý Cú hướng dẫn phương pháp gợi mở Socratic từng bước!',
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button: BẮT ĐẦU HỌC NGAY / MỞ KHÓA & HỌC NGAY
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted
                  ? AppColors.accentGreen
                  : isLocked
                      ? const Color(0xFFD97706)
                      : AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: (isCompleted
                      ? AppColors.accentGreen
                      : isLocked
                          ? const Color(0xFFD97706)
                          : AppColors.primary)
                  .withAlpha(100),
            ),
            onPressed: () {
              if (isLocked) {
                context.read<AppStateProvider>().unlockLesson(lesson.id);
              }
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LearningScreen(lesson: lesson),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCompleted
                      ? 'LUYỆN TẬP LẠI'
                      : isLocked
                          ? 'MỞ KHÓA & HỌC NGAY'
                          : 'BẮT ĐẦU HỌC NGAY',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLocked ? Icons.lock_open_rounded : Icons.arrow_forward_rounded,
                  size: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
