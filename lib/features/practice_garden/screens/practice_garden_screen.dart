import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../learning_engine/screens/learning_progress_screen.dart';
import '../../learning_engine/screens/review_wrong_answers_screen.dart';
import '../../learning_engine/study_screen.dart';
import '../../shared/widgets/app_header.dart';
import 'math_flappy_game_screen.dart';

class PracticeGardenScreen extends StatelessWidget {
  const PracticeGardenScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppStateProvider?>();
    final compactHeader =
        MediaQuery.sizeOf(context).width < 380 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.2;
    final dark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final muted = dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final border = dark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: state?.hasKids == true && !compactHeader
          ? const AppHeader()
          : AppBar(
              title: Text(
                'Vườn luyện tập',
                style: AppTypography.titleLarge.copyWith(color: textColor),
              ),
              surfaceTintColor: Colors.transparent,
            ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          // Leave space for the student shell's floating navigation and AI button.
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 176),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 840),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vườn luyện tập',
                              style: AppTypography.displayMedium.copyWith(
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Luyện mỗi ngày, tự tin hơn mỗi chút.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _icon(Icons.spa_rounded, AppColors.accentGreen, dark),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          dark ? AppColors.darkSurface : AppColors.primaryLight,
                          theme.colorScheme.surface,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimens.radiusLarge,
                      ),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(dark ? 110 : 65),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              color: AppColors.heart,
                              size: 22,
                            ),
                            Text(
                              'LUYỆN TẬP MIỄN PHÍ',
                              style: AppTypography.labelSmall.copyWith(
                                color: dark
                                    ? AppColors.accentGold
                                    : AppColors.primaryHover,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Nạp đầy tim,\nsẵn sàng học tiếp!',
                          style: AppTypography.displayMedium.copyWith(
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Làm đúng 5 câu để hồi đầy đủ tim. Luôn miễn phí.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(
                                0,
                                AppDimens.buttonHeight,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppDimens.radiusMedium,
                                ),
                              ),
                              textStyle: AppTypography.bodyLarge.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () => _open(
                              context,
                              const StudyScreen(kind: 'practice'),
                            ),
                            icon: const Icon(Icons.bolt_rounded),
                            label: const Text('Luyện tập câu hỏi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Khám phá thêm',
                    style: AppTypography.titleLarge.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chọn cách luyện tập phù hợp với em.',
                    style: AppTypography.bodySmall.copyWith(color: muted),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns =
                          constraints.maxWidth >= 640 &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.3;
                      final width = twoColumns
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _activity(
                            context,
                            width: constraints.maxWidth,
                            title: 'Chơi Math Flappy',
                            subtitle: 'Bay qua những thử thách toán học.',
                            icon: Icons.flight_takeoff_rounded,
                            color: AppColors.accentPurple,
                            dark: dark,
                            border: border,
                            destination: const MathFlappyGameScreen(),
                          ),
                          _activity(
                            context,
                            width: width,
                            title: 'Xem lại câu trả lời sai',
                            subtitle: 'Ôn lại để hiểu bài chắc hơn.',
                            icon: Icons.history_edu_rounded,
                            color: AppColors.primary,
                            dark: dark,
                            border: border,
                            destination: const ReviewWrongAnswersScreen(),
                          ),
                          _activity(
                            context,
                            width: width,
                            title: 'Tiến độ học tập',
                            subtitle: 'Nhìn lại hành trình học của em.',
                            icon: Icons.insights_rounded,
                            color: AppColors.accentGreen,
                            dark: dark,
                            border: border,
                            destination: const LearningProgressScreen(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget destination) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination));

  Widget _icon(IconData icon, Color color, bool dark) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color.withAlpha(dark ? 40 : 22),
      borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
    ),
    child: Icon(icon, color: color, size: 26),
  );

  Widget _activity(
    BuildContext context, {
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool dark,
    required Color border,
    required Widget destination,
  }) => SizedBox(
    width: width,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.all(18),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
        ),
      ),
      onPressed: () => _open(context, destination),
      child: Row(
        children: [
          _icon(icon, color, dark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: dark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: color, size: 22),
        ],
      ),
    ),
  );
}
