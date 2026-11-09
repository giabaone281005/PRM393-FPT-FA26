import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../data/models/learning_journal.dart';
import '../../data/models/slide_lesson.dart';
import '../../data/providers/admin_dashboard_controller.dart';
import '../../experiments/slide_lesson_workspace.dart';

const _engineIcons = {
  'story': Icons.article_outlined,
  'quiz': Icons.quiz_outlined,
  'pairs': Icons.drag_indicator,
  'graph': Icons.show_chart,
};

class AdminLessonStudio extends StatefulWidget {
  const AdminLessonStudio({super.key, required this.controller});
  final AdminDashboardController controller;
  @override
  State<AdminLessonStudio> createState() => _AdminLessonStudioState();
}

class _AdminLessonStudioState extends State<AdminLessonStudio> {
  String? _topic;
  Map<String, dynamic>? _editing;
  bool _creating = false;
  Future<List<Map<String, dynamic>>>? _drafts;
  void _load(String topic) {
    _topic = topic;
    _drafts = widget.controller.loadBuilderDrafts(topic);
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.controller.topics;
    if (_topic == null && topics.isNotEmpty) _load(topics.first.id);
    if (_creating || _editing != null) {
      return AdminSlideComposer(
        key: ValueKey(_editing?['id'] ?? 'new-$_topic'),
        controller: widget.controller,
        topicId: _topic!,
        lesson: _editing,
        onBack: () {
          setState(() {
            _editing = null;
            _creating = false;
            _load(_topic!);
          });
        },
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Xưởng tạo bài học',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Chọn chủ đề → Thiết kế slide → Nhờ Gemini soạn nội dung → Chơi thử và phát hành.',
        ),
        const SizedBox(height: 24),
        if (topics.isEmpty)
          const Text('Tạo một chủ đề ở tab Chủ đề trước khi soạn bài.'),
        if (topics.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey('studio-topic-$_topic'),
            isExpanded: true,
            initialValue: topics.any((t) => t.id == _topic) ? _topic : null,
            decoration: const InputDecoration(labelText: 'Chủ đề của bài học'),
            items: [
              for (final t in topics)
                DropdownMenuItem(value: t.id, child: Text(t.title)),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _load(v));
            },
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const ValueKey('studio-new'),
              onPressed: _topic == null
                  ? null
                  : () => setState(() => _creating = true),
              icon: const Icon(Icons.add),
              label: const Text('Tạo bài học theo slide'),
            ),
            OutlinedButton.icon(
              onPressed: _topic == null
                  ? null
                  : () => setState(() => _load(_topic!)),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại bản nháp'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final engine in slideEngineNames.entries)
              Chip(
                avatar: Icon(_engineIcons[engine.key], size: 18),
                label: Text(engine.value),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Bài đã soạn', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_drafts != null)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _drafts,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Chưa tải được bản nháp. Bấm Tải lại để thử lại.',
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final rows = snapshot.data!;
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'Chưa có bản nháp. Chọn Tạo bài học theo slide để bắt đầu.',
                  ),
                );
              }
              return Column(
                children: [
                  for (final row in rows)
                    Card(
                      elevation: 0,
                      color: paper,
                      child: ListTile(
                        leading: const Icon(Icons.auto_stories_outlined),
                        title: Text(
                          (row['title'] as String? ?? '').isEmpty
                              ? 'Bài chưa đặt tên'
                              : row['title'] as String,
                        ),
                        subtitle: Text(
                          '${(row['config']?['slides'] as List? ?? []).length} slide · ${row['builder_status'] == 'published' ? 'Đã phát hành' : 'Bản nháp'}',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => setState(() => _editing = row),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class AdminSlideComposer extends StatefulWidget {
  const AdminSlideComposer({
    super.key,
    required this.controller,
    required this.topicId,
    required this.onBack,
    this.lesson,
  });
  final AdminDashboardController controller;
  final String topicId;
  final VoidCallback onBack;
  final Map<String, dynamic>? lesson;
  @override
  State<AdminSlideComposer> createState() => _AdminSlideComposerState();
}

class _AdminSlideComposerState extends State<AdminSlideComposer> {
  late final String _id;
  late final TextEditingController _title, _goal, _ai;
  late List<Map<String, dynamic>> _slides;
  int _selected = 0, _draftRevision = 0, _contentRevision = 0, _formEpoch = 0;
  bool _busy = false, _loading = false, _dirty = false, _published = false;
  String? _message, _feedback;
  Timer? _autosave;
  Map<String, dynamic> _previewState = {};
  @override
  void initState() {
    super.initState();
    final row = widget.lesson;
    _id = row?['id'] as String? ?? 'lesson-${learningUuid()}';
    _title = TextEditingController(text: row?['title'] as String? ?? '');
    _goal = TextEditingController(
      text:
          row?['prompt'] as String? ??
          'Hoàn thành các slide và thử các tương tác trong bài.',
    );
    _ai = TextEditingController();
    _slides =
        (row?['config']?['slides'] as List?)
            ?.map((s) => learningCopy(learningMap(s)))
            .toList() ??
        [newLessonSlide('story')];
    _draftRevision = row?['draft_revision'] as int? ?? 0;
    _contentRevision =
        row?['content_revision'] as int? ?? row?['revision'] as int? ?? 0;
    if (row != null && row['draft_revision'] == null) {
      _loading = true;
      _restoreDraft();
    }
  }

  Future<void> _restoreDraft() async {
    try {
      final rows = await widget.controller.loadBuilderDrafts(widget.topicId);
      if (!mounted) return;
      final row = rows.where((r) => r['id'] == _id).firstOrNull;
      if (row != null) {
        _draftRevision = row['draft_revision'] as int;
        _contentRevision = row['content_revision'] as int;
        if (row['builder_status'] == 'draft') {
          _title.text = row['title'] as String? ?? '';
          _goal.text = row['prompt'] as String? ?? '';
          _slides = (row['config']['slides'] as List)
              .map((s) => learningCopy(learningMap(s)))
              .toList();
        }
      }
    } catch (_) {
      if (mounted) _message = 'Chưa tải được bản nháp hiện có. Tải lại trước khi lưu để tránh ghi đè.';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _autosave?.cancel();
    _title.dispose();
    _goal.dispose();
    _ai.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _config => {'schema_version': 1, 'slides': _slides};
  Map<String, dynamic> _payload() => {
    'id': _id,
    'topic_id': widget.topicId,
    'title': _title.text.trim(),
    'prompt': _goal.text.trim(),
    'stage': 'Khám phá',
    'hint': 'Đọc yêu cầu của từng slide, điều chỉnh mô hình rồi kiểm tra.',
    'explanation': 'Bạn đã hoàn thành các tương tác trong bài học.',
    'sort_order': widget.lesson?['sort_order'] ?? 0,
    'status': widget.lesson?['editor_status'] == 'archived'
        ? 'archived'
        : 'active',
    'mechanism': 'slideLesson',
    'config': learningCopy(_config),
  };
  void _changed() {
    setState(() {
      _dirty = true;
      _published = false;
      _previewState = {};
      _feedback = null;
    });
    _autosave?.cancel();
    _autosave = Timer(const Duration(seconds: 2), () {
      if (mounted && !_busy && !_loading) _saveDraft(announce: false);
    });
  }

  Future<bool> _saveDraft({bool announce = true}) async {
    if (_busy || _loading) return false;
    _autosave?.cancel();
    setState(() => _busy = true);
    final saved = await widget.controller.saveBuilderDraft({
      ..._payload(),
      'revision': _draftRevision,
    });
    if (!mounted) return saved;
    setState(() {
      _busy = false;
      if (saved) {
        _draftRevision++;
        _dirty = false;
        _message = announce ? 'Đã lưu bản nháp trên máy chủ.' : null;
      } else {
        _message = widget.controller.message;
      }
    });
    return saved;
  }

  Future<void> _publish() async {
    if (_busy || _loading) return;
    if (_title.text.trim().isEmpty ||
        _goal.text.trim().isEmpty ||
        !validSlideLesson(_config)) {
      setState(
        () => _message = 'Đặt tên bài, điền đủ nội dung và thêm ít nhất một slide tương tác. Kiểm tra số đáp án, cặp ghép và giới hạn đồ thị.',
      );
      return;
    }
    if (utf8.encode(jsonEncode(_payload())).length > 95000) {
      setState(
        () => _message = 'Nội dung quá dài. Hãy chia thành nhiều bài nhỏ hơn.',
      );
      return;
    }
    if (!await _saveDraft(announce: false) || !mounted) return;
    setState(() => _busy = true);
    final saved = await widget.controller.saveLesson({
      ..._payload(),
      'status': 'active',
      'revision': _contentRevision,
      'builder_revision': _draftRevision,
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (saved) {
        _contentRevision++;
        _published = true;
        _dirty = false;
        _message = 'Đã phát hành! Mobile 1.3.4 trở lên sẽ nhận bài khi đang online. Chủ đề cần ở trạng thái hoạt động.';
      } else {
        _message = widget.controller.message;
      }
    });
  }

  Future<void> _generate() async {
    if (_busy || _loading) return;
    if (_ai.text.trim().length < 10 ||
        !validSlideLesson(_config, requireInteractive: false)) {
      setState(
        () => _message = 'Điền cấu trúc slide hợp lệ và mô tả nội dung muốn tạo (ít nhất 10 ký tự).',
      );
      return;
    }
    _autosave?.cancel();
    setState(() => _busy = true);
    final result = await widget.controller.generateSlides(
      _ai.text.trim(),
      widget.topicId,
      learningCopy(_config),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) {
      setState(() => _message = widget.controller.message);
      return;
    }
    final candidate = {'schema_version': 1, 'slides': result};
    if (!validSlideLesson(candidate, requireInteractive: false) ||
        result.length != _slides.length ||
        result.indexed.any(
          (e) =>
              e.$2['id'] != _slides[e.$1]['id'] ||
              e.$2['engine'] != _slides[e.$1]['engine'],
        )) {
      setState(
        () => _message = 'AI trả về cấu trúc khác thiết kế. Nội dung hiện tại được giữ nguyên.',
      );
      return;
    }
    _slides = result;
    _formEpoch++;
    _changed();
    setState(
      () => _message = 'Gemini đã điền nội dung vào thiết kế. Hãy duyệt đáp án và chơi thử trước khi phát hành.',
    );
  }

  Future<void> _leave() async {
    if (_busy) return;
    if (_dirty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lưu thiết kế trước khi rời?'),
          content: const Text('Bản đang soạn có thay đổi chưa lưu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'stay'),
              child: const Text('Soạn tiếp'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: const Text('Bỏ thay đổi'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: const Text('Lưu và quay lại'),
            ),
          ],
        ),
      );
      if (choice == null || choice == 'stay') return;
      if (choice == 'save' && !await _saveDraft()) return;
    }
    if (mounted) widget.onBack();
  }

  void _select(int index) {
    setState(() {
      _selected = index;
      _previewState = {};
      _feedback = null;
    });
  }

  void _move(int from, int to) {
    if (_busy || to < 0 || to >= _slides.length) return;
    final slide = _slides.removeAt(from);
    _slides.insert(to, slide);
    _selected = to;
    _formEpoch++;
    _changed();
  }

  Future<void> _add() async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Chọn cơ chế tương tác'),
        children: [
          for (final entry in slideEngineNames.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, entry.key),
              child: ListTile(
                leading: Icon(_engineIcons[entry.key]),
                title: Text(entry.value),
              ),
            ),
        ],
      ),
    );
    if (type == null || !mounted || _slides.length >= 12) return;
    _slides.add(newLessonSlide(type));
    _selected = _slides.length - 1;
    _changed();
  }

  Widget _input(
    String key,
    String label,
    String value,
    void Function(String) update, {
    int lines = 1,
    int maximum = 2000,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('builder-${_slides[_selected]['id']}-$key-$_formEpoch'),
      initialValue: value,
      enabled: !_busy && !_loading,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      maxLength: maximum,
      keyboardType: number
          ? const TextInputType.numberWithOptions(signed: true)
          : null,
      decoration: InputDecoration(labelText: label, counterText: ''),
      onChanged: (v) {
        update(v);
        _changed();
      },
    ),
  );
  List<Widget> _editor() {
    final s = _slides[_selected], c = s['config'] as Map<String, dynamic>;
    return [
      Text('Thông tin bài học', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 16),
      TextField(
        key: const ValueKey('builder-title'),
        controller: _title,
        enabled: !_busy,
        decoration: const InputDecoration(labelText: 'Tên bài học'),
        maxLength: 160,
        onChanged: (_) => _changed(),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _goal,
        enabled: !_busy,
        decoration: const InputDecoration(
          labelText: 'Mục tiêu / lời dẫn của bài',
        ),
        minLines: 2,
        maxLines: 4,
        maxLength: 1000,
        onChanged: (_) => _changed(),
      ),
      const Divider(height: 32),
      Text(
        'Slide ${_selected + 1} · ${slideEngineNames[s['engine']]}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 16),
      _input(
        'title',
        'Tiêu đề slide',
        s['title'] as String,
        (v) => s['title'] = v,
        maximum: 160,
      ),
      _input(
        'prompt',
        'Yêu cầu cho người học',
        s['prompt'] as String,
        (v) => s['prompt'] = v,
        lines: 2,
        maximum: 10000,
      ),
      if (s['engine'] == 'story') ...[
        _input(
          'text',
          'Nội dung dẫn chuyện',
          c['text'] as String,
          (v) => c['text'] = v,
          lines: 4,
          maximum: 10000,
        ),
        _input(
          'image',
          'Đường dẫn hình ảnh HTTPS (tùy chọn)',
          c['image_url'] as String,
          (v) => c['image_url'] = v,
        ),
        _input(
          'alt',
          'Mô tả hình ảnh',
          c['image_alt'] as String,
          (v) => c['image_alt'] = v,
          maximum: 500,
        ),
      ],
      if (s['engine'] == 'quiz') ...[
        const Text('Nhấn dấu tròn để chọn đáp án đúng.'),
        const SizedBox(height: 12),
        for (final entry in (c['choices'] as List).indexed)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                tooltip: 'Đáp án đúng ${entry.$1 + 1}',
                onPressed: _busy
                    ? null
                    : () {
                        c['answer'] = entry.$1;
                        _changed();
                      },
                icon: Icon(
                  c['answer'] == entry.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
              ),
              Expanded(
                child: _input(
                  'choice-${entry.$1}',
                  'Đáp án ${entry.$1 + 1}',
                  entry.$2 as String,
                  (v) => (c['choices'] as List)[entry.$1] = v,
                ),
              ),
              IconButton(
                tooltip: 'Xóa đáp án',
                onPressed: _busy || (c['choices'] as List).length <= 2
                    ? null
                    : () {
                        (c['choices'] as List).removeAt(entry.$1);
                        c['answer'] = (c['answer'] as int).clamp(
                          0,
                          (c['choices'] as List).length - 1,
                        );
                        _formEpoch++;
                        _changed();
                      },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: _busy || (c['choices'] as List).length >= 8
              ? null
              : () {
                  (c['choices'] as List).add('Đáp án mới');
                  _formEpoch++;
                  _changed();
                },
          icon: const Icon(Icons.add),
          label: const Text('Thêm đáp án'),
        ),
      ],
      if (s['engine'] == 'pairs') ...[
        const Text(
          'Hai ô cùng hàng tạo thành một cặp đúng. Mobile sẽ đảo thứ tự các thẻ bên phải.',
        ),
        const SizedBox(height: 12),
        for (final entry in (c['pairs'] as List).indexed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cặp ${entry.$1 + 1}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _input(
                'pair-left-${entry.$1}',
                'Nội dung cần ghép',
                entry.$2['left'] as String,
                (v) => entry.$2['left'] = v,
                maximum: 1000,
              ),
              _input(
                'pair-right-${entry.$1}',
                'Đáp án tương ứng',
                entry.$2['right'] as String,
                (v) => entry.$2['right'] = v,
                maximum: 1000,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _busy || (c['pairs'] as List).length <= 2
                      ? null
                      : () {
                          (c['pairs'] as List).removeAt(entry.$1);
                          _formEpoch++;
                          _changed();
                        },
                  child: const Text('Bỏ cặp này'),
                ),
              ),
            ],
          ),
        OutlinedButton.icon(
          onPressed: _busy || (c['pairs'] as List).length >= 6
              ? null
              : () {
                  (c['pairs'] as List).add({
                    'left': 'Nội dung mới',
                    'right': 'Đáp án mới',
                  });
                  _formEpoch++;
                  _changed();
                },
          icon: const Icon(Icons.add),
          label: const Text('Thêm cặp'),
        ),
      ],
      if (s['engine'] == 'graph') ...[
        const Text(
          'Mô hình đường thẳng y = a × x + b. Học sinh điều chỉnh hai thanh trượt để đạt a và b mục tiêu. Các tham số là số nguyên từ −10 đến 10.',
        ),
        const SizedBox(height: 16),
        for (final field in const {
          'target_a': 'Độ dốc a cần đạt',
          'target_b': 'Giao điểm b cần đạt',
          'start_a': 'Giá trị a ban đầu',
          'start_b': 'Giá trị b ban đầu',
          'min_a': 'Giới hạn nhỏ nhất của a',
          'max_a': 'Giới hạn lớn nhất của a',
          'min_b': 'Giới hạn nhỏ nhất của b',
          'max_b': 'Giới hạn lớn nhất của b',
        }.entries)
          _input(
            field.key,
            field.value,
            '${c[field.key]}',
            (v) => c[field.key] = int.tryParse(v) ?? v,
            number: true,
            maximum: 3,
          ),
      ],
      const SizedBox(height: 16),
      _input(
        'hint',
        'Gợi ý khi làm bài',
        s['hint'] as String,
        (v) => s['hint'] = v,
        lines: 2,
        maximum: 3000,
      ),
      _input(
        'explanation',
        'Giải thích sau tương tác',
        s['explanation'] as String,
        (v) => s['explanation'] = v,
        lines: 2,
        maximum: 10000,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Khóa tham số khi dùng Gemini'),
        subtitle: const Text(
          'Giữ đáp án đúng và mục tiêu đồ thị. Loại engine, số slide, số lựa chọn và giới hạn thanh trượt luôn được giữ.',
        ),
        value: s['locked'] != false,
        onChanged: _busy
            ? null
            : (v) {
                s['locked'] = v;
                _changed();
              },
      ),
      const Divider(height: 32),
      Text(
        'Gemini điền nội dung vào thiết kế',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('builder-ai-prompt'),
        controller: _ai,
        enabled: !_busy,
        minLines: 3,
        maxLines: 6,
        maxLength: 3000,
        decoration: const InputDecoration(
          labelText: 'Chủ đề, độ tuổi, độ khó và ý tưởng',
          hintText: 'Ví dụ: Dẫn chuyện về chia pizza cho học sinh lớp 4, giữ cấu trúc tôi đã thiết kế.',
        ),
      ),
      FilledButton.tonalIcon(
        key: const ValueKey('builder-generate'),
        onPressed: _busy ? null : _generate,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Soạn nội dung cho toàn bộ slide'),
      ),
      const SizedBox(height: 32),
    ];
  }

  Widget _slideList({bool compact = false}) {
    final rows = [
      for (final entry in _slides.indexed)
        Card(
          elevation: 0,
          color: entry.$1 == _selected
              ? BrilliantPalette.successSurface
              : paper,
          child: Column(
            children: [
              ListTile(
                dense: true,
                selected: entry.$1 == _selected,
                leading: Icon(_engineIcons[entry.$2['engine']], size: 20),
                title: Text('${entry.$1 + 1}. ${entry.$2['title']}'),
                subtitle: Text(slideEngineNames[entry.$2['engine']]!),
                onTap: _busy ? null : () => _select(entry.$1),
              ),
              if (entry.$1 == _selected)
                Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Đưa slide lên',
                      onPressed: _busy || entry.$1 == 0
                          ? null
                          : () => _move(entry.$1, entry.$1 - 1),
                      icon: const Icon(Icons.arrow_upward, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Đưa slide xuống',
                      onPressed: _busy || entry.$1 == _slides.length - 1
                          ? null
                          : () => _move(entry.$1, entry.$1 + 1),
                      icon: const Icon(Icons.arrow_downward, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Nhân bản slide',
                      onPressed: _busy || _slides.length >= 12
                          ? null
                          : () {
                              final copy = learningCopy(entry.$2)
                                ..['id'] = 'slide-${learningUuid()}';
                              _slides.insert(entry.$1 + 1, copy);
                              _selected = entry.$1 + 1;
                              _changed();
                            },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Xóa slide',
                      onPressed: _busy || _slides.length == 1
                          ? null
                          : () {
                              _slides.removeAt(entry.$1);
                              _selected = _selected.clamp(
                                0,
                                _slides.length - 1,
                              );
                              _formEpoch++;
                              _changed();
                            },
                      icon: const Icon(Icons.delete_outline, size: 18),
                    ),
                  ],
                ),
            ],
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cấu trúc · ${_slides.length}/12 slide',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (compact) ...rows else Expanded(child: ListView(children: rows)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const ValueKey('builder-add-slide'),
          onPressed: _busy || _slides.length >= 12 ? null : _add,
          icon: const Icon(Icons.add),
          label: const Text('Thêm slide mới'),
        ),
      ],
    );
  }

  Widget _phone() {
    final slide = _slides[_selected];
    final valid = validSlideLesson({
      'schema_version': 1,
      'slides': [slide],
    }, requireInteractive: false);
    if (valid && _previewState.isEmpty) {
      _previewState = learningMap(
        (initialSlideState({
                  'slides': [slide],
                })['slides']
                as List)
            .first,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.smartphone_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Mobile · Chơi thử',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: paper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: BrilliantPalette.track),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Slide ${_selected + 1}/${_slides.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  slide['title'] as String,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(slide['prompt'] as String),
                const SizedBox(height: 20),
                if (valid)
                  SlideEngineWorkspace(
                    key: ValueKey('preview-${slide['id']}'),
                    slide: slide,
                    state: _previewState,
                    locked: false,
                    onChanged: (state) => setState(() {
                      _previewState = state;
                      _feedback = null;
                    }),
                  )
                else
                  const Text(
                    'Hoàn thiện nội dung và tham số hợp lệ để chơi thử.',
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const ValueKey('builder-check'),
                  onPressed: !valid
                      ? null
                      : () => setState(
                          () => _feedback = slideIsCorrect(slide, _previewState)
                              ? 'Chính xác! ${slide['explanation']}'
                              : 'Chưa đúng. ${slide['hint']}',
                        ),
                  child: const Text('Kiểm tra tương tác'),
                ),
                if (_feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _feedback!,
                      key: const ValueKey('builder-feedback'),
                    ),
                  ),
                TextButton(
                  onPressed: () => setState(() {
                    _previewState = {};
                    _feedback = null;
                  }),
                  child: const Text('Chơi lại'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _busy ? null : _leave,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Danh sách bài soạn'),
                ),
                Text(
                  _busy
                      ? 'Đang xử lý…'
                      : _published
                      ? 'Đã phát hành'
                      : _dirty
                      ? 'Đang soạn · tự lưu sau 2 giây'
                      : _draftRevision > 0
                      ? 'Đã lưu trên máy chủ'
                      : 'Thiết kế mới',
                ),
                OutlinedButton(
                  key: const ValueKey('builder-save'),
                  onPressed: _busy || _loading ? null : () => _saveDraft(),
                  child: const Text('Lưu bản nháp'),
                ),
                FilledButton.icon(
                  key: const ValueKey('builder-publish'),
                  onPressed: _busy || _loading ? null : _publish,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Phát hành lên mobile'),
                ),
              ],
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_message!, key: const ValueKey('builder-message')),
              ),
            if (_busy || _loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: LayoutBuilder(
          builder: (context, size) => size.maxWidth >= 1100
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 200,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _slideList(),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: _editor(),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: 350,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [_phone()],
                      ),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _slideList(compact: true),
                    const Divider(height: 32),
                    ..._editor(),
                    _phone(),
                  ],
                ),
        ),
      ),
    ],
  );
}
