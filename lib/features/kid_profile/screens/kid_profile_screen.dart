import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../parent_portal/popups/parent_gate_dialog.dart';
import '../../mascot_wardrobe/screens/mascot_wardrobe_screen.dart';
import '../popups/kid_switch_sheet.dart';
import '../popups/edit_kid_dialog.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/auth_screen.dart';

class KidProfileScreen extends StatelessWidget {
  const KidProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hồ Sơ Của Bé', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
            tooltip: 'Cổng phụ huynh',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ParentGateDialog(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + Name Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFF4A7FBD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar circle with gear edit
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Center(
                          child: Text('🦉', style: TextStyle(fontSize: 44)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MascotWardrobeScreen()),
                          ),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.accentGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        kid.nickname,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
                        tooltip: 'Chỉnh sửa hồ sơ bé',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => EditKidDialog(kid: kid, state: state),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Lớp ${kid.grade} • ${kid.activeBadge}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2),

            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _buildStatCard('⭐', '${kid.energyStars}', 'Sao Năng Lượng', delay: 100),
                const SizedBox(width: 12),
                _buildStatCard('🔥', '${kid.streakCount}', 'Ngày Liên Tiếp', delay: 200),
                const SizedBox(width: 12),
                _buildStatCard('❤️', '${kid.currentHearts}/${kid.maxHearts}', 'Tim Còn Lại', delay: 300),
              ],
            ),

            const SizedBox(height: 20),

            // Progress section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📊 Tiến Độ Học Tập', style: AppTypography.titleMedium),
                  const SizedBox(height: 16),
                  _buildProgressBar('Phép cộng & trừ', 0.9, AppColors.accentGreen),
                  const SizedBox(height: 12),
                  _buildProgressBar('Bảng cửu chương', 0.72, AppColors.accentGold),
                  const SizedBox(height: 12),
                  _buildProgressBar('Bài toán có lời văn', 0.55, AppColors.accentRed),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 16),

            // Quick actions: Trang phục Cú & Đổi Hồ Sơ
            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    context,
                    icon: Icons.face_rounded,
                    label: 'Trang Phục Cú',
                    color: AppColors.accentGold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MascotWardrobeScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionBtn(
                    context,
                    icon: Icons.swap_horiz_rounded,
                    label: 'Đổi Hồ Sơ',
                    color: AppColors.primary,
                    onTap: () => _showKidSwitcher(context),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 20),

            // Đăng xuất tài khoản
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await AuthRepository.signOut();
                  if (!context.mounted) return;
                  context.read<AppStateProvider>().lockParentPortal();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 16),
                label: const Text(
                  'Đăng Xuất Tài Khoản Phụ Huynh',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, {int delay = 0}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.titleMedium.copyWith(fontSize: 16)),
            Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ).animate().fadeIn(delay: delay.ms).scale(curve: Curves.easeOut),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Text('${(value * 100).round()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppColors.surfaceSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.titleMedium.copyWith(fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  void _showKidSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const KidSwitchSheet(),
    );
  }
}
