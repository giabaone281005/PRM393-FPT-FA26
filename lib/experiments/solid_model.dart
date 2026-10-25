import 'dart:math' as math;

/// Small, dependency-free mesh engine for convex teaching solids.
/// Camera is at positive Z. Faces are emitted back-to-front for Canvas painting.
class Point3 {
  const Point3(this.x, this.y, this.z);
  final double x, y, z;

  Point3 rotate(double yaw, double pitch) {
    final rx = x * math.cos(yaw) + z * math.sin(yaw);
    final rz = -x * math.sin(yaw) + z * math.cos(yaw);
    return Point3(
      rx,
      y * math.cos(pitch) - rz * math.sin(pitch),
      y * math.sin(pitch) + rz * math.cos(pitch),
    );
  }
}

class ProjectedFace {
  const ProjectedFace(this.points, this.depth, this.shade, {this.material = 0});
  final List<Point3> points;
  final double depth, shade;
  final int material;
}

class SolidScene {
  const SolidScene({
    required this.width,
    required this.height,
    required this.depth,
    this.yaw = -.55,
    this.pitch = .35,
    this.centerY = 0,
    this.normalizationRadius,
  });
  final double width, height, depth, yaw, pitch;
  final double centerY;
  final double? normalizationRadius;

  /// Normalized coordinates remain inside [-1, 1] under all camera rotations.
  List<ProjectedFace> project() {
    final extentY = height + 2 * centerY.abs();
    final requiredRadius = math.sqrt(
      width * width + extentY * extentY + depth * depth,
    );
    final radius = normalizationRadius ?? requiredRadius;
    if (!radius.isFinite ||
        radius <= 0 ||
        radius + 1e-9 < requiredRadius ||
        !width.isFinite ||
        !height.isFinite ||
        !depth.isFinite ||
        width <= 0 ||
        height <= 0 ||
        depth <= 0 ||
        !yaw.isFinite ||
        !pitch.isFinite ||
        !centerY.isFinite) {
      throw ArgumentError(
        'Solid dimensions and camera must be finite and valid',
      );
    }
    final vertices = [
      for (final z in [-1, 1])
        for (final y in [-1, 1])
          for (final x in [-1, 1])
            Point3(
              x * width / radius,
              (y * height + 2 * centerY) / radius,
              z * depth / radius,
            ).rotate(yaw, pitch),
    ];
    const indices = [
      [0, 1, 3, 2],
      [4, 6, 7, 5],
      [0, 4, 5, 1],
      [2, 3, 7, 6],
      [0, 2, 6, 4],
      [1, 5, 7, 3],
    ];
    final faces = <ProjectedFace>[];
    for (var index = 0; index < indices.length; index++) {
      final points = [for (final i in indices[index]) vertices[i]];
      faces.add(
        ProjectedFace(
          [
            for (final p in points)
              Point3(p.x * 3 / (4 - p.z), p.y * 3 / (4 - p.z), p.z),
          ],
          points.fold<double>(0, (total, p) => total + p.z) / 4,
          const [.74, .95, .82, 1.0, .68, .88][index],
        ),
      );
    }
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    return faces;
  }
}

/// No camera gesture or cached UI flag can satisfy a lesson constraint.
bool validSolidState(Map<String, dynamic> data) => [
  'width',
  'height',
  'depth',
].every((key) => data[key] is int && data[key] >= 1 && data[key] <= 5);

/// A validated value copy, independent of the mutable learner draft.
Map<String, int>? solidReference(dynamic raw) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) return null;
  final candidate = Map<String, dynamic>.from(raw);
  if (!validSolidState(candidate)) return null;
  return Map<String, int>.unmodifiable({
    for (final key in ['width', 'height', 'depth']) key: candidate[key] as int,
  });
}

int solidVolume(Map<String, dynamic> data) =>
    (data['width'] as int) * (data['height'] as int) * (data['depth'] as int);

int solidSurface(Map<String, dynamic> data) {
  final w = data['width'] as int;
  final h = data['height'] as int;
  final d = data['depth'] as int;
  return 2 * (w * h + w * d + h * d);
}

/// Geographic sphere: prime meridian faces the camera at zero rotation.
Point3 globePoint(double latitude, double longitude) {
  final lat = latitude * math.pi / 180;
  final lon = longitude * math.pi / 180;
  return Point3(
    math.cos(lat) * math.sin(lon),
    -math.sin(lat),
    math.cos(lat) * math.cos(lon),
  );
}

List<ProjectedFace> geologicalFaces(List<int> ages, double yaw, double pitch) {
  if (ages.length != 3 ||
      ages.toSet().length != 3 ||
      !ages.every((age) => const [10, 20, 30].contains(age))) {
    throw ArgumentError('Expected three distinct teaching layers');
  }
  final faces = <ProjectedFace>[];
  for (var layer = 0; layer < ages.length; layer++) {
    for (final face in SolidScene(
      width: 3,
      height: .65,
      depth: 2,
      centerY: (layer - 1) * .65,
      normalizationRadius: 4.1,
      yaw: yaw,
      pitch: pitch,
    ).project()) {
      faces.add(
        ProjectedFace(
          face.points,
          face.depth,
          face.shade,
          material: ages[layer],
        ),
      );
    }
  }
  faces.sort((a, b) => a.depth.compareTo(b.depth));
  return faces;
}

bool validLayerOrder(dynamic value) =>
    value is List &&
    value.length == 3 &&
    value.every((v) => v is int) &&
    value[0] == 10 &&
    value[1] == 20 &&
    value[2] == 30;

/// Inverse orthographic projection for selecting the visible hemisphere.
List<int>? globeCoordinates(double x, double y, double yaw, double pitch) {
  final radius = x * x + y * y;
  if (radius > 1) return null;
  final p = Point3(x, y, math.sqrt(1 - radius));
  final undoPitch = Point3(
    p.x,
    p.y * math.cos(pitch) + p.z * math.sin(pitch),
    -p.y * math.sin(pitch) + p.z * math.cos(pitch),
  );
  final world = undoPitch.rotate(-yaw, 0);
  return [
    (-math.asin(world.y.clamp(-1, 1)) * 180 / math.pi / 15).round() * 15,
    (math.atan2(world.x, world.z) * 180 / math.pi / 15).round() * 15,
  ];
}
