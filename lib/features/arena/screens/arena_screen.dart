import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/arena_repository.dart';
import '../../shared/widgets/app_header.dart';
import '../popups/arena_challenge_dialog.dart';
import '../popups/league_rules_sheet.dart';
import '../games/mario_rescue_game.dart';
import '../games/pixel_racing_game.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTimeRemaining();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    // Chốt kết quả vào 21:00 tối Chủ Nhật hàng tuần theo thể lệ đấu trường
    int daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    DateTime nextSundayReset = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      21,
      0,
      0,
    );
    if (nextSundayReset.isBefore(now)) {
      nextSundayReset = nextSundayReset.add(const Duration(days: 7));
    }
    _timeRemaining = nextSundayReset.difference(now);
  }

  String get _formattedCountdown {
    if (_timeRemaining.isNegative) return '00:00:00';
    final hours = _timeRemaining.inHours.toString().padLeft(2, '0');
    final minutes = (_timeRemaining.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeRemaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _loadLeaderboard() async {
    final state = context.read<AppStateProvider>();
    final grade = state.currentKid.grade;
    final data = await ArenaRepository.fetchLeaderboard(grade);

    if (!mounted) return;
    setState(() {
      _leaderboard = data;
      _loading = false;
    });
  }

  void _openChallenge(AppStateProvider state) {
    // Ngẫu nhiên chọn 1 trong các tựa game pixel cute vừa học vừa chơi:
    // 0: Mario Cứu Công Chúa
    // 1: Đua Xe Pixel Turbo Math Racing
    // 2: Thử Thách Đấu Trường Tiêu Chuẩn
    final randomGame = Random().nextInt(3);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        if (randomGame == 0) {
          return MarioPrincessRescueGame(
            state: state,
            onGameOver: _loadLeaderboard,
          );
        } else if (randomGame == 1) {
          return PixelTurboMathRacingGame(
            state: state,
            onGameOver: _loadLeaderboard,
          );
        } else {
          return ArenaChallengeDialog(
            state: state,
            onScoreSubmitted: _loadLeaderboard,
          );
        }
      },
    );
  }

  void _openRules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LeagueRulesSheet(),
    );
  }

  void _handle1v1Tap(AppStateProvider state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_kabaddi_rounded, color: Color(0xFF2563EB), size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'Đấu Đơn 1vs1',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚡ TÍNH NĂNG SẮP RA MẮT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Chế độ ghép cặp thi đấu 1vs1 trực tiếp cùng bạn bè trên toàn quốc đang được hoàn thiện.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hiện tại bé có thể tham gia ngay Thử Thách Đấu Trường để tích lũy XP leo Bảng Vinh Danh tuần này!',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Để sau', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openChallenge(state);
            },
            child: const Text('Vào Đấu Ngay ⚡', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleClassTourneyTap() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF059669), size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'Giải Đấu Lớp',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '🏆 GIẢI ĐẤU KHỐI 5 TUẦN NÀY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bảng thi đấu tự động ghi danh toàn bộ học sinh cùng khối lớp. Top 3 bạn có XP cao nhất tuần sẽ nhận Cúp Vàng và phần thưởng Cú.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bé hãy xem Thể Lệ Thi Đấu để nắm rõ cách tính điểm và mốc chốt tuần nhé!',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openRules();
            },
            child: const Text('Xem Thể Lệ 📜', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;

    // Find current kid's rank in leaderboard
    final myXp = kid.energyStars * 2;
    final myEntry = {
      'rank': 4,
      'name': kid.nickname,
      'xp': myXp,
      'badge': kid.activeBadge,
      'isCurrent': true,
      'class': 'Lớp ${kid.grade}A',
    };

    // Merge leaderboard with current kid
    List<Map<String, dynamic>> display = [];
    if (_leaderboard.isNotEmpty) {
      bool myRankInserted = false;
      for (final entry in _leaderboard) {
        if (!myRankInserted && (entry['xp'] as int) <= myXp) {
          display.add({...myEntry, 'rank': display.length + 1});
          myRankInserted = true;
        }
        display.add({
          ...entry,
          'rank': display.length + 1,
          'isCurrent': false,
          'class': entry['class'] ?? 'Lớp ${kid.grade}A',
        });
      }
      if (!myRankInserted) {
        display.add({...myEntry, 'rank': display.length + 1});
      }
    } else {
      display = [
        {'rank': 1, 'name': 'Minh Khang', 'xp': 1420, 'badge': 'Nhà Bác Học Nhí', 'class': 'Lớp 5A', 'isCurrent': false},
        {...myEntry, 'rank': 2, 'name': '${kid.nickname} (Bạn)', 'xp': myXp > 0 ? myXp : 1250, 'isCurrent': true},
        {'rank': 3, 'name': 'Hà Linh', 'xp': 1180, 'badge': 'Thám Tử Toán Học', 'class': 'Lớp 5B', 'isCurrent': false},
        {'rank': 4, 'name': 'Hoàng Nam', 'xp': 980, 'badge': 'Siêu Trí Tuệ', 'class': 'Lớp 5A', 'isCurrent': false},
        {'rank': 5, 'name': 'Gia Bảo', 'xp': 850, 'badge': 'Thợ Săn Phép Tính', 'class': 'Lớp 5C', 'isCurrent': false},
        {'rank': 6, 'name': 'Khánh An', 'xp': 720, 'badge': 'Nhà Khám Phá', 'class': 'Lớp 5B', 'isCurrent': false},
      ];
    }

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              title: Text('Đấu Trường', style: AppTypography.titleLarge),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C)),
                  tooltip: 'Thể lệ giải đấu',
                  onPressed: _openRules,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  tooltip: 'Làm mới BXH',
                  onPressed: _loadLeaderboard,
                ),
              ],
            )
          : const AppHeader(subtitle: 'Đấu Trường'),
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        color: const Color(0xFFEA580C),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 160),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hot Event Banner (Ảnh 1: SỰ KIỆN NÓNG - ĐẤU TRƯỜNG CUỐI TUẦN)
              _buildHotEventBanner(state),
              const SizedBox(height: 22),

              // 2. Chế Độ Chơi Nhanh (Ảnh 1: Đấu Đơn 1vs1 & Giải Đấu Lớp)
              _buildQuickPlayModes(state, kid.grade),
              const SizedBox(height: 24),

              // 3. Bảng Vinh Danh Tuần Này (Ảnh 1: Top 3 & Danh sách)
              _buildLeaderboardSection(display, kid.grade),
              const SizedBox(height: 20),

              // 4. Mission Trophy Hunter Banner (Ảnh 1: Nhiệm Vụ Thợ Săn Cúp)
              _buildMascotMissionCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Hot Event Banner (Ảnh 1)
  // ---------------------------------------------------------------------------
  Widget _buildHotEventBanner(AppStateProvider state) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9A3412), // Deep warm amber
            Color(0xFFC2410C), // Rich orange
            Color(0xFFEA580C), // Bright orange
            Color(0xFF7C2D12), // Bottom shadow accent
          ],
          stops: [0.0, 0.45, 0.85, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withAlpha(100),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle trophy watermark in top-right corner
          Positioned(
            top: -12,
            right: 8,
            child: Icon(
              Icons.military_tech_rounded,
              size: 110,
              color: Colors.white.withAlpha(22),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row: SỰ KIỆN NÓNG & ĐẾM NGƯỢC
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(50)),
                      ),
                      child: const Text(
                        'SỰ KIỆN NÓNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            _formattedCountdown,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Title
                const Text(
                  'ĐẤU TRƯỜNG CUỐI TUẦN',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  'Thách đấu 1vs1 hoặc giải đấu bảng xếp hạng nhận x2 Xu Vàng đổi Mascot siêu ngầu!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withAlpha(235),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),

                // Prominent Action Button (Pill white)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFC2410C),
                    elevation: 6,
                    shadowColor: Colors.black.withAlpha(70),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () => _openChallenge(state),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_esports_rounded, size: 22, color: Color(0xFFEA580C)),
                      SizedBox(width: 8),
                      Text(
                        'VÀO ĐẤU NGAY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC2410C),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFEA580C)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.15, duration: 350.ms);
  }

  // ---------------------------------------------------------------------------
  // 2. Chế Độ Chơi Nhanh (Ảnh 1)
  // ---------------------------------------------------------------------------
  Widget _buildQuickPlayModes(AppStateProvider state, int grade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 19)),
                const SizedBox(width: 8),
                Text(
                  'Chế Độ Chơi Nhanh',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            Text(
              'Lớp $grade Tốc Độ',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: Đấu Đơn 1vs1
            Expanded(
              child: _buildPlayModeCard(
                iconWidget: const Icon(Icons.sports_kabaddi_rounded, color: Color(0xFF2563EB), size: 22),
                iconBgColor: const Color(0xFFEFF6FF),
                rewardPillText: '+30',
                rewardPillBg: const Color(0xFFFFF7ED),
                rewardPillTextColor: const Color(0xFFEA580C),
                title: 'Đấu Đơn 1vs1',
                desc: 'Ghép cặp ngẫu nhiên bạn cùng khối $grade toàn...',
                buttonText: 'Tìm Bạn Đấu',
                buttonIcon: Icons.arrow_forward_rounded,
                buttonColor: const Color(0xFF2563EB),
                onTap: () => _handle1v1Tap(state),
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Giải Đấu Lớp
            Expanded(
              child: _buildPlayModeCard(
                iconWidget: const Icon(Icons.emoji_events_rounded, color: Color(0xFF059669), size: 22),
                iconBgColor: const Color(0xFFECFDF5),
                rewardPillText: '+100',
                rewardPillBg: const Color(0xFFECFDF5),
                rewardPillTextColor: const Color(0xFF059669),
                title: 'Giải Đấu Lớp',
                desc: 'Top 3 nhận Cúp Vàng tuần và Vinh danh Bản...',
                buttonText: 'Ghi Danh',
                buttonIcon: Icons.edit_note_rounded,
                buttonColor: const Color(0xFFEA580C),
                onTap: _handleClassTourneyTap,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }

  Widget _buildPlayModeCard({
    required Widget iconWidget,
    required Color iconBgColor,
    required String rewardPillText,
    required Color rewardPillBg,
    required Color rewardPillTextColor,
    required String title,
    required String desc,
    required String buttonText,
    required IconData buttonIcon,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon & Reward Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: iconWidget),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rewardPillBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rewardPillTextColor.withAlpha(70)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 10)),
                    const SizedBox(width: 2),
                    Text(
                      rewardPillText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: rewardPillTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),

          // Description
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 1,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4),
                  Icon(buttonIcon, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Bảng Vinh Danh Tuần Này (Ảnh 1)
  // ---------------------------------------------------------------------------
  Widget _buildLeaderboardSection(List<Map<String, dynamic>> display, int grade) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFFEA580C), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Bảng Vinh Danh Tuần Này',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _openRules,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Color(0xFF4F46E5), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Hạng Kim Cương',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List Items
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFFEA580C)),
            ),
          )
        else
          ...display.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final rank = item['rank'] as int;
            final isMe = item['isCurrent'] == true;

            return _buildLeaderboardItem(item, rank, isMe, index);
          }),
      ],
    ).animate().fadeIn(delay: 250.ms);
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> item, int rank, bool isMe, int animIndex) {
    // Medal & Trophy Badge Styling
    Widget rankBadge;
    Widget? trophyTag;

    if (rank == 1) {
      rankBadge = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
        ),
        child: const Center(
          child: Text(
            '1🥇',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF9A3412)),
          ),
        ),
      );
      trophyTag = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: 11)),
            SizedBox(width: 3),
            Text(
              'Cúp Vàng',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
            ),
          ],
        ),
      );
    } else if (rank == 2) {
      rankBadge = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFDBEAFE),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        ),
        child: const Center(
          child: Text(
            '2🥈',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF)),
          ),
        ),
      );
      trophyTag = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🛡', style: TextStyle(fontSize: 11)),
            SizedBox(width: 3),
            Text(
              'Cúp Bạc',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
            ),
          ],
        ),
      );
    } else if (rank == 3) {
      rankBadge = Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
        ),
        child: const Center(
          child: Text(
            '3🥉',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFC2410C)),
          ),
        ),
      );
      trophyTag = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⚙', style: TextStyle(fontSize: 11)),
            SizedBox(width: 3),
            Text(
              'Cúp Đồng',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
            ),
          ],
        ),
      );
    } else {
      rankBadge = SizedBox(
        width: 34,
        child: Text(
          '#$rank',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isMe ? const Color(0xFFEA580C) : AppColors.textSecondary,
          ),
        ),
      );
    }

    final rawName = item['name'] as String? ?? 'Bé Ẩn Danh';
    final xp = item['xp'] ?? 0;
    final className = item['class'] as String? ?? 'Lớp 5A';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isMe ? const Color(0xFF3B82F6) : AppColors.borderSubtle,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isMe ? const Color(0xFF3B82F6).withAlpha(30) : Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          rankBadge,
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isMe
                    ? [const Color(0xFF2563EB), const Color(0xFF60A5FA)]
                    : rank == 1
                        ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
                        : [const Color(0xFF64748B), const Color(0xFF94A3B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                rawName.isNotEmpty ? rawName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User Info & Badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        rawName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isMe ? const Color(0xFF1D4ED8) : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Tôi',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          className,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$xp XP',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isMe ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Right Trophy/Medal Pill
          ?trophyTag,
        ],
      ),
    ).animate(delay: (animIndex * 50).ms).fadeIn().slideX(begin: 0.08);
  }

  // ---------------------------------------------------------------------------
  // 4. Mascot Mission Card (Ảnh 1)
  // ---------------------------------------------------------------------------
  Widget _buildMascotMissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E40AF), // Deep royal blue
            Color(0xFF2563EB), // Vibrant blue
            Color(0xFF3B82F6), // Bright blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(90),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mascot Owl Circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Text('🦉', style: TextStyle(fontSize: 27)),
            ),
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NHIỆM VỤ THỢ SĂN CÚP',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Thắng 2 trận nữa để mở khóa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Mũ Phi Hành Gia cho Bé Cú! 🚀',
                  style: TextStyle(
                    color: Color(0xFFFDE047),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Circular progress ring
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: 1 / 3,
                  strokeWidth: 4.5,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                ),
                const Text(
                  '1/3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15);
  }
}
