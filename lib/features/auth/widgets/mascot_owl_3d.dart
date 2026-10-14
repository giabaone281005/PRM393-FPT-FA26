import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MascotState {
  idle,
  typingEmail,
  typingPassword,
  tapped,
  celebrate,
}

class MascotOwl3D extends StatefulWidget {
  final MascotState state;
  final VoidCallback? onTap;
  final double size;
  final String? hat; // 'Mũ Thám Tử', 'Mũ Bác Học', 'Mũ Phù Thủy', 'Vương Miện', 'Không đội'
  final String? glasses; // 'Kính Tri Thức', 'Kính Ngôi Sao', 'Kính Thám Tử', 'Không đeo'
  final String? wings; // 'Cánh Hào Quang', 'Không có'

  const MascotOwl3D({
    super.key,
    this.state = MascotState.idle,
    this.onTap,
    this.size = 110,
    this.hat,
    this.glasses,
    this.wings,
  });

  @override
  State<MascotOwl3D> createState() => _MascotOwl3DState();
}

class _MascotOwl3DState extends State<MascotOwl3D>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _breatheAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _breatheAnim = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutSine),
    );

    _rotateAnim = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (context, child) {
          final isTapped = widget.state == MascotState.tapped;
          final isCelebrating = widget.state == MascotState.celebrate;
          final isPeeking = widget.state == MascotState.typingEmail;

          double translateY = _breatheAnim.value;
          double rotation = _rotateAnim.value;
          double scale = 1.0;

          if (isTapped) {
            scale = 1.08;
            translateY = -8;
          } else if (isCelebrating) {
            translateY = -12 + math.sin(_animCtrl.value * math.pi * 4) * 4;
            rotation = math.sin(_animCtrl.value * math.pi * 4) * 0.1;
          } else if (isPeeking) {
            rotation = 0.08;
            translateY = -2;
          }

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Claymorphism Drop Shadow (Soft 3D floor shadow)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: widget.size * 0.65,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 3D Clay Painted Owl with dynamic gear
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _ClayOwlPainter(
                          state: widget.state,
                          animProgress: _animCtrl.value,
                          hat: widget.hat,
                          glasses: widget.glasses,
                          wings: widget.wings,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClayOwlPainter extends CustomPainter {
  final MascotState state;
  final double animProgress;
  final String? hat;
  final String? glasses;
  final String? wings;

  _ClayOwlPainter({
    required this.state,
    required this.animProgress,
    this.hat,
    this.glasses,
    this.wings,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // ================= 0. AURA WINGS (CÁNH HÀO QUANG NẾU CÓ) =================
    final hasWings = wings != null && (wings!.contains('Cánh') || wings!.contains('Hào Quang'));
    if (hasWings) {
      final glowPaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x8038BDF8), Color(0x0038BDF8)],
        ).createShader(Rect.fromCircle(center: center, radius: w * 0.55));
      canvas.drawCircle(center, w * 0.55, glowPaint);

      // Angel / Aura Clay Wings behind body
      final angelWingPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBAE6FD), Color(0xFF38BDF8)],
        ).createShader(Rect.fromLTWH(0, 0, w, h));

      // Left angel wing
      final leftAngel = Path()
        ..moveTo(w * 0.25, h * 0.5)
        ..cubicTo(w * 0.05, h * 0.35, w * -0.05, h * 0.15, w * 0.05, h * 0.05)
        ..cubicTo(w * 0.15, h * 0.18, w * 0.12, h * 0.35, w * 0.28, h * 0.45)
        ..close();
      canvas.drawPath(leftAngel, angelWingPaint);

      // Right angel wing
      final rightAngel = Path()
        ..moveTo(w * 0.75, h * 0.5)
        ..cubicTo(w * 0.95, h * 0.35, w * 1.05, h * 0.15, w * 0.95, h * 0.05)
        ..cubicTo(w * 0.85, h * 0.18, w * 0.88, h * 0.35, w * 0.72, h * 0.45)
        ..close();
      canvas.drawPath(rightAngel, angelWingPaint);
    }

    // ================= 1. FEET (3D Rounded Claws) =================
    final feetPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ).createShader(Rect.fromLTWH(0, h * 0.82, w, h * 0.15));

    final feetShadow = Paint()
      ..color = const Color(0xFFB45309)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Left claw
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.38, h * 0.89), width: w * 0.2, height: h * 0.1),
        const Radius.circular(8),
      ),
      feetShadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.38, h * 0.88), width: w * 0.2, height: h * 0.1),
        const Radius.circular(8),
      ),
      feetPaint,
    );

    // Right claw
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.62, h * 0.89), width: w * 0.2, height: h * 0.1),
        const Radius.circular(8),
      ),
      feetShadow,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.62, h * 0.88), width: w * 0.2, height: h * 0.1),
        const Radius.circular(8),
      ),
      feetPaint,
    );

    // ================= 2. EARS / TUFTS =================
    final earPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 0.9,
        colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Left ear tuft
    final leftEarPath = Path()
      ..moveTo(w * 0.22, h * 0.35)
      ..lineTo(w * 0.15, h * 0.12)
      ..quadraticBezierTo(w * 0.30, h * 0.16, w * 0.38, h * 0.25)
      ..close();
    canvas.drawPath(leftEarPath, earPaint);

    // Right ear tuft
    final rightEarPath = Path()
      ..moveTo(w * 0.78, h * 0.35)
      ..lineTo(w * 0.85, h * 0.12)
      ..quadraticBezierTo(w * 0.70, h * 0.16, w * 0.62, h * 0.25)
      ..close();
    canvas.drawPath(rightEarPath, earPaint);

    // ================= 3. 3D CLAY BODY =================
    final bodyRect = Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: w * 0.76, height: h * 0.76);
    
    // Clay outer shadow
    final bodyShadow = Paint()
      ..color = const Color(0xFF3B0764).withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(bodyRect.translate(0, 4), bodyShadow);

    // Clay body gradient (Soft 3D purple sphere)
    final bodyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.25, -0.35),
        radius: 0.85,
        colors: [
          Color(0xFFA78BFA), // Highlight top-left
          Color(0xFF7C3AED), // Midtone
          Color(0xFF5B21B6), // Deep shadow bottom-right
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // ================= 4. BELLY (Soft cream clay patch) =================
    final bellyRect = Rect.fromCenter(center: Offset(center.dx, center.dy + h * 0.14), width: w * 0.48, height: h * 0.44);
    final bellyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.3),
        radius: 0.8,
        colors: [Color(0xFFFFFBEB), Color(0xFFFDE68A)],
      ).createShader(bellyRect);
    canvas.drawOval(bellyRect, bellyPaint);

    // Belly subtle feather speckles
    final featherPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fY1 = bellyRect.center.dy - 6;
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.44, fY1), width: 12, height: 8), 0.2, math.pi * 0.8, false, featherPaint);
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.56, fY1), width: 12, height: 8), 0.2, math.pi * 0.8, false, featherPaint);
    final fY2 = bellyRect.center.dy + 10;
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, fY2), width: 14, height: 8), 0.2, math.pi * 0.8, false, featherPaint);

    // ================= 5. EYES / GLASSES =================
    final leftEyeCenter = Offset(w * 0.36, h * 0.40);
    final rightEyeCenter = Offset(w * 0.64, h * 0.40);
    final eyeRadius = w * 0.16;

    // Eye sockets (Deep white clay circles with bevel)
    final eyeSocketPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        radius: 0.8,
        colors: [Colors.white, const Color(0xFFF1F5F9)],
      ).createShader(Rect.fromCircle(center: leftEyeCenter, radius: eyeRadius));

    final eyeSocketShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(leftEyeCenter.translate(0, 1.5), eyeRadius, eyeSocketShadow);
    canvas.drawCircle(leftEyeCenter, eyeRadius, eyeSocketPaint);

    canvas.drawCircle(rightEyeCenter.translate(0, 1.5), eyeRadius, eyeSocketShadow);
    canvas.drawCircle(rightEyeCenter, eyeRadius, eyeSocketPaint);

    // EYES BEHAVIOR BASED ON STATE
    if (state == MascotState.typingPassword) {
      final closedEyePaint = Paint()
        ..color = const Color(0xFF1E1B4B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCenter(center: Offset(leftEyeCenter.dx, leftEyeCenter.dy + 2), width: eyeRadius * 1.2, height: eyeRadius * 0.8),
        0.1, math.pi * 0.8, false, closedEyePaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(rightEyeCenter.dx, rightEyeCenter.dy + 2), width: eyeRadius * 1.2, height: eyeRadius * 0.8),
        0.1, math.pi * 0.8, false, closedEyePaint,
      );
    } else {
      double pupilOffsetX = 0;
      double pupilOffsetY = 0;

      if (state == MascotState.typingEmail) {
        pupilOffsetX = 3.0;
        pupilOffsetY = 4.0;
      } else if (state == MascotState.tapped) {
        pupilOffsetY = -2.0;
      }

      final pupilRadius = eyeRadius * 0.55;
      final pupilPaint = Paint()..color = const Color(0xFF1E1B4B);

      // Left Pupil
      final lPupilCenter = Offset(leftEyeCenter.dx + pupilOffsetX, leftEyeCenter.dy + pupilOffsetY);
      canvas.drawCircle(lPupilCenter, pupilRadius, pupilPaint);
      final irisRingPaint = Paint()
        ..color = const Color(0xFF06B6D4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawCircle(lPupilCenter, pupilRadius - 1, irisRingPaint);
      canvas.drawCircle(Offset(lPupilCenter.dx - pupilRadius * 0.35, lPupilCenter.dy - pupilRadius * 0.35), pupilRadius * 0.35, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(lPupilCenter.dx + pupilRadius * 0.25, lPupilCenter.dy + pupilRadius * 0.25), pupilRadius * 0.16, Paint()..color = Colors.white);

      // Right Pupil
      final rPupilCenter = Offset(rightEyeCenter.dx + pupilOffsetX, rightEyeCenter.dy + pupilOffsetY);
      canvas.drawCircle(rPupilCenter, pupilRadius, pupilPaint);
      canvas.drawCircle(rPupilCenter, pupilRadius - 1, irisRingPaint);
      canvas.drawCircle(Offset(rPupilCenter.dx - pupilRadius * 0.35, rPupilCenter.dy - pupilRadius * 0.35), pupilRadius * 0.35, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(rPupilCenter.dx + pupilRadius * 0.25, rPupilCenter.dy + pupilRadius * 0.25), pupilRadius * 0.16, Paint()..color = Colors.white);
    }

    // ================= 6. BEAK (Chunky 3D Orange Cone) =================
    final beakCenter = Offset(w * 0.5, h * 0.49);
    final beakPath = Path()
      ..moveTo(beakCenter.dx - 8, beakCenter.dy - 3)
      ..lineTo(beakCenter.dx + 8, beakCenter.dy - 3)
      ..lineTo(beakCenter.dx, beakCenter.dy + 12)
      ..close();

    final beakPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF97316), Color(0xFFC2410C)],
      ).createShader(Rect.fromCircle(center: beakCenter, radius: 12));

    canvas.drawPath(beakPath, beakPaint);
    canvas.drawCircle(Offset(beakCenter.dx, beakCenter.dy + 1), 2.2, Paint()..color = Colors.white.withValues(alpha: 0.6));

    // ================= 7. WINGS (Left & Right 3D Clay flaps) =================
    final wingPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Left Wing
    final leftWingPath = Path()
      ..moveTo(w * 0.14, h * 0.48)
      ..quadraticBezierTo(w * 0.04, h * 0.62, w * 0.18, h * 0.74)
      ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.22, h * 0.50)
      ..close();
    canvas.drawPath(leftWingPath, wingPaint);

    // Right Wing
    final rightWingPath = Path()
      ..moveTo(w * 0.86, h * 0.48)
      ..quadraticBezierTo(w * 0.96, h * 0.62, w * 0.82, h * 0.74)
      ..quadraticBezierTo(w * 0.75, h * 0.62, w * 0.78, h * 0.50)
      ..close();
    canvas.drawPath(rightWingPath, wingPaint);

    // ================= 8. DYNAMIC GLASSES (KÍNH ĐEO) =================
    _drawGlasses(canvas, size, leftEyeCenter, rightEyeCenter, eyeRadius);

    // ================= 9. DYNAMIC HAT (MŨ ĐỘI) =================
    _drawHat(canvas, size);
  }

  void _drawGlasses(Canvas canvas, Size size, Offset leftEyeCenter, Offset rightEyeCenter, double eyeRadius) {
    if (glasses == null || glasses == 'Không đeo') return;

    if (glasses!.contains('Kính Tri Thức') || glasses!.contains('Kính Tròn')) {
      // Round Academic Glasses (Vintage tortoiseshell / dark wire)
      final framePaint = Paint()
        ..color = const Color(0xFF78350F) // Warm brown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6;

      final bridgePaint = Paint()
        ..color = const Color(0xFFB45309)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      // Left glass frame
      canvas.drawCircle(leftEyeCenter, eyeRadius * 1.05, framePaint);
      // Right glass frame
      canvas.drawCircle(rightEyeCenter, eyeRadius * 1.05, framePaint);
      // Nose bridge
      final bridgePath = Path()
        ..moveTo(leftEyeCenter.dx + eyeRadius * 0.9, leftEyeCenter.dy - 2)
        ..quadraticBezierTo(size.width * 0.5, leftEyeCenter.dy - 8, rightEyeCenter.dx - eyeRadius * 0.9, rightEyeCenter.dy - 2);
      canvas.drawPath(bridgePath, bridgePaint);

      // Glass lens reflection highlight
      final glarePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(leftEyeCenter.dx - eyeRadius * 0.5, leftEyeCenter.dy - eyeRadius * 0.5),
        Offset(leftEyeCenter.dx - eyeRadius * 0.1, leftEyeCenter.dy - eyeRadius * 0.7),
        glarePaint,
      );
      canvas.drawLine(
        Offset(rightEyeCenter.dx - eyeRadius * 0.5, rightEyeCenter.dy - eyeRadius * 0.5),
        Offset(rightEyeCenter.dx - eyeRadius * 0.1, rightEyeCenter.dy - eyeRadius * 0.7),
        glarePaint,
      );
    } else if (glasses!.contains('Kính Ngôi Sao') || glasses!.contains('Kính Mát')) {
      // Star sunglasses
      final starPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.fill;
      final starBorder = Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      _drawStar(canvas, leftEyeCenter, eyeRadius * 1.15, starPaint, starBorder);
      _drawStar(canvas, rightEyeCenter, eyeRadius * 1.15, starPaint, starBorder);

      // Bridge
      canvas.drawLine(
        Offset(leftEyeCenter.dx + eyeRadius * 0.7, leftEyeCenter.dy),
        Offset(rightEyeCenter.dx - eyeRadius * 0.7, rightEyeCenter.dy),
        starBorder,
      );
    } else if (glasses!.contains('Kính Thám Tử')) {
      // Monocle on right eye
      final monoclePaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawCircle(rightEyeCenter, eyeRadius * 1.08, monoclePaint);
      // Gold chain down
      final chainPaint = Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      final chainPath = Path()
        ..moveTo(rightEyeCenter.dx + eyeRadius, rightEyeCenter.dy)
        ..quadraticBezierTo(size.width * 0.85, size.height * 0.65, size.width * 0.75, size.height * 0.75);
      canvas.drawPath(chainPath, chainPaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint fillPaint, Paint borderPaint) {
    final path = Path();
    const int points = 5;
    final double innerRadius = radius * 0.5;
    double rot = -math.pi / 2;
    final double step = math.pi / points;

    for (int i = 0; i < points; i++) {
      final x1 = center.dx + math.cos(rot) * radius;
      final y1 = center.dy + math.sin(rot) * radius;
      if (i == 0) {
        path.moveTo(x1, y1);
      } else {
        path.lineTo(x1, y1);
      }
      rot += step;
      final x2 = center.dx + math.cos(rot) * innerRadius;
      final y2 = center.dy + math.sin(rot) * innerRadius;
      path.lineTo(x2, y2);
      rot += step;
    }
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawHat(Canvas canvas, Size size) {
    if (hat == null || hat == 'Không đội') return;
    final w = size.width;
    final h = size.height;

    if (hat!.contains('Thám Tử')) {
      // 🕵️ Detective Sherlock Holmes Deerstalker Hat (Classic Brown Checked clay)
      final hatPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB45309), Color(0xFF78350F)],
        ).createShader(Rect.fromLTWH(w * 0.15, h * 0.05, w * 0.7, h * 0.3));

      // Hat dome
      final domePath = Path()
        ..moveTo(w * 0.22, h * 0.26)
        ..cubicTo(w * 0.20, h * 0.04, w * 0.80, h * 0.04, w * 0.78, h * 0.26)
        ..close();
      canvas.drawPath(domePath, hatPaint);

      // Hat Brim
      final brimPaint = Paint()..color = const Color(0xFF92400E);
      final brimRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.25), width: w * 0.74, height: h * 0.09);
      canvas.drawRRect(RRect.fromRectAndRadius(brimRect, const Radius.circular(8)), brimPaint);

      // Ribbon ribbon bow
      final ribbonPaint = Paint()..color = const Color(0xFFD97706);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.5, h * 0.22), width: w * 0.45, height: h * 0.04), const Radius.circular(4)),
        ribbonPaint,
      );
      // Top button
      canvas.drawCircle(Offset(w * 0.5, h * 0.06), 4.5, Paint()..color = const Color(0xFF78350F));

    } else if (hat!.contains('Bác Học') || hat!.contains('Cử Nhân') || hat!.contains('Thủ Khoa')) {
      // 🎓 Academic Mortarboard Graduation Cap
      final capPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ).createShader(Rect.fromLTWH(w * 0.1, 0, w * 0.8, h * 0.3));

      // Diamond Top
      final diamondPath = Path()
        ..moveTo(w * 0.5, h * 0.02)
        ..lineTo(w * 0.88, h * 0.14)
        ..lineTo(w * 0.5, h * 0.24)
        ..lineTo(w * 0.12, h * 0.14)
        ..close();
      canvas.drawPath(diamondPath, capPaint);

      // Skull cap base
      final basePaint = Paint()..color = const Color(0xFF0F172A);
      final basePath = Path()
        ..moveTo(w * 0.32, h * 0.19)
        ..lineTo(w * 0.68, h * 0.19)
        ..lineTo(w * 0.64, h * 0.27)
        ..lineTo(w * 0.36, h * 0.27)
        ..close();
      canvas.drawPath(basePath, basePaint);

      // Gold Tassel & button
      canvas.drawCircle(Offset(w * 0.5, h * 0.13), 3.5, Paint()..color = const Color(0xFFFBBF24));
      final tasselPaint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      final tasselPath = Path()
        ..moveTo(w * 0.5, h * 0.13)
        ..lineTo(w * 0.78, h * 0.18)
        ..lineTo(w * 0.82, h * 0.32);
      canvas.drawPath(tasselPath, tasselPaint);
      canvas.drawCircle(Offset(w * 0.82, h * 0.33), 4, Paint()..color = const Color(0xFFD97706));

    } else if (hat!.contains('Phù Thủy') || hat!.contains('Áo Choàng')) {
      // 🧙 Wizard Conical Hat
      final wizPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4338CA), Color(0xFF312E81)],
        ).createShader(Rect.fromLTWH(w * 0.1, 0, w * 0.8, h * 0.3));

      // Cone with curved tip
      final conePath = Path()
        ..moveTo(w * 0.25, h * 0.25)
        ..quadraticBezierTo(w * 0.42, h * 0.08, w * 0.72, h * 0.02)
        ..quadraticBezierTo(w * 0.58, h * 0.12, w * 0.75, h * 0.25)
        ..close();
      canvas.drawPath(conePath, wizPaint);

      // Wide Brim
      final brimPaint = Paint()..color = const Color(0xFF3730A3);
      final brimRect = Rect.fromCenter(center: Offset(w * 0.5, h * 0.25), width: w * 0.78, height: h * 0.08);
      canvas.drawOval(brimRect, brimPaint);

      // Yellow Star patch on hat
      _drawStar(canvas, Offset(w * 0.48, h * 0.16), 6.0, Paint()..color = const Color(0xFFFBBF24), Paint()..color = const Color(0xFFD97706)..strokeWidth = 1..style = PaintingStyle.stroke);

    } else if (hat!.contains('Vương Miện')) {
      // 👑 Gold Royal Crown
      final crownPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
        ).createShader(Rect.fromLTWH(w * 0.2, h * 0.08, w * 0.6, h * 0.2));

      final crownPath = Path()
        ..moveTo(w * 0.25, h * 0.25)
        ..lineTo(w * 0.22, h * 0.12)
        ..lineTo(w * 0.36, h * 0.18)
        ..lineTo(w * 0.50, h * 0.08)
        ..lineTo(w * 0.64, h * 0.18)
        ..lineTo(w * 0.78, h * 0.12)
        ..lineTo(w * 0.75, h * 0.25)
        ..close();
      canvas.drawPath(crownPath, crownPaint);

      // Ruby gemstones
      canvas.drawCircle(Offset(w * 0.5, h * 0.20), 3.5, Paint()..color = const Color(0xFFEF4444));
      canvas.drawCircle(Offset(w * 0.34, h * 0.22), 2.8, Paint()..color = const Color(0xFF3B82F6));
      canvas.drawCircle(Offset(w * 0.66, h * 0.22), 2.8, Paint()..color = const Color(0xFF10B981));
    }
  }

  @override
  bool shouldRepaint(covariant _ClayOwlPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.animProgress != animProgress ||
        oldDelegate.hat != hat ||
        oldDelegate.glasses != glasses ||
        oldDelegate.wings != wings;
  }
}
