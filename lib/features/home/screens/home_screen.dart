import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../../learning_engine/lesson_navigation.dart';
import '../../learning_engine/widgets/student_learning_overview.dart';
import '../../treasure_map/screens/treasure_map_screen.dart';
import '../../practice_garden/screens/practice_garden_screen.dart';
import '../../arena/screens/arena_screen.dart';
import '../../mascot_wardrobe/screens/mascot_wardrobe_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final lessons = state.currentLessons;
    if (lessons.isEmpty) {
      return Scaffold(
        appBar: AppHeader.adaptive(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.syncError ?? 'Chưa có bài học khả dụng.'),
              TextButton(
                onPressed: state.refreshFromCloud,
                child: const Text('Tải lại bài học'),
              ),
            ],
          ),
        ),
      );
    }

    // Tìm bài học đang học hoặc bài có sẵn kế tiếp
    final activeLesson = lessons.firstWhere(
      (l) =>
          l.status == LessonStatus.available ||
          l.status == LessonStatus.inProgress,
      orElse: () => lessons.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader.adaptive(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Khóa Học Đang Theo Học (Nhấn để chuyển sang Bản Đồ Kho Báu)
              GestureDetector(
                onTap: () => context.read<AppStateProvider>().setNavIndex(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withAlpha(60),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: AppColors.primaryHover,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gói Toán Toàn Diện Lớp ${kid.grade}',
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Học kỳ 2 • Lộ trình 3–5 phút/ngày (Xem lộ trình)',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreenLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentGreen.withAlpha(90),
                          ),
                        ),
                        child: const Text(
                          'ĐANG HỌC',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ Bài Học Trọng Tâm Hôm Nay (Theo Stitch)
              GestureDetector(
                onTap: () => openLearningLesson(context, activeLesson),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'BÀI ${activeLesson.lessonNumber}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primaryHover,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.bolt_rounded,
                                          color: AppColors.accentGold,
                                          size: 16,
                                        ),
                                        Text(
                                          '+${activeLesson.xpReward} XP',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  activeLesson.title,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activeLesson.subtitle,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.functions_rounded,
                              color: AppColors.primaryHover,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nút TIẾP TỤC HỌC NGAY lớn bóng bẩy (Stitch: btn-continue-lesson)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withAlpha(100),
                        ),
                        onPressed: () =>
                            openLearningLesson(context, activeLesson),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                'TIẾP TỤC HỌC NGAY',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.play_arrow_rounded, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const CurrentLearningOverview(),
              const SizedBox(height: 20),

              // Các Lối Tắt Tính Năng (Quick Actions)
              Text('Tính Năng & Hoạt Động', style: AppTypography.titleMedium),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: '🗺️',
                      title: 'Bản Đồ Bài Học',
                      subtitle: '${lessons.length} bài trong lộ trình',
                      color: const Color(0xFFE0F2FE),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TreasureMapScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: '🌿',
                      title: 'Vườn Luyện Tập',
                      subtitle: 'Hồi Tim (BR-03)',
                      color: const Color(0xFFDCFCE7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PracticeGardenScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: '🏆',
                      title: 'Đấu Trường',
                      subtitle: 'Thi đua 30 bạn',
                      color: const Color(0xFFEDE9FE),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ArenaScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: '🦉',
                      title: 'Kho Đồ Cú 3D',
                      subtitle: '${kid.energyStars} Sao đổi đồ',
                      color: const Color(0xFFFEF3C7),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MascotWardrobeScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
