import 'lesson_rich_text.dart';
import 'extended_slide_workspace.dart';
import '../data/models/slide_engine_contract.dart';

import 'package:flutter/material.dart';

import '../data/models/learning_journal.dart';
import '../data/models/slide_lesson.dart';
import 'experiment_model.dart';

class SlideLessonWorkspace extends StatelessWidget {
  const SlideLessonWorkspace({
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
  Widget build(BuildContext context) {
    final slides = spec.config['slides'] as List;
    final index = (data['index'] as int? ?? 0).clamp(0, slides.length - 1);
    final states = data['slides'] is List
        ? data['slides'] as List
        : initialSlideState(spec.config)['slides'] as List;
    final slide = learningMap(slides[index]),
        state = learningMap(states[index]);
    void update(Map<String, dynamic> next) => onChanged({
      ...data,
      'slides': [
        for (var i = 0; i < slides.length; i++) i == index ? next : states[i],
      ],
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < slides.length; i++)
              ChoiceChip(
                label: Text('${i + 1}'),
                selected: i == index,
                avatar:
                    slideIsCorrect(
                      learningMap(slides[i]),
                      learningMap(states[i]),
                    )
                    ? const Icon(Icons.check, size: 16)
                    : null,
                onSelected: locked
                    ? null
                    : (_) => onChanged({...data, 'index': i}),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LessonRichText(
          slide['title'] as String,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if ((slide['prompt'] as String).isNotEmpty) ...[
          const SizedBox(height: 12),
          LessonRichText(slide['prompt'] as String),
        ],
        const SizedBox(height: 16),
        SlideEngineWorkspace(
          slide: slide,
          state: state,
          locked: locked,
          onChanged: update,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text('Slide ${index + 1}/${slides.length}'),
            const Spacer(),
            TextButton(
              onPressed: locked || index == 0
                  ? null
                  : () => onChanged({...data, 'index': index - 1}),
              child: const Text('Trước'),
            ),
            FilledButton(
              onPressed: locked || index == slides.length - 1
                  ? null
                  : () => onChanged({...data, 'index': index + 1}),
              child: const Text('Tiếp'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reused verbatim by the admin phone preview and the learner application.
class SlideEngineWorkspace extends StatelessWidget {
  const SlideEngineWorkspace({
    super.key,
    required this.slide,
    required this.state,
    required this.locked,
    required this.onChanged,
  });
  final Map<String, dynamic> slide, state;
  final bool locked;
  final ValueChanged<Map<String, dynamic>> onChanged;
  @override
  Widget build(BuildContext context) {
    final c = learningMap(slide['config']);
    switch (slide['engine']) {
      case 'story':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LessonRichText(
              c['text'] as String,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if ((c['image_url'] as String).isNotEmpty) ...[
              const SizedBox(height: 16),
              Image.network(
                c['image_url'] as String,
                semanticLabel: c['image_alt'] as String,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Text('Không tải được ảnh: ${c['image_alt']}'),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tôi đã đọc nội dung'),
              value: state['ack'] == true,
              onChanged: locked
                  ? null
                  : (v) => onChanged({...state, 'ack': v == true}),
            ),
          ],
        );
      case 'quiz':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final entry in (c['choices'] as List).indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  key: ValueKey('slide-answer-${entry.$1}'),
                  onPressed: locked
                      ? null
                      : () => onChanged({...state, 'answer': entry.$1}),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: Icon(
                    state['answer'] == entry.$1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  label: LessonRichText(entry.$2 as String),
                ),
              ),
          ],
        );
      case 'pairs':
        final pairs = c['pairs'] as List;
        final values =
            state['values'] as List? ?? List.filled(pairs.length, -1);
        void assign(int slot, int value) => onChanged({
          ...state,
          'values': [
            for (var i = 0; i < pairs.length; i++)
              i == slot
                  ? value
                  : values[i] == value
                  ? -1
                  : values[i],
          ],
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Kéo thẻ vào ô phù hợp, hoặc chạm ô để chọn.'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in pairs.indexed.toList().reversed)
                  Draggable<int>(
                    data: entry.$1,
                    maxSimultaneousDrags: locked ? 0 : 1,
                    feedback: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(entry.$2['right'] as String),
                      ),
                    ),
                    child: Chip(
                      label: Text(entry.$2['right'] as String),
                      avatar: const Icon(Icons.drag_indicator, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in pairs.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DragTarget<int>(
                  onWillAcceptWithDetails: (details) =>
                      !locked &&
                      details.data >= 0 &&
                      details.data < pairs.length,
                  onAcceptWithDetails: (details) =>
                      assign(entry.$1, details.data),
                  builder: (context, candidates, rejected) =>
                      DropdownButtonFormField<int>(
                        key: ValueKey(
                          '${slide['id']}-pair-${entry.$1}-${values[entry.$1]}',
                        ),
                        isExpanded: true,
                        initialValue:
                            values[entry.$1] is int &&
                                (values[entry.$1] as int) >= 0
                            ? values[entry.$1] as int
                            : null,
                        decoration: InputDecoration(
                          labelText: entry.$2['left'] as String,
                          filled: candidates.isNotEmpty,
                        ),
                        hint: const Text('Thả hoặc chọn đáp án'),
                        items: [
                          for (final answer in pairs.indexed.toList().reversed)
                            DropdownMenuItem(
                              value: answer.$1,
                              child: Text(answer.$2['right'] as String),
                            ),
                        ],
                        onChanged: locked
                            ? null
                            : (v) {
                                if (v != null) assign(entry.$1, v);
                              },
                      ),
                ),
              ),
          ],
        );
      case 'graph':
        final a = state['a'] as int? ?? c['start_a'] as int,
            b = state['b'] as int? ?? c['start_b'] as int;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label: 'Đồ thị đường thẳng y bằng $a nhân x cộng $b',
              child: SizedBox(
                height: 230,
                child: CustomPaint(
                  painter: _LinearGraph(a, b, Theme.of(context).colorScheme),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'y = $a × x ${b < 0 ? '− ${b.abs()}' : '+ $b'}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final field in ['a', 'b']) ...[
              Text(field == 'a' ? 'Độ dốc a = $a' : 'Giao điểm b = $b'),
              Slider(
                key: ValueKey('slide-slider-$field'),
                value: (field == 'a' ? a : b)
                    .clamp(c['min_$field'] as int, c['max_$field'] as int)
                    .toDouble(),
                min: (c['min_$field'] as int).toDouble(),
                max: (c['max_$field'] as int).toDouble(),
                divisions: (c['max_$field'] as int) - (c['min_$field'] as int),
                label: '${field == 'a' ? a : b}',
                onChanged: locked
                    ? null
                    : (v) => onChanged({...state, field: v.round()}),
              ),
            ],
          ],
        );
    }
    if (extendedSlideEngines.containsKey(slide['engine'])) {
      return ExtendedSlideWorkspace(
        slide: slide,
        state: state,
        locked: locked,
        onChanged: onChanged,
      );
    }
    return const Text('Engine chưa được hỗ trợ.');
  }
}

class _LinearGraph extends CustomPainter {
  _LinearGraph(this.a, this.b, this.colors);
  final int a, b;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTWH(28, 12, size.width - 44, size.height - 36);
    Offset point(double x, double y) => Offset(
      plot.left + (x + 5) / 10 * plot.width,
      plot.bottom - (y + 10) / 20 * plot.height,
    );
    final grid = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;
    for (var x = -5; x <= 5; x++) {
      canvas.drawLine(point(x.toDouble(), -10), point(x.toDouble(), 10), grid);
    }
    for (var y = -10; y <= 10; y += 2) {
      canvas.drawLine(point(-5, y.toDouble()), point(5, y.toDouble()), grid);
    }
    final axis = Paint()
      ..color = colors.onSurfaceVariant
      ..strokeWidth = 1.5;
    canvas.drawLine(point(-5, 0), point(5, 0), axis);
    canvas.drawLine(point(0, -10), point(0, 10), axis);
    canvas.save();
    canvas.clipRect(plot);
    canvas.drawLine(
      point(-5, (-5 * a + b).toDouble()),
      point(5, (5 * a + b).toDouble()),
      Paint()
        ..color = colors.primary
        ..strokeWidth = 3,
    );
    canvas.restore();
    for (final entry in {
      'x': Offset(plot.right - 8, point(0, 0).dy + 4),
      'y': Offset(point(0, 0).dx + 5, plot.top),
      '0': point(0, 0) + const Offset(-13, 4),
      '-5': Offset(plot.left, plot.bottom + 4),
      '5': Offset(plot.right - 10, plot.bottom + 4),
    }.entries) {
      final text = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, entry.value);
    }
  }

  @override
  bool shouldRepaint(_LinearGraph old) =>
      old.a != a || old.b != b || old.colors != colors;
}
