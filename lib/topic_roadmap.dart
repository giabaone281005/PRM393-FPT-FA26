import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'learning_catalog.dart';
import 'learning_store.dart';
import 'lesson_theme.dart';

/// Checkpoints preview activities; only validated learning marks them complete.
class TopicRoadmap extends StatefulWidget {
  const TopicRoadmap({super.key, required this.topic, required this.store});
  final LearningTopic topic;
  final LearningStore store;
  @override
  State<TopicRoadmap> createState() => _TopicRoadmapState();
}

class _TopicRoadmapState extends State<TopicRoadmap> {
  int? selected;

  @override
  Widget build(BuildContext context) {
    final specs = widget.topic.experiments;
    final draft = widget.store.progress(widget.topic.id);
    final credited = widget.store.completedExperimentIds(widget.topic.id);
    final states = draft?['states'];
    final checked = draft?['checked'];
    final touched = draft?['touched'];
    bool done(int i) {
      final spec = specs[i];
      if (credited.contains(spec.id)) return true;
      final state = states is Map ? states[spec.id] : null;
      return checked is List &&
          checked.contains(spec.id) &&
          touched is List &&
          touched.contains(spec.id) &&
          state is Map &&
          spec.isCorrect(Map<String, dynamic>.from(state));
    }

    final firstNew = List.generate(
      specs.length,
      (i) => i,
    ).where((i) => !done(i)).firstOrNull;
    final rawStep = draft?['step'];
    final current = rawStep is num
        ? rawStep.toInt().clamp(0, specs.length - 1)
        : firstNew ?? specs.length - 1;
    final active = (selected ?? current).clamp(0, specs.length - 1);
    final count = List.generate(specs.length, (i) => i).where(done).length;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.route_rounded, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hành trình khám phá',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$count/${specs.length} checkpoint hoàn thành · Chạm để xem trước',
          style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < specs.length; i++)
          Builder(
            builder: (context) {
              final palette = LessonTheme(
                widget.topic.id,
                i,
                Theme.of(context),
              ).theme.colorScheme;
              final completed = done(i);
              final status = completed
                  ? 'Đã hoàn thành'
                  : i == current
                  ? 'Đang học'
                  : 'Sắp tới';
              final isSelected = active == i;
              return CustomPaint(
                painter: _RoadConnector(
                  index: i,
                  last: i == specs.length - 1,
                  color: completed ? palette.primary : colors.outlineVariant,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 104,
                        height: 98,
                        child: Align(
                          alignment: i.isEven
                              ? Alignment.topLeft
                              : Alignment.topRight,
                          child: Semantics(
                            label:
                                'Checkpoint ${i + 1}: ${specs[i].title}. $status',
                            selected: isSelected,
                            button: true,
                            child: Tooltip(
                              message: 'Xem checkpoint ${i + 1}',
                              child: _CheckpointIsland(
                                key: ValueKey('checkpoint-${specs[i].id}'),
                                colors: palette,
                                completed: completed,
                                current: i == current,
                                selected: isSelected,
                                number: i + 1,
                                onTap: () => setState(() => selected = i),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: AnimatedContainer(
                            duration: AppMotion.duration(context, 220),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? palette.primaryContainer
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? palette.primary
                                    : colors.outlineVariant,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => setState(() => selected = i),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CHECKPOINT ${i + 1}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected
                                          ? palette.onPrimaryContainer
                                          : colors.primary,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    specs[i].title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                      color: isSelected
                                          ? palette.onPrimaryContainer
                                          : colors.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${specs[i].stage} · $status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.5,
                                      color: isSelected
                                          ? palette.onPrimaryContainer
                                          : colors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      specs[i].prompt,
                                      key: const ValueKey('checkpoint-preview'),
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: palette.onPrimaryContainer,
                                      ),
                                    ),
                                    if (!completed && i != current) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Xem trước · Phiên học tiếp tục từ checkpoint ${current + 1}.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.5,
                                          color: palette.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, color: colors.primary, size: 30),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Hoàn thành hành trình',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckpointIsland extends StatefulWidget {
  const _CheckpointIsland({
    super.key,
    required this.colors,
    required this.completed,
    required this.current,
    required this.selected,
    required this.number,
    required this.onTap,
  });
  final ColorScheme colors;
  final bool completed, current, selected;
  final int number;
  final VoidCallback onTap;
  @override
  State<_CheckpointIsland> createState() => _CheckpointIslandState();
}

class _CheckpointIslandState extends State<_CheckpointIsland> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final bright = widget.current || widget.completed || widget.selected;
    return GestureDetector(
      onTapDown: (_) => setState(() => pressed = true),
      onTapCancel: () => setState(() => pressed = false),
      onTapUp: (_) => setState(() => pressed = false),
      child: SizedBox(
        width: 76,
        height: 94,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 70,
              child: Container(
                width: 64,
                height: 15,
                decoration: BoxDecoration(
                  color: colors.shadow.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppMotion.duration(context, 160),
              margin: EdgeInsets.only(
                top: pressed
                    ? 8
                    : widget.selected
                    ? 0
                    : 5,
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .001)
                  ..rotateX(.43),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: bright
                          ? [
                              colors.primary,
                              Color.lerp(
                                colors.primary,
                                colors.onPrimaryContainer,
                                .3,
                              )!,
                            ]
                          : [
                              colors.primaryContainer,
                              Color.lerp(
                                colors.primaryContainer,
                                colors.primary,
                                .18,
                              )!,
                            ],
                    ),
                    border: Border.all(
                      color: widget.selected
                          ? colors.onPrimaryContainer
                          : colors.outlineVariant,
                      width: widget.selected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: bright
                            ? colors.onPrimaryContainer
                            : colors.outline,
                        offset: Offset(0, pressed ? 3 : 9),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: widget.onTap,
                      child: Center(
                        child: widget.completed
                            ? Icon(
                                Icons.check_rounded,
                                color: colors.onPrimary,
                                size: 32,
                              )
                            : widget.current
                            ? Icon(
                                Icons.play_arrow_rounded,
                                color: colors.onPrimary,
                                size: 34,
                              )
                            : Text(
                                '${widget.number}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: bright
                                      ? colors.onPrimary
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadConnector extends CustomPainter {
  const _RoadConnector({
    required this.index,
    required this.last,
    required this.color,
  });
  final int index;
  final bool last;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final x = index.isEven ? 38.0 : 66.0;
    final nextX = index.isEven ? 66.0 : 38.0;
    final path = Path()
      ..moveTo(x, index == 0 ? 44 : 0)
      ..lineTo(x, 44);
    if (!last) {
      path.cubicTo(
        x,
        size.height * .65,
        nextX,
        size.height * .65,
        nextX,
        size.height,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RoadConnector oldDelegate) =>
      oldDelegate.index != index ||
      oldDelegate.last != last ||
      oldDelegate.color != color;
}
