import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers/app_state_provider.dart';
import '../home/home_screen.dart';
import '../treasure_map/treasure_map_screen.dart';
import '../practice_garden/screens/practice_garden_screen.dart';
import '../parent_portal/popups/parent_gate_dialog.dart';
import '../kid_profile/kid_profile_screen.dart';
import '../ai_scanner/ai_scanner_screen.dart';
import '../auth/auth_screen.dart';
import '../kid_profile/popups/add_kid_dialog.dart';
import '../subscriptions/learning_packages_screen.dart';
import '../../core/supabase/supabase_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final List<Widget> _screens = const [
    HomeScreen(),
    TreasureMapScreen(),
    PracticeGardenScreen(),
    KidProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Trang chủ'),
    _NavItem(icon: Icons.explore_rounded, label: 'Bài học'),
    _NavItem(icon: Icons.sports_esports_rounded, label: 'Luyện tập'),
    _NavItem(icon: Icons.person_rounded, label: 'Hồ sơ'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    if (!state.hasKids) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gia đình MathLingo')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isLoadingFromCloud)
                  const CircularProgressIndicator()
                else ...[
                  const Icon(Icons.family_restroom, size: 64),
                  const Text('Tạo hồ sơ bé đầu tiên để bắt đầu học.'),
                  if (state.syncError != null) Text(state.syncError!),
                  if (SupabaseService.isLoggedIn) ...[
                    FilledButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => ParentGateDialog(
                          onUnlocked: () => showDialog(
                            context: context,
                            builder: (_) => AddKidDialog(state: state),
                          ),
                        ),
                      ),
                      child: const Text('Thêm bé'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LearningPackagesScreen(),
                        ),
                      ),
                      child: const Text('Gói học tập'),
                    ),
                    TextButton(
                      onPressed: state.refreshFromCloud,
                      child: const Text('Thử tải lại'),
                    ),
                  ] else
                    FilledButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      ),
                      child: const Text('Đăng nhập'),
                    ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    final selectedTab = state.currentNavIndex;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Content Screen
          IndexedStack(index: selectedTab, children: _screens),

          // AI Scanner FAB (Floating – fixed position above bottom nav)
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withAlpha(90)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'QUÉT AI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryHover,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // FAB button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiScannerScreen(),
                      ),
                    );
                  },
                  child:
                      Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.accentGold,
                                ],
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(100),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.photo_camera_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(
                            begin: 1.0,
                            end: 1.05,
                            duration: 1500.ms,
                            curve: Curves.easeInOut,
                          ),
                ),
              ],
            ),
          ),

          // Bottom Navigation Bar – Floating Capsule
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(248),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navItems.asMap().entries.map((entry) {
                  return _buildNavItem(index: entry.key, item: entry.value);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required int index, required _NavItem item}) {
    final isActive = context.watch<AppStateProvider>().currentNavIndex == index;

    return GestureDetector(
      onTap: () => context.read<AppStateProvider>().setNavIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    item.icon,
                    key: ValueKey('icon_${index}_$isActive'),
                    size: 22,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  child: Text(item.label),
                ),
              ],
            ),
            if (item.badge != null)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String? badge = null;

  const _NavItem({required this.icon, required this.label});
}
