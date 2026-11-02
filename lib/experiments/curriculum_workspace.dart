import 'dart:async';

import 'package:flutter/material.dart';

import '../data/engines/language_audio.dart';
import 'experiment_model.dart';

class CurriculumWorkspace extends StatefulWidget {
  const CurriculumWorkspace({
    super.key,
    required this.spec,
    required this.data,
    required this.locked,
    required this.onChanged,
    this.audio,
  });
  final ExperimentSpec spec;
  final ExperimentData data;
  final bool locked;
  final ValueChanged<ExperimentData> onChanged;
  final LanguageAudio? audio;
  @override
  State<CurriculumWorkspace> createState() => _CurriculumWorkspaceState();
}

class _CurriculumWorkspaceState extends State<CurriculumWorkspace>
    with WidgetsBindingObserver {
  late final _response = TextEditingController(
    text: widget.data['response'] as String? ?? '',
  );
  LanguageAudio get audio => widget.audio ?? DeviceLanguageAudio.shared;
  ExperimentData get config => widget.spec.config;
  ExperimentData get data => widget.data;
  bool busy = false, transcript = false;
  String? audioMessage;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(CurriculumWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locked && !oldWidget.locked) _cancel();
  }

  void _cancel() {
    generation++;
    if (busy) unawaited(audio.stop().catchError((Object _) {}));
    busy = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && busy) {
      _cancel();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancel();
    _response.dispose();
    super.dispose();
  }

  void change(String key, dynamic value) {
    if (!widget.locked) widget.onChanged({...data, key: value});
  }

  List<String> strings(String key) => (config[key] as List).cast<String>();
  List<int> get values => (data['values'] as List).cast<int>();
  Widget note(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
  Widget label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: switch (widget.spec.mechanism) {
      'sequenceTiles' => _sequence(),
      'evidenceBoard' => _evidence(),
      'causalExperiment' => _lab(),
      'resourceBudget' => _budget(),
      'listeningChoice' || 'speechPractice' => _language(),
      _ => _connections(),
    },
  );

  List<Widget> _connections() {
    final items = strings('items'), choices = strings('choices');
    return [
      note(switch (widget.spec.mechanism) {
        'categorySort' => 'Phân loại từng thẻ. Một nhóm có thể chứa nhiều thẻ.',
        'clozeBank' => 'Chọn từ hoặc giá trị cho mỗi chỗ trống.',
        _ => 'Chạm một lựa chọn cho mỗi thẻ; có thể thay đổi bất kỳ lúc nào.',
      }),
      for (int i = 0; i < items.length; i++) ...[
        label('${i + 1}. ${items[i]}'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int j = 0; j < choices.length; j++)
              ChoiceChip(
                key: ValueKey('connect-$i-$j'),
                label: Text(choices[j]),
                selected: values[i] == j,
                onSelected: widget.locked
                    ? null
                    : (_) {
                        final next = [...values];
                        next[i] = j;
                        change('values', next);
                      },
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _sequence() {
    final items = strings('items');
    void move(int from, int to) {
      if (widget.locked || from == to) return;
      final next = [...values], item = values[from];
      next.removeAt(from);
      next.insert(to, item);
      change('values', next);
    }

    Widget tile(int i) => Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text('${i + 1}.'),
          const SizedBox(width: 8),
          Expanded(child: Text(items[values[i]])),
          Column(
            children: [
              IconButton(
                key: ValueKey('move-up-$i'),
                tooltip: 'Đưa thẻ ${i + 1} lên',
                onPressed: widget.locked || i == 0
                    ? null
                    : () => move(i, i - 1),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: 'Đưa thẻ ${i + 1} xuống',
                onPressed: widget.locked || i == values.length - 1
                    ? null
                    : () => move(i, i + 1),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ],
      ),
    );
    return [
      note(
        'Kéo bằng cách nhấn giữ thẻ, hoặc dùng mũi tên để sắp xếp từ trên xuống.',
      ),
      for (int i = 0; i < values.length; i++)
        DragTarget<int>(
          onWillAcceptWithDetails: (d) => !widget.locked && d.data != i,
          onAcceptWithDetails: (d) => move(d.data, i),
          builder: (context, candidates, rejected) => LongPressDraggable<int>(
            data: i,
            maxSimultaneousDrags: widget.locked ? 0 : 1,
            feedback: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 220,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(items[values[i]]),
                ),
              ),
            ),
            child: tile(i),
          ),
        ),
    ];
  }

  List<Widget> _evidence() => [
    note('Chạm để chọn hoặc bỏ chọn. Có thể có nhiều bằng chứng đúng.'),
    for (final (i, item) in strings('items').indexed)
      Material(
        color: Colors.transparent,
        child: CheckboxListTile(
          key: ValueKey('evidence-$i'),
          contentPadding: EdgeInsets.zero,
          title: Text(item),
          controlAffinity: ListTileControlAffinity.leading,
          value: (data['selected'] as List).contains(i),
          onChanged: widget.locked
              ? null
              : (v) {
                  final selected = List<int>.from(data['selected'] as List);
                  v == true ? selected.add(i) : selected.remove(i);
                  change('selected', selected);
                },
        ),
      ),
  ];

  List<Widget> _lab() {
    final x = data['x'] as int, y = data['y'] as int;
    final prediction = data['prediction'] as int;
    final trials = data['trials'] as List;
    return [
      for (final (i, axis) in strings('axes').indexed) ...[
        label('$axis: ${i == 0 ? x : y}'),
        Slider(
          key: ValueKey('lab-${i == 0 ? 'x' : 'y'}'),
          min: 0,
          max: 3,
          divisions: 3,
          label: '${i == 0 ? x : y}',
          value: (i == 0 ? x : y).toDouble(),
          onChanged: widget.locked
              ? null
              : (v) => widget.onChanged({
                  ...data,
                  i == 0 ? 'x' : 'y': v.round(),
                  'observed': <int>[],
                }),
        ),
      ],
      label('Dự đoán kết quả trước khi chạy'),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (int i = 0; i <= 9; i++)
            ChoiceChip(
              label: Text('$i'),
              selected: prediction == i,
              onSelected: widget.locked ? null : (_) => change('prediction', i),
            ),
        ],
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        key: const ValueKey('run-lab'),
        onPressed: widget.locked || prediction < 0
            ? null
            : () {
                final trial = [x, y, x * y];
                widget.onChanged({
                  ...data,
                  'observed': trial,
                  'trials': [
                    ...trials,
                    trial,
                  ].reversed.take(6).toList().reversed.toList(),
                });
              },
        icon: const Icon(Icons.science_outlined),
        label: const Text('Chạy mô hình'),
      ),
      if (trials.isNotEmpty) ...[
        label('Nhật ký thử nghiệm • tối đa 6 lần gần nhất'),
        for (final trial in trials) ...[
          Text('${trial[0]} × ${trial[1]} → ${trial[2]}'),
          Semantics(
            label: 'Kết quả ${trial[2]} trên 9',
            child: LinearProgressIndicator(value: (trial[2] as int) / 9),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }

  List<Widget> _budget() {
    final total = values.fold<int>(0, (a, b) => a + b);
    return [
      label('Đã phân bổ $total/10 • còn ${10 - total}'),
      LinearProgressIndicator(value: (total / 10).clamp(0, 1)),
      for (final (i, item) in strings('items').indexed) ...[
        label('$item • tối thiểu ${(config['minima'] as List)[i]}'),
        Row(
          children: [
            IconButton(
              key: ValueKey('budget-minus-$i'),
              tooltip: 'Giảm $item',
              onPressed: widget.locked || values[i] == 0
                  ? null
                  : () {
                      final next = [...values];
                      next[i]--;
                      change('values', next);
                    },
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${values[i]}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            IconButton(
              key: ValueKey('budget-plus-$i'),
              tooltip: 'Tăng $item',
              onPressed: widget.locked || total >= 10
                  ? null
                  : () {
                      final next = [...values];
                      next[i]++;
                      change('values', next);
                    },
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
      note(
        'Có nhiều phương án đúng. Dùng nút giảm để chuyển nguồn lực sang mục khác.',
      ),
    ];
  }

  Future<void> _play(bool slow) async {
    final current = ++generation;
    setState(() {
      busy = true;
      audioMessage = null;
    });
    try {
      await audio.speak(config['text'] as String, slow: slow);
      if (!mounted || current != generation || widget.locked) return;
      if (widget.spec.mechanism == 'listeningChoice') {
        change('experienced', true);
      }
    } catch (_) {
      if (mounted && current == generation) {
        setState(
          () => audioMessage = 'Chưa phát được giọng tiếng Anh. Bạn có thể mở bản chữ và tiếp tục.',
        );
      }
    } finally {
      if (mounted && current == generation) setState(() => busy = false);
    }
  }

  Future<void> _record() async {
    final current = ++generation;
    setState(() {
      busy = true;
      audioMessage = null;
    });
    bool active() => mounted && current == generation && !widget.locked;
    void finish() {
      if (active()) setState(() => busy = false);
    }

    void failed() {
      if (active()) {
        setState(() {
          busy = false;
          audioMessage = 'Micro hoặc nhận dạng tiếng Anh chưa sẵn sàng. Bạn vẫn có thể nhập câu bên dưới.';
        });
      }
    }

    try {
      final available = await audio.listen(
        onWords: (text) {
          if (!active()) return;
          _response.text = text;
          change('response', text);
          finish();
        },
        onDone: finish,
        onError: failed,
      );
      if (!available) failed();
    } catch (_) {
      failed();
    }
  }

  List<Widget> _language() {
    final listening = widget.spec.mechanism == 'listeningChoice';
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const ValueKey('language-play'),
            onPressed: widget.locked || busy ? null : () => _play(false),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Nghe mẫu'),
          ),
          OutlinedButton.icon(
            onPressed: widget.locked || busy ? null : () => _play(true),
            icon: const Icon(Icons.slow_motion_video),
            label: const Text('Nghe chậm'),
          ),
          if (busy)
            TextButton.icon(
              onPressed: () {
                _cancel();
                setState(() {});
              },
              icon: const Icon(Icons.stop),
              label: const Text('Dừng âm thanh'),
            ),
        ],
      ),
      if (busy)
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Đang sử dụng âm thanh…',
            semanticsLabel: 'Đang sử dụng âm thanh',
          ),
        ),
      if (audioMessage != null)
        Semantics(liveRegion: true, child: note(audioMessage!)),
      if (!listening || transcript)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            config['text'] as String,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      if (listening) ...[
        TextButton(
          key: const ValueKey('language-transcript'),
          onPressed: widget.locked
              ? null
              : () {
                  setState(() => transcript = !transcript);
                  if (!data.containsKey('experienced') ||
                      data['experienced'] != true) {
                    change('experienced', true);
                  }
                },
          child: Text(transcript ? 'Ẩn bản chữ' : 'Xem bản chữ thay âm thanh'),
        ),
        for (final (i, choice) in strings('choices').indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: OutlinedButton(
              key: ValueKey('listen-answer-$i'),
              onPressed: widget.locked ? null : () => change('answer', i),
              child: Row(
                children: [
                  Icon(
                    data['answer'] == i
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(choice)),
                ],
              ),
            ),
          ),
      ] else ...[
        note(
          'Micro chỉ bật khi bạn bấm. Dịch vụ nhận dạng của thiết bị có thể cần mạng. Matlingo không lưu bản ghi âm; câu chữ được lưu cùng tiến độ. Có thể nhập thay vì nói.',
        ),
        OutlinedButton.icon(
          key: const ValueKey('language-record'),
          onPressed: widget.locked || busy ? null : _record,
          icon: const Icon(Icons.mic_none),
          label: const Text('Bấm để nói • tối đa 15 giây'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('language-response'),
          controller: _response,
          enabled: !widget.locked,
          maxLength: 500,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Câu của bạn',
            hintText: 'Nói hoặc nhập câu tiếng Anh',
          ),
          onChanged: (text) {
            if (busy) {
              _cancel();
              setState(() {});
            }
            change('response', text);
          },
        ),
        note('Đối chiếu từ và thứ tự câu; không phải bài chấm điểm phát âm.'),
      ],
    ];
  }
}
