import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';
import '../popups/lesson_intro_sheet.dart';

class TreasureMapScreen extends StatelessWidget {
  const TreasureMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final lessons = state.currentLessons;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bản Đồ Kho Báu Lớp ${kid.grade}', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Banner Đảo Kho Báu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withAlpha(80),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🗺️', style: TextStyle(fontSize: 36)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hành Trình Khám Phá Toán Học',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Mỗi bài học chỉ 3–5 phút • Chinh phục đảo số học!',
                          style: AppTypography.bodySmall.copyWith(color: const Color(0xFFE0F2FE)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Lộ trình Node Bản Đồ
            ...List.generate(lessons.length, (index) {
              final lesson = lessons[index];
              final isLast = index == lessons.length - 1;

              // Node zig-zag alignment
              final alignment = index % 2 == 0 ? Alignment.centerLeft : Alignment.centerRight;

              return Column(
                children: [
                  Align(
                    alignment: alignment,
                    child: _buildLessonNode(context, lesson),
                  ),
                  if (!isLast)
                    Container(
                      width: 6,
                      height: 44,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: lesson.status == LessonStatus.completed
                            ? AppColors.accentGreen
                            : AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonNode(BuildContext context, Lesson lesson) {
    Color nodeColor;
    Widget icon;
    switch (lesson.status) {
      case LessonStatus.completed:
        nodeColor = AppColors.accentGreen;
        icon = const Icon(Icons.check_rounded, color: Colors.white, size: 30);
        break;
      case LessonStatus.available:
      case LessonStatus.inProgress:
        nodeColor = AppColors.primary;
        icon = const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34);
        break;
      case LessonStatus.locked:
        nodeColor = AppColors.textMuted;
        icon = const Icon(Icons.lock_rounded, color: Colors.white, size: 24);
        break;
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => LessonIntroSheet(lesson: lesson),
        );
      },
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: lesson.status == LessonStatus.available
                ? AppColors.primary
                : AppColors.borderSubtle,
            width: lesson.status == LessonStatus.available ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: nodeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: nodeColor.withAlpha(90),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${lesson.estimatedMinutes} phút • +${lesson.xpReward} XP',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                  if (lesson.status == LessonStatus.completed)
                    Row(
                      children: List.generate(
                        3,
                        (s) => const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
