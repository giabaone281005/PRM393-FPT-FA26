import 'package:flutter/material.dart';

import '../../app_layout.dart';
import '../../data/models/learning_modules.dart';

/// Controlled canvas: callers own the document and decide when to save/send it.
class SharedCanvas extends StatefulWidget {
  const SharedCanvas({
    super.key,
    required this.document,
    required this.onChanged,
  });
  final SharedCanvasDocument document;
  final ValueChanged<SharedCanvasDocument> onChanged;
  @override
  State<SharedCanvas> createState() => _SharedCanvasState();
}

class _SharedCanvasState extends State<SharedCanvas> {
  bool _drawing = false;
  SharedCanvasDocument get document => widget.document;
  void onChanged(SharedCanvasDocument value) => widget.onChanged(value);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Bảng cùng khám phá',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            tooltip: 'Hoàn tác nét vẽ',
            onPressed: document.strokes.isEmpty
                ? null
                : () => onChanged(
                    SharedCanvasDocument(
                      strokes: document.strokes.sublist(
                        0,
                        document.strokes.length - 1,
                      ),
                      overlays: document.overlays,
                    ),
                  ),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Xóa nét vẽ',
            onPressed: document.strokes.isEmpty
                ? null
                : () => onChanged(
                    SharedCanvasDocument(overlays: document.overlays),
                  ),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      AspectRatio(
        aspectRatio: 4 / 3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            CanvasPoint point(Offset position) => CanvasPoint(
              (position.dx / constraints.maxWidth).clamp(0, 1),
              (position.dy / constraints.maxHeight).clamp(0, 1),
            );
            return Semantics(
              label: 'Bảng vẽ tương tác. Kéo để vẽ, dùng nút hoàn tác để sửa.',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppLayout.tileRadius),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    _drawing = document.strokes.length < 100;
                    if (!_drawing) return;
                    onChanged(
                      SharedCanvasDocument(
                        strokes: [
                          ...document.strokes,
                          CanvasStroke([point(details.localPosition)]),
                        ],
                        overlays: document.overlays,
                      ),
                    );
                  },
                  onPanUpdate: (details) {
                    if (!_drawing ||
                        document.strokes.isEmpty ||
                        document.strokes.last.points.length >= 2000) {
                      return;
                    }
                    onChanged(
                      SharedCanvasDocument(
                        strokes: [
                          ...document.strokes.take(document.strokes.length - 1),
                          CanvasStroke([
                            ...document.strokes.last.points,
                            point(details.localPosition),
                          ]),
                        ],
                        overlays: document.overlays,
                      ),
                    );
                  },
                  onPanEnd: (_) => _drawing = false,
                  onPanCancel: () => _drawing = false,
                  child: CustomPaint(
                    painter: _CanvasPainter(
                      document,
                      Theme.of(context).colorScheme,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter(this.document, this.colors);
  final SharedCanvasDocument document;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.surfaceContainerLowest,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = colors.outlineVariant
        ..style = PaintingStyle.stroke,
    );
    Offset offset(CanvasPoint point) =>
        Offset(point.x * size.width, point.y * size.height);
    final pen = Paint()
      ..color = colors.onSurface
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in document.strokes) {
      if (stroke.points.isEmpty) continue;
      if (stroke.points.length == 1) {
        canvas.drawCircle(
          offset(stroke.points.first),
          1.5,
          Paint()..color = colors.onSurface,
        );
        continue;
      }
      final path = Path()
        ..moveTo(
          offset(stroke.points.first).dx,
          offset(stroke.points.first).dy,
        );
      for (final point in stroke.points.skip(1)) {
        path.lineTo(offset(point).dx, offset(point).dy);
      }
      canvas.drawPath(path, pen);
    }
    for (final overlay in document.overlays) {
      final box = Rect.fromPoints(
        offset(overlay.topLeft),
        offset(overlay.bottomRight),
      );
      canvas.drawRect(
        box,
        Paint()
          ..color = colors.primary
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      final label = TextPainter(
        text: TextSpan(
          text: overlay.label,
          style: TextStyle(
            color: colors.primary,
            fontFamily: 'CofoBrilliant',
            fontFamilyFallback: const ['NotoSans'],
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: box.width.clamp(1, size.width));
      label.paint(canvas, box.topLeft);
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter old) =>
      old.document != document || old.colors != colors;
}
