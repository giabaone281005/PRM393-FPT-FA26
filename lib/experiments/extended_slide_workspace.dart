import 'extra_slide_workspace.dart';
import '../data/models/extra_slide_engines.dart';

import 'package:flutter/material.dart';

import '../data/models/slide_engine_contract.dart';
import 'curriculum_workspace.dart';
import 'discovery_experiments.dart';
import 'experiment_model.dart';
import 'space_workspace.dart';

/// Adapts the CMS contract to shipped learner controls, without a second runtime.
class ExtendedSlideWorkspace extends StatelessWidget {
  const ExtendedSlideWorkspace({
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
    final engine = slide['engine'] as String,
        c = Map<String, dynamic>.from(slide['config'] as Map);
    if (!validExtendedSlide(engine, c)) {
      return const Text('Cấu hình tương tác chưa hợp lệ.');
    }
    if (extraSlideEngines.containsKey(engine)) {
      return ExtraSlideWorkspace(
        slide: slide,
        state: state,
        locked: locked,
        onChanged: onChanged,
      );
    }
    final data = {...initialExtendedSlide(engine, c), ...state};
    final mechanism = switch (engine) {
      'solid3D' => 'solidExplorer',
      'globe3D' => 'globeExplorer',
      'strata3D' => 'strataExplorer',
      'causalLab' => 'causalExperiment',
      _ => engine,
    };
    final spec = ExperimentSpec(
      id: slide['id'] as String,
      title: slide['title'] as String,
      prompt: slide['prompt'] as String,
      hint: slide['hint'] as String,
      explanation: slide['explanation'] as String,
      mechanism: mechanism,
      initial: data,
      config: c,
      validator: (s) => extendedSlideCorrect(engine, c, s),
    );
    Widget body;
    if (supportsSpaceExperiment(mechanism)) {
      body = SpaceWorkspace(
        key: ValueKey(slide['id']),
        spec: spec,
        data: data,
        locked: locked,
        onChanged: onChanged,
      );
    } else if (supportsDiscoveryExperiment(mechanism)) {
      body = DiscoveryExperiment(
        key: ValueKey(slide['id']),
        spec: spec,
        data: data,
        locked: locked,
        onChanged: onChanged,
      );
    } else if (engine == 'textEntry') {
      body = TextFormField(
        key: ValueKey(slide['id']),
        initialValue: data['response'] as String,
        enabled: !locked,
        maxLength: 500,
        minLines: 2,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Câu trả lời bằng tiếng Anh',
        ),
        onChanged: (value) => onChanged({...data, 'response': value}),
      );
    } else if (engine == 'balanceScale') {
      final weight = data['weight'] as int;
      body = Column(
        children: [
          Icon(
            Icons.balance,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          Text('Đĩa trái: $weight · Đĩa phải: ${c['target_weight']}'),
          Slider(
            key: const ValueKey('slide-weight'),
            min: 0,
            max: 10,
            divisions: 10,
            value: weight.clamp(0, 10).toDouble(),
            label: '$weight',
            onChanged: locked
                ? null
                : (v) => onChanged({...data, 'weight': v.round()}),
          ),
        ],
      );
    } else {
      body = CurriculumWorkspace(
        key: ValueKey(slide['id']),
        spec: spec,
        data: data,
        locked: locked,
        onChanged: onChanged,
      );
    }
    final goal = switch (engine) {
      'solid3D' => 'Tạo khối có thể tích ${c['target_volume']}.',
      'polygonVertices' =>
        'Tạo hình chữ nhật có diện tích ${c['target_area']}.',
      'globe3D' =>
        'Tìm tọa độ (${c['target_latitude']}°, ${c['target_longitude']}°).',
      'causalLab' || 'causalExperiment' =>
        'Dự đoán và chạy mô hình để tìm tích ${c['target_product']}.',
      'loopBuilder' =>
        'Ghép ${(c['target_body'] as List).join(', ')} và lặp ${c['target_repeat']} lần.',
      'robotRoute' =>
        'Tới (3,3), tránh đá (1,1), tối đa ${c['max_commands']} lệnh.',
      _ => '',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (goal.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(goal),
          ),
        body,
      ],
    );
  }
}
