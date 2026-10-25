import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../app_motion.dart';
import 'experiment_model.dart';

const _mechanisms = [
  'balanceBlocks',
  'removeBothSides',
  'gearRatios',
  'fractionPaint',
  'fractionFold',
  'distributeObjects',
  'launchAngle',
  'motionTimeline',
  'leverTorque',
  'sortBars',
  'histogramBins',
  'redistributeMean',
];
bool supportsMathExperiment(String mechanism) =>
    _mechanisms.contains(mechanism);

class MathExperiment extends StatefulWidget {
  const MathExperiment({
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
  State<MathExperiment> createState() => _MathExperimentState();
}

class _MathExperimentState extends State<MathExperiment> {
  double? anglePreview;
  double gearDrag = 0;
  int? selected;
  @override
  void didUpdateWidget(covariant MathExperiment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.id != widget.spec.id) {
      selected = null;
      anglePreview = null;
      gearDrag = 0;
    }
  }

  int n(String key) => (widget.data[key] as num? ?? 0).toInt();
  List<int> values(String key) =>
      (widget.data[key] as List).cast<num>().map((v) => v.toInt()).toList();
  void change(String key, dynamic value) {
    if (!widget.locked) widget.onChanged({...widget.data, key: value});
  }

  Widget action(String key, String label, VoidCallback callback) =>
      OutlinedButton(
        key: ValueKey(key),
        onPressed: widget.locked ? null : callback,
        child: Text(label, textAlign: TextAlign.center),
      );
  Widget note(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(text, textAlign: TextAlign.center),
  );
  Widget tile(String text, {Color color = paper}) => Container(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      border: Border.all(color: BrilliantPalette.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, textAlign: TextAlign.center),
  );
  Widget drag(int value, String label) => Draggable<int>(
    data: value,
    maxSimultaneousDrags: widget.locked ? 0 : 1,
    feedback: Material(
      color: Colors.transparent,
      child: tile(label, color: BrilliantPalette.successSurface),
    ),
    childWhenDragging: Opacity(opacity: .35, child: tile(label)),
    child: tile(label),
  );
  Widget target(
    String key,
    String label,
    ValueChanged<int> accept, {
    Widget? child,
    VoidCallback? tap,
  }) => DragTarget<int>(
    onWillAcceptWithDetails: (_) => !widget.locked,
    onAcceptWithDetails: (d) => accept(d.data),
    builder: (context, candidates, rejected) => Semantics(
      container: true,
      excludeSemantics: true,
      label: label,
      button: tap != null,
      onTap: widget.locked ? null : tap,
      child: InkWell(
        key: ValueKey(key),
        onTap: widget.locked ? null : tap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 60),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: candidates.isEmpty
                ? BrilliantPalette.surface
                : BrilliantPalette.successSurface,
            border: Border.all(
              color: candidates.isEmpty ? BrilliantPalette.border : green,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child ?? Text(label, textAlign: TextAlign.center),
        ),
      ),
    ),
  );
  Widget canvas(String kind, Map<String, dynamic> data, {double height = 160}) {
    final field = kind == 'balance'
        ? 'blocks'
        : kind == 'lever'
        ? 'position'
        : null;
    final painting = field == null
        ? CustomPaint(painter: _MathPainter(kind, data))
        : TweenAnimationBuilder<double>(
            tween: Tween(end: (data[field] as num).toDouble()),
            duration: AppMotion.duration(context, 460),
            curve: Curves.easeOutBack,
            builder: (context, value, _) => CustomPaint(
              painter: _MathPainter(kind, {...data, field: value}),
            ),
          );
    return SizedBox(height: height, width: double.infinity, child: painting);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (widget.spec.mechanism) {
      case 'balanceBlocks':
        final count = n('blocks');
        body = Column(
          children: [
            canvas('balance', {
              'blocks': count,
              'target': widget.spec.config['target'] ?? 4,
            }),
            note('Hộp bí mật  •  $count khối'),
            drag(1, '1 khối'),
            const SizedBox(height: 12),
            target(
              'balance-drop',
              'Thả khối vào cân',
              (_) => change('blocks', (count + 1).clamp(0, 8)),
              tap: () => change('blocks', (count + 1).clamp(0, 8)),
            ),
            action(
              'balance-remove',
              'Lấy ra 1 khối',
              () => change('blocks', (count - 1).clamp(0, 8)),
            ),
          ],
        );
      case 'removeBothSides':
        final pairs = n('pairs');
        final extra = widget.spec.config['extra'] as int? ?? 3;
        final total = widget.spec.config['total'] as int? ?? 7;
        body = Column(
          children: [
            note('Vuốt ngang trên phép cân bằng'),
            GestureDetector(
              key: const ValueKey('remove-swipe'),
              onHorizontalDragEnd: widget.locked
                  ? null
                  : (_) => change('pairs', (pairs + 1).clamp(0, extra)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  color: BrilliantPalette.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'x + ${extra - pairs} = ${total - pairs}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${'■ ' * (extra - pairs)}  ↔  ${'■ ' * (total - pairs)}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            action(
              'remove-pair',
              'Bỏ 1 khối ở mỗi vế',
              () => change('pairs', (pairs + 1).clamp(0, extra)),
            ),
          ],
        );
      case 'gearRatios':
        final turns = n('turns');
        body = Column(
          children: [
            GestureDetector(
              key: const ValueKey('gear-rotate'),
              onHorizontalDragStart: widget.locked
                  ? null
                  : (_) {
                      gearDrag = 0;
                    },
              onHorizontalDragUpdate: widget.locked
                  ? null
                  : (d) {
                      gearDrag += d.delta.dx;
                    },
              onHorizontalDragEnd: widget.locked
                  ? null
                  : (_) {
                      if (gearDrag.abs() > 35) {
                        change(
                          'turns',
                          (turns + (gearDrag > 0 ? 1 : -1)).clamp(0, 4),
                        );
                      }
                    },
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: turns.toDouble()),
                duration: AppMotion.duration(context, 650),
                builder: (context, value, child) =>
                    canvas('gears', {'turns': value}),
              ),
            ),
            note('Nhỏ: $turns vòng  •  Lớn: ${turns / 2} vòng'),
            Wrap(
              spacing: 8,
              children: [
                action(
                  'gear-back',
                  '↶ 1 vòng',
                  () => change('turns', (turns - 1).clamp(0, 4)),
                ),
                action(
                  'gear-forward',
                  '↷ 1 vòng',
                  () => change('turns', (turns + 1).clamp(0, 4)),
                ),
              ],
            ),
          ],
        );
      case 'fractionPaint':
        final painted = values('painted');
        void toggle(int i) {
          final next = [...painted];
          next.contains(i) ? next.remove(i) : next.add(i);
          change('painted', next);
        }
        body = Column(
          children: [
            GestureDetector(
              key: const ValueKey('fraction-wheel'),
              onTapUp: widget.locked
                  ? null
                  : (d) {
                      const center = Offset(100, 100);
                      final delta = d.localPosition - center;
                      if (delta.distance <= 100) {
                        final a =
                            (math.atan2(delta.dy, delta.dx) + math.pi * 2) %
                            (math.pi * 2);
                        toggle((a / (math.pi / 4)).floor());
                      }
                    },
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _MathPainter('pie', {'painted': painted}),
                ),
              ),
            ),
            note('Đã tô ${painted.length}/8'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 8; i++)
                  Semantics(
                    selected: painted.contains(i),
                    child: action(
                      'paint-$i',
                      'Lát ${i + 1}${painted.contains(i) ? ' ✓' : ''}',
                      () => toggle(i),
                    ),
                  ),
              ],
            ),
          ],
        );
      case 'fractionFold':
        final folds = n('folds');
        body = Column(
          children: [
            GestureDetector(
              key: const ValueKey('fold-paper'),
              onHorizontalDragEnd: widget.locked
                  ? null
                  : (_) => change('folds', (folds + 1).clamp(0, 3)),
              child: AnimatedContainer(
                duration: AppMotion.duration(context, 450),
                height: 160,
                width: 220 / math.pow(2, folds),
                decoration: BoxDecoration(
                  color: BrilliantPalette.surface,
                  border: Border.all(color: ink, width: 2),
                ),
                alignment: Alignment.center,
                child: Text('1/${math.pow(2, folds).toInt()}'),
              ),
            ),
            note('$folds lần gấp • ${math.pow(2, folds).toInt()} phần'),
            Wrap(
              spacing: 8,
              children: [
                action(
                  'fold-again',
                  'Gấp đôi →',
                  () => change('folds', (folds + 1).clamp(0, 3)),
                ),
                action(
                  'fold-open',
                  'Mở một nếp',
                  () => change('folds', (folds - 1).clamp(0, 3)),
                ),
              ],
            ),
          ],
        );
      case 'distributeObjects':
        final baskets = values('baskets');
        final remaining = 9 - baskets.fold(0, (a, b) => a + b);
        void add(int i) {
          if (remaining > 0) {
            final next = [...baskets];
            next[i]++;
            change('baskets', next);
          }
        }
        body = Column(
          children: [
            if (remaining > 0) drag(1, '● Cam ($remaining)'),
            note('Chạm giỏ để thêm; nút bên dưới trả lại một quả.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  SizedBox(
                    width: 96,
                    child: Column(
                      children: [
                        target(
                          'basket-$i',
                          'Giỏ ${i + 1}\n${baskets[i]} quả',
                          (_) => add(i),
                          tap: () => add(i),
                        ),
                        action('basket-return-$i', 'Trả 1', () {
                          if (baskets[i] > 0) {
                            final next = [...baskets];
                            next[i]--;
                            change('baskets', next);
                          }
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      case 'launchAngle':
        final angle = anglePreview ?? (widget.data['angle'] as num).toDouble();
        void update(Offset p, Size size) {
          final dx = p.dx - 24, dy = size.height - 24 - p.dy;
          setState(
            () => anglePreview = (math.atan2(dy, dx) * 180 / math.pi).clamp(
              5,
              85,
            ),
          );
        }
        body = Column(
          children: [
            LayoutBuilder(
              builder: (context, c) => GestureDetector(
                key: const ValueKey('launch-aim'),
                onPanUpdate: widget.locked
                    ? null
                    : (d) => update(d.localPosition, Size(c.maxWidth, 180)),
                onPanEnd: widget.locked
                    ? null
                    : (_) {
                        if (anglePreview != null) {
                          widget.onChanged({
                            ...widget.data,
                            'angle': anglePreview!.round(),
                            'launched': false,
                          });
                          setState(() => anglePreview = null);
                        }
                      },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    end: widget.data['launched'] == true ? 1 : 0,
                  ),
                  duration: AppMotion.duration(context, 1000),
                  builder: (context, progress, child) => canvas('launch', {
                    'angle': angle,
                    'launched': widget.data['launched'],
                    'progress': progress,
                  }, height: 180),
                ),
              ),
            ),
            note(
              'Góc ${angle.round()}° • Tầm xa ${(10 * math.sin(2 * angle * math.pi / 180)).toStringAsFixed(1)} m',
            ),
            Wrap(
              spacing: 8,
              children: [
                action(
                  'angle-down',
                  '− 5°',
                  () => widget.onChanged({
                    ...widget.data,
                    'angle': (angle - 5).clamp(5, 85),
                    'launched': false,
                  }),
                ),
                action(
                  'angle-up',
                  '+ 5°',
                  () => widget.onChanged({
                    ...widget.data,
                    'angle': (angle + 5).clamp(5, 85),
                    'launched': false,
                  }),
                ),
                action(
                  'launch-fire',
                  'Phóng bóng ↗',
                  () => change('launched', true),
                ),
              ],
            ),
          ],
        );
      case 'motionTimeline':
        final segments = values('segments');
        const labels = ['Nghỉ', 'Đi chậm', 'Đi nhanh'];
        void put(int i, int v) {
          final next = [...segments];
          next[i] = v;
          change('segments', next);
        }
        body = Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  InkWell(
                    onTap: widget.locked
                        ? null
                        : () => setState(() => selected = i),
                    child: Semantics(
                      selected: selected == i,
                      child: drag(
                        i,
                        '${labels[i]}${selected == i ? ' ✓' : ''}',
                      ),
                    ),
                  ),
              ],
            ),
            note('Kéo thẻ vào ô; hoặc chạm thẻ rồi chạm ô.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  target(
                    'timeline-$i',
                    '${i * 2}–${i * 2 + 2} s\n${segments[i] < 0 ? 'Thả thẻ' : labels[segments[i]]}',
                    (v) => put(i, v),
                    tap: () => put(i, selected ?? 0),
                  ),
              ],
            ),
            canvas('motion', {'segments': segments}, height: 100),
          ],
        );
      case 'leverTorque':
        final position = n('position');
        body = Column(
          children: [
            canvas('lever', {'position': position}),
            drag(2, '2 kg'),
            note('Kéo quả nặng tới vạch, hoặc chạm vào vạch.'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 1; i <= 4; i++)
                  target(
                    'lever-$i',
                    '$i m${position == i ? '\n● 2 kg' : ''}',
                    (_) => change('position', i),
                    tap: () => change('position', i),
                  ),
              ],
            ),
          ],
        );
      case 'sortBars':
        final order = values('order');
        void swap(int a, int b) {
          if (a == b) return;
          final next = [...order];
          final temp = next[a];
          next[a] = next[b];
          next[b] = temp;
          change('order', next);
          setState(() => selected = null);
        }
        body = Column(
          children: [
            note('Chạm một cột rồi chạm cột khác để đổi chỗ, hoặc kéo thả.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  target(
                    'sort-slot-$i',
                    'Cột ${order[i]}',
                    (from) => swap(from, i),
                    tap: () {
                      if (selected == null) {
                        setState(() => selected = i);
                      } else {
                        swap(selected!, i);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(height: (4 - order[i]) * 20.0),
                        drag(i, '${order[i]}'),
                        Container(
                          height: order[i] * 20.0,
                          width: 40,
                          color: selected == i ? green : ink,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      case 'histogramBins':
        final bins = values('bins');
        const numbers = [1, 2, 4, 5, 7, 8];
        void put(int point, int bin) {
          final next = [...bins];
          next[point] = bin;
          change('bins', next);
          setState(() => selected = null);
        }
        body = Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 6; i++)
                  InkWell(
                    key: ValueKey('point-$i'),
                    onTap: widget.locked
                        ? null
                        : () => setState(() => selected = i),
                    child: Semantics(
                      selected: selected == i,
                      child: drag(
                        i,
                        '${numbers[i]}${selected == i ? ' ✓' : ''}',
                      ),
                    ),
                  ),
              ],
            ),
            note('Chọn một điểm rồi chạm khoảng; cũng có thể kéo thả.'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var b = 0; b < 3; b++)
                  target(
                    'bin-$b',
                    '${b * 3}–${b * 3 + 2}\n${[for (var i = 0; i < 6; i++)
                      if (bins[i] == b) numbers[i]].join(', ')}',
                    (point) => put(point, b),
                    tap: () {
                      if (selected != null) put(selected!, b);
                    },
                  ),
              ],
            ),
          ],
        );
      case 'redistributeMean':
        final heights = values('heights');
        void move(int from, int to) {
          if (from == to || heights[from] == 0) return;
          final next = [...heights];
          next[from]--;
          next[to]++;
          change('heights', next);
          setState(() => selected = null);
        }
        body = Column(
          children: [
            note(
              'Kéo một tầng sang tòa khác; hoặc chạm tòa nguồn rồi tòa nhận.',
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  target(
                    'mean-tower-$i',
                    'Tòa ${i + 1}: ${heights[i]} tầng',
                    (from) => move(from, i),
                    tap: () {
                      if (selected == null) {
                        setState(() => selected = i);
                      } else {
                        move(selected!, i);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${heights[i]} tầng'),
                        const SizedBox(height: 8),
                        drag(i, '↗'),
                        for (var j = 0; j < heights[i]; j++)
                          Container(
                            width: 42,
                            height: 18,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: selected == i
                                  ? green
                                  : BrilliantPalette.surface,
                              border: Border.all(color: ink),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      default:
        body = const Text('Chưa có thí nghiệm cho bài này.');
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: BrilliantPalette.track),
        borderRadius: BorderRadius.circular(20),
      ),
      child: body,
    );
  }
}

class _MathPainter extends CustomPainter {
  const _MathPainter(this.kind, this.data);
  final String kind;
  final Map<String, dynamic> data;
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = ink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = green;
    final w = size.width, h = size.height;
    void text(String label, Offset p) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: ink,
            fontSize: 13,
            fontFamily: 'CofoBrilliant',
            fontFamilyFallback: ['NotoSans'],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p);
    }

    if (kind == 'pie') {
      final center = Offset(w / 2, h / 2), r = math.min(w, h) / 2 - 3;
      final painted = (data['painted'] as List);
      for (var i = 0; i < 8; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          i * math.pi / 4,
          math.pi / 4,
          true,
          Paint()
            ..color = painted.contains(i) ? green : BrilliantPalette.surface,
        );
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          i * math.pi / 4,
          math.pi / 4,
          true,
          line,
        );
      }
      return;
    }
    if (kind == 'balance' || kind == 'lever') {
      final count = (data['blocks'] as num? ?? 0).toDouble(),
          position = (data['position'] as num? ?? 0).toDouble();
      final tilt = kind == 'balance'
          ? (count - (data['target'] as num? ?? 4)) * 4.0
          : (position * 2 - 6) * 3.0;
      final center = Offset(w / 2, h * .55);
      canvas.drawLine(center, Offset(w / 2, h - 15), line);
      canvas.drawLine(
        Offset(16, center.dy - tilt),
        Offset(w - 16, center.dy + tilt),
        line,
      );
      canvas.drawCircle(center, 6, fill);
      if (kind == 'balance') {
        text('Hộp ?', Offset(12, center.dy - tilt - 30));
        text('${count.round()} × 1', Offset(w - 65, center.dy + tilt - 30));
      } else {
        text('3 kg · 2 m', Offset(0, center.dy - tilt - 30));
        text(
          '2 kg · ${position.round()} m',
          Offset(w - 90, center.dy + tilt - 30),
        );
      }
      canvas.drawLine(
        Offset(w / 2 - 30, h - 12),
        Offset(w / 2 + 30, h - 12),
        line,
      );
      return;
    }
    if (kind == 'gears') {
      for (var i = 0; i < 2; i++) {
        final r = i == 0 ? 32.0 : 54.0,
            c = Offset(w * (i == 0 ? 0.3 : 0.65), h / 2);
        canvas.drawCircle(c, r, line);
        canvas.drawCircle(c, 5, fill);
        final teeth = i == 0 ? 12 : 24;
        for (var j = 0; j < teeth; j++) {
          final rotation =
              (data['turns'] as num).toDouble() * math.pi * (i == 0 ? 2 : -1);
          final a = j * math.pi * 2 / teeth + rotation;
          canvas.drawLine(
            c + Offset(math.cos(a), math.sin(a)) * (r - 3),
            c + Offset(math.cos(a), math.sin(a)) * (r + 6),
            line,
          );
        }
        final rotation =
            (data['turns'] as num).toDouble() * math.pi * (i == 0 ? 2 : -1);
        canvas.drawLine(
          c,
          c + Offset(math.cos(rotation), math.sin(rotation)) * (r * .8),
          line,
        );
        text('$teeth răng', Offset(c.dx - r, c.dy + r + 12));
      }
      return;
    }
    if (kind == 'launch') {
      final angle = (data['angle'] as num).toDouble() * math.pi / 180,
          origin = Offset(24, h - 24),
          scale = (w - 48) / 10;
      canvas.drawLine(origin, Offset(w - 12, h - 24), line);
      canvas.drawLine(Offset(w - 24, h - 24), Offset(w - 24, h - 64), line);
      text('10 m', Offset(w - 55, h - 85));
      canvas.drawLine(
        origin,
        origin + Offset(math.cos(angle), -math.sin(angle)) * 45,
        line,
      );
      if (data['launched'] == true) {
        final path = Path()..moveTo(origin.dx, origin.dy);
        final flight = 2 * math.sin(angle);
        final progress = (data['progress'] as num? ?? 1).toDouble();
        for (var i = 1; i <= 60; i++) {
          final t = flight * progress * i / 60,
              x = 10 * math.cos(angle) * t,
              y = 10 * math.sin(angle) * t - 5 * t * t;
          path.lineTo(origin.dx + x * scale, origin.dy - y * scale);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = green
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(
          Offset(
            origin.dx + 10 * math.cos(angle) * flight * progress * scale,
            origin.dy -
                (10 * math.sin(angle) * flight * progress -
                        5 * flight * flight * progress * progress) *
                    scale,
          ),
          6,
          fill,
        );
      }
      return;
    }
    if (kind == 'motion') {
      final segments = (data['segments'] as List);
      double x = 16;
      final path = Path()..moveTo(x, h - 20);
      double distance = 0;
      for (var i = 0; i < 3; i++) {
        distance += math.max(0, (segments[i] as int)) * 2;
        path.lineTo(16 + (i + 1) * (w - 32) / 3, h - 20 - distance * 8);
      }
      canvas.drawPath(path, line);
      text('Quãng đường: ${distance.toInt()} m', Offset(16, 4));
    }
  }

  @override
  bool shouldRepaint(covariant _MathPainter oldDelegate) => true;
}
