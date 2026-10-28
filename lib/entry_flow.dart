import 'app_layout.dart';
import 'features/account/cloud_account_page.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_motion.dart';
import 'learning_store.dart';

/// Device profiles are explicit here; this screen does not simulate authentication.
class EntryPage extends StatefulWidget {
  const EntryPage({super.key, required this.store});
  final LearningStore store;
  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted && widget.store.saveError != null) {
        setState(() => _error = widget.store.saveError);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Chưa mở được hồ sơ. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _create() {
    if (_form.currentState!.validate()) {
      _run(() => widget.store.createDeviceProfile(_name.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudScope.maybeOf(context);
    final profiles = cloud?.profiles ?? widget.store.profiles;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: AppLayout.pagePadding,
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Brand(),
                    const CloudSessionBar(),
                    const SizedBox(height: 20),
                    const _DiscoveryArt(height: 174),
                    const SizedBox(height: 24),
                    Text(
                      profiles.isEmpty
                          ? 'Chạm vào điều\nbạn chưa biết.'
                          : 'Một chút tò mò.\nMột khám phá mới.',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Kéo, xoay, ghép và thử. Tự tìm ra lời giải bằng chính đôi tay của bạn.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: BrilliantPalette.secondaryText,
                      ),
                    ),
                    if (profiles.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      const Text(
                        'TIẾP TỤC HỒ SƠ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final profile in profiles)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            key: ValueKey('profile-${profile.id}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _busy
                                ? null
                                : () => _run(
                                    () => widget.store.activateProfile(
                                      profile.id,
                                    ),
                                  ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 28),
                    Text(
                      profiles.isEmpty
                          ? 'Tạo góc khám phá của bạn'
                          : 'Hoặc tạo hồ sơ mới',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const ValueKey('entry-name'),
                      controller: _name,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Bạn muốn được gọi là gì?',
                        hintText: 'Tên hoặc biệt danh',
                        counterText: '',
                      ),
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        return name.isEmpty || name.length > 40
                            ? 'Nhập tên từ 1 đến 40 ký tự.'
                            : null;
                      },
                      onFieldSubmitted: (_) => _create(),
                    ),
                    const SizedBox(height: 18),
                    PrimaryAction(
                      expand: true,
                      key: const ValueKey('entry-create'),
                      onPressed: _busy ? null : _create,
                      child: Text(
                        _busy ? 'Đang mở hồ sơ…' : 'Bắt đầu khám phá',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.phonelink_lock_outlined,
                          size: 18,
                          color: BrilliantPalette.secondaryText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cloud == null
                                ? 'Hồ sơ trên thiết bị • Học được khi offline.'
                                : 'Tiến độ tự lưu lên tài khoản khi có mạng. Khi offline, dữ liệu được giữ trên thiết bị và gửi lại khi kết nối.',
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: BrilliantPalette.secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const CloudAccountButton(),
                    if (_error != null || widget.store.saveError != null)
                      _ErrorNote(_error ?? widget.store.saveError!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.store});
  final LearningStore store;
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _step = 0;
  int _minutes = 10;
  final Set<String> _interests = {};
  bool _busy = false;
  String? _error;
  static const _topics = <String, (String, IconData)>{
    'logic': ('Logic', Icons.extension_outlined),
    'math': ('Toán học', Icons.functions),
    'science': ('Khoa học', Icons.science_outlined),
    'data': ('Dữ liệu', Icons.bar_chart),
    'geometry': ('Hình học', Icons.category_outlined),
    'coding': ('Lập trình', Icons.code),
    'circuits': ('Mạch điện', Icons.electric_bolt_outlined),
    'probability': ('Xác suất', Icons.casino_outlined),
  };

  Future<void> _continue() async {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.store.finishOnboarding(
        _interests.isEmpty ? _topics.keys.toList() : _interests.toList(),
        _minutes,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa lưu được lựa chọn. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
          child: SingleChildScrollView(
            padding: AppLayout.pagePadding,
            child: MotionEntrance(
              replayKey: _step,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (_step == 1)
                        IconButton(
                          key: const ValueKey('onboarding-back'),
                          onPressed: _busy
                              ? null
                              : () => setState(() => _step = 0),
                          tooltip: 'Quay lại sở thích',
                          icon: const Icon(Icons.arrow_back),
                        ),
                      const Expanded(child: _Brand()),
                      Text(
                        '${_step + 1} / 2',
                        style: const TextStyle(
                          color: BrilliantPalette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  const CloudSessionBar(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (int i = 0; i < 2; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: i <= _step
                                  ? green
                                  : BrilliantPalette.track,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _DiscoveryArt(height: 128, rhythm: _step == 1),
                  const SizedBox(height: 24),
                  Text(
                    _step == 0
                        ? 'Điều gì khiến\nbạn tò mò?'
                        : 'Dành một khoảng\nnhỏ để khám phá.',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _step == 0
                        ? 'Chọn những thế giới bạn muốn chạm vào. Bạn luôn có thể khám phá thêm sau.'
                        : 'Chọn nhịp học phù hợp với bạn. Không cần vội, cũng không có áp lực giữ chuỗi.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: BrilliantPalette.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_step == 0) ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final topic in _topics.entries)
                          FilterChip(
                            key: ValueKey('interest-${topic.key}'),
                            avatar: Icon(topic.value.$2, size: 20),
                            label: Text(topic.value.$1),
                            selected: _interests.contains(topic.key),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 13,
                            ),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                _interests.add(topic.key);
                              } else {
                                _interests.remove(topic.key);
                              }
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      key: const ValueKey('interest-all'),
                      onPressed: () => setState(() => _interests.clear()),
                      icon: Icon(
                        _interests.isEmpty
                            ? Icons.check_circle
                            : Icons.explore_outlined,
                        size: 20,
                      ),
                      label: const Text('Khám phá tất cả'),
                    ),
                  ] else ...[
                    for (final minutes in [5, 10, 20])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Semantics(
                          selected: _minutes == minutes,
                          container: true,
                          child: OutlinedButton(
                            key: ValueKey('minutes-$minutes'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _minutes == minutes
                                  ? Theme.of(context).colorScheme.primary
                                        .withValues(alpha: .1)
                                  : Theme.of(context).colorScheme.surface,
                              side: BorderSide(
                                color: _minutes == minutes
                                    ? Theme.of(context).colorScheme.primary
                                    : BrilliantPalette.track,
                                width: _minutes == minutes ? 2 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.all(18),
                            ),
                            onPressed: _busy
                                ? null
                                : () => setState(() => _minutes = minutes),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 24),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$minutes phút mỗi ngày',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        minutes == 5
                                            ? 'Một tia ý tưởng'
                                            : minutes == 10
                                            ? 'Vừa đủ cho một khám phá'
                                            : 'Một chuyến phiêu lưu nhỏ',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: BrilliantPalette.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_minutes == minutes)
                                  const Icon(
                                    Icons.check_circle,
                                    color: BrilliantPalette.successInk,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryAction(
                    expand: true,
                    key: const ValueKey('onboarding-continue'),
                    onPressed: _busy ? null : _continue,
                    child: Text(
                      _busy
                          ? 'Đang lưu…'
                          : _step == 0
                          ? 'Tiếp tục'
                          : 'Vào thế giới khám phá',
                    ),
                  ),
                  if (_error != null) _ErrorNote(_error!),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) => const FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, color: ink, size: 28),
        SizedBox(width: 8),
        Text(
          'Matlingo',
          maxLines: 1,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
      ],
    ),
  );
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF000000), fontSize: 14),
      ),
    ),
  );
}

class _DiscoveryArt extends StatelessWidget {
  const _DiscoveryArt({required this.height, this.rhythm = false});
  final double height;
  final bool rhythm;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(rhythm),
        tween: Tween(begin: 0, end: 1),
        duration: AppMotion.duration(context, 800),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) =>
            CustomPaint(painter: _DiscoveryPainter(rhythm, progress)),
      ),
    ),
  );
}

/// Original geometric illustration using the palette observed in the REA CSS.
class _DiscoveryPainter extends CustomPainter {
  _DiscoveryPainter(this.rhythm, this.progress);
  final bool rhythm;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 360, size.height / 170);
    canvas.save();
    canvas.translate((size.width - 360 * s) / 2, (size.height - 170 * s) / 2);
    canvas.scale(s);
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final line = Paint()
      ..color = BrilliantPalette.track
      ..strokeWidth = 1;
    for (double x = 10; x < 360; x += 22) {
      for (double y = 8; y < 170; y += 22) {
        canvas.drawCircle(Offset(x, y), 1, line);
      }
    }
    if (rhythm) {
      final path = Path()
        ..moveTo(24, 130)
        ..cubicTo(84, 130, 63, 40, 124, 45)
        ..cubicTo(177, 51, 162, 139, 222, 129)
        ..cubicTo(267, 118, 257, 32, 329, 32);
      canvas.drawPath(path, stroke);
      for (final point in [
        const Offset(45, 125),
        const Offset(124, 45),
        const Offset(222, 129),
        const Offset(314, 34),
      ]) {
        canvas.drawCircle(point, 13, Paint()..color = green);
        canvas.drawCircle(point, 13, stroke);
      }
      canvas.drawCircle(const Offset(124, 45), 4, Paint()..color = ink);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(46, 115)
          ..cubicTo(90, 20, 198, 167, 311, 49),
        stroke,
      );
      canvas.save();
      canvas.translate(79 - (1 - progress) * 28, 64 - (1 - progress) * 16);
      canvas.rotate(-.22 - (1 - progress) * .5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-31, -31, 62, 62),
          const Radius.circular(10),
        ),
        Paint()..color = BrilliantPalette.surface,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-31, -31, 62, 62),
          const Radius.circular(10),
        ),
        stroke,
      );
      canvas.restore();
      canvas.save();
      canvas.translate(182, 103);
      canvas.scale(.7 + .3 * progress);
      canvas.translate(-182, -103);
      canvas.drawCircle(const Offset(182, 103), 39, Paint()..color = green);
      canvas.drawCircle(const Offset(182, 103), 39, stroke);
      canvas.drawArc(
        const Rect.fromLTWH(164, 89, 36, 22),
        0,
        math.pi,
        false,
        stroke,
      );
      canvas.drawCircle(const Offset(171, 90), 2.6, Paint()..color = ink);
      canvas.drawCircle(const Offset(192, 90), 2.6, Paint()..color = ink);
      canvas.restore();
      canvas.save();
      canvas.translate(288, 67);
      canvas.rotate((1 - progress) * .4);
      canvas.translate(-288, -67);
      final triangle = Path()
        ..moveTo(288, 24)
        ..lineTo(324, 88)
        ..lineTo(253, 88)
        ..close();
      canvas.drawPath(triangle, Paint()..color = BrilliantPalette.surface);
      canvas.drawPath(triangle, stroke);
      canvas.restore();
      canvas.drawCircle(const Offset(47, 132), 7, Paint()..color = ink);
      canvas.drawCircle(const Offset(325, 122), 7, Paint()..color = green);
      canvas.drawLine(const Offset(226, 23), const Offset(226, 39), stroke);
      canvas.drawLine(const Offset(218, 31), const Offset(234, 31), stroke);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DiscoveryPainter oldDelegate) =>
      rhythm != oldDelegate.rhythm || progress != oldDelegate.progress;
}
