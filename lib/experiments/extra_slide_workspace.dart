import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';

import '../data/models/extra_slide_engines.dart';
import 'lesson_rich_text.dart';

class ExtraSlideWorkspace extends StatelessWidget {
  const ExtraSlideWorkspace({
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
    final e = slide['engine'] as String, c = slide['config'] as Map;
    if (!validExtraSlide(e, c)) return const Text('Cấu hình chưa hợp lệ.');
    final s = {...initialExtraSlide(e, c), ...state},
        color = Theme.of(context).colorScheme.primary;
    void set(String k, dynamic v) {
      if (!locked) onChanged({...s, k: v});
    }

    Widget slider(String k, String label, int min, int max) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$label: ${s[k]}'),
        Slider(
          key: ValueKey('extra-$k'),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: (s[k] as num).clamp(min, max).toDouble(),
          onChanged: locked ? null : (v) => set(k, v.round()),
        ),
      ],
    );
    Widget svg(
      String geometry, {
      double height = 140,
      String label = 'Mô hình hình học',
    }) => SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 180">$geometry</svg>',
      height: height,
      semanticsLabel: label,
    );
    String shape(String name) => switch (name) {
      'circle' => '<circle cx="150" cy="90" r="65"/>',
      'triangle' => '<polygon points="150,15 235,160 65,160"/>',
      'square' => '<rect x="85" y="25" width="130" height="130"/>',
      _ => '<polygon points="110,20 190,20 230,90 190,160 110,160 70,90"/>',
    };
    Widget fraction(int n, int d) => Column(
      children: [
        LessonRichText('\$\\frac{$n}{$d}\$'),
        svg(
          List.generate(
            d,
            (i) =>
                '<rect x="${i * 290 / d + 5}" y="45" width="${280 / d}" height="90" fill="${i < n ? '#9fce8b' : '#f5f7f2'}" stroke="#53754a"/>',
          ).join(),
          height: 100,
          label: '$n/$d',
        ),
      ],
    );
    if (e == 'numberInput') {
      return TextFormField(
        key: ValueKey('extra-number-${slide['id']}-${c['target_value']}'),
        initialValue: s['value'] as String,
        maxLength: 6,
        enabled: !locked,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        decoration: const InputDecoration(labelText: 'Kết quả của bạn'),
        onChanged: (v) => set('value', v),
      );
    }
    if (e == 'numberLine') {
      return Column(
        children: [
          Text('Đặt điểm tại ${c['target']}.'),
          svg(
            '<path d="M10 90H290" stroke="#53754a" stroke-width="3"/><circle cx="${10 + ((s['position'] as num) - (c['min'] as num)) / ((c['max'] as num) - (c['min'] as num)) * 280}" cy="90" r="10" fill="#287945"/>',
            height: 95,
            label: 'Điểm tại ${s['position']}',
          ),
          slider('position', 'Vị trí', c['min'] as int, c['max'] as int),
        ],
      );
    }
    if (e == 'fractionBoard') {
      final selected = (s['selected'] as List).cast<int>(),
          den = c['denominator'] as int;
      return Column(
        children: [
          Text('Tô ${c['numerator']}/$den hình.'),
          svg(
            List.generate(
              den,
              (i) =>
                  '<rect x="${i * 290 / den + 5}" y="30" width="${280 / den}" height="120" fill="${selected.contains(i) ? '#9fce8b' : '#f5f7f2'}" stroke="#53754a"/>',
            ).join(),
            label: 'Đã tô ${selected.length}/$den',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < den; i++)
                FilterChip(
                  label: Text('Phần ${i + 1}'),
                  selected: selected.contains(i),
                  onSelected: locked
                      ? null
                      : (v) => set(
                          'selected',
                          v
                              ? [...selected, i]
                              : selected.where((x) => x != i).toList(),
                        ),
                ),
            ],
          ),
        ],
      );
    }
    if (e == 'fractionCompare') {
      return Column(
        children: [
          fraction(c['left_numerator'] as int, c['left_denominator'] as int),
          Wrap(
            spacing: 12,
            children: [
              for (final (i, label) in ['<', '=', '>'].indexed)
                ChoiceChip(
                  label: Text(label),
                  selected: s['comparison'] == i,
                  onSelected: locked ? null : (_) => set('comparison', i),
                ),
            ],
          ),
          fraction(c['right_numerator'] as int, c['right_denominator'] as int),
        ],
      );
    }
    if (e == 'shapeMatch') {
      return Column(
        children: [
          const Text('Chọn hình giống mẫu:'),
          svg(
            '<g fill="#9fce8b" stroke="#32513a" stroke-width="2">${shape(c['target_shape'] as String)}</g>',
            label: 'Hình mẫu',
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final name in slideShapes)
                SizedBox(
                  width: 110,
                  child: OutlinedButton(
                    onPressed: locked ? null : () => set('shape', name),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: s['shape'] == name
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    child: svg(
                      '<g fill="#b6cee8" stroke="#32513a" stroke-width="2">${shape(name)}</g>',
                      height: 75,
                      label: name,
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    }
    if (e == 'vennDiagram') {
      final values = (s['values'] as List).cast<int>();
      final items = (c['items'] as List).cast<String>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          svg(
            '<circle cx="110" cy="90" r="70" fill="#b2dba2" fill-opacity=".6" stroke="#45713b"/><circle cx="190" cy="90" r="70" fill="#b6cee8" fill-opacity=".6" stroke="#436383"/><text x="65" y="90">A</text><text x="225" y="90">B</text>',
            label: 'Hai tập A và B giao nhau',
          ),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<int>(
                key: ValueKey('venn-$i-${values[i]}'),
                initialValue: values[i] < 0 ? null : values[i],
                isExpanded: true,
                decoration: InputDecoration(labelText: items[i]),
                items: [
                  for (final (j, label) in [
                    'Ngoài A và B',
                    'Chỉ A',
                    'Chỉ B',
                    'Giao A ∩ B',
                  ].indexed)
                    DropdownMenuItem(value: j, child: Text(label)),
                ],
                onChanged: locked
                    ? null
                    : (v) => set('values', [
                        for (var j = 0; j < values.length; j++)
                          j == i ? v : values[j],
                      ]),
              ),
            ),
        ],
      );
    }
    if (e == 'barChart') {
      final values = (s['values'] as List).cast<int>(),
          labels = (c['labels'] as List).cast<String>();
      return Column(
        children: [
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                maxY: 10,
                minY: 0,
                titlesData: const FlTitlesData(show: false),
                barTouchData: BarTouchData(enabled: false),
                barGroups: [
                  for (final (i, v) in values.indexed)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: v.toDouble(),
                          width: 24,
                          color: color,
                        ),
                      ],
                    ),
                ],
              ),
              duration: Duration.zero,
            ),
          ),
          Text('Dựng dữ liệu: ${(c['target_values'] as List).join(', ')}.'),
          for (var i = 0; i < labels.length; i++)
            Column(
              children: [
                Text('${labels[i]}: ${values[i]}'),
                Slider(
                  key: ValueKey('bar-$i'),
                  value: values[i].toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: locked
                      ? null
                      : (v) => set('values', [
                          for (var j = 0; j < values.length; j++)
                            j == i ? v.round() : values[j],
                        ]),
                ),
              ],
            ),
        ],
      );
    }
    final point = e == 'coordinatePoint';
    final spots = point
        ? [FlSpot((s['x'] as num).toDouble(), (s['y'] as num).toDouble())]
        : [
            for (var i = -40; i <= 40; i++)
              FlSpot(
                i / 8,
                (s['a'] as num) * (i / 8) * (i / 8) +
                    (s['b'] as num) * (i / 8) +
                    (s['c'] as num),
              ),
          ];
    return Column(
      children: [
        SizedBox(
          height: 230,
          child: LineChart(
            LineChartData(
              minX: -5,
              maxX: 5,
              minY: point ? -5 : -10,
              maxY: point ? 5 : 10,
              clipData: const FlClipData.all(),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  color: color,
                  isCurved: false,
                  dotData: FlDotData(show: point),
                  barWidth: point ? 0 : 3,
                ),
              ],
            ),
            duration: Duration.zero,
          ),
        ),
        if (point) ...[
          Text('Đặt điểm (${c['target_x']}, ${c['target_y']}).'),
          slider('x', 'Tọa độ x', -5, 5),
          slider('y', 'Tọa độ y', -5, 5),
        ] else ...[
          LessonRichText('\$y = ${s['a']}x^2 + ${s['b']}x + ${s['c']}\$'),
          Text(
            'Mục tiêu: a=${c['target_a']}, b=${c['target_b']}, c=${c['target_c']}',
          ),
          slider('a', 'Hệ số a', -3, 3),
          slider('b', 'Hệ số b', -5, 5),
          slider('c', 'Hệ số c', -5, 5),
        ],
      ],
    );
  }
}
