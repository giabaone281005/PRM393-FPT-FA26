import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'challenges.dart';
import 'app_theme.dart';

const _ink = ink;
const _green = green;

/// Keeps drag previews local. Only completed gestures are persisted by the page.
class InteractiveWorkspace extends StatefulWidget {
  const InteractiveWorkspace({
    super.key,
    required this.challenge,
    required this.value,
    required this.locked,
    required this.onChanged,
  });
  final Challenge challenge;
  final int value;
  final bool locked;
  final ValueChanged<int> onChanged;
  @override
  State<InteractiveWorkspace> createState() => _InteractiveWorkspaceState();
}

class _InteractiveWorkspaceState extends State<InteractiveWorkspace>
    with SingleTickerProviderStateMixin {
  late int value = widget.value;
  late final AnimationController simulation = AnimationController(vsync: this);
  Challenge get c => widget.challenge;
  @override
  void didUpdateWidget(InteractiveWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value || oldWidget.challenge != c) {
      value = widget.value;
      simulation.reset();
    }
  }

  @override
  void dispose() {
    simulation.dispose();
    super.dispose();
  }

  void commit(int next) {
    if (widget.locked) return;
    setState(() {
      value = c.normalize(next);
      simulation.reset();
    });
    widget.onChanged(value);
  }

  Widget token(int delta, String label) => Draggable<int>(
    data: delta,
    maxSimultaneousDrags: widget.locked ? 0 : 1,
    feedback: Material(color: Colors.transparent, child: _token(label)),
    childWhenDragging: Opacity(opacity: .35, child: _token(label)),
    child: _token(label),
  );
  Widget _token(String label) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: paper,
      border: Border.all(color: BrilliantPalette.border, width: 2),
      borderRadius: BorderRadius.circular(6),
      boxShadow: const [
        BoxShadow(color: BrilliantPalette.track, offset: Offset(0, 2)),
      ],
    ),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
  Widget drop(String id, int delta, Widget child) => DragTarget<int>(
    key: ValueKey(id),
    onWillAcceptWithDetails: (d) =>
        !widget.locked &&
        d.data == delta &&
        c.normalize(value + delta) != value,
    onAcceptWithDetails: (_) => commit(value + delta),
    builder: (context, candidates, rejected) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: candidates.isEmpty ? BrilliantPalette.surface : _green,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: candidates.isEmpty ? BrilliantPalette.track : green,
        ),
      ),
      child: child,
    ),
  );

  Widget balance() => Column(
    children: [
      Text(
        c.offset == 0
            ? 'Trái: ${c.target}  •  Phải: $value'
            : 'x = $value     •     $value + ${c.offset} = ${c.target + c.offset}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      SizedBox(
        height: 145,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(
            end: (c.offset == 0 ? value - c.target : c.target - value)
                .toDouble(),
          ),
          duration: const Duration(milliseconds: 220),
          builder: (_, tilt, child) => CustomPaint(
            painter: _BalanceScene(
              c.offset == 0 ? c.target : value + c.offset,
              c.offset == 0 ? value : c.target + c.offset,
              tilt,
            ),
          ),
        ),
      ),
      Row(
        children: [
          Expanded(
            child: drop(
              'block-bank',
              -1,
              Column(
                children: [
                  const Text('Kho khối'),
                  const SizedBox(height: 8),
                  token(1, '+1 khối'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: drop(
              'balance-pan',
              1,
              Column(
                children: [
                  Text(c.offset == 0 ? 'Đĩa phải' : 'Vùng x'),
                  const SizedBox(height: 8),
                  token(-1, '$value khối'),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        'Kéo từ kho sang đĩa để thêm; kéo về kho để bớt.',
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget fraction() => Column(
    children: [
      Text(
        '${c.quantity(value)}/4 chiếc bánh',
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: 216,
        height: 216,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PieScene(value))),
            for (int i = 0; i < 4; i++)
              Positioned(
                left: i % 2 * 108.0,
                top: i ~/ 2 * 108.0,
                width: 108,
                height: 108,
                child: Semantics(
                  selected: value & (1 << i) != 0,
                  child: TextButton(
                    key: ValueKey('slice-$i'),
                    onPressed: widget.locked
                        ? null
                        : () => commit(value ^ (1 << i)),
                    child: Text(
                      '¼',
                      semanticsLabel: 'Miếng bánh ${i + 1}',
                      style: const TextStyle(fontSize: 24, color: _ink),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Text('Chạm một miếng để tô; chạm lại để bỏ tô.'),
    ],
  );

  Widget sharing() => Column(
    children: [
      Text(
        'Tổng: ${c.total} ${c == challenges['math']!.last ? 'chiếc bánh' : 'cuốn sách'}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int side = 0; side < 2; side++) ...[
            if (side == 1) const SizedBox(width: 12),
            Expanded(
              child: drop(
                'group-$side',
                side == 0 ? 1 : -1,
                Column(
                  children: [
                    Text(
                      'Bạn ${side == 0 ? 'A' : 'B'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${side == 0 ? value : c.total - value}',
                      style: const TextStyle(fontSize: 30),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 104,
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: List.generate(
                          side == 0 ? value : c.total - value,
                          (_) => Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: side == 0
                                  ? _green
                                  : const Color(0xFFABBDFF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if ((side == 0 ? value : c.total - value) > 0)
                      token(side == 0 ? -1 : 1, 'Chuyển 1'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      const Text(
        'Kéo “Chuyển 1” sang người còn lại. Tổng luôn giữ nguyên.',
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget graph() => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      const margin = 24.0;
      final span = width - margin * 2;
      final vertical = c.kind == InteractionKind.bars;
      void preview(Offset position) {
        if (widget.locked) return;
        final fraction = vertical
            ? (180 - position.dy) / 144
            : (position.dx - margin) / span;
        setState(() {
          value = c.normalize((fraction * c.max).round());
          simulation.reset();
        });
      }

      return Column(
        children: [
          Text(
            c.kind == InteractionKind.motion
                ? (c.speedControl
                      ? '$value m/s × ${c.seconds} s = ${value * c.seconds} m'
                      : 'Cờ dự đoán: $value m')
                : c.kind == InteractionKind.median
                ? 'Mốc trung vị: $value cuốn'
                : 'Nhóm A: 3  •  Nhóm B: $value',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: vertical ? 'Kéo đỉnh cột B' : 'Kéo mốc trên trục',
            value: '$value',
            child: GestureDetector(
              key: const ValueKey('graph-gesture'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: vertical || widget.locked
                  ? null
                  : (d) => preview(d.localPosition),
              onHorizontalDragUpdate: vertical || widget.locked
                  ? null
                  : (d) => preview(d.localPosition),
              onHorizontalDragEnd: vertical || widget.locked
                  ? null
                  : (_) => commit(value),
              onHorizontalDragCancel: vertical
                  ? null
                  : () => setState(() => value = widget.value),
              onVerticalDragStart: !vertical || widget.locked
                  ? null
                  : (d) => preview(d.localPosition),
              onVerticalDragUpdate: !vertical || widget.locked
                  ? null
                  : (d) => preview(d.localPosition),
              onVerticalDragEnd: !vertical || widget.locked
                  ? null
                  : (_) => commit(value),
              onVerticalDragCancel: !vertical
                  ? null
                  : () => setState(() => value = widget.value),
              child: SizedBox(
                height: 224,
                width: double.infinity,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: simulation,
                    builder: (_, child) => CustomPaint(
                      painter: _GraphScene(c, value, simulation.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (c.kind == InteractionKind.motion)
            OutlinedButton.icon(
              onPressed: () {
                simulation.duration = Duration(seconds: c.seconds);
                simulation.forward(from: 0);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Chạy mô phỏng'),
            ),
          Text(
            vertical
                ? 'Kéo lên hoặc xuống trên cột B.'
                : c.speedControl
                ? 'Kéo núm trên trục tốc độ. Cờ đích ở 8 mét.'
                : 'Kéo ngang để đặt mốc; mốc tự khớp với vạch gần nhất.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: paper,
      border: Border.all(color: BrilliantPalette.track),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
      ],
    ),
    child: Column(
      children: [
        switch (c.kind) {
          InteractionKind.balance => balance(),
          InteractionKind.fraction => fraction(),
          InteractionKind.sharing => sharing(),
          _ => graph(),
        },
        if (c.kind != InteractionKind.fraction) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                key: const ValueKey('decrease'),
                tooltip: 'Bớt một đơn vị',
                onPressed: widget.locked || value == 0
                    ? null
                    : () => commit(value - 1),
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey('increase'),
                tooltip: 'Thêm một đơn vị',
                onPressed: widget.locked || value == c.max
                    ? null
                    : () => commit(value + 1),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

void _label(Canvas canvas, String text, Offset at, {Color color = _ink}) {
  final p = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontFamily: 'CofoBrilliant',
        fontFamilyFallback: const ['NotoSans'],
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  p.paint(canvas, Offset(at.dx - p.width / 2, at.dy));
}

class _BalanceScene extends CustomPainter {
  _BalanceScene(this.left, this.right, this.tilt);
  final int left, right;
  final double tilt;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final p = Paint()
      ..color = _ink
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final t = tilt.clamp(-4.0, 4.0).toDouble() * 4;
    canvas.drawLine(Offset(center, 45), Offset(center, 134), p);
    canvas.drawLine(Offset(center - 25, 134), Offset(center + 25, 134), p);
    canvas.drawLine(Offset(40, 45 - t), Offset(size.width - 40, 45 + t), p);
    for (int side = 0; side < 2; side++) {
      final x = side == 0 ? 40.0 : size.width - 40;
      final y = 45 + (side == 0 ? -t : t);
      canvas.drawLine(Offset(x, y), Offset(x, y + 40), p);
      canvas.drawLine(Offset(x - 30, y + 40), Offset(x + 30, y + 40), p);
      final count = side == 0 ? left : right;
      for (int i = 0; i < count; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - 27 + (i % 4) * 14,
              y + 26 - (i ~/ 4) * 14,
              12,
              12,
            ),
            const Radius.circular(3),
          ),
          Paint()..color = side == 0 ? _ink : const Color(0xFF29CC57),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BalanceScene old) =>
      left != old.left || right != old.right || tilt != old.tilt;
}

class _PieScene extends CustomPainter {
  _PieScene(this.mask);
  final int mask;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Quadrants correspond to the four semantic touch targets.
    const angles = [math.pi, -math.pi / 2, math.pi / 2, 0.0];
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        rect.deflate(4),
        angles[i],
        math.pi / 2,
        true,
        Paint()..color = mask & (1 << i) != 0 ? _green : Colors.white,
      );
      canvas.drawArc(
        rect.deflate(4),
        angles[i],
        math.pi / 2,
        true,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_PieScene old) => mask != old.mask;
}

class _GraphScene extends CustomPainter {
  _GraphScene(this.c, this.value, this.time);
  final Challenge c;
  final int value;
  final double time;
  @override
  void paint(Canvas canvas, Size size) {
    final span = size.width - 48;
    final p = Paint()
      ..color = _ink
      ..strokeWidth = 2;
    if (c.kind == InteractionKind.bars) {
      for (int i = 0; i < 2; i++) {
        final x = size.width * (i == 0 ? .28 : .72);
        final count = i == 0 ? 3 : value;
        final top = 180 - count / c.max * 144;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(x - 24, top, x + 24, 180),
            const Radius.circular(8),
          ),
          Paint()..color = i == 0 ? _ink : const Color(0xFF29CC57),
        );
        _label(canvas, '$count', Offset(x, top - 20));
        _label(canvas, 'Nhóm ${i == 0 ? 'A' : 'B'}', Offset(x, 196));
        if (i == 1) {
          canvas.drawCircle(Offset(x, top), 12, Paint()..color = _green);
        }
      }
      return;
    }
    const y = 170.0;
    canvas.drawLine(const Offset(24, y), Offset(size.width - 24, y), p);
    for (int i = 0; i <= c.max; i++) {
      final x = 24 + span * i / c.max;
      canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), p);
      if (c.max <= 6 || i.isEven) _label(canvas, '$i', Offset(x, y + 12));
    }
    final marker = 24 + span * value / c.max;
    if (c.kind == InteractionKind.median) {
      for (int n in [2, 3, 4]) {
        final x = 24 + span * n / c.max;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 12, 130 - n * 20, 24, n * 20.0),
            const Radius.circular(4),
          ),
          p,
        );
        _label(canvas, '$n', Offset(x, 108 - n * 20.0));
      }
      _label(canvas, '2, 3, 4 cuốn sách', Offset(size.width / 2, 8));
    } else {
      final distanceMax = c.speedControl ? c.max * c.seconds : c.max;
      final actualDistance = c.speedControl ? value * c.seconds : c.target;
      final carX = 24 + span * actualDistance / distanceMax * time;
      canvas.drawLine(
        const Offset(24, 80),
        Offset(size.width - 24, 80),
        Paint()
          ..color = Colors.black26
          ..strokeWidth = 3,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(carX - 12, 54, 24, 18),
          const Radius.circular(5),
        ),
        p,
      );
      for (final dx in [-7, 7]) {
        canvas.drawCircle(Offset(carX + dx, 76), 4, p);
      }
      final flagX = c.speedControl ? 24 + span * 8 / distanceMax : marker;
      canvas.drawLine(Offset(flagX, 26), Offset(flagX, 80), p);
      canvas.drawRect(
        Rect.fromLTWH(flagX, 26, 12, 12),
        Paint()..color = const Color(0xFF29CC57),
      );
      _label(
        canvas,
        c.speedControl
            ? 'Đích: 8 m'
            : '${c.target ~/ c.seconds} m/s • ${c.seconds} giây',
        Offset(size.width / 2, 0),
      );
      _label(
        canvas,
        '${(actualDistance * time).toStringAsFixed(1)} m / ${(c.seconds * time).toStringAsFixed(1)} s',
        Offset(size.width / 2, 100),
      );
      _label(
        canvas,
        c.speedControl ? 'Tốc độ (m/s)' : 'Quãng đường (m)',
        Offset(size.width / 2, 208),
      );
    }
    canvas.drawLine(Offset(marker, y - 20), Offset(marker, y + 5), p);
    canvas.drawCircle(Offset(marker, y - 20), 13, Paint()..color = _green);
    canvas.drawCircle(
      Offset(marker, y - 20),
      13,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_GraphScene old) =>
      c != old.c || value != old.value || time != old.time;
}
