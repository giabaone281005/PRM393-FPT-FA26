import 'dart:convert';

import '../lib/experiments/solid_catalog.dart';
import '../lib/experiments/solid_model.dart';

void main() {
  var checks = 0;
  void check(bool condition, String message) {
    checks++;
    if (!condition) throw StateError(message);
  }

  final geometry = solidExperiments['geometry']!.single;
  final algebra = solidExperiments['algebra']!.single;
  for (var w = 1; w <= 5; w++) {
    for (var h = 1; h <= 5; h++) {
      for (var d = 1; d <= 5; d++) {
        final state = {'width': w, 'height': h, 'depth': d};
        final sorted = [w, h, d]..sort();
        check(
          geometry.isCorrect(state) == (sorted.join(',') == '2,2,3'),
          'Geometry constraints',
        );
        check(
          algebra.isCorrect(state) == (w == 4 && h == 2 && d == 2),
          'Algebra constraints',
        );
      }
    }
  }
  for (final spec in solidExperiments.values.expand((v) => v)) {
    check(!spec.isCorrect(spec.initialData()), 'Starts unsolved: ${spec.id}');
    check(!spec.isCorrect({}), 'Rejects missing fields: ${spec.id}');
  }
  final globe = solidExperiments['geography']!.firstWhere(
    (s) => s.mechanism == 'globeExplorer',
  );
  for (var lat = -90; lat <= 90; lat += 15) {
    for (var lon = -180; lon <= 180; lon += 15) {
      final state = jsonDecode(
        jsonEncode({'latitude': lat, 'longitude': lon}),
      ) as Map<String, dynamic>;
      check(
        globe.isCorrect(state) == (lat == 15 && lon == 105),
        'Globe target/restoration',
      );
    }
  }
  for (var yaw = -3.0; yaw <= 3; yaw += .3) {
    for (var pitch = -1.0; pitch <= 1; pitch += .4) {
      final faces = SolidScene(
        width: 5,
        height: 1,
        depth: 3,
        yaw: yaw,
        pitch: pitch,
      ).project();
      check(faces.length == 6, 'Six faces');
      for (var i = 0; i < faces.length; i++) {
        check(i == 0 || faces[i - 1].depth <= faces[i].depth, 'Depth order');
        for (final p in faces[i].points) {
          check(
            p.x.isFinite && p.y.isFinite && p.x.abs() <= 1 && p.y.abs() <= 1,
            'Projection bounds',
          );
        }
      }
      final layers = geologicalFaces([10, 20, 30], yaw, pitch);
      check(
        layers.length == 18 &&
            layers.map((f) => f.material).toSet().length == 3,
        'Layer materials',
      );
      for (var lat = -60; lat <= 60; lat += 15) {
        for (var lon = -165; lon <= 165; lon += 15) {
          final p = globePoint(
            lat.toDouble(),
            lon.toDouble(),
          ).rotate(yaw, pitch);
          if (p.z < .01) continue;
          final coords = globeCoordinates(p.x, p.y, yaw, pitch);
          check(
            coords != null && coords[0] == lat && coords[1] == lon,
            'Globe pick round trip',
          );
        }
      }
    }
  }
  final geology = solidExperiments['geography']!.firstWhere(
    (s) => s.mechanism == 'strataExplorer',
  );
  for (final a in [10, 20, 30]) {
    for (final b in [10, 20, 30]) {
      for (final c in [10, 20, 30]) {
        check(
          geology.isCorrect({
                'layers': [a, b, c],
              }) ==
              (a == 10 && b == 20 && c == 30),
          'Layer order',
        );
      }
    }
  }
  for (final invalid in [null, '2', 2.0, true, -1, 6]) {
    check(
      !geometry.isCorrect({'width': invalid, 'height': 2, 'depth': 3}),
      'Reject invalid dimensions',
    );
  }
  for (final invalid in [
    null,
    '10,20,30',
    [10.0, 20, 30],
    [10, 20],
    [10, 20, 30, 40],
  ]) {
    check(
      !geology.isCorrect({'layers': invalid}),
      'Reject invalid layer types',
    );
  }
  check(globeCoordinates(1.1, 0, 0, 0) == null, 'Ignore tap outside sphere');
  check((globePoint(0, 90).x - 1).abs() < 1e-9, 'East orientation');
  check((globePoint(90, 0).y + 1).abs() < 1e-9, 'North orientation');
  print(
    '$checks checks passed: solid constraints, layers, camera projection, globe picking and restoration.',
  );
}
