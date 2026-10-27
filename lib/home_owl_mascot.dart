import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'owl_scene.dart';

class HomeOwlMascot extends StatefulWidget {
  const HomeOwlMascot({super.key});
  @override
  State<HomeOwlMascot> createState() => _HomeOwlMascotState();
}

class _HomeOwlMascotState extends State<HomeOwlMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  double yaw = -.12;
  int greetings = 0;
  bool welcomed = false;
  static const messages = [
    'Tớ là Mây. Chạm để chào tớ nhé!',
    'Chào bạn! Cùng khám phá điều mới nào!',
    'Thử một chút, hiểu thêm một chút!',
    'Tớ luôn cổ vũ bạn. Mình học tiếp nhé!',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      reaction.stop();
      reaction.value = 0;
      welcomed = true;
    } else if (!welcomed) {
      welcomed = true;
      reaction.forward(from: 0);
    }
  }

  void greet() {
    setState(() => greetings++);
    if (!AppMotion.reduced(context)) reaction.forward(from: 0);
  }

  void rotate(double amount) =>
      setState(() => yaw = (yaw + amount + math.pi) % (2 * math.pi) - math.pi);

  @override
  void dispose() {
    reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('home-owl'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          const Color(0xFF4B9BBB).withValues(alpha: .07),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF4B9BBB).withValues(alpha: .22),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cú Mây',
                  style: Theme.of(context).textTheme.titleMedium!
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                key: const ValueKey('owl-reset'),
                onPressed: () => setState(() => yaw = -.12),
                tooltip: 'Đặt lại góc nhìn',
                icon: const Icon(Icons.center_focus_strong_outlined),
              ),
            ],
          ),
          Semantics(
            label: 'Cú Mây 3D. Chạm để chào, kéo ngang để xoay.',
            image: true,
            button: true,
            onTap: greet,
            child: GestureDetector(
              key: const ValueKey('owl-orbit'),
              excludeFromSemantics: true,
              behavior: HitTestBehavior.opaque,
              onTap: greet,
              // Horizontal-only orbit leaves vertical page scrolling available.
              onHorizontalDragUpdate: (details) =>
                  rotate(details.delta.dx * .012),
              child: SizedBox(
                height: 236,
                width: double.infinity,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: reaction,
                    builder: (context, _) => CustomPaint(
                      key: const ValueKey('owl-scene'),
                      painter: OwlPainter(yaw: yaw, reaction: reaction.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(
            messages[greetings % messages.length],
            key: const ValueKey('owl-message'),
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5, color: colors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Chạm để chào · Kéo ngang để xoay',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                key: const ValueKey('owl-left'),
                tooltip: 'Xoay cú sang trái',
                onPressed: () => rotate(-.4),
                icon: const Icon(Icons.rotate_left_rounded),
              ),
              IconButton(
                key: const ValueKey('owl-greet'),
                tooltip: 'Chào Cú Mây',
                onPressed: greet,
                icon: const Icon(Icons.waving_hand_outlined),
              ),
              IconButton(
                key: const ValueKey('owl-right'),
                tooltip: 'Xoay cú sang phải',
                onPressed: () => rotate(.4),
                icon: const Icon(Icons.rotate_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OwlPainter extends CustomPainter {
  const OwlPainter({required this.yaw, required this.reaction});
  final double yaw, reaction;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .87);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 8),
        width: 118,
        height: 18,
      ),
      Paint()
        ..color = const Color(0xFF346078).withValues(alpha: .15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 130, height: 24),
      Paint()..color = const Color(0xFFC8E3E7),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center - const Offset(0, 5),
        width: 130,
        height: 24,
      ),
      Paint()..color = const Color(0xFFE7F5F4),
    );
    for (final face in OwlScene(yaw: yaw, reaction: reaction).project(size)) {
      final path = Path()..addPolygon(face.points, true);
      canvas.drawPath(path, Paint()..color = face.color);
      // Matching edge strokes avoid seams between neighboring lit polygons.
      canvas.drawPath(
        path,
        Paint()
          ..color = face.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = .35,
      );
    }
  }

  @override
  bool shouldRepaint(OwlPainter oldDelegate) =>
      oldDelegate.yaw != yaw || oldDelegate.reaction != reaction;
}
