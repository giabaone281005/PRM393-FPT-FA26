import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../parent_portal/popups/parent_gate_dialog.dart';
import '../../kid_profile/popups/kid_switch_sheet.dart';
import '../popups/heart_status_sheet.dart';
import '../popups/streak_info_sheet.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onHeartTap;
  final String? subtitle;

  const AppHeader({super.key, this.onHeartTap, this.subtitle});

  @override
  Size get preferredSize => const Size.fromHeight(68.0);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;

    return Container(
      color: Colors.white.withAlpha(240),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo + Grade + Kid Switcher
              GestureDetector(
                onTap: () => _showKidSwitcher(context),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accentGold],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/owl_mascot.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.calculate_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              'MathLingo',
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'LỚP ${kid.grade}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryHover,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          subtitle ?? kid.nickname,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Pills: Streak & Hearts & Parent Portal
              Row(
                children: [
                  // Streak Pill (Tap to view streak details BR-02)
                  GestureDetector(
                    onTap: () => _showStreakInfo(context, state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGoldLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentGold.withAlpha(90),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: AppColors.streakFire,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${kid.streakCount}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Heart Pill (Tap to view heart restoration BR-03)
                  GestureDetector(
                    onTap: onHeartTap ?? () => _showHeartStatus(context, state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentRedLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentRed.withAlpha(90),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: AppColors.heart,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${kid.currentHearts}/${kid.maxHearts}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFBE123C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Parent Portal Lock Button
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSubtle,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onPressed: () => _openParentGate(context),
                  ),
                ],
              ),
            ],
          ),
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

  void _showStreakInfo(BuildContext context, AppStateProvider state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreakInfoSheet(kid: state.currentKid),
    );
  }

  void _showHeartStatus(BuildContext context, AppStateProvider state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HeartStatusSheet(kid: state.currentKid),
    );
  }

  void _openParentGate(BuildContext context) {
    showDialog(context: context, builder: (_) => const ParentGateDialog());
  }
}
