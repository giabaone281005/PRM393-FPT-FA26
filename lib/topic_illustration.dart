import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original dimensional illustrations. All coordinates use a 200 × 180 stage,
/// so the same artwork stays sharp in a shortcut, card, or course header.
class TopicIllustration extends StatelessWidget {
  const TopicIllustration({
    super.key,
    required this.topicId,
    required this.label,
    this.height = 144,
  });

  final String topicId, label;
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    child: RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _SculptedTopicPainter(topicId)),
      ),
    ),
  );
}

class _SculptedTopicPainter extends CustomPainter {
  const _SculptedTopicPainter(this.id);
  final String id;
  static const blue = Color(0xFF4564F5);
  static const navy = Color(0xFF24399D);
  static const violet = Color(0xFF9373FF);
  static const gold = Color(0xFFFFCA47);
  static const emerald = Color(0xFF28BC78);

  Path polygon(List<Offset> points) => Path()..addPolygon(points, true);

  void face(Canvas c, Path path, List<Color> colors) {
    c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(path.getBounds()),
    );
  }

  void line(Canvas c, List<Offset> points, Color color, double width) {
    c.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void oval(Canvas c, Rect rect, List<Color> colors) {
    c.drawOval(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
  }

  void rounded(Canvas c, Rect rect, double radius, List<Color> colors) => face(
    c,
    Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))),
    colors,
  );

  void sparkle(Canvas c, Offset p, double s, Color color) {
    final path = Path()
      ..moveTo(p.dx, p.dy - s)
      ..quadraticBezierTo(p.dx + s * .15, p.dy - s * .15, p.dx + s, p.dy)
      ..quadraticBezierTo(p.dx + s * .15, p.dy + s * .15, p.dx, p.dy + s)
      ..quadraticBezierTo(p.dx - s * .15, p.dy + s * .15, p.dx - s, p.dy)
      ..quadraticBezierTo(p.dx - s * .15, p.dy - s * .15, p.dx, p.dy - s);
    c.drawPath(path, Paint()..color = color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 200, size.height / 180);
    canvas.save();
    canvas.translate(
      (size.width - 200 * scale) / 2,
      (size.height - 180 * scale) / 2,
    );
    canvas.scale(scale);
    canvas.drawOval(
      const Rect.fromLTWH(45, 148, 116, 14),
      Paint()
        ..color = const Color(0xFF273267).withValues(alpha: .16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    switch (id) {
      case 'algebra':
      case 'logic':
        _gear(
          canvas,
          const Offset(80, 102),
          44,
          emerald,
          const Color(0xFF116A51),
          -.18,
        );
        _gear(
          canvas,
          const Offset(133, 63),
          32,
          gold,
          const Color(0xFFBD7D14),
          .15,
        );
      case 'math':
        _fraction(canvas);
      case 'science':
        _rocket(canvas);
      case 'data':
        _bars(canvas);
      case 'geometry':
        _geometry(canvas);
      case 'optimization':
      case 'coding':
        _robot(canvas);
      case 'circuits':
        _bulb(canvas);
      case 'probability':
        _chance(canvas);
      case 'geography':
        oval(canvas, const Rect.fromLTWH(47, 26, 108, 108), [
          const Color(0xFFEAFAEE),
          emerald,
          const Color(0xFF116A51),
        ]);
        canvas.drawOval(
          const Rect.fromLTWH(76, 26, 50, 108),
          Paint()
            ..color = const Color(0xFF116A51)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawOval(
          const Rect.fromLTWH(47, 65, 108, 30),
          Paint()
            ..color = const Color(0xFF116A51)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        line(canvas, [const Offset(101, 135), const Offset(101, 150)], navy, 5);
        rounded(canvas, const Rect.fromLTWH(73, 148, 56, 9), 4, [
          emerald,
          navy,
        ]);
    }
    sparkle(canvas, const Offset(37, 46), 7, violet.withValues(alpha: .65));
    sparkle(canvas, const Offset(166, 118), 5, gold);
    canvas.drawCircle(
      const Offset(163, 36),
      3,
      Paint()..color = emerald.withValues(alpha: .5),
    );
    canvas.restore();
  }

  void _gear(
    Canvas c,
    Offset center,
    double r,
    Color light,
    Color dark,
    double rotation,
  ) {
    c.save();
    c.translate(center.dx, center.dy);
    c.rotate(rotation);
    final points = <Offset>[];
    for (var i = 0; i < 48; i++) {
      final angle = i * math.pi / 24;
      final radius = (i % 4 == 0 || i % 4 == 3) ? r * .82 : r;
      points.add(Offset(math.cos(angle) * radius, math.sin(angle) * radius));
    }
    final path = polygon(points);
    c.save();
    c.translate(0, 9);
    face(c, path, [dark, dark]);
    c.restore();
    face(c, path, [Color.lerp(light, Colors.white, .38)!, light]);
    oval(c, Rect.fromCircle(center: Offset.zero, radius: r * .58), [
      light,
      dark,
    ]);
    oval(c, Rect.fromCircle(center: const Offset(0, -2), radius: r * .45), [
      dark,
      light,
    ]);
    oval(c, Rect.fromCircle(center: const Offset(0, 1), radius: r * .21), [
      dark,
      const Color(0xFF162B3D),
    ]);
    c.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * .65),
      3.4,
      1.5,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.restore();
  }

  void _fraction(Canvas c) {
    c.save();
    c.translate(97, 95);
    c.rotate(-.22);
    oval(c, const Rect.fromLTWH(-59, -41, 118, 104), [
      navy,
      const Color(0xFF172B81),
    ]);
    oval(c, const Rect.fromLTWH(-59, -55, 118, 104), [
      const Color(0xFFA69BFF),
      blue,
    ]);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      line(
        c,
        [const Offset(0, -3), Offset(math.cos(a) * 55, math.sin(a) * 48 - 3)],
        const Color(0xFFDBD9FF),
        2,
      );
    }
    // Lifted wedge makes the fraction tangible instead of a flat chart.
    final wedge = Path()
      ..moveTo(14, -17)
      ..lineTo(14, -69)
      ..cubicTo(35, -68, 54, -55, 62, -39)
      ..close();
    c.save();
    c.translate(0, 8);
    face(c, wedge, [const Color(0xFFCD8F16), gold]);
    c.restore();
    face(c, wedge, [const Color(0xFFFFEB9F), gold]);
    line(
      c,
      [const Offset(16, -66), const Offset(16, -22), const Offset(57, -40)],
      const Color(0xFFFFF1BE),
      2,
    );
    c.restore();
  }

  void _rocket(Canvas c) {
    c.save();
    c.translate(99, 85);
    c.rotate(.48);
    face(
      c,
      Path()
        ..moveTo(-14, 47)
        ..quadraticBezierTo(-25, 84, 0, 89)
        ..quadraticBezierTo(25, 72, 14, 47)
        ..close(),
      [gold, const Color(0xFFFF8B46)],
    );
    face(
      c,
      polygon([
        const Offset(-20, 6),
        const Offset(-43, 48),
        const Offset(-15, 40),
      ]),
      [violet, navy],
    );
    face(
      c,
      polygon([
        const Offset(20, 6),
        const Offset(43, 48),
        const Offset(15, 40),
      ]),
      [blue, navy],
    );
    final hull = Path()
      ..moveTo(0, -64)
      ..cubicTo(34, -39, 30, 20, 18, 48)
      ..lineTo(-18, 48)
      ..cubicTo(-30, 20, -34, -39, 0, -64)
      ..close();
    face(c, hull, [
      Colors.white,
      const Color(0xFFD6DFFA),
      const Color(0xFF94A8E4),
    ]);
    face(
      c,
      Path()
        ..moveTo(0, -64)
        ..quadraticBezierTo(17, -52, 23, -30)
        ..quadraticBezierTo(0, -23, -23, -30)
        ..quadraticBezierTo(-17, -52, 0, -64),
      [violet, blue],
    );
    oval(c, const Rect.fromLTWH(-17, -17, 34, 34), [navy, blue]);
    oval(c, const Rect.fromLTWH(-12, -13, 24, 24), [
      const Color(0xFFB6F8FC),
      const Color(0xFF519DDC),
    ]);
    line(c, [const Offset(-6, -8), const Offset(2, -11)], Colors.white, 3);
    rounded(c, const Rect.fromLTWH(-17, 39, 34, 12), 4, [navy, blue]);
    c.restore();
  }

  void _block(
    Canvas c,
    double x,
    double y,
    double w,
    double h,
    Color top,
    Color front,
    Color side,
  ) {
    face(
      c,
      polygon([
        Offset(x, y),
        Offset(x + w, y + 9),
        Offset(x + w, y + h + 9),
        Offset(x, y + h),
      ]),
      [top, front],
    );
    face(
      c,
      polygon([
        Offset(x + w, y + 9),
        Offset(x + w + 15, y),
        Offset(x + w + 15, y + h),
        Offset(x + w, y + h + 9),
      ]),
      [front, side],
    );
    face(
      c,
      polygon([
        Offset(x, y),
        Offset(x + 15, y - 9),
        Offset(x + w + 15, y),
        Offset(x + w, y + 9),
      ]),
      [Color.lerp(top, Colors.white, .4)!, top],
    );
    line(
      c,
      [Offset(x + 2, y + 2), Offset(x + w - 2, y + 10)],
      Colors.white.withValues(alpha: .4),
      1.5,
    );
  }

  void _bars(Canvas c) {
    _block(c, 41, 108, 24, 32, const Color(0xFFA794FF), violet, navy);
    _block(c, 77, 76, 24, 68, const Color(0xFF85A3FF), blue, navy);
    _block(
      c,
      113,
      39,
      24,
      109,
      const Color(0xFF8AE4B4),
      emerald,
      const Color(0xFF107857),
    );
    line(
      c,
      [const Offset(45, 86), const Offset(85, 55), const Offset(132, 20)],
      gold,
      5,
    );
    line(
      c,
      [const Offset(118, 20), const Offset(132, 20), const Offset(131, 34)],
      gold,
      5,
    );
  }

  void _geometry(Canvas c) {
    c.save();
    c.translate(12, 8);
    face(
      c,
      polygon([
        const Offset(42, 74),
        const Offset(78, 54),
        const Offset(111, 73),
        const Offset(75, 94),
      ]),
      [const Color(0xFFC9BDFF), violet],
    );
    face(
      c,
      polygon([
        const Offset(42, 74),
        const Offset(75, 94),
        const Offset(75, 137),
        const Offset(42, 117),
      ]),
      [violet, blue],
    );
    face(
      c,
      polygon([
        const Offset(75, 94),
        const Offset(111, 73),
        const Offset(111, 117),
        const Offset(75, 137),
      ]),
      [blue, navy],
    );
    line(
      c,
      [const Offset(43, 74), const Offset(75, 94), const Offset(110, 74)],
      const Color(0xFFE2DAFF),
      2,
    );
    face(
      c,
      polygon([
        const Offset(128, 21),
        const Offset(92, 83),
        const Offset(158, 94),
      ]),
      [const Color(0xFFFFEA9D), gold],
    );
    face(
      c,
      polygon([
        const Offset(128, 21),
        const Offset(158, 94),
        const Offset(173, 78),
      ]),
      [gold, const Color(0xFFE09A1D)],
    );
    oval(c, const Rect.fromLTWH(105, 114, 51, 39), [
      const Color(0xFF9AEBC2),
      emerald,
      const Color(0xFF137C59),
    ]);
    c.restore();
  }

  void _robot(Canvas c) {
    line(c, [const Offset(100, 37), const Offset(100, 20)], navy, 5);
    oval(c, const Rect.fromLTWH(93, 10, 14, 14), [
      const Color(0xFFFFEB9F),
      gold,
    ]);
    rounded(c, const Rect.fromLTWH(61, 103, 78, 44), 15, [blue, navy]);
    rounded(c, const Rect.fromLTWH(66, 101, 68, 35), 12, [
      const Color(0xFFB3A1FF),
      violet,
    ]);
    rounded(c, const Rect.fromLTWH(43, 49, 15, 36), 7, [violet, navy]);
    rounded(c, const Rect.fromLTWH(142, 49, 15, 36), 7, [violet, navy]);
    rounded(c, const Rect.fromLTWH(52, 38, 96, 73), 23, [
      const Color(0xFFB6ABFF),
      blue,
      navy,
    ]);
    rounded(c, const Rect.fromLTWH(61, 46, 77, 52), 17, [
      const Color(0xFF222D67),
      const Color(0xFF101A44),
    ]);
    for (final x in [80.0, 119.0]) {
      oval(c, Rect.fromLTWH(x - 5, 61, 10, 15), [
        Colors.white,
        const Color(0xFF8DEAD7),
      ]);
    }
    c.drawArc(
      const Rect.fromLTWH(90, 73, 20, 13),
      .1,
      math.pi - .2,
      false,
      Paint()
        ..color = const Color(0xFF8DEAD7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    rounded(c, const Rect.fromLTWH(87, 114, 26, 8), 4, [
      const Color(0xFFFFEDAE),
      gold,
    ]);
    line(
      c,
      [const Offset(66, 42), const Offset(84, 40)],
      Colors.white.withValues(alpha: .65),
      3,
    );
  }

  void _bulb(Canvas c) {
    final halo = Paint()
      ..shader = RadialGradient(
        colors: [gold.withValues(alpha: .24), gold.withValues(alpha: 0)],
      ).createShader(const Rect.fromLTWH(20, 0, 160, 160));
    c.drawCircle(const Offset(100, 80), 80, halo);
    final bulb = Path()
      ..moveTo(78, 115)
      ..cubicTo(77, 97, 55, 92, 57, 64)
      ..cubicTo(60, 12, 139, 12, 143, 64)
      ..cubicTo(145, 92, 123, 97, 122, 115)
      ..close();
    face(c, bulb, [const Color(0xFFFFF3BB), gold, const Color(0xFFEAA42C)]);
    line(
      c,
      [
        const Offset(89, 113),
        const Offset(83, 74),
        const Offset(99, 85),
        const Offset(116, 72),
        const Offset(110, 113),
      ],
      const Color(0xFFFFFAE2),
      4,
    );
    for (var i = 0; i < 3; i++) {
      rounded(c, Rect.fromLTWH(78, 114 + i * 9, 44, 10), 4, [
        const Color(0xFFB9C3E1),
        const Color(0xFF53688E),
      ]);
    }
    rounded(c, const Rect.fromLTWH(88, 141, 24, 9), 4, [
      navy,
      const Color(0xFF142340),
    ]);
    line(
      c,
      [const Offset(70, 62), const Offset(74, 49), const Offset(82, 43)],
      Colors.white.withValues(alpha: .75),
      4,
    );
    line(c, [const Offset(42, 39), const Offset(32, 30)], gold, 3);
    line(c, [const Offset(157, 40), const Offset(167, 30)], gold, 3);
    line(c, [const Offset(100, 12), const Offset(100, 4)], gold, 3);
  }

  void _chance(Canvas c) {
    // Isometric die: each pip sits on its own face, not on a flat icon glyph.
    c.save();
    c.translate(-5, 10);
    c.rotate(-.08);
    face(
      c,
      polygon([
        const Offset(53, 72),
        const Offset(94, 52),
        const Offset(132, 77),
        const Offset(91, 99),
      ]),
      [const Color(0xFFAFBCFF), blue],
    );
    face(
      c,
      polygon([
        const Offset(53, 72),
        const Offset(91, 99),
        const Offset(91, 149),
        const Offset(53, 122),
      ]),
      [blue, navy],
    );
    face(
      c,
      polygon([
        const Offset(91, 99),
        const Offset(132, 77),
        const Offset(132, 128),
        const Offset(91, 149),
      ]),
      [const Color(0xFF98A8FF), const Color(0xFF6C7BF5)],
    );
    for (final p in [
      const Offset(64, 91),
      const Offset(79, 123),
      const Offset(64, 114),
      const Offset(79, 103),
    ]) {
      oval(c, Rect.fromCenter(center: p, width: 7, height: 10), [
        navy,
        const Color(0xFF162A81),
      ]);
    }
    for (final p in [
      const Offset(104, 108),
      const Offset(120, 99),
      const Offset(104, 131),
      const Offset(120, 122),
    ]) {
      oval(c, Rect.fromCenter(center: p, width: 8, height: 6), [blue, blue]);
    }
    oval(c, const Rect.fromLTWH(87, 69, 9, 6), [navy, navy]);
    c.restore();
    c.save();
    c.translate(132, 54);
    c.rotate(-.24);
    oval(c, const Rect.fromLTWH(-39, -30, 78, 71), [
      const Color(0xFFB98215),
      gold,
    ]);
    oval(c, const Rect.fromLTWH(-39, -36, 78, 71), [
      const Color(0xFFFFEC9D),
      gold,
    ]);
    c.drawOval(
      const Rect.fromLTWH(-32, -30, 64, 58),
      Paint()
        ..color = const Color(0xFFDAA323)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    sparkle(c, const Offset(0, -1), 20, const Color(0xFFFFF2AD));
    c.drawArc(
      const Rect.fromLTWH(-35, -32, 70, 63),
      3.4,
      1.8,
      false,
      Paint()
        ..color = const Color(0xFFFFF7D4)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  @override
  bool shouldRepaint(_SculptedTopicPainter oldDelegate) => oldDelegate.id != id;
}
