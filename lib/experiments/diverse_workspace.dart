import 'package:flutter/material.dart';

import '../app_theme.dart';
import 'experiment_model.dart';

bool supportsDiverseExperiment(String mechanism) => const [
  'fractionNumberLine',
  'logicalCounterexample',
  'outlierExplorer',
].contains(mechanism);

class DiverseWorkspace extends StatelessWidget {
  const DiverseWorkspace({
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
    void change(String key, Object value) {
      if (!locked) onChanged({...data, key: value});
    }

    Widget body;
    if (spec.mechanism == 'logicalCounterexample') {
      body = Column(
        children: [
          const Text('Nếu A sáng → B sáng', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          for (final key in ['a', 'b'])
            SwitchListTile.adaptive(
              key: ValueKey('condition-$key'),
              title: Text('Đèn ${key.toUpperCase()}'),
              subtitle: Text(data[key] == true ? 'Đang sáng' : 'Đang tắt'),
              secondary: Icon(
                data[key] == true ? Icons.lightbulb : Icons.lightbulb_outline,
                color: data[key] == true ? BrilliantPalette.successInk : ink,
              ),
              value: data[key] == true,
              onChanged: locked ? null : (v) => change(key, v),
            ),
          const Text(
            'Thử từng trạng thái rồi đối chiếu với quy tắc.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      final fraction = spec.mechanism == 'fractionNumberLine';
      final key = fraction ? 'position' : 'outlier';
      final min = fraction ? 0 : 5;
      final max = fraction ? 8 : 15;
      final raw = data[key];
      final value = (raw is int ? raw : min).clamp(min, max);
      body = Column(
        children: [
          Text(
            fraction ? 'Vị trí: $value/8' : 'Dữ liệu: 1, 2, 3, 4, $value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          if (fraction)
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('0'), Text('1/2'), Text('1')],
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final point in [1, 2, 3, 4, value])
                  Chip(
                    label: Text('$point'),
                    backgroundColor: point == value
                        ? BrilliantPalette.successSurface
                        : BrilliantPalette.surface,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Trung bình: ${((10 + value) / 5).toStringAsFixed(1)} · Trung vị: 3',
              textAlign: TextAlign.center,
            ),
          ],
          Slider(
            key: ValueKey('explore-$key'),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            value: value.toDouble(),
            label: fraction ? '$value/8' : '$value',
            semanticFormatterCallback: (v) =>
                fraction ? '${v.round()} phần tám' : 'Điểm cuối ${v.round()}',
            onChanged: locked ? null : (v) => change(key, v.round()),
          ),
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton(
                onPressed: locked || value == min
                    ? null
                    : () => change(key, value - 1),
                child: const Text('Lùi một nấc'),
              ),
              OutlinedButton(
                onPressed: locked || value == max
                    ? null
                    : () => change(key, value + 1),
                child: const Text('Tiến một nấc'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            fraction
                ? 'Kéo điểm hoặc dùng nút để di chuyển trên trục số.'
                : 'Kéo điểm cuối; so sánh hai đại lượng sau mỗi thay đổi.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrilliantPalette.border),
      ),
      child: body,
    );
  }
}
