import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../ai_scanner/ai_scanner_screen.dart';
import '../../learning_engine/screens/learning_screen.dart';
import '../../parent_portal/popups/parent_gate_dialog.dart';
import '../popups/lesson_intro_sheet.dart';

class TreasureMapScreen extends StatefulWidget {
  const TreasureMapScreen({super.key});

  @override
  State<TreasureMapScreen> createState() => _TreasureMapScreenState();
}

class _TreasureMapScreenState extends State<TreasureMapScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Cuộn tự động đến bài đang học sau khi dựng khung xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppStateProvider>();
      final lessons = state.currentLessons;
      final activeIndex = lessons.indexWhere(
        (l) =>
            l.status == LessonStatus.inProgress ||
            l.status == LessonStatus.available,
      );
      if (activeIndex > 3 && _scrollController.hasClients) {
        _scrollController.animateTo(
          (activeIndex - 2) * 110.0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final lessons = state.currentLessons;
    if (lessons.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.syncError ?? 'Chưa có bài học khả dụng.'),
              TextButton(
                onPressed: state.refreshFromCloud,
                child: const Text('Tải lại'),
              ),
            ],
          ),
        ),
      );
    }

    // Tìm bài đang học
    final activeLesson = lessons.firstWhere(
      (l) =>
          l.status == LessonStatus.inProgress ||
          l.status == LessonStatus.available,
      orElse: () => lessons.first,
    );

    final completedCount = lessons
        .where((l) => l.status == LessonStatus.completed)
        .length;
    final totalCount = lessons.length;
    final progressPercent = totalCount > 0
        ? (completedCount / totalCount)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Nút quay về màn hình trước
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),

            // 1. TOP HEADER
            _buildTopStatsBar(context, state, kid),

            // 2. MAIN SCROLLABLE MAP & BOTTOM SHEET
            Expanded(
              child: Stack(
                children: [
                  // Lộ trình quanh co (Curved Path Canvas & Nodes)
                  SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 210),
                    child: Column(
                      children: [
                        // Card Header Chương Học
                        _buildChapterCard(
                          kid.grade,
                          completedCount,
                          totalCount,
                          progressPercent,
                        ),
                        const SizedBox(height: 24),

                        // Lộ trình 30 Nodes quanh co
                        _buildCurvedMapPath(context, lessons, activeLesson),
                      ],
                    ),
                  ),

                  // 3. BOTTOM FLOATING CARD "MỤC TIÊU HIỆN TẠI / BẮT ĐẦU BÀI HỌC"
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 76, // Nằm ngay trên BottomNavigationBar
                    child: _buildBottomActionCard(context, activeLesson),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Top Bar với icon Cú MathLingo, Tag Lớp, Điểm Sao, Tim và Profile Avatar
  Widget _buildTopStatsBar(
    BuildContext context,
    AppStateProvider state,
    dynamic kid,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
      ),
      child: Row(
        children: [
          // Logo Cú MathLingo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA500), Color(0xFFFF7A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withAlpha(60),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/owl_mascot.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'MathLingo',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFDBA74),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'LỚP ${kid.grade}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ],
              ),
              const Text(
                'Hành trình bài học',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Chip Chuỗi Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 3),
                Text(
                  '${kid.streakCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Chip Trái Tim
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFF43F5E),
                  size: 14,
                ),
                const SizedBox(width: 3),
                Text(
                  '${kid.currentHearts}/5',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Avatar bé
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFFFEDD5),
            child: ClipOval(
              child: Image.asset(
                'assets/images/owl_mascot.jpg',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Text('🦉', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Header Thẻ Chương Học & Thanh Tiến Độ
  Widget _buildChapterCard(
    int grade,
    int completed,
    int total,
    double progress,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'HÀNH TRÌNH SỐ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Lớp $grade • Kỳ 1 & 2',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: Color(0xFFF59E0B),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$completed/$total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            grade == 5
                ? 'Toán Lớp 5: Phân Số, Số Thập Phân & Chuyển Động'
                : 'Khám Phá Bản Đồ 30 Bài Toán Thú Vị Lớp $grade',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiến độ lộ trình',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              Text(
                '$completed/$total Bài (${(progress * 100).toInt()}%)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Lộ Trình Vẽ Đường Cong Quanh Co (S-Curve Road)
  Widget _buildCurvedMapPath(
    BuildContext context,
    List<Lesson> lessons,
    Lesson activeLesson,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        const nodeHeight = 110.0;
        final totalHeight = lessons.length * nodeHeight;

        // Tính tọa độ X, Y hình sóng sin nhẹ cho từng node (Căn giữa uốn lượn)
        final List<Offset> positions = List.generate(lessons.length, (i) {
          final y = (i * nodeHeight) + 40.0;
          // Sin wave: biên độ dao động khoảng 90px từ tâm
          final x = (screenWidth / 2) + math.sin(i * 0.9) * 90.0;
          return Offset(x, y);
        });

        return SizedBox(
          width: screenWidth,
          height: totalHeight + 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Lớp vẽ đường cong nối các Node
              Positioned.fill(
                child: CustomPaint(
                  painter: _MapCurvedRoadPainter(
                    positions: positions,
                    activeLessonIndex: activeLesson.lessonNumber - 1,
                  ),
                ),
              ),

              // Thêm Rương Thần Kỳ hoặc Quà Tặng dọc đường (Sau bài 5, 10, 20...)
              _buildMilestoneReward(
                positions,
                4,
                'RƯƠNG VÀNG LỘ TRÌNH',
                'Mở sau bài 5',
              ),
              _buildMilestoneReward(
                positions,
                9,
                'ĐẤU TRƯỜNG BOSS CUỐI',
                'Mở sau bài 10',
              ),
              _buildMilestoneReward(
                positions,
                19,
                'HUY HIỆU DŨNG CĨ',
                'Mở sau bài 20',
              ),

              // Vẽ 30 Trạm Node Học
              for (int i = 0; i < lessons.length; i++)
                Positioned(
                  left: positions[i].dx - 36, // Tâm của nút 72px
                  top: positions[i].dy - 36,
                  child: _buildStationNode(
                    context,
                    lessons[i],
                    activeLesson.lessonNumber == lessons[i].lessonNumber,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Trạm bài học dạng nút tròn 3D bóng bẩy kèm Tag Tiêu Đề bên dưới
  Widget _buildStationNode(BuildContext context, Lesson lesson, bool isActive) {
    final isCompleted = lesson.status == LessonStatus.completed;
    final isLocked = lesson.status == LessonStatus.locked;

    return GestureDetector(
      onTap: () => _openLesson(context, lesson),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút tròn 3D
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Bubble "Học ở đây nè!" với icon Cú chỉ đường
              if (isActive)
                Positioned(
                  top: -34,
                  child:
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFF7A00).withAlpha(120),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF7A00).withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('🦉', style: TextStyle(fontSize: 12)),
                                SizedBox(width: 4),
                                Text(
                                  'Học ở đây nè!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveY(begin: 0, end: -4, duration: 800.ms),
                ),

              // Hiệu ứng Glow tỏa sáng khi Đang Học
              if (isActive)
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A00).withAlpha(90),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

              // Button Shape
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : isActive
                      ? const LinearGradient(
                          colors: [Color(0xFFFFA500), Color(0xFFFF5500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isCompleted
                                  ? const Color(0xFF059669)
                                  : isActive
                                  ? const Color(0xFFFF5500)
                                  : const Color(0xFF94A3B8))
                              .withAlpha(isLocked ? 30 : 90),
                      blurRadius: isLocked ? 4 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 34,
                        )
                      : isActive
                      ? const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 38,
                        )
                      : const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF64748B),
                          size: 28,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Tag nhãn tên bài dưới node
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF7A00) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? Colors.transparent : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              isActive
                  ? 'Bài ${lesson.lessonNumber} • ĐANG HỌC'
                  : 'Bài ${lesson.lessonNumber}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mốc Rương / Phần Thưởng phụ trên bản đồ
  Widget _buildMilestoneReward(
    List<Offset> positions,
    int index,
    String label,
    String sub,
  ) {
    if (index >= positions.length) return const SizedBox.shrink();
    final pos = positions[index];

    return Positioned(
      left: pos.dx > 180 ? 30 : null,
      right: pos.dx <= 180 ? 30 : null,
      top: pos.dy - 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withAlpha(30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 4. Bottom Action Card (Giống chính xác ảnh 2 thiết kế nịnh mắt)
  Widget _buildBottomActionCard(BuildContext context, Lesson activeLesson) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFDBA74).withAlpha(160),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A00).withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Tag Thưởng
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A00),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'MỤC TIÊU HIỆN TẠI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFEA580C),
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${activeLesson.xpReward} XP',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+10 Xu 🪙',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            activeLesson.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            activeLesson.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          // Hai Nút: BẮT ĐẦU BÀI HỌC (Cam lớn) + AI SCAN (Kế bên)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openLesson(context, activeLesson),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA500), Color(0xFFFF7A00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A00).withAlpha(70),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'BẮT ĐẦU BÀI HỌC',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Nút AI Scan
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiScannerScreen()),
                  );
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFEDD5),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFFEA580C),
                        size: 18,
                      ),
                      Text(
                        'AI SCAN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openLesson(BuildContext context, Lesson lesson) async {
    final action = await showModalBottomSheet<LessonIntroAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LessonIntroSheet(lesson: lesson),
    );
    if (!context.mounted) return;

    switch (action) {
      case LessonIntroAction.startLesson:
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LearningScreen(lesson: lesson)),
        );
      case LessonIntroAction.unlockForParent:
        await showDialog(
          context: context,
          builder: (_) => const ParentGateDialog(),
        );
      case null:
        break;
    }
  }
}

/// CustomPainter vẽ đường cong mềm mại nối các Node trên bản đồ
class _MapCurvedRoadPainter extends CustomPainter {
  final List<Offset> positions;
  final int activeLessonIndex;

  _MapCurvedRoadPainter({
    required this.positions,
    required this.activeLessonIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (positions.length < 2) return;

    for (int i = 0; i < positions.length - 1; i++) {
      final p1 = positions[i];
      final p2 = positions[i + 1];

      // Đã học qua: Màu xanh ngọc lá tươi
      // Chưa học tới: Màu xám đứt nét / mờ
      final isCompletedPath = i < activeLessonIndex;

      final paintRoad = Paint()
        ..color = isCompletedPath
            ? const Color(0xFF10B981)
            : const Color(0xFFCBD5E1)
        ..strokeWidth = isCompletedPath ? 5.5 : 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(p1.dx, p1.dy);

      // Điểm uốn cong Bezier mượt mà giữa 2 trạm
      final midY = (p1.dy + p2.dy) / 2;
      path.cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);

      canvas.drawPath(path, paintRoad);
    }
  }

  @override
  bool shouldRepaint(covariant _MapCurvedRoadPainter oldDelegate) {
    return oldDelegate.activeLessonIndex != activeLessonIndex ||
        oldDelegate.positions.length != positions.length;
  }
}
