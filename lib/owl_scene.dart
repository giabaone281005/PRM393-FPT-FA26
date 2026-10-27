import 'dart:math' as math;
import 'dart:ui';

class _Vector {
  const _Vector(this.x, this.y, this.z);
  final double x, y, z;
  _Vector operator +(_Vector b) => _Vector(x + b.x, y + b.y, z + b.z);
  _Vector operator *(double n) => _Vector(x * n, y * n, z * n);
  _Vector get normalized {
    final length = math.sqrt(x * x + y * y + z * z);
    return length == 0 ? this : this * (1 / length);
  }

  _Vector rotateZ(double angle) => _Vector(
    x * math.cos(angle) - y * math.sin(angle),
    x * math.sin(angle) + y * math.cos(angle),
    z,
  );
  _Vector rotate(double yaw, double pitch) {
    final rx = x * math.cos(yaw) + z * math.sin(yaw);
    final rz = -x * math.sin(yaw) + z * math.cos(yaw);
    return _Vector(
      rx,
      y * math.cos(pitch) - rz * math.sin(pitch),
      y * math.sin(pitch) + rz * math.cos(pitch),
    );
  }
}

class OwlFace {
  const OwlFace(this.points, this.depth, this.color);
  final List<Offset> points;
  final double depth;
  final Color color;
}

/// Native perspective-projected geometry, with depth sorting and lit surfaces.
/// Camera/pose are presentation state and never affect learning progress.
class OwlScene {
  const OwlScene({this.yaw = -.12, this.pitch = .08, this.reaction = 0});
  final double yaw, pitch, reaction;

  List<OwlFace> project(Size size) {
    if (!yaw.isFinite ||
        !pitch.isFinite ||
        !reaction.isFinite ||
        !size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return const [];
    }
    final faces = <OwlFace>[];
    final scale = math.min(size.width / 3.25, size.height / 3.8);
    final t = reaction.clamp(0.0, 1.0);
    final hop = math.sin(math.pi * t) * .10;
    final wave = math.sin(math.pi * t) * (.5 + .5 * math.sin(6 * math.pi * t));
    final blink = t > .26 && t < .42
        ? math.sin((t - .26) / .16 * math.pi)
        : 0.0;
    const light = _Vector(-.4, .65, .8);
    final lightDirection = light.normalized;

    void ellipsoid(
      _Vector center,
      _Vector radius,
      Color color, {
      double tilt = 0,
      int segments = 20,
      int rings = 12,
    }) {
      _Vector vertex(double lat, double lon) =>
          _Vector(
            radius.x * math.cos(lat) * math.cos(lon),
            radius.y * math.sin(lat),
            radius.z * math.cos(lat) * math.sin(lon),
          ).rotateZ(tilt) +
          center;
      _Vector camera(_Vector v) =>
          _Vector(v.x, v.y - .78 + hop, v.z).rotate(yaw, pitch);
      Offset screen(_Vector v) {
        final perspective = 7 / (7 - v.z);
        return Offset(
          size.width / 2 + v.x * scale * perspective,
          size.height * .53 - v.y * scale * perspective,
        );
      }

      for (var ring = 0; ring < rings; ring++) {
        final lat0 = -math.pi / 2 + math.pi * ring / rings;
        final lat1 = -math.pi / 2 + math.pi * (ring + 1) / rings;
        for (var slice = 0; slice < segments; slice++) {
          final lon0 = 2 * math.pi * slice / segments;
          final lon1 = 2 * math.pi * (slice + 1) / segments;
          final lat = (lat0 + lat1) / 2, lon = (lon0 + lon1) / 2;
          final normal = _Vector(
            math.cos(lat) * math.cos(lon) / radius.x,
            math.sin(lat) / radius.y,
            math.cos(lat) * math.sin(lon) / radius.z,
          ).rotateZ(tilt).rotate(yaw, pitch).normalized;
          if (normal.z <= -.02) continue;
          final diffuse = math.max(
            0.0,
            normal.x * lightDirection.x +
                normal.y * lightDirection.y +
                normal.z * lightDirection.z,
          );
          final gloss =
              math
                  .pow(
                    math.max(
                      0.0,
                      normal.x * -.18 + normal.y * .35 + normal.z * .92,
                    ),
                    22,
                  )
                  .toDouble() *
              .13;
          final shade = .58 + .42 * diffuse;
          double channel(double value) =>
              (value * shade + gloss).clamp(0.0, 1.0);
          final shaded = Color.from(
            alpha: 1,
            red: channel(color.r),
            green: channel(color.g),
            blue: channel(color.b),
          );
          final vertices = [
            camera(vertex(lat0, lon0)),
            camera(vertex(lat0, lon1)),
            camera(vertex(lat1, lon1)),
            camera(vertex(lat1, lon0)),
          ];
          faces.add(
            OwlFace(
              vertices.map(screen).toList(),
              vertices.fold<double>(0, (sum, v) => sum + v.z) / 4,
              shaded,
            ),
          );
        }
      }
    }

    const plumage = Color(0xFF4B9BBB), dark = Color(0xFF34758F);
    const cream = Color(0xFFFFF3D9), gold = Color(0xFFFFBC58);
    // Body, belly and a fully modeled back remain visible during a full orbit.
    ellipsoid(const _Vector(0, .39, 0), const _Vector(.72, .93, .54), plumage);
    ellipsoid(
      const _Vector(0, .29, .43),
      const _Vector(.49, .62, .19),
      const Color(0xFFD7EEE5),
    );
    for (final side in [-1.0, 1.0]) {
      ellipsoid(
        _Vector(side * .69, .40, .02),
        const _Vector(.22, .72, .32),
        dark,
        tilt: side * (.18 + (side > 0 ? wave * .95 : wave * .12)),
        segments: 16,
      );
      ellipsoid(
        _Vector(side * .32, -.50, .29),
        const _Vector(.22, .11, .27),
        gold,
        segments: 16,
        rings: 8,
      );
      for (var toe = -1; toe <= 1; toe++) {
        ellipsoid(
          _Vector(side * .32 + toe * .105, -.54, .47),
          const _Vector(.065, .065, .18),
          gold,
          segments: 10,
          rings: 6,
        );
      }
    }
    // Feather tufts, oversized head and cream facial disks.
    for (final side in [-1.0, 1.0]) {
      ellipsoid(
        _Vector(side * .57, 1.99, .01),
        const _Vector(.22, .43, .25),
        dark,
        tilt: -side * .39,
        segments: 16,
      );
    }
    ellipsoid(
      const _Vector(0, 1.42, .045),
      const _Vector(.86, .72, .60),
      plumage,
      segments: 28,
      rings: 18,
    );
    for (final side in [-1.0, 1.0]) {
      ellipsoid(
        _Vector(side * .34, 1.46, .535),
        const _Vector(.39, .43, .16),
        cream,
        segments: 24,
      );
      final eyeHeight = .235 * (1 - .90 * blink);
      ellipsoid(
        _Vector(side * .34, 1.51, .68),
        _Vector(.235, eyeHeight, .16),
        const Color(0xFFFFFFFF),
      );
      ellipsoid(
        _Vector(side * .34 + .015, 1.51, .81),
        _Vector(.125, .145 * (1 - .94 * blink), .075),
        const Color(0xFF203A4C),
        segments: 20,
      );
      if (blink < .7) {
        ellipsoid(
          _Vector(side * .34 - .025, 1.57, .876),
          const _Vector(.036, .043, .025),
          const Color(0xFFFFFFFF),
          segments: 10,
          rings: 8,
        );
      }
      ellipsoid(
        _Vector(side * .39, 1.18, .66),
        const _Vector(.12, .06, .018),
        const Color(0xFFF0B6A2),
        segments: 14,
        rings: 8,
      );
    }
    ellipsoid(
      const _Vector(0, 1.20, .74),
      const _Vector(.13, .19, .20),
      gold,
      segments: 12,
    );
    // A few raised chest feathers give the small silhouette tactile depth.
    for (var i = -1; i <= 1; i++) {
      ellipsoid(
        _Vector(i * .20, .36 - i.abs() * .10, .607),
        const _Vector(.075, .13, .027),
        const Color(0xFFB3D9D4),
        tilt: i * .14,
        segments: 10,
        rings: 8,
      );
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    return faces;
  }
}
