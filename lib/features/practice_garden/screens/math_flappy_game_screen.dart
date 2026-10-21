import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum _GameMode { easy, medium, hard }

class MathFlappyGameScreen extends StatefulWidget {
  const MathFlappyGameScreen({super.key});
  @override
  State<MathFlappyGameScreen> createState() => _MathFlappyGameScreenState();
}

class _MathFlappyGameScreenState extends State<MathFlappyGameScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  final _random = math.Random();
  final List<_Gate> _gates = [];
  double _birdY = .5, _speed = 0, _last = 0;
  int _lives = 3, _score = 0;
  bool _playing = false, _over = false;
  String? _feedbackText;
  bool _feedbackCorrect = false;
  Timer? _feedbackTimer;
  _GameMode? _mode;

  String get _modeLabel => switch (_mode) {
    _GameMode.easy => 'Dễ',
    _GameMode.medium => 'Vừa',
    _GameMode.hard => 'Khó',
    null => '',
  };

  double get _scrollSpeed => switch (_mode) {
    _GameMode.easy => .20,
    _GameMode.medium => .28,
    _GameMode.hard => .36,
    null => .28,
  };

  double get _gravity => switch (_mode) {
    _GameMode.easy => 1.15,
    _GameMode.medium => 1.45,
    _GameMode.hard => 1.8,
    null => 1.45,
  };

  @override
  void initState() {
    super.initState();
    _reset();
    _clock = AnimationController(vsync: this, duration: const Duration(days: 1))
      ..addListener(_tick)
      ..repeat();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  void _reset([_GameMode? mode]) {
    if (mode != null) _mode = mode;
    _birdY = .5;
    _speed = 0;
    _lives = 3;
    _score = 0;
    _playing = false;
    _over = false;
    _feedbackText = null;
    _feedbackCorrect = false;
    _feedbackTimer?.cancel();
    _last = 0;
    _gates
      ..clear()
      ..add(_gate(1));
  }

  _Gate _gate(double x) {
    final maximum = switch (_mode) {
      _GameMode.easy => 10,
      _GameMode.medium => 50,
      _GameMode.hard => 100,
      null => 50,
    };
    final a = 1 + _random.nextInt(maximum),
        b = 1 + _random.nextInt(maximum),
        add = _mode == _GameMode.easy || _random.nextBool();
    final answer = add ? a + b : (a >= b ? a - b : b - a);
    final spread = switch (_mode) {
      _GameMode.easy => 3,
      _GameMode.medium => 8,
      _GameMode.hard => 15,
      null => 8,
    };
    final values = {answer};
    while (values.length < 3) {
      values.add(
        math.max(0, answer + _random.nextInt(spread * 2 + 1) - spread),
      );
    }
    final choices = values.toList()..shuffle(_random);
    return _Gate(
      x,
      add ? '$a + $b' : '${math.max(a, b)} - ${math.min(a, b)}',
      answer,
      choices,
    );
  }

  void _tick() {
    if (!_playing || _over || !mounted) return;
    final now = _clock.lastElapsedDuration?.inMicroseconds.toDouble() ?? 0;
    final dt = _last == 0 ? .016 : math.min((now - _last) / 1000000, .04);
    _last = now;
    setState(() {
      _speed += _gravity * dt;
      _birdY += _speed * dt;
      for (final g in _gates) {
        g.x -= _scrollSpeed * dt;
      }
      if (_gates.last.x < .30) _gates.add(_gate(1.18));
      if (_gates.first.x < -.28) _gates.removeAt(0);
      _collide();
    });
  }

  void _collide() {
    if (_birdY < .06 || _birdY > .94) {
      _lose();
      return;
    }
    for (final g in _gates) {
      if (g.hit || (g.x - .22).abs() >= .09) continue;
      final slot = ((_birdY - g.top) / (g.slot + g.gap)).floor().clamp(0, 2);
      final answerArea = g.slot * 3 + g.gap * 2;
      if (_birdY >= g.top && _birdY <= g.top + answerArea) {
        g.hit = true;
        if (g.choices[slot] == g.answer) {
          _score++;
          g.resultCorrect = true;
          g.selectedSlot = slot;
          _showFeedback('Đúng! +1 điểm', true);
        } else {
          g.resultCorrect = false;
          g.selectedSlot = slot;
          _showFeedback('Sai rồi! Đáp án đúng là ${g.answer}', false);
          _lose();
        }
      } else if (_birdY < g.top || _birdY > g.top + answerArea) {
        g.hit = true;
        _showFeedback('Hụt rồi! Hãy bay qua một ô đáp án.', false);
        _lose();
      }
    }
  }

  void _showFeedback(String text, bool correct) {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _feedbackText = null;
      });
    });
    _feedbackText = text;
    _feedbackCorrect = correct;
  }

  void _lose() {
    if (_over) return;
    _lives--;
    _speed = -.35;
    if (_lives == 0) {
      _over = true;
      _playing = false;
    }
  }

  void _flap() {
    if (_over) return;
    setState(() {
      _playing = true;
      _last = 0;
      _speed = -.62;
    });
  }

  Widget _buildModeSelector() => Center(
    child: Card(
      margin: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chọn độ khó',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('Tốc độ bay và phép tính sẽ thay đổi theo chế độ.'),
            const SizedBox(height: 20),
            _modeButton(
              'Dễ',
              'Phép tính nhỏ, chim bay chậm',
              _GameMode.easy,
              Colors.green,
            ),
            _modeButton(
              'Vừa',
              'Phép tính đến 50',
              _GameMode.medium,
              AppColors.primary,
            ),
            _modeButton(
              'Khó',
              'Phép tính đến 100, bay nhanh',
              _GameMode.hard,
              AppColors.accentRed,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _modeButton(String label, String hint, _GameMode mode, Color color) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () => setState(() => _reset(mode)),
            child: Column(
              children: [
                Text(label),
                Text(hint, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      );

  Widget _buildBody() => _mode == null
      ? _buildModeSelector()
      : GestureDetector(
          onTap: _flap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _Painter(_birdY, _gates)),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _HudChip(
                      icon: Icons.favorite_rounded,
                      label: '$_lives/3',
                      color: AppColors.heart,
                    ),
                    const SizedBox(width: 8),
                    _HudChip(
                      icon: Icons.speed_rounded,
                      label: _modeLabel,
                      color: AppColors.primary,
                    ),
                    const Spacer(),
                    _HudChip(
                      icon: Icons.star_rounded,
                      label: '$_score',
                      color: AppColors.accentGold,
                    ),
                  ],
                ),
              ),
              if (_feedbackText != null)
                Positioned(
                  top: 72,
                  left: 16,
                  right: 16,
                  child: _FeedbackBanner(
                    text: _feedbackText!,
                    correct: _feedbackCorrect,
                  ),
                ),

              if (_feedbackText != null)
                Positioned(
                  top: 72,
                  left: 16,
                  right: 16,
                  child: _FeedbackBanner(
                    text: _feedbackText!,
                    correct: _feedbackCorrect,
                  ),
                ),
              if (!_playing && !_over)
                const _Message(
                  'Math Flappy',
                  'Bay qua khoảng trống có đáp án đúng\nChạm màn hình để bắt đầu',
                ),
              if (_over)
                _Message(
                  'Hết tim rồi!',
                  'Bé trả lời đúng $_score câu',
                  ElevatedButton.icon(
                    onPressed: () => setState(_reset),
                    icon: const Icon(Icons.replay),
                    label: const Text('Chơi lại'),
                  ),
                ),
            ],
          ),
        );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFBAE6FD),
    appBar: AppBar(
      title: const Text('Math Flappy'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              'Điểm $_score',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ),
    body: _buildBody(),

    /* Gesture handling is contained in _buildBody. */
    /*
      GestureDetector(
      onTap: _flap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _Painter(_birdY, _gates)),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const Text(
                  'Tim: ',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                ...List.generate(
                  3,
                  (i) => Icon(
                    i < _lives ? Icons.favorite : Icons.favorite_border,
                    color: AppColors.heart,
                    size: 28,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Chạm để bay',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (!_playing && !_over)
            const _Message(
              'Math Flappy',
              'Bay qua ô có đáp án đúng\nChạm màn hình để bắt đầu',
            ),
          if (_over)
            _Message(
              'Hết tim rồi!',
              'Bé trả lời đúng $_score câu',
              ElevatedButton.icon(
                onPressed: () => setState(_reset),
                icon: const Icon(Icons.replay),
                label: const Text('Chơi lại'),
              ),
            ),
        ],
      ),
    ),
    */
  );
}

class _Gate {
  _Gate(this.x, this.expression, this.answer, this.choices);
  double x;
  final String expression;
  final int answer;
  final List<int> choices;
  bool hit = false;
  bool? resultCorrect;
  int? selectedSlot;
  double get top => .25;
  // Each answer is a narrow flight lane separated by a solid green bar.
  double get slot => .085;
  double get gap => .045;
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(220),
      borderRadius: BorderRadius.circular(999),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.text, required this.correct});

  final String text;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.accentGreen : AppColors.accentRed;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(correct ? Icons.check_circle : Icons.cancel, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.title, this.subtitle, [this.action]);
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext c) => Center(
    child: Card(
      margin: const EdgeInsets.all(32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(c).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    ),
  );
}

class _Painter extends CustomPainter {
  const _Painter(this.birdY, this.gates);
  final double birdY;
  final List<_Gate> gates;
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Rect.fromLTWH(0, s.height - 42, s.width, 42),
      Paint()..color = const Color(0xFF86EFAC),
    );
    final bird = Offset(s.width * .22, s.height * birdY);
    c.drawCircle(bird, 20, Paint()..color = AppColors.accentGold);
    c.drawCircle(bird + const Offset(7, -5), 4, Paint()..color = Colors.white);
    for (final g in gates) {
      final x = g.x * s.width,
          top = g.top * s.height,
          slot = g.slot * s.height,
          gap = g.gap * s.height,
          w = s.width * .16,
          p = Paint()..color = const Color(0xFF16A34A);
      c.drawRect(Rect.fromLTWH(x - w / 2, 0, w, top), p);
      final answerArea = slot * 3 + gap * 2;
      c.drawRect(Rect.fromLTWH(x - w / 2, top + answerArea, w, s.height), p);
      // Keep separators and answer boxes aligned with the obstacle columns.
      for (var i = 0; i < 2; i++) {
        c.drawRect(
          Rect.fromLTWH(x - w / 2, top + slot * (i + 1) + gap * i, w, gap),
          p,
        );
      }
      for (var i = 0; i < 3; i++) {
        final gapRect = Rect.fromLTWH(
          x - w / 2,
          top + i * (slot + gap),
          w,
          slot - 5,
        );
        final laneColor = g.resultCorrect == null
            ? const Color(0xFFBAE6FD)
            : g.resultCorrect! && g.selectedSlot == i
            ? AppColors.accentGreenLight
            : !g.resultCorrect! && g.selectedSlot == i
            ? AppColors.accentRedLight
            : !g.resultCorrect! && g.choices[i] == g.answer
            ? AppColors.accentGreenLight
            : const Color(0xFFBAE6FD);
        c.drawRect(gapRect, Paint()..color = laneColor);
        final t = TextPainter(
          text: TextSpan(
            text: '${g.choices[i]}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        t.paint(
          c,
          Offset(
            x - t.width / 2,
            top + i * (slot + gap) + (slot - t.height) / 2,
          ),
        );
      }
      final q = TextPainter(
        text: TextSpan(
          text: g.expression,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      q.paint(c, Offset(x - q.width / 2, top - 28));
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
