import 'package:flutter/material.dart';

import 'experiment_model.dart';

class ReasoningWorkspace extends StatelessWidget {
  const ReasoningWorkspace({
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Kiến thức cốt lõi', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(
        spec.config['knowledge'] as String,
        style: const TextStyle(height: 1.6),
      ),
      if (spec.config['code'] case final String code) ...[
        const SizedBox(height: 16),
        const Text('Đọc mã Python'),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(14),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SelectableText(
            code,
            style: const TextStyle(fontFamily: 'monospace', height: 1.6),
          ),
        ),
      ],
      if (spec.config['swatches'] case final List<int> swatches) ...[
        const SizedBox(height: 16),
        Semantics(
          label: 'Ba ô sắc độ, theo thứ tự từ trái sang phải',
          child: Row(
            children: [
              for (final value in swatches)
                Expanded(child: Container(height: 64, color: Color(value))),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      _options(
        context,
        'answer',
        '1. Chọn kết quả',
        spec.config['choices'] as List<String>,
      ),
      const SizedBox(height: 16),
      _options(
        context,
        'reason',
        '2. Chọn lý do',
        spec.config['reasons'] as List<String>,
      ),
      const SizedBox(height: 16),
      Text(
        'Nguồn học: ${spec.config['source']}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    ],
  );

  Widget _options(
    BuildContext context,
    String field,
    String title,
    List<String> values,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (var i = 0; i < values.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Semantics(
            selected: data[field] == i,
            child: OutlinedButton(
              key: ValueKey('$field-$i'),
              onPressed: locked ? null : () => onChanged({...data, field: i}),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.all(14),
                backgroundColor: data[field] == i
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: data[field] == i
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSecondaryContainer,
                side: BorderSide(
                  color: data[field] == i
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    data[field] == i
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(values[i], style: const TextStyle(height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}
