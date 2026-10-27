import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../app_motion.dart';
import 'experiment_model.dart';
import 'discovery_catalog.dart';

const _mechanisms = {
  'polygonVertices',
  'symmetryMirror',
  'tangramRotate',
  'robotRoute',
  'loopBuilder',
  'sortingNetwork',
  'wireCircuit',
  'switchLogic',
  'colorMixer',
  'probabilityBag',
  'sampleSpace',
  'probabilitySpinner',
};
bool supportsDiscoveryExperiment(String mechanism) =>
    _mechanisms.contains(mechanism);

class DiscoveryExperiment extends StatefulWidget {
  const DiscoveryExperiment({
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
  State<DiscoveryExperiment> createState() => _DiscoveryExperimentState();
}

class _DiscoveryExperimentState extends State<DiscoveryExperiment> {
  int _selected = 0;
  int? _wireStart;
  List<List<int>>? _points;
  List<double>? _rgb;
  int? _sectors;
  Offset? _swipe;
  String get mode => widget.spec.mechanism;
  ExperimentData get d => widget.data;
  void change(String key, dynamic value) {
    if (!widget.locked) widget.onChanged({...d, key: value});
  }

  List<dynamic> list(String key) => List<dynamic>.from(d[key] as List);
  Widget button(String label, VoidCallback action, {IconData? icon}) =>
      OutlinedButton(
        onPressed: widget.locked ? null : action,
        child: icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
      );
  Widget note(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: BrilliantPalette.secondaryText),
    ),
  );
  Widget board(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: BrilliantPalette.track),
    ),
    child: child,
  );
  @override
  void didUpdateWidget(covariant DiscoveryExperiment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.id != widget.spec.id) {
      _selected = 0;
      _wireStart = null;
      _points = null;
      _rgb = null;
      _sectors = null;
    }
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: widget.locked,
    child: switch (mode) {
      'polygonVertices' => _polygon(),
      'symmetryMirror' => _mirror(),
      'tangramRotate' => _tangram(),
      'robotRoute' => _robot(),
      'loopBuilder' => _loop(),
      'sortingNetwork' => _sort(),
      'wireCircuit' => _wires(),
      'switchLogic' => _switches(),
      'colorMixer' => _mixer(),
      'probabilityBag' => _bag(),
      'sampleSpace' => _space(),
      'probabilitySpinner' => _spinner(),
      _ => const Text('Chưa có bàn tương tác.'),
    },
  );

  List<List<int>> get points =>
      _points ??
      (d['points'] as List)
          .map((p) => (p as List).cast<int>().toList())
          .toList();
  void movePoint(int x, int y, {bool commit = true}) {
    final p = points.map((v) => List<int>.from(v)).toList();
    p[_selected] = [x.clamp(0, 4), y.clamp(0, 4)];
    if (commit) {
      change('points', p);
    } else {
      setState(() => _points = p);
    }
  }

  Widget _polygon() => board(
    Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, c) => GestureDetector(
              onPanStart: (e) {
                final p = points;
                final unit = c.maxWidth / 5;
                _selected = List.generate(4, (i) => i).reduce(
                  (a, b) =>
                      (Offset((p[a][0] + .5) * unit, (p[a][1] + .5) * unit) -
                                  e.localPosition)
                              .distance <
                          (Offset(
                                    (p[b][0] + .5) * unit,
                                    (p[b][1] + .5) * unit,
                                  ) -
                                  e.localPosition)
                              .distance
                      ? a
                      : b,
                );
              },
              onPanUpdate: (e) => movePoint(
                (e.localPosition.dx / (c.maxWidth / 5) - .5).round(),
                (e.localPosition.dy / (c.maxWidth / 5) - .5).round(),
                commit: false,
              ),
              onPanEnd: (_) {
                change('points', points);
                setState(() => _points = null);
              },
              child: CustomPaint(
                painter: _ScenePainter('polygon', {'points': points}),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: 4,
          children: [
            for (int i = 0; i < 4; i++)
              button(
                '${i + 1}${_selected == i ? ' •' : ''}',
                () => setState(() => _selected = i),
              ),
          ],
        ),
        Wrap(
          spacing: 4,
          children: [
            button(
              'Trái',
              () => movePoint(points[_selected][0] - 1, points[_selected][1]),
            ),
            button(
              'Phải',
              () => movePoint(points[_selected][0] + 1, points[_selected][1]),
            ),
            button(
              'Lên',
              () => movePoint(points[_selected][0], points[_selected][1] - 1),
            ),
            button(
              'Xuống',
              () => movePoint(points[_selected][0], points[_selected][1] + 1),
            ),
          ],
        ),
        note('Kéo một đỉnh; hoặc chọn đỉnh và dùng các nút di chuyển.'),
      ],
    ),
  );

  Widget _mirror() {
    final cells = list('cells');
    return board(
      Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(288, constraints.maxWidth),
                height: math.max(288, constraints.maxWidth) * 5 / 6,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 30,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                  ),
                  itemBuilder: (context, i) {
                    final fixed = [6, 13, 18].contains(i);
                    final active = cells.contains(i);
                    return Semantics(
                      label: 'Hàng ${i ~/ 6 + 1}, cột ${i % 6 + 1}',
                      selected: fixed || active,
                      button: i % 6 >= 3,
                      child: GestureDetector(
                        onTap: i % 6 < 3
                            ? null
                            : () {
                                if (active) {
                                  cells.remove(i);
                                } else {
                                  cells.add(i);
                                }
                                change('cells', cells);
                              },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: fixed || active
                                ? green
                                : BrilliantPalette.surface,
                            border: Border(
                              right: BorderSide(
                                color: i % 6 == 2
                                    ? ink
                                    : BrilliantPalette.track,
                                width: i % 6 == 2 ? 3 : 1,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          note('Trục đen ở giữa • chạm lại để xóa ô.'),
          button('Xóa hình phản chiếu', () => change('cells', <int>[])),
        ],
      ),
    );
  }

  Widget _tangram() {
    final turns = list('turns');
    final placed = list('placed');
    return board(
      Column(
        children: [
          DragTarget<int>(
            onWillAcceptWithDetails: (e) => !widget.locked,
            onAcceptWithDetails: (e) {
              placed[e.data] = true;
              change('placed', placed);
            },
            builder: (context, candidates, rejected) => Container(
              height: 210,
              width: 210,
              decoration: BoxDecoration(
                color: candidates.isNotEmpty
                    ? BrilliantPalette.successSurface
                    : BrilliantPalette.surface,
                border: Border.all(color: ink, width: 2),
              ),
              child: CustomPaint(
                painter: _ScenePainter('tangram', {
                  'turns': turns,
                  'placed': placed,
                }),
              ),
            ),
          ),
          note('Khung ghép • xoay rồi thả hai mảnh vào đây.'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < 2; i++)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Draggable<int>(
                      data: i,
                      maxSimultaneousDrags: widget.locked ? 0 : 1,
                      feedback: Material(
                        color: Colors.transparent,
                        child: _triangleToken(i, turns[i]),
                      ),
                      child: _triangleToken(i, turns[i]),
                    ),
                    button('Xoay mảnh ${i + 1}', () {
                      turns[i] = (turns[i] + 1) % 4;
                      change('turns', turns);
                    }),
                    button(
                      placed[i] ? 'Lấy mảnh ${i + 1} ra' : 'Đặt mảnh ${i + 1}',
                      () {
                        placed[i] = !placed[i];
                        change('placed', placed);
                      },
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _triangleToken(int i, int turn) => SizedBox(
    width: 70,
    height: 70,
    child: CustomPaint(
      painter: _ScenePainter('triangle', {'turn': turn, 'index': i}),
    ),
  );

  void command(String c) {
    final commands = list('commands');
    if (commands.length < 32) {
      commands.add(c);
      change('commands', commands);
    }
  }

  Widget _robotScene(
    List commands, {
    required bool obstacle,
    bool replay = false,
  }) => TweenAnimationBuilder<double>(
    key: replay ? ValueKey(commands.join()) : null,
    tween: Tween(begin: 0, end: commands.length.toDouble()),
    duration: AppMotion.duration(context, replay ? 1000 : 360),
    curve: Curves.easeInOutCubic,
    builder: (context, steps, _) => CustomPaint(
      painter: _ScenePainter('robot', {
        'commands': commands,
        'obstacle': obstacle,
        'steps': steps,
      }),
      child: const SizedBox.expand(),
    ),
  );

  Widget _robot() => board(
    Column(
      children: [
        GestureDetector(
          onPanStart: (e) => _swipe = e.localPosition,
          onPanEnd: (e) => _swipe = null,
          onPanUpdate: (e) {
            if (_swipe == null) return;
            final delta = e.localPosition - _swipe!;
            if (delta.distance > 35) {
              command(
                delta.dx.abs() > delta.dy.abs()
                    ? (delta.dx > 0 ? 'R' : 'L')
                    : (delta.dy > 0 ? 'D' : 'U'),
              );
              _swipe = e.localPosition;
            }
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: _robotScene(list('commands'), obstacle: true),
          ),
        ),
        note(
          'Lệnh: ${list('commands').map((e) => {'R': '→', 'L': '←', 'D': '↓', 'U': '↑'}[e]).join(' ')}',
        ),
        Wrap(
          spacing: 6,
          children: [
            for (final c in ['L', 'U', 'D', 'R'])
              button(
                {'L': '←', 'U': '↑', 'D': '↓', 'R': '→'}[c]!,
                () => command(c),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            button('Lùi một lệnh', () {
              final c = list('commands');
              if (c.isNotEmpty) c.removeLast();
              change('commands', c);
            }),
            button('Làm lại đường đi', () => change('commands', <String>[])),
          ],
        ),
      ],
    ),
  );

  Widget _loop() {
    final body = list('body');
    final repeat = d['repeat'] as int;
    return board(
      Column(
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: _robotScene(
              [for (int n = 0; n < repeat; n++) ...body],
              obstacle: false,
              replay: true,
            ),
          ),
          note('LẶP $repeat LẦN'),
          Wrap(
            spacing: 12,
            children: [
              for (int i = 0; i < 2; i++)
                button(
                  'Lệnh ${i + 1}: ${{'R': '→', 'D': '↓', 'L': '←', 'U': '↑'}[body[i]]}',
                  () {
                    const options = ['R', 'D', 'L', 'U'];
                    body[i] = options[(options.indexOf(body[i]) + 1) % 4];
                    change('body', body);
                  },
                ),
            ],
          ),
          Slider(
            value: repeat.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: '$repeat lần',
            onChanged: (v) => change('repeat', v.round()),
            semanticFormatterCallback: (v) => 'Lặp ${v.round()} lần',
          ),
          note('Chạm khối lệnh để đổi hướng. Kéo thanh để chạy vòng lặp.'),
        ],
      ),
    );
  }

  Widget _sort() {
    final stages = list('stages').cast<int>();
    final result = list('result');
    final passed = comparatorTestInputs.where((input) {
      final output = runComparatorNetwork(stages, input);
      return List.generate(4, (i) => output[i] == i + 1).every((v) => v);
    }).length;
    void update(List<int> next) {
      if (!widget.locked) {
        widget.onChanged({...d, 'stages': next, 'result': <int>[]});
      }
    }

    return board(
      Column(
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: CustomPaint(
              painter: _ScenePainter('network', {
                'stages': stages,
                'result': result,
              }),
            ),
          ),
          note('Bộ so sánh đã lắp: ${stages.length}/6'),
          Wrap(
            spacing: 6,
            children: [
              for (int i = 0; i < 3; i++)
                button('Nối ${i + 1}–${i + 2}', () {
                  if (stages.length < 6) {
                    update([...stages, i]);
                  }
                }),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              button('Tháo bộ cuối', () {
                if (stages.isNotEmpty) {
                  update(stages.sublist(0, stages.length - 1));
                }
              }),
              button(
                'Chạy 24 đầu vào',
                () => change(
                  'result',
                  runComparatorNetwork(stages, [4, 1, 3, 2]),
                ),
              ),
            ],
          ),
          if (result.isNotEmpty) ...[
            note('Máy chạy: 4, 1, 3, 2 → ${result.join(', ')}'),
            Text(
              '$passed/24 đầu vào được sắp đúng',
              style: TextStyle(
                color: passed == 24 ? BrilliantPalette.successInk : ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else
            note(
              'Lắp mạng rồi chạy để quan sát kết quả. Mỗi bộ chỉ đổi số nếu cần.',
            ),
        ],
      ),
    );
  }

  void connect(int end) {
    if (_wireStart == null) {
      setState(() => _wireStart = end);
      return;
    }
    if (_wireStart != end) {
      final a = math.min(_wireStart!, end), b = math.max(_wireStart!, end);
      final edge = '$a-$b';
      final edges = list('edges');
      if (edges.contains(edge)) {
        edges.remove(edge);
      } else {
        edges.add(edge);
      }
      change('edges', edges);
    }
    setState(() => _wireStart = null);
  }

  Widget _wires() => board(
    Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, c) {
              final size = Size(c.maxWidth, c.maxWidth);
              int nearest(Offset p) => List.generate(4, (i) => i).reduce(
                (a, b) =>
                    (_node(a, size) - p).distance <
                        (_node(b, size) - p).distance
                    ? a
                    : b,
              );
              return GestureDetector(
                onPanStart: (e) =>
                    setState(() => _wireStart = nearest(e.localPosition)),
                onPanEnd: (_) {
                  if (_wireStart != null) setState(() => _wireStart = null);
                },
                onPanUpdate: (e) {
                  final end = nearest(e.localPosition);
                  if (_wireStart != null &&
                      end != _wireStart &&
                      (_node(end, size) - e.localPosition).distance < 28) {
                    connect(end);
                  }
                },
                child: _lightScene(
                  'wire',
                  {'edges': list('edges'), 'selected': _wireStart},
                  child: Stack(
                    children: [
                      for (int i = 0; i < 4; i++)
                        Positioned(
                          left: _node(i, size).dx - 24,
                          top: _node(i, size).dy - 24,
                          child: Semantics(
                            label: [
                              'Cực dương nguồn',
                              'Đầu vào đèn',
                              'Đầu ra đèn',
                              'Cực âm nguồn',
                            ][i],
                            child: IconButton(
                              onPressed: () => connect(i),
                              icon: const Icon(Icons.circle_outlined, size: 32),
                              color: _wireStart == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        note(
          _wireStart == null
              ? 'Chọn cọc bắt đầu rồi chọn cọc kết thúc.'
              : 'Đã chọn cọc ${_wireStart! + 1}. Chọn cọc còn lại.',
        ),
        button('Tháo tất cả dây', () => change('edges', <String>[])),
      ],
    ),
  );

  Widget _lightScene(String kind, Map<String, dynamic> state, {Widget? child}) {
    final edges = state['edges'] as List? ?? [];
    final switches = state['switches'] as List? ?? [false, false, false];
    final lit = kind == 'wire'
        ? edges.length == 2 && edges.toSet().containsAll(['0-1', '2-3'])
        : (switches[0] || switches[1]) && switches[2];
    return TweenAnimationBuilder<double>(
      tween: Tween(end: lit ? 1 : 0),
      duration: AppMotion.duration(context, 420),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, glow, child) => CustomPaint(
        painter: _ScenePainter(kind, {...state, 'glow': glow}),
        child: child,
      ),
    );
  }

  Widget _switches() {
    final s = list('switches');
    final lit = (s[0] || s[1]) && s[2];
    return board(
      Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: _lightScene('logic', {'switches': s}),
          ),
          note(
            lit
                ? 'Đèn sáng • dòng điện đã khép kín'
                : 'Đèn tắt • cần khép kín đường điện',
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: BrilliantPalette.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text('Nguồn → [A song song B] → C → Đèn'),
                for (int i = 0; i < 3; i++)
                  Material(
                    color: paper,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${['A — nhánh bảo trì', 'B — nhánh dự phòng', 'C — công tắc chính'][i]}: ${s[i] ? 'đóng' : 'mở'}',
                      ),
                      value: s[i],
                      activeThumbColor: Theme.of(context).colorScheme.onPrimary,
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      onChanged: (v) {
                        s[i] = v;
                        change('switches', s);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mixer() {
    final rgb =
        _rgb ?? (d['rgb'] as List).map((v) => (v as num).toDouble()).toList();
    final color = Color.fromRGBO(
      (rgb[0] * 255).round(),
      (rgb[1] * 255).round(),
      (rgb[2] * 255).round(),
      1,
    );
    return board(
      Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        border: Border.all(color: BrilliantPalette.border),
                      ),
                    ),
                    note('Ánh sáng của bạn'),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(
                          widget.spec.config['color'] as int? ?? 0xFFFFFF00,
                        ),
                        border: Border.all(color: BrilliantPalette.border),
                      ),
                    ),
                    note(
                      widget.spec.config['colorLabel'] as String? ?? 'Mẫu vàng',
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (int i = 0; i < 3; i++)
            Column(
              children: [
                Text('${['Đỏ', 'Lục', 'Lam'][i]} • ${(rgb[i] * 100).round()}%'),
                Slider(
                  value: rgb[i],
                  divisions: 20,
                  activeColor: [Colors.red, green, Colors.blue][i],
                  semanticFormatterCallback: (v) =>
                      '${['Đỏ', 'Lục', 'Lam'][i]} ${(v * 100).round()} phần trăm',
                  onChanged: (v) => setState(() => _rgb = [...rgb]..[i] = v),
                  onChangeEnd: (_) {
                    change('rgb', _rgb ?? rgb);
                    setState(() => _rgb = null);
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  void addBall(String color) {
    final b = list('balls');
    if (b.length < (widget.spec.config['capacity'] as int? ?? 6)) {
      b.add(color);
      change('balls', b);
    }
  }

  Widget ball(String color) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color == 'B' ? const Color(0xFF3265CB) : const Color(0xFFE55F45),
      border: Border.all(color: ink),
    ),
    alignment: Alignment.center,
    child: Text(
      color == 'B' ? 'X' : 'Đ',
      style: const TextStyle(color: paper, fontWeight: FontWeight.bold),
    ),
  );
  Widget _bag() {
    final b = list('balls');
    return board(
      Column(
        children: [
          DragTarget<String>(
            onWillAcceptWithDetails: (_) =>
                !widget.locked &&
                b.length < (widget.spec.config['capacity'] as int? ?? 6),
            onAcceptWithDetails: (e) => addBall(e.data),
            builder: (context, c, rejected) => Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 170),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.isNotEmpty
                    ? BrilliantPalette.successSurface
                    : BrilliantPalette.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                  bottom: Radius.circular(60),
                ),
                border: Border.all(color: BrilliantPalette.border, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    'TÚI • ${b.length}/${widget.spec.config['capacity'] ?? 6} VIÊN',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < b.length; i++)
                        Semantics(
                          label: 'Lấy viên ${i + 1} ra',
                          button: true,
                          child: GestureDetector(
                            onTap: () {
                              b.removeAt(i);
                              change('balls', b);
                            },
                            child: ball(b[i]),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          note('Kéo viên vào túi. Chạm viên trong túi để lấy ra.'),
          Wrap(
            spacing: 24,
            children: [
              for (final color in ['B', 'R'])
                Draggable<String>(
                  data: color,
                  maxSimultaneousDrags: widget.locked ? 0 : 1,
                  feedback: Material(
                    color: Colors.transparent,
                    child: ball(color),
                  ),
                  child: ball(color),
                ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [
              button('Thêm xanh', () => addBall('B')),
              button('Thêm đỏ', () => addBall('R')),
            ],
          ),
          note(
            b.isEmpty
                ? 'Túi đang rỗng • thêm viên để tạo xác suất.'
                : 'Xác suất xanh hiện tại: ${b.where((v) => v == 'B').length}/${b.length}',
          ),
        ],
      ),
    );
  }

  void addOutcome(String value) {
    final outcomes = list('outcomes');
    if (!outcomes.contains(value)) {
      outcomes.add(value);
      change('outcomes', outcomes);
    }
  }

  Widget _space() {
    final outcomes = list('outcomes');
    return board(
      Column(
        children: [
          const Text('S = sấp • N = ngửa'),
          const SizedBox(height: 12),
          DragTarget<String>(
            onAcceptWithDetails: (e) => addOutcome(e.data),
            builder: (context, c, rejected) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.isNotEmpty
                    ? BrilliantPalette.successSurface
                    : BrilliantPalette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BrilliantPalette.border),
              ),
              child: Column(
                children: [
                  const Text('KHÔNG GIAN MẪU'),
                  const SizedBox(height: 12),
                  for (int row = 0; row < 2; row++)
                    Row(
                      children: [
                        for (int col = 0; col < 2; col++)
                          Expanded(
                            child: Container(
                              height: 70,
                              margin: const EdgeInsets.all(4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: paper,
                                border: Border.all(
                                  color: BrilliantPalette.track,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                outcomes.length > row * 2 + col
                                    ? outcomes[row * 2 + col]
                                    : '·',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          note('Tạo một cặp rồi kéo vào bảng. Cặp trùng sẽ không được thêm.'),
          _CoinComposer(onAdd: addOutcome, locked: widget.locked),
          button('Xóa bảng', () => change('outcomes', <String>[])),
        ],
      ),
    );
  }

  Widget _spinner() {
    final sectors = _sectors ?? d['sectors'] as int;
    return board(
      Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, c) => GestureDetector(
                onPanUpdate: (e) {
                  final center = Offset(c.maxWidth / 2, c.maxWidth / 2);
                  final delta = e.localPosition - center;
                  double angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
                  if (angle < 0) angle += math.pi * 2;
                  setState(
                    () => _sectors = (angle / (math.pi * 2) * 8).round().clamp(
                      0,
                      8,
                    ),
                  );
                },
                onPanEnd: (_) {
                  change('sectors', _sectors ?? sectors);
                  setState(() => _sectors = null);
                },
                child: CustomPaint(
                  painter: _ScenePainter('spinner', {'sectors': sectors}),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          note('$sectors/8 vòng có màu xanh'),
          Slider(
            value: sectors.toDouble(),
            min: 0,
            max: 8,
            divisions: 8,
            label: '$sectors trên 8',
            semanticFormatterCallback: (v) => '${v.round()} cung xanh trên 8',
            onChanged: (v) => setState(() => _sectors = v.round()),
            onChangeEnd: (v) {
              change('sectors', v.round());
              setState(() => _sectors = null);
            },
          ),
          note('Kéo quanh vòng hoặc dùng thanh chia cung.'),
        ],
      ),
    );
  }
}

class _CoinComposer extends StatefulWidget {
  const _CoinComposer({required this.onAdd, required this.locked});
  final ValueChanged<String> onAdd;
  final bool locked;
  @override
  State<_CoinComposer> createState() => _CoinComposerState();
}

class _CoinComposerState extends State<_CoinComposer> {
  final coins = ['S', 'S'];
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Wrap(
        spacing: 12,
        children: [
          for (int i = 0; i < 2; i++)
            OutlinedButton(
              onPressed: widget.locked
                  ? null
                  : () =>
                        setState(() => coins[i] = coins[i] == 'S' ? 'N' : 'S'),
              child: Text('Xu ${i + 1}: ${coins[i]}'),
            ),
        ],
      ),
      Draggable<String>(
        data: coins.join(),
        maxSimultaneousDrags: widget.locked ? 0 : 1,
        feedback: Material(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(coins.join(), style: const TextStyle(fontSize: 24)),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BrilliantPalette.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Kéo cặp ${coins.join()}'),
        ),
      ),
      TextButton(
        onPressed: widget.locked ? null : () => widget.onAdd(coins.join()),
        child: const Text('Thêm cặp vào bảng'),
      ),
    ],
  );
}

Offset _node(int i, Size s) => [
  Offset(s.width * .18, s.height * .18),
  Offset(s.width * .82, s.height * .18),
  Offset(s.width * .82, s.height * .82),
  Offset(s.width * .18, s.height * .82),
][i];

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.kind, this.data);
  final String kind;
  final Map<String, dynamic> data;
  void label(
    Canvas canvas,
    String text,
    Offset at, {
    Color color = ink,
    double size = 14,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'CofoBrilliant',
          fontFamilyFallback: const ['NotoSans'],
          fontSize: size,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = BrilliantPalette.track
      ..strokeWidth = 1;
    if (kind == 'polygon') {
      final unit = size.width / 5;
      Offset at(List v) => Offset((v[0] + .5) * unit, (v[1] + .5) * unit);
      for (int i = 0; i < 5; i++) {
        canvas.drawLine(
          Offset(unit / 2, (i + .5) * unit),
          Offset(unit * 4.5, (i + .5) * unit),
          p,
        );
        canvas.drawLine(
          Offset((i + .5) * unit, unit / 2),
          Offset((i + .5) * unit, unit * 4.5),
          p,
        );
      }
      final points = data['points'] as List;
      final path = Path()..moveTo(at(points[0]).dx, at(points[0]).dy);
      for (final pt in points.skip(1)) {
        path.lineTo(at(pt).dx, at(pt).dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = green.withValues(alpha: .25));
      canvas.drawPath(
        path,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (int i = 0; i < 4; i++) {
        canvas.drawCircle(at(points[i]), 14, Paint()..color = green);
        label(canvas, '${i + 1}', at(points[i]));
      }
    }
    if (kind == 'triangle' || kind == 'tangram') {
      void triangle(int turn, int index, Size s) {
        canvas.save();
        canvas.translate(s.width / 2, s.height / 2);
        canvas.rotate(turn * math.pi / 2);
        final path = Path()
          ..moveTo(-s.width / 2, -s.height / 2)
          ..lineTo(s.width / 2, -s.height / 2)
          ..lineTo(-s.width / 2, s.height / 2)
          ..close();
        canvas.drawPath(
          path,
          Paint()..color = index == 0 ? green : const Color(0xFFCCCCCC),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = ink
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );
        canvas.restore();
      }

      if (kind == 'triangle') {
        triangle(data['turn'], data['index'], size);
      } else {
        for (int i = 0; i < 2; i++) {
          if (data['placed'][i]) triangle(data['turns'][i], i, size);
        }
      }
    }
    if (kind == 'robot') {
      final unit = math.min(size.width, size.height) / 4;
      for (int i = 0; i <= 4; i++) {
        canvas.drawLine(Offset(i * unit, 0), Offset(i * unit, unit * 4), p);
        canvas.drawLine(Offset(0, i * unit), Offset(unit * 4, i * unit), p);
      }
      if (data['obstacle'] == true) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(unit + 5, unit + 5, unit - 10, unit - 10),
            const Radius.circular(8),
          ),
          Paint()..color = BrilliantPalette.border,
        );
      }
      label(
        canvas,
        '★',
        Offset(unit * 3.5, unit * 3.5),
        color: BrilliantPalette.successInk,
        size: 30,
      );
      int x = 0, y = 0;
      bool invalid = false;
      Offset at() => Offset((x + .5) * unit, (y + .5) * unit);
      final path = Path()..moveTo(at().dx, at().dy);
      for (final c in data['commands'] as List) {
        if (c == 'R') x++;
        if (c == 'L') x--;
        if (c == 'D') y++;
        if (c == 'U') y--;
        if (x < 0 ||
            x > 3 ||
            y < 0 ||
            y > 3 ||
            (data['obstacle'] == true && x == 1 && y == 1)) {
          invalid = true;
          break;
        }
        path.lineTo(at().dx, at().dy);
      }
      final metrics = path.computeMetrics().toList();
      final metric = metrics.isEmpty ? null : metrics.first;
      final distance = ((data['steps'] as num? ?? 32) * unit).toDouble();
      final visible = metric == null
          ? path
          : metric.extractPath(0, math.min(distance, metric.length));
      canvas.drawPath(
        visible,
        Paint()
          ..color = invalid ? ink : green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      x = x.clamp(0, 3);
      y = y.clamp(0, 3);
      final robot =
          metric
              ?.getTangentForOffset(math.min(distance, metric.length))
              ?.position ??
          const Offset(.5, .5) * unit;
      canvas.drawCircle(robot, unit * .22, Paint()..color = ink);
      label(canvas, invalid ? '!' : '●', robot, color: paper, size: 18);
    }
    if (kind == 'logic') {
      final switches = data['switches'] as List;
      final lit = (switches[0] || switches[1]) && switches[2];
      final left = size.width * .12, right = size.width * .7;
      final x = size.width * .4;
      void wire(Offset a, Offset b, {bool active = false}) => canvas.drawLine(
        a,
        b,
        Paint()
          ..color = active ? green : ink
          ..strokeWidth = 3,
      );
      for (int i = 0; i < 2; i++) {
        final y = i == 0 ? 35.0 : 90.0;
        wire(Offset(left, y), Offset(x - 14, y), active: lit && switches[i]);
        wire(Offset(x + 14, y), Offset(right, y), active: lit && switches[i]);
        wire(
          Offset(x - 14, y),
          Offset(x + 14, switches[i] ? y : y - 16),
          active: lit && switches[i],
        );
        for (final dx in [-14.0, 14.0]) {
          canvas.drawCircle(Offset(x + dx, y), 4, Paint()..color = ink);
        }
        label(canvas, i == 0 ? 'A' : 'B', Offset(x, y + 16));
      }
      wire(Offset(left, 35), Offset(left, 145), active: lit);
      wire(Offset(right, 35), Offset(right, 90), active: lit);
      wire(Offset(right, 63), Offset(size.width * .88, 63), active: lit);
      wire(
        Offset(size.width * .88, 63),
        Offset(size.width * .88, 145),
        active: lit,
      );
      wire(Offset(left, 145), Offset(x - 14, 145), active: lit);
      wire(Offset(x + 14, 145), Offset(size.width * .88, 145), active: lit);
      wire(
        Offset(x - 14, 145),
        Offset(x + 14, switches[2] ? 145 : 129),
        active: lit,
      );
      label(canvas, 'C', Offset(x, 165));
      final glow = (data['glow'] as num? ?? (lit ? 1 : 0)).toDouble();
      final lamp = Offset(size.width * .88, 103);
      canvas.drawCircle(
        lamp,
        13 + 10 * glow,
        Paint()..color = green.withValues(alpha: .18 * glow),
      );
      canvas.drawCircle(
        lamp,
        13,
        Paint()..color = Color.lerp(BrilliantPalette.track, green, glow)!,
      );
      label(canvas, '×', Offset(size.width * .88, 103));
      canvas.drawCircle(Offset(left, 118), 14, Paint()..color = paper);
      label(canvas, '+ −', Offset(left, 118), size: 12);
    }
    if (kind == 'network') {
      final stages = data['stages'] as List;
      final results = data['result'] as List;
      final left = 24.0, right = size.width - 24;
      final step = (right - left) / (stages.length + 1);
      for (int i = 0; i < 4; i++) {
        final y = 35.0 + i * 45;
        canvas.drawLine(
          Offset(left, y),
          Offset(right, y),
          Paint()
            ..color = BrilliantPalette.border
            ..strokeWidth = 2,
        );
        label(canvas, '${[4, 1, 3, 2][i]}', Offset(10, y));
        if (results.length == 4) {
          label(
            canvas,
            '${results[i]}',
            Offset(size.width - 9, y),
            color: BrilliantPalette.successInk,
          );
        }
      }
      for (int i = 0; i < stages.length; i++) {
        final x = left + step * (i + 1), y = 35.0 + (stages[i] as int) * 45;
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + 45),
          Paint()
            ..color = ink
            ..strokeWidth = 3,
        );
        canvas.drawCircle(Offset(x, y), 5, Paint()..color = green);
        canvas.drawCircle(Offset(x, y + 45), 5, Paint()..color = green);
        label(canvas, '${i + 1}', Offset(x, 195), size: 11);
      }
    }
    if (kind == 'wire') {
      final edges = data['edges'] as List;
      final closed =
          edges.length == 2 && edges.toSet().containsAll(['0-1', '2-3']);
      final shorted = edges.any((edge) => !['0-1', '2-3'].contains(edge));
      final lamp = Offset(_node(1, size).dx, size.height / 2);
      final source = Offset(_node(0, size).dx, size.height / 2);
      final fixedPaint = Paint()
        ..color = ink
        ..strokeWidth = 3;
      canvas.drawLine(_node(1, size), _node(2, size), fixedPaint);
      canvas.drawLine(_node(0, size), _node(3, size), fixedPaint);
      final glow = (data['glow'] as num? ?? (closed ? 1 : 0)).toDouble();
      canvas.drawCircle(
        lamp,
        20 + 13 * glow,
        Paint()..color = green.withValues(alpha: .18 * glow),
      );
      canvas.drawCircle(
        lamp,
        20,
        Paint()..color = Color.lerp(paper, green, glow)!,
      );
      canvas.drawCircle(
        lamp,
        20,
        Paint()
          ..color = ink
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      label(canvas, '×', lamp, size: 26);
      canvas.drawRect(
        Rect.fromCenter(center: source, width: 40, height: 26),
        Paint()..color = paper,
      );
      canvas.drawLine(
        source + const Offset(-18, -6),
        source + const Offset(18, -6),
        fixedPaint,
      );
      canvas.drawLine(
        source + const Offset(-10, 6),
        source + const Offset(10, 6),
        fixedPaint,
      );
      for (final edge in edges) {
        final nodes = (edge as String).split('-').map(int.parse).toList();
        canvas.drawLine(
          _node(nodes[0], size),
          _node(nodes[1], size),
          Paint()
            ..color = shorted ? const Color(0xFFE55F45) : green
            ..strokeWidth = 5,
        );
      }
      for (int i = 0; i < 4; i++) {
        label(
          canvas,
          ['+ nguồn', 'đèn vào', 'đèn ra', '− nguồn'][i],
          _node(i, size) + Offset(0, i < 2 ? -32 : 32),
          size: 12,
        );
      }
      label(
        canvas,
        shorted
            ? 'NỐI TẮT!'
            : closed
            ? 'SÁNG'
            : 'TẮT',
        Offset(size.width / 2, size.height / 2),
        size: 12,
      );
    }
    if (kind == 'spinner') {
      final center = Offset(size.width / 2, size.height / 2),
          r = size.width * .4;
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawCircle(center, r, Paint()..color = BrilliantPalette.surface);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        (data['sectors'] as int) * math.pi / 4,
        true,
        Paint()..color = green,
      );
      for (int i = 0; i < 8; i++) {
        final a = -math.pi / 2 + i * math.pi / 4;
        canvas.drawLine(
          center,
          center + Offset(math.cos(a) * r, math.sin(a) * r),
          Paint()
            ..color = paper
            ..strokeWidth = 2,
        );
      }
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final a = -math.pi / 2 + (data['sectors'] as int) * math.pi / 4;
      canvas.drawCircle(
        center + Offset(math.cos(a) * r, math.sin(a) * r),
        12,
        Paint()..color = ink,
      );
      canvas.drawCircle(center, 24, Paint()..color = paper);
      label(canvas, '${data['sectors']}/8', center);
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) => true;
}
