import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/arena_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
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

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;

    // Find current kid's rank in leaderboard
    final myXp = kid.energyStars * 2;
    final myEntry = {'rank': 4, 'name': kid.nickname, 'xp': myXp, 'badge': kid.activeBadge, 'isCurrent': true};

    // Merge leaderboard with current kid
    List<Map<String, dynamic>> display = [];
    if (_leaderboard.isNotEmpty) {
      bool myRankInserted = false;
      for (final entry in _leaderboard) {
        if (!myRankInserted && (entry['xp'] as int) <= myXp) {
          display.add({...myEntry, 'rank': display.length + 1});
          myRankInserted = true;
        }
        display.add({...entry, 'rank': display.length + 1, 'isCurrent': false});
      }
      if (!myRankInserted) {
        display.add({...myEntry, 'rank': display.length + 1});
      }
    } else {
      display = [
        {'rank': 1, 'name': 'Minh Khang', 'xp': 450, 'badge': 'Nhà Bác Học Nhí', 'isCurrent': false},
        {'rank': 2, 'name': 'Thảo Linh', 'xp': 420, 'badge': 'Thám Tử Toán Học', 'isCurrent': false},
        {'rank': 3, 'name': 'Hoàng Nam', 'xp': 390, 'badge': 'Siêu Trí Tuệ', 'isCurrent': false},
        {...myEntry, 'rank': 4},
        {'rank': 5, 'name': 'Gia Bảo', 'xp': 340, 'badge': 'Thợ Săn Phép Tính', 'isCurrent': false},
        {'rank': 6, 'name': 'Khánh An', 'xp': 310, 'badge': 'Nhà Khám Phá', 'isCurrent': false},
      ];
    }

    final daysLeft = 7 - DateTime.now().weekday;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Đấu Trường Khối ${kid.grade}', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF8B5CF6)),
            tooltip: 'Thể lệ giải đấu',
            onPressed: _openRules,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Làm mới BXH',
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Giải Đấu 30 Bạn
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withAlpha(80),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 44))
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2000.ms, color: Colors.white.withAlpha(60)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giải Đấu 30 Bạn Cùng Khối',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Còn $daysLeft ngày',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Top 3 nhận Cú Vàng!',
                                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              const SizedBox(height: 16),

              // Nút THI ĐẤU NGAY lớn bóng bẩy (Stitch / Gamification action)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF8B5CF6).withAlpha(120),
                ),
                onPressed: () => _openChallenge(state),
                icon: const Icon(Icons.flash_on_rounded, color: AppColors.accentGold),
                label: const Text(
                  'THỬ THÁCH ĐẤU TRƯỜNG (+50 XP)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),

              const SizedBox(height: 20),

              // My rank summary card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          kid.nickname.isNotEmpty ? kid.nickname[0] : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(kid.nickname, style: AppTypography.titleMedium.copyWith(color: AppColors.primaryHover)),
                          Text(
                            kid.activeBadge,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: AppColors.accentGold, size: 18),
                            Text(
                              '$myXp XP',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Text('Tuần này', style: AppTypography.bodySmall),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // Leaderboard title + Rules shortcut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bảng Xếp Hạng Tuần Này', style: AppTypography.titleMedium),
                  GestureDetector(
                    onTap: _openRules,
                    child: Text(
                      'Thể lệ thi đấu',
                      style: AppTypography.labelSmall.copyWith(color: const Color(0xFF8B5CF6)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else
                ...display.asMap().entries.map((e) {
                  final item = e.value;
                  final isMe = item['isCurrent'] == true;
                  final rank = item['rank'] as int;

                  Widget? medalIcon;
                  if (rank == 1) medalIcon = const Text('🥇', style: TextStyle(fontSize: 22));
                  if (rank == 2) medalIcon = const Text('🥈', style: TextStyle(fontSize: 22));
                  if (rank == 3) medalIcon = const Text('🥉', style: TextStyle(fontSize: 22));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryLight : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe ? AppColors.primary : AppColors.borderSubtle,
                        width: isMe ? 2 : 1,
                      ),
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(30),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: medalIcon ??
                              Text(
                                '#$rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isMe ? AppColors.primaryHover : AppColors.textSecondary,
                                ),
                              ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontSize: 15,
                                      color: isMe ? AppColors.primaryHover : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'BẠN',
                                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (item['badge'] != null)
                                Text(
                                  item['badge'] as String,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accentPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: AppColors.accentGold, size: 18),
                            Text(
                              '${item['xp']} XP',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate(delay: (e.key * 60).ms).fadeIn().slideX(begin: 0.1);
                }),
            ],
          ),
        ),
      ),
    );
  }
}
