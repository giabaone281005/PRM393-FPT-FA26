import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'mascot_owl_3d.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.register,
    required this.message,
    required this.error,
    required this.notice,
    required this.mascotState,
    required this.onMascotTap,
    required this.child,
  });

  final bool register, error, notice;
  final String message;
  final MascotState mascotState;
  final VoidCallback onMascotTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final muted = dark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final bubbleColor = error
        ? AppColors.accentRed
        : notice
        ? AppColors.accentGreen
        : AppColors.primary;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? [AppColors.darkSurface, AppColors.darkBackground]
                : [AppColors.primaryLight, AppColors.background],
            stops: const [0, .72],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'MathLingo',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!keyboard) ...[
                        const SizedBox(height: 24),
                        Text(
                          register
                              ? 'Hành trình nhỏ,\nkhám phá lớn!'
                              : 'Học toán vui hơn\ncùng bạn Cú!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            height: 1.22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Mỗi ngày một chút, tự tin thêm một chút.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                      SizedBox(height: keyboard ? 12 : 18),
                      Semantics(
                        liveRegion: true,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: bubbleColor.withValues(alpha: .2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    error
                                        ? Icons.info_outline_rounded
                                        : notice
                                        ? Icons.mark_email_read_outlined
                                        : Icons.chat_bubble_outline_rounded,
                                    size: 16,
                                    color: bubbleColor,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: error
                                          ? bubbleColor
                                          : theme.colorScheme.onSurface,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: CustomPaint(
                          size: const Size(18, 10),
                          painter: _BubbleTail(
                            theme.colorScheme.surface,
                            bubbleColor.withValues(alpha: .2),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: keyboard ? 110 : 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              bottom: 4,
                              child: Container(
                                width: keyboard ? 130 : 190,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: .08,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                            if (!keyboard) ...[
                              Positioned(
                                left: 25,
                                top: 18,
                                child: _symbol('+', AppColors.primary, -.2),
                              ),
                              Positioned(
                                right: 28,
                                top: 14,
                                child: _symbol(
                                  '×',
                                  AppColors.accentPurple,
                                  .15,
                                ),
                              ),
                              Positioned(
                                left: 58,
                                bottom: 20,
                                child: _symbol('3', AppColors.accentGreen, .12),
                              ),
                              Positioned(
                                right: 55,
                                bottom: 22,
                                child: _symbol('=', AppColors.accentGold, -.1),
                              ),
                            ],
                            Semantics(
                              button: true,
                              label: 'Trò chuyện với bạn Cú',
                              child: ExcludeSemantics(
                                child: MascotOwl3D(
                                  size: keyboard ? 108 : 150,
                                  state: mascotState,
                                  onTap: onMascotTap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: dark
                                ? AppColors.darkBorderSubtle
                                : AppColors.borderSubtle.withValues(alpha: .6),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: .05),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.family_restroom_rounded,
                            size: 16,
                            color: muted,
                          ),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'Một tài khoản phụ huynh,\ncả nhà cùng khám phá.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _symbol(String text, Color color, double angle) => ExcludeSemantics(
    child: Transform.rotate(
      angle: angle,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: .6),
          ),
        ),
      ),
    ),
  );
}

class _BubbleTail extends CustomPainter {
  const _BubbleTail(this.fill, this.border);
  final Color fill, border;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_BubbleTail oldDelegate) =>
      fill != oldDelegate.fill || border != oldDelegate.border;
}
