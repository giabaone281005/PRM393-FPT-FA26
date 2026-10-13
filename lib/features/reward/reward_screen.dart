import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/lesson.dart';
import '../../data/providers/app_state_provider.dart';
import '../main/main_screen.dart';

class RewardScreen extends StatelessWidget {
  final Lesson lesson;

  const RewardScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final beforeNoon21 = DateTime.now().hour < 21;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Trophy animation
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGold, Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGold.withAlpha(120),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 68)),
                ),
              )
                  .animate()
                  .scale(
                    delay: 100.ms,
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shimmer(duration: 1200.ms, color: Colors.white.withAlpha(80)),

              const SizedBox(height: 24),

              Text('HOÀN THÀNH BÀI HỌC! 🎉', style: AppTypography.displayMedium)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.3),

              const SizedBox(height: 8),
              Text(
                lesson.title,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(lesson.starReward, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 40)
                        .animate(delay: (500 + i * 150).ms)
                        .scale(curve: Curves.elasticOut)
                        .fadeIn(),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Reward Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRewardCard(
                    icon: Icons.bolt_rounded,
                    color: AppColors.accentGold,
                    value: '+${lesson.xpReward} XP',
                    label: 'Kinh Nghiệm',
                    delay: 600,
                  ),
                  const SizedBox(width: 12),
                  _buildRewardCard(
                    icon: Icons.star_rounded,
                    color: AppColors.star,
                    value: '+${lesson.starReward} Sao',
                    label: 'Năng Lượng',
                    delay: 700,
                  ),
                  const SizedBox(width: 12),
                  _buildRewardCard(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.streakFire,
                    value: '${kid.streakCount} Ngày',
                    label: 'Math Streak',
                    delay: 800,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Shield earned if before 21:00
              if (beforeNoon21)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accentGold.withAlpha(90)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.streakFire, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Hoàn thành trước 21:00! +1 Khiên Bảo Vệ (BR-02)',
                          style: AppTypography.labelSmall.copyWith(
                            color: const Color(0xFFB45309),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2),

              const Spacer(),

              // CTA buttons
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withAlpha(100),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (_) => false,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'TIẾP TỤC HÀNH TRÌNH',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ).animate().slideY(begin: 0.3, delay: 1000.ms, duration: 400.ms).fadeIn(),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Ôn tập lại bài này',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ).animate().fadeIn(delay: 1100.ms),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    int delay = 0,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    ).animate().scale(delay: delay.ms, curve: Curves.elasticOut).fadeIn();
  }
}
