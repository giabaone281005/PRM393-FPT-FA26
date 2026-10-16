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
    final state = context.watch<AppStateProvider>();
    final lessons = state.currentLessons;

    // Tìm bài học đang học hiện tại
    final currentActiveLesson = lessons.firstWhere(
      (l) => l.status == LessonStatus.inProgress || l.status == LessonStatus.available,
      orElse: () => lessons.first,
    );

    final isCompleted = lesson.status == LessonStatus.completed;
    final isLocked = lesson.status == LessonStatus.locked;
    final isJumpAhead = isLocked && lesson.lessonNumber > currentActiveLesson.lessonNumber;

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

          // Tên bài & Mô tả
          Text(lesson.title, style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(lesson.subtitle, style: AppTypography.bodySmall),
          const SizedBox(height: 16),

          // Cảnh báo nếu mở nhảy bậc
          if (isJumpAhead) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bé cần học theo đúng thứ tự lộ trình! Nhấn nút bên dưới hệ thống sẽ đưa bạn về bài đang học: "${currentActiveLesson.title}".',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Thông số bài học
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.timer_outlined,
                  color: const Color(0xFF0284C7),
                  label: 'Thời lượng',
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
                  label: 'Sao thưởng',
                  value: '+${lesson.starReward} Sao',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Trợ lý Socratic Cú
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/owl_mascot.jpg',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text('🦉', style: TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bài học gồm Lý thuyết SGK dẫn dắt chi tiết, Trắc nghiệm, Tự luận và Mini Game bổ ích!',
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button: BẮT ĐẦU HỌC NGAY / VỀ BÀI ĐANG HỌC
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted
                  ? AppColors.accentGreen
                  : isJumpAhead
                      ? const Color(0xFFEA580C)
                      : AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            onPressed: () {
              Navigator.pop(context);

              // Nếu cố tình mở bài nhảy bậc -> Bắt buộc route về bài học hiện tại!
              final targetLesson = isJumpAhead ? currentActiveLesson : lesson;

              if (isJumpAhead) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đang đưa bạn về đúng lộ trình: ${currentActiveLesson.title} 🚀'),
                    backgroundColor: const Color(0xFFEA580C),
                  ),
                );
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LearningScreen(lesson: targetLesson),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isCompleted
                      ? 'LUYỆN TẬP LẠI'
                      : isJumpAhead
                          ? 'VỀ BÀI ĐANG HỌC (BÀI ${currentActiveLesson.lessonNumber})'
                          : 'BẮT ĐẦU HỌC NGAY',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                ),
                const SizedBox(width: 8),
                Icon(
                  isJumpAhead ? Icons.replay_rounded : Icons.arrow_forward_rounded,
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
