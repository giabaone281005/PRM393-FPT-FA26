import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../shared/widgets/app_header.dart';
import '../popups/lesson_intro_sheet.dart';

class TreasureMapScreen extends StatelessWidget {
  const TreasureMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final lessons = state.currentLessons;

    final completedCount = lessons.where((l) => l.status == LessonStatus.completed).length;
    final totalStars = lessons.fold<int>(0, (sum, l) => sum + (l.status == LessonStatus.completed ? (l.starsEarned > 0 ? l.starsEarned : 3) : 0));
    final progressPercent = lessons.isNotEmpty ? (completedCount / lessons.length).clamp(0.0, 1.0) : 0.0;
    final allCompleted = completedCount == lessons.length;

    // Find the currently active lesson (available or inProgress)
    final activeIndex = lessons.indexWhere(
      (l) => l.status == LessonStatus.available || l.status == LessonStatus.inProgress,
    );
    final safeActiveIndex = activeIndex != -1 ? activeIndex : (allCompleted ? lessons.length - 1 : 0);
    final activeLesson = lessons[safeActiveIndex];

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: const BackButton(color: AppColors.textPrimary),
              title: Text(
                'Bản Đồ Bài Học Lớp ${kid.grade}',
                style: AppTypography.titleLarge.copyWith(fontSize: 18),
              ),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.borderSubtle),
              ),
            )
          : const AppHeader(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 160),
        child: Column(
          children: [
            // 1. Chapter Header Card (Matching Image 1)
            _buildChapterCard(
              grade: kid.grade,
              completedCount: completedCount,
              totalLessons: lessons.length,
              progressPercent: progressPercent,
              totalStars: totalStars,
            ),
            const SizedBox(height: 20),

            // 2. Adventure Game Winding S-Road Map (Matching Image 1)
            _buildAdventureMap(
              context: context,
              lessons: lessons,
              activeIndex: safeActiveIndex,
              allCompleted: allCompleted,
              grade: kid.grade,
            ),
            const SizedBox(height: 24),

            // 3. Floating "Mục Tiêu Hiện Tại" Card (Matching Image 1)
            _buildCurrentGoalCard(context, activeLesson),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Chapter Header Card (Matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildChapterCard({
    required int grade,
    required int completedCount,
    required int totalLessons,
    required double progressPercent,
    required int totalStars,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Tag + Subtitle + Star pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'HÀNH TRÌNH SỐ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C3AED),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Lớp $grade • Tập 1',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGoldLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$totalStars/${totalLessons * 3}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Chapter Title
          Text(
            'Chương 3: Phân Số & Số Thập Phân',
            style: AppTypography.titleLarge.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Progress text row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ chương',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              Text(
                '$completedCount/$totalLessons Bài (${(progressPercent * 100).toInt()}%)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Gradient Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 8,
              width: double.infinity,
              color: const Color(0xFFF1F5F9),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressPercent,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669), Color(0xFFF59E0B)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Winding S-Road Map (Matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildAdventureMap({
    required BuildContext context,
    required List<Lesson> lessons,
    required int activeIndex,
    required bool allCompleted,
    required int grade,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapWidth = constraints.maxWidth;
        final xCenter = mapWidth * 0.50;
        final xLeft = mapWidth * 0.25;
        final xRight = mapWidth * 0.75;

        // Coordinates for the 5 lessons + 1 Boss chest
        // Smooth S-curve alternating: Center -> Right -> Left -> Right -> Left -> Center
        final List<Offset> points = [
          Offset(xCenter, 45), // Stop 0 (Bài 1)
          Offset(xRight, 185), // Stop 1 (Bài 2 - Active)
          Offset(xLeft, 325), // Stop 2 (Bài 3)
          Offset(mapWidth * 0.70, 465), // Stop 3 (Bài 4)
          Offset(mapWidth * 0.30, 605), // Stop 4 (Bài 5)
          Offset(xCenter, 760), // Stop 5 (Boss Chest)
        ];

        const mapHeight = 870.0;

        return SizedBox(
          width: mapWidth,
          height: mapHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. S-Curve Road Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapRoadPainter(
                    points: points,
                    activeIndex: activeIndex,
                  ),
                ),
              ),

              // 2. Floating Badges / Island Decorations (Matching Image 1)
              // Diamond bonus on the left of Bài 1/2
              Positioned(
                top: 105,
                left: 12,
                child: _buildFloatingBonusBadge('💎 +20 Ngọc', const Color(0xFF0284C7)),
              ),
              // Mascot bubble beside the Active Lesson
              Positioned(
                top: 155,
                left: 10,
                child: _buildMascotSpeechBubble(),
              ),
              // XP bonus near Bài 3/4
              Positioned(
                top: 395,
                right: 14,
                child: _buildFloatingBonusBadge('⚡ +40 XP', const Color(0xFFB45309)),
              ),

              // 3. Lesson Stops (Stops 0 to 4)
              ...lessons.asMap().entries.map((entry) {
                final i = entry.key;
                if (i >= points.length - 1) return const SizedBox.shrink();
                final lesson = entry.value;
                final pos = points[i];
                final isActive = i == activeIndex;

                return _buildLessonStopNode(
                  context: context,
                  lesson: lesson,
                  position: pos,
                  isActive: isActive,
                );
              }),

              // 4. Boss Chest Destination (Stop 5)
              _buildBossChestNode(
                context: context,
                position: points.last,
                allCompleted: allCompleted,
                grade: grade,
              ),
            ],
          ),
        );
      },
    );
  }

  // Floating bonus badge (like "💎 +20 Ngọc" in Image 1)
  Widget _buildFloatingBonusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  // Mascot Speech Bubble "Học ở đây nè!" (matching Image 1)
  Widget _buildMascotSpeechBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withAlpha(120), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(30),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'Học ở đây nè! 🦉',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFC2410C),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accentGold, width: 1.5),
          ),
          child: const Center(
            child: Text('Lvl 5', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Lesson Stop Node (Completed, Active, Locked)
  // ---------------------------------------------------------------------------
  Widget _buildLessonStopNode({
    required BuildContext context,
    required Lesson lesson,
    required Offset position,
    required bool isActive,
  }) {
    final isCompleted = lesson.status == LessonStatus.completed;
    final isLocked = lesson.status == LessonStatus.locked;

    final nodeSize = isActive ? 72.0 : 56.0;

    return Positioned(
      left: position.dx - 90,
      top: position.dy - (nodeSize / 2),
      width: 180,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => LessonIntroSheet(lesson: lesson),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Node with Halo
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft glow halo for active node
                if (isActive)
                  Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withAlpha(60),
                          AppColors.primary.withAlpha(20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                // Main Circle Node
                Container(
                  width: nodeSize,
                  height: nodeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [const Color(0xFF34D399), const Color(0xFF10B981), const Color(0xFF059669)]
                          : (isActive
                              ? [const Color(0xFFFB923C), const Color(0xFFF97316), const Color(0xFFEA580C)]
                              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isLocked ? const Color(0xFFCBD5E1) : Colors.white,
                      width: isActive ? 3.5 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCompleted
                            ? const Color(0xFF10B981).withAlpha(120)
                            : (isActive
                                ? AppColors.primary.withAlpha(150)
                                : Colors.black.withAlpha(12)),
                        blurRadius: isActive ? 16 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : (isActive ? Icons.play_arrow_rounded : Icons.lock_rounded),
                      color: isLocked ? const Color(0xFF94A3B8) : Colors.white,
                      size: isActive ? 38 : (isCompleted ? 30 : 22),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Stars for completed lesson (Matching Image 1)
            if (isCompleted) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (s) => const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                ),
              ),
              const SizedBox(height: 3),
            ],

            // Active badge OR Label capsule under each node
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(90),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'BÀI ${lesson.lessonNumber} • ĐANG HỌC',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Bài ${lesson.lessonNumber} • ${_getShortLessonTitle(lesson)}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isLocked ? const Color(0xFF64748B) : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Boss Chest Node (Matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildBossChestNode({
    required BuildContext context,
    required Offset position,
    required bool allCompleted,
    required int grade,
  }) {
    const boxSize = 64.0;

    return Positioned(
      left: position.dx - 100,
      top: position.dy - (boxSize / 2),
      width: 200,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _showBossChestDialog(context, allCompleted, grade);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dark glass 3D chest box
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: allCompleted
                      ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                      : [const Color(0xFF334155), const Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: allCompleted ? const Color(0xFFFDE68A) : const Color(0xFF64748B),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: allCompleted
                        ? const Color(0xFFF59E0B).withAlpha(140)
                        : Colors.black.withAlpha(40),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      allCompleted ? '🏆' : '🎁',
                      style: const TextStyle(fontSize: 30),
                    ),
                    if (!allCompleted)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_rounded, size: 12, color: AppColors.accentGold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Golden label capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: allCompleted ? const Color(0xFFFEF3C7) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF59E0B).withAlpha(120)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('👑', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(
                    'RƯƠNG THỬ THÁCH BOSS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: allCompleted ? const Color(0xFF92400E) : const Color(0xFFB45309),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              allCompleted ? '🎉 Đã mở khóa thành công!' : 'Mở khóa sau bài 5',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Floating "Mục Tiêu Hiện Tại" Card (Matching Image 1)
  // ---------------------------------------------------------------------------
  Widget _buildCurrentGoalCard(BuildContext context, Lesson activeLesson) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Orange dot + "MỤC TIÊU HIỆN TẠI" + Rewards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'MỤC TIÊU HIỆN TẠI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryHover,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGoldLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.accentGold, size: 13),
                        Text(
                          '+${activeLesson.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '🪙 +10 Xu',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Active Lesson Title
          Text(
            activeLesson.title,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),

          // Subtitle
          Text(
            activeLesson.subtitle,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),

          // Action Button: BẮT ĐẦU BÀI HỌC
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              shadowColor: AppColors.primary.withAlpha(120),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => LessonIntroSheet(lesson: activeLesson),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BẮT ĐẦU BÀI HỌC',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _getShortLessonTitle(Lesson lesson) {
    if (lesson.title.contains(':')) {
      final parts = lesson.title.split(':');
      if (parts.length > 1) {
        final text = parts[1].trim();
        if (text.length > 16) {
          return '${text.substring(0, 14)}...';
        }
        return text;
      }
    }
    return lesson.title.length > 16 ? '${lesson.title.substring(0, 14)}...' : lesson.title;
  }

  void _showBossChestDialog(BuildContext context, bool allCompleted, int grade) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Text(allCompleted ? '🏆' : '🔒', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                allCompleted ? 'Rương Boss Đã Mở!' : 'Rương Thử Thách Boss',
                style: AppTypography.titleMedium.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          allCompleted
              ? 'Chúc mừng bạn nhỏ đã xuất sắc hoàn thành trọn vẹn cả 5 bài học của Lớp $grade! Hãy nhận +100 XP và huy hiệu danh dự!'
              : 'Rương Boss đang được khóa kín! Hãy hoàn thành cả 5 bài học của Lớp $grade để mở khóa kho báu bí mật nhé!',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// S-Road CustomPainter (Continuous Bezier Curve Road with Dashes)
// -----------------------------------------------------------------------------
class _MapRoadPainter extends CustomPainter {
  final List<Offset> points;
  final int activeIndex;

  _MapRoadPainter({
    required this.points,
    required this.activeIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dy = p2.dy - p1.dy;

      final path = Path();
      path.moveTo(p1.dx, p1.dy);
      // Cubic Bezier with vertical tangents at both endpoints
      path.cubicTo(
        p1.dx,
        p1.dy + dy * 0.5,
        p2.dx,
        p2.dy - dy * 0.5,
        p2.dx,
        p2.dy,
      );

      // 1. Underlayer Road Base (wide soft track)
      final baseRoadPaint = Paint()
        ..color = const Color(0xFFE2E8F0).withAlpha(160)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, baseRoadPaint);

      // 2. Completed road vs Locked road
      if (i < activeIndex) {
        // Completed segment: vibrant solid emerald road!
        final completedRoadPaint = Paint()
          ..color = const Color(0xFF10B981)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, completedRoadPaint);

        // Highlight stripe in center
        final highlightPaint = Paint()
          ..color = const Color(0xFF6EE7B7)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(path, highlightPaint);
      } else {
        // Locked/upcoming segment: dashed line along the curved path
        final dashPaint = Paint()
          ..color = const Color(0xFF94A3B8)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

        for (final metric in path.computeMetrics()) {
          double distance = 0.0;
          const double dashLength = 7.0;
          const double dashGap = 6.0;
          while (distance < metric.length) {
            final extractPath = metric.extractPath(
              distance,
              (distance + dashLength).clamp(0.0, metric.length),
            );
            canvas.drawPath(extractPath, dashPaint);
            distance += dashLength + dashGap;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapRoadPainter oldDelegate) =>
      oldDelegate.activeIndex != activeIndex || oldDelegate.points != points;
}
