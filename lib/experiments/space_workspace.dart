import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'experiment_model.dart';
import 'solid_model.dart';
import 'space_guidance.dart';

bool supportsSpaceExperiment(String mechanism) =>
    mechanism == 'solidExplorer' ||
    mechanism == 'globeExplorer' ||
    mechanism == 'strataExplorer';

class SpaceWorkspace extends StatefulWidget {
  const SpaceWorkspace({
    super.key,
    required this.spec,
    required this.data,
    required this.locked,
    required this.onChanged,
  });
  final ExperimentSpec spec;
  final ExperimentData data;
  final bool locked;
  final ValueChanged<ExperimentData> onChanged;
  @override
  State<SpaceWorkspace> createState() => _SpaceWorkspaceState();
}

class _SpaceWorkspaceState extends State<SpaceWorkspace> {
  double yaw = -.55, pitch = .35;
  bool get globe => widget.spec.mechanism == 'globeExplorer';
  bool get strata => widget.spec.mechanism == 'strataExplorer';
  List<int> get layers {
    final raw = widget.data['layers'];
    return raw is List &&
            raw.length == 3 &&
            raw.toSet().length == 3 &&
            raw.every((v) => v is int && const [10, 20, 30].contains(v))
        ? raw.cast<int>()
        : [30, 10, 20];
  }

  void moveLayer(int from, int to) {
    if (widget.locked) return;
    final next = [...layers];
    final age = next.removeAt(from);
    next.insert(to, age);
    widget.onChanged({...widget.data, 'layers': next});
  }

  @override
  void didUpdateWidget(covariant SpaceWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.id != widget.spec.id) {
      yaw = -.55;
      pitch = .35;
    }
  }

  int number(String key, int fallback) =>
      widget.data[key] is int ? widget.data[key] as int : fallback;
  void change(String key, int value) {
    if (!widget.locked && widget.data[key] != value) {
      widget.onChanged({...widget.data, key: value});
    }
  }

  void rotate(double dx, double dy) => setState(() {
    yaw = (yaw + dx) % (math.pi * 2);
    pitch = (pitch + dy).clamp(-1.1, 1.1);
  });
  Widget control(String key, String label, int min, int max, int step) {
    final value = number(key, min).clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: $value${globe ? '°' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            IconButton(
              key: ValueKey('$key-less'),
              tooltip: 'Giảm $label',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.locked || value <= min
                  ? null
                  : () => change(key, value - step),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Slider(
                key: ValueKey('space-$key'),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min) ~/ step,
                value: value.toDouble(),
                label: '$value',
                onChanged: widget.locked
                    ? null
                    : (v) => change(key, (v / step).round() * step),
              ),
            ),
            IconButton(
              key: ValueKey('$key-more'),
              tooltip: 'Tăng $label',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: widget.locked || value >= max
                  ? null
                  : () => change(key, value + step),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = number('width', 2).clamp(1, 5);
    final h = number('height', 2).clamp(1, 5);
    final d = number('depth', 2).clamp(1, 5);
    final lat = number('latitude', 0).clamp(-90, 90);
    final lon = number('longitude', 0).clamp(-180, 180);
    final reference = solidReference(widget.data['comparisonReference']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrilliantPalette.border),
      ),
      child: Column(
        children: [
          Text(
            strata
                ? 'Mặt cắt • Lịch sử các lớp đá'
                : globe
                ? 'Quả địa cầu • Kinh tuyến & vĩ tuyến'
                : 'Xưởng khối • Chạm và khám phá',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final side = math.min(constraints.maxWidth, 300.0);
              return Center(
                child: Semantics(
                  image: true,
                  label: strata
                      ? 'Khối trầm tích. Tuổi các lớp từ trên xuống: ${layers.join(', ')} triệu năm'
                      : globe
                      ? 'Quả địa cầu, điểm chọn $lat độ vĩ, $lon độ kinh'
                      : 'Khối hộp dài $w, cao $h, sâu $d',
                  child: GestureDetector(
                    key: const ValueKey('space-scene'),
                    onPanUpdate: widget.locked
                        ? null
                        : (details) => rotate(
                            details.delta.dx * .012,
                            details.delta.dy * .012,
                          ),
                    onTapUp: !globe || widget.locked
                        ? null
                        : (details) {
                            final scale = side * .38;
                            final coords = globeCoordinates(
                              (details.localPosition.dx - side / 2) / scale,
                              (details.localPosition.dy - side / 2) / scale,
                              yaw,
                              pitch,
                            );
                            if (coords != null) {
                              widget.onChanged({
                                ...widget.data,
                                'latitude': coords[0],
                                'longitude': coords[1],
                              });
                            }
                          },
                    child: RepaintBoundary(
                      child: SizedBox.square(
                        dimension: side,
                        child: CustomPaint(
                          painter: _SpacePainter(
                            globe: globe,
                            yaw: yaw,
                            pitch: pitch,
                            width: w,
                            height: h,
                            depth: d,
                            latitude: lat,
                            longitude: lon,
                            layers: strata ? layers : const [],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Text(
            globe
                ? 'Kéo để xoay · Chạm để đặt điểm'
                : 'Kéo ngang/dọc để xoay khối',
            textAlign: TextAlign.center,
            style: const TextStyle(color: BrilliantPalette.secondaryText),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              IconButton(
                tooltip: 'Xoay trái',
                onPressed: widget.locked ? null : () => rotate(-.3, 0),
                icon: const Icon(Icons.rotate_left),
              ),
              IconButton(
                tooltip: 'Xoay phải',
                onPressed: widget.locked ? null : () => rotate(.3, 0),
                icon: const Icon(Icons.rotate_right),
              ),
              IconButton(
                tooltip: 'Nhìn từ trên',
                onPressed: widget.locked ? null : () => rotate(0, -.2),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: 'Nhìn từ dưới',
                onPressed: widget.locked ? null : () => rotate(0, .2),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              IconButton(
                tooltip: 'Đặt lại góc nhìn',
                onPressed: widget.locked
                    ? null
                    : () => setState(() {
                        yaw = -.55;
                        pitch = .35;
                      }),
                icon: const Icon(Icons.center_focus_strong),
              ),
            ],
          ),
          if (strata) ...[
            const Text(
              'Sắp thứ tự từ trên xuống',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            for (var i = 0; i < layers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Lớp ${i + 1}: ${layers[i]} triệu năm'),
                    ),
                    IconButton(
                      key: ValueKey('layer-$i-up'),
                      tooltip: 'Đưa lớp ${i + 1} lên',
                      onPressed: widget.locked || i == 0
                          ? null
                          : () => moveLayer(i, i - 1),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                    IconButton(
                      key: ValueKey('layer-$i-down'),
                      tooltip: 'Đưa lớp ${i + 1} xuống',
                      onPressed: widget.locked || i == 2
                          ? null
                          : () => moveLayer(i, i + 1),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                  ],
                ),
              ),
            const Text(
              'Mặt cắt minh họa; tuổi các lớp là dữ kiện giả định của bài.',
              textAlign: TextAlign.center,
            ),
          ] else if (globe) ...[
            OutlinedButton.icon(
              onPressed: widget.locked
                  ? null
                  : () => setState(() {
                      yaw = -lon * math.pi / 180;
                      pitch = (-lat * math.pi / 180).clamp(-1.1, 1.1);
                    }),
              icon: const Icon(Icons.location_searching),
              label: const Text('Nhìn tới điểm đã chọn'),
            ),
            control('latitude', 'Vĩ độ (Bắc + / Nam −)', -90, 90, 15),
            control('longitude', 'Kinh độ (Đông + / Tây −)', -180, 180, 15),
            const Text(
              'Đường đậm: xích đạo và kinh tuyến gốc.\nMô hình tọa độ giản lược, không thể hiện biên giới.',
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                Chip(label: Text('Thể tích: ${w * h * d} đv³')),
                Chip(label: Text('Bề mặt: ${2 * (w * h + w * d + h * d)} đv²')),
              ],
            ),
            control('width', 'Chiều dài', 1, 5, 1),
            control('height', 'Chiều cao', 1, 5, 1),
            control('depth', 'Chiều sâu', 1, 5, 1),
            const Divider(height: 28),
            const Text(
              'So sánh để tìm quy luật',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('save-solid-reference'),
                  onPressed: widget.locked || !validSolidState(widget.data)
                      ? null
                      : () {
                          widget.onChanged({
                            ...widget.data,
                            'comparisonReference': solidReference(widget.data)!,
                          });
                        },
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(
                    reference == null
                        ? 'Lưu mẫu so sánh'
                        : 'Thay mẫu bằng khối này',
                  ),
                ),
                if (reference != null)
                  TextButton(
                    key: const ValueKey('clear-solid-reference'),
                    onPressed: widget.locked
                        ? null
                        : () => widget.onChanged({
                            ...widget.data,
                            'comparisonReference': null,
                          }),
                    child: const Text('Bỏ mẫu'),
                  ),
              ],
            ),
            if (reference == null)
              const Text(
                'Lưu khối hiện tại, đổi một cạnh rồi so sánh với mẫu. Bạn có thể thay mẫu bất kỳ lúc nào.',
                textAlign: TextAlign.center,
              )
            else ...[
              Text(
                'Mẫu: dài ${reference['width']}, cao ${reference['height']}, sâu ${reference['depth']}\n'
                'V = ${solidVolume(reference)} đv³ · S = ${solidSurface(reference)} đv²',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  compareSolids(widget.data, reference),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SpacePainter extends CustomPainter {
  const _SpacePainter({
    required this.globe,
    required this.yaw,
    required this.pitch,
    required this.width,
    required this.height,
    required this.depth,
    required this.latitude,
    required this.longitude,
    this.layers = const [],
  });
  final bool globe;
  final double yaw, pitch;
  final int width, height, depth, latitude, longitude;
  final List<int> layers;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * .38;
    Offset pixel(Point3 p) => center + Offset(p.x, p.y) * scale;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, scale * 1.02),
        width: scale * 1.5,
        height: scale * .12,
      ),
      Paint()..color = ink.withValues(alpha: .06),
    );
    if (!globe) {
      final faces = layers.isNotEmpty
          ? geologicalFaces(layers, yaw, pitch)
          : SolidScene(
              width: width.toDouble(),
              height: height.toDouble(),
              depth: depth.toDouble(),
              yaw: yaw,
              pitch: pitch,
            ).project();
      for (final face in faces) {
        final path = Path()..addPolygon(face.points.map(pixel).toList(), true);
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.lerp(
              face.material == 0
                  ? BrilliantPalette.successInk
                  : const Color(0xFF514237),
              face.material == 10
                  ? const Color(0xFFF1DEBC)
                  : face.material == 20
                  ? const Color(0xFFCEB08B)
                  : face.material == 30
                  ? const Color(0xFF9B8170)
                  : BrilliantPalette.successSurface,
              face.shade,
            )!,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = face.material == 0
                ? BrilliantPalette.successInk
                : const Color(0xFF514237)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..strokeJoin = StrokeJoin.round,
        );
      }
      return;
    }
    final disk = Rect.fromCircle(center: center, radius: scale);
    canvas.drawCircle(
      center,
      scale,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.5),
          colors: [paper, BrilliantPalette.successSurface, Color(0xFF95D5A5)],
          stops: [0, .6, 1],
        ).createShader(disk),
    );
    void line(List<Point3> points, {bool major = false}) {
      final path = Path();
      var drawing = false;
      for (final world in points) {
        final p = world.rotate(yaw, pitch);
        if (p.z < 0) {
          drawing = false;
          continue;
        }
        final pos = pixel(p);
        if (drawing) {
          path.lineTo(pos.dx, pos.dy);
        } else {
          path.moveTo(pos.dx, pos.dy);
          drawing = true;
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = major
              ? BrilliantPalette.successInk
              : ink.withValues(alpha: .18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = major ? 1.8 : .8,
      );
    }

    for (var lat = -75; lat <= 75; lat += 15) {
      line([
        for (var lon = -180; lon <= 180; lon += 3)
          globePoint(lat.toDouble(), lon.toDouble()),
      ], major: lat == 0);
    }
    for (var lon = -180; lon < 180; lon += 15) {
      line([
        for (var lat = -90; lat <= 90; lat += 3)
          globePoint(lat.toDouble(), lon.toDouble()),
      ], major: lon == 0);
    }
    final marker = globePoint(
      latitude.toDouble(),
      longitude.toDouble(),
    ).rotate(yaw, pitch);
    if (marker.z >= 0) {
      canvas.drawCircle(pixel(marker), 9, Paint()..color = paper);
      canvas.drawCircle(pixel(marker), 6, Paint()..color = ink);
    }
    canvas.drawCircle(
      center,
      scale,
      Paint()
        ..color = BrilliantPalette.successInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SpacePainter old) =>
      old.layers.join(',') != layers.join(',') ||
      old.yaw != yaw ||
      old.pitch != pitch ||
      old.globe != globe ||
      old.width != width ||
      old.height != height ||
      old.depth != depth ||
      old.latitude != latitude ||
      old.longitude != longitude;
}
