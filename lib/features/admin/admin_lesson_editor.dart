import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../data/models/admin_dashboard.dart';
import '../../data/models/authored_lesson.dart';
import '../../data/models/learning_journal.dart';
import '../../data/providers/admin_dashboard_controller.dart';
import '../../experiments/reasoning_workspace.dart';
import 'admin_slide_composer.dart';

class AdminLessonLibrary extends StatefulWidget {
  const AdminLessonLibrary({
    super.key,
    required this.controller,
    required this.topic,
    required this.onBack,
  });
  final AdminDashboardController controller;
  final AdminTopic topic;
  final VoidCallback onBack;
  @override
  State<AdminLessonLibrary> createState() => _AdminLessonLibraryState();
}

class _AdminLessonLibraryState extends State<AdminLessonLibrary> {
  List<Map<String, dynamic>> _lessons = [];
  Map<String, dynamic>? _selected;
  bool _loading = true, _editing = false;
  String? _error;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.controller.loadLessons(widget.topic.id);
      if (!mounted || request != _request) return;
      setState(() => _lessons = rows);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Chưa tải được bài học. Hãy thử tải lại.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      if (_selected?['evaluator_version'] == 4) {
        return AdminSlideComposer(
          controller: widget.controller,
          topicId: widget.topic.id,
          lesson: _selected,
          onBack: () {
            setState(() => _editing = false);
            _load();
          },
        );
      }
      return AdminLessonEditor(
        key: ValueKey(_selected?['id'] ?? 'new'),
        controller: widget.controller,
        topicId: widget.topic.id,
        lesson: _selected,
        onCancel: () => setState(() => _editing = false),
        onSaved: () {
          setState(() => _editing = false);
          _load();
        },
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Thư viện chủ đề'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.topic.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${_lessons.where((r) => r['editor_status'] != 'archived').length} bài học đang hiển thị · ${widget.topic.status == 'active' ? 'Chủ đề đang hoạt động' : 'Chủ đề chưa hiển thị trên mobile'}',
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const ValueKey('admin-add-lesson'),
              onPressed: _loading
                  ? null
                  : () => setState(() {
                      _selected = null;
                      _editing = true;
                    }),
              icon: const Icon(Icons.add),
              label: const Text('Thêm bài tương tác'),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại bài học'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        if (!_loading && _lessons.isEmpty && _error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(Icons.auto_stories_outlined, size: 48),
                SizedBox(height: 12),
                Text('Bắt đầu bằng bài tương tác đầu tiên'),
                SizedBox(height: 8),
                Text(
                  'Nhập câu hỏi, lựa chọn và lời giải. Bạn có thể chơi thử trước khi phát hành.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        for (final row in _lessons)
          Card(
            color: paper,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: BrilliantPalette.track),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: BrilliantPalette.successSurface,
                        child: Text(
                          '${(row['sort_order'] as num? ?? 0).toInt() + 1}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row['title'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              row['prompt'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(
                          row['editor_status'] == 'archived'
                              ? 'Đã lưu trữ'
                              : 'Đang hiển thị',
                        ),
                      ),
                      Text(
                        row['evaluator_version'] == 4
                            ? 'Bài học nhiều slide'
                            : row['evaluator_version'] == 3
                            ? 'Lựa chọn + giải thích'
                            : 'Mô phỏng tương tác · ${row['mechanism']}',
                      ),
                      TextButton.icon(
                        key: ValueKey('edit-lesson-${row['id']}'),
                        onPressed: () => setState(() {
                          _selected = row;
                          _editing = true;
                        }),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Biên tập / xem thử'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class AdminLessonEditor extends StatefulWidget {
  const AdminLessonEditor({
    super.key,
    required this.controller,
    required this.topicId,
    required this.onSaved,
    required this.onCancel,
    this.lesson,
  });
  final AdminDashboardController controller;
  final String topicId;
  final Map<String, dynamic>? lesson;
  final VoidCallback onSaved, onCancel;
  @override
  State<AdminLessonEditor> createState() => _AdminLessonEditorState();
}

class _AdminLessonEditorState extends State<AdminLessonEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  late final String _id;
  late String _status;
  bool _saving = false;
  bool _generated = false;
  String? _aiError;
  String? _error;
  Map<String, dynamic> _previewState = {'answer': -1, 'reason': -1};
  bool get _authored =>
      widget.lesson == null || widget.lesson!['evaluator_version'] == 3;
  TextEditingController field(String key) => _fields[key]!;
  @override
  void initState() {
    super.initState();
    final row = widget.lesson ?? <String, dynamic>{};
    final config = learningMap(row['config']);
    _id = row['id'] as String? ?? 'lesson-${learningUuid()}';
    _status = row['editor_status'] as String? ?? 'active';
    final values = <String, String>{
      'ai_prompt': '',
      'title': row['title'] as String? ?? '',
      'stage': row['stage'] as String? ?? 'Khám phá',
      'prompt': row['prompt'] as String? ?? '',
      'hint': (row['hint_levels'] as List?)?.firstOrNull as String? ?? '',
      'explanation': row['explanation'] as String? ?? '',
      'sort_order': '${row['sort_order'] ?? 0}',
      'knowledge': config['knowledge'] as String? ?? '',
      'source': config['source'] as String? ?? '',
      'choices': (config['choices'] as List? ?? []).join('\n'),
      'reasons': (config['reasons'] as List? ?? []).join('\n'),
      'answer': '${(config['answer'] as num? ?? 0).toInt() + 1}',
      'reason': '${(config['reason'] as num? ?? 0).toInt() + 1}',
    };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  List<String> lines(String key) =>
      field(key).text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
  Map<String, dynamic> payload() => {
    'id': _id,
    'topic_id': widget.topicId,
    'revision': widget.lesson?['revision'] ?? 0,
    for (final key in ['title', 'stage', 'prompt', 'hint', 'explanation'])
      key: field(key).text.trim(),
    'sort_order': int.tryParse(field('sort_order').text) ?? 0,
    'status': _status,
    if (_authored)
      'config': {
        'knowledge': field('knowledge').text.trim(),
        'source': field('source').text.trim(),
        'choices': lines('choices'),
        'reasons': lines('reasons'),
        'answer': (int.tryParse(field('answer').text) ?? 0) - 1,
        'reason': (int.tryParse(field('reason').text) ?? 0) - 1,
      },
  };
  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.controller.saveLesson(payload());
    if (!mounted) return;
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã phát hành nội dung. Mobile đang online sẽ nhận bản cập nhật.',
          ),
        ),
      );
      widget.onSaved();
    } else {
      setState(() {
        _saving = false;
        _error =
            widget.controller.message ??
            'Chưa lưu được. Hãy tải lại để kiểm tra phiên bản mới nhất.';
      });
    }
  }

  Future<void> _generate() async {
    final prompt = field('ai_prompt').text.trim();
    if (_saving) return;
    if (prompt.length < 10 || prompt.length > 3000) {
      setState(() => _aiError = 'Mô tả bài học từ 10 đến 3000 ký tự.');
      return;
    }
    setState(() {
      _saving = true;
      _aiError = null;
    });
    final draft = await widget.controller.generateLesson(
      prompt,
      widget.topicId,
    );
    if (!mounted) return;
    if (draft != null) {
      final config = learningMap(draft['config']);
      for (final name in ['title', 'stage', 'prompt', 'hint', 'explanation']) {
        field(name).text = draft[name] as String;
      }
      for (final name in ['knowledge', 'source']) {
        field(name).text = config[name] as String? ?? '';
      }
      for (final name in ['choices', 'reasons']) {
        field(name).text = (config[name] as List).join('\n');
      }
      field('answer').text = '${(config['answer'] as int) + 1}';
      field('reason').text = '${(config['reason'] as int) + 1}';
      setState(() {
        _saving = false;
        _generated = true;
      });
    } else {
      setState(() {
        _saving = false;
        _aiError =
            widget.controller.message ?? 'Chưa tạo được bản nháp. Hãy thử lại.';
      });
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ẩn bài học khỏi mobile?'),
        content: const Text(
          'Bài học sẽ được lưu trữ. Phiên học và điểm đã xác nhận được giữ lại. Bạn có thể khôi phục bài học sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu trữ bài học'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _status = 'archived');
    await _save();
  }

  Widget input(
    String name,
    String label, {
    int max = 3000,
    int lines = 1,
    String? helper,
    String? Function(String?)? validate,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('lesson-$name'),
      controller: field(name),
      enabled: !_saving,
      maxLength: max,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        counterText: '',
      ),
      validator:
          validate ??
          (v) => required && (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập $label.'
              : null,
    ),
  );
  void _preview() {
    if (!_form.currentState!.validate()) return;
    final data = payload();
    final spec = decodeAuthoredLesson({
      ...data,
      'activity_id': _id,
      'content_version': 1,
      'evaluator_version': 3,
      'mechanism': 'reasonedChoice',
      'hint_levels': [data['hint']],
    });
    if (spec == null) return;
    _previewState = spec.initialData();
    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(spec.title),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spec.prompt),
                  const SizedBox(height: 16),
                  ReasoningWorkspace(
                    spec: spec,
                    data: _previewState,
                    locked: false,
                    onChanged: (state) => refresh(() => _previewState = state),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    spec.isCorrect(_previewState)
                        ? 'Chính xác! ${spec.explanation}'
                        : 'Chọn đáp án và lý do để kiểm tra.',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng xem thử'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _saving ? null : widget.onCancel,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Danh sách bài học'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.lesson == null ? 'Tạo bài tương tác' : 'Biên tập bài học',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            _authored
                ? 'Mẫu: Chọn đáp án + giải thích. Nhập nội dung, chơi thử và phát hành tới mobile.'
                : 'Mô phỏng ${widget.lesson!['mechanism']}: sửa nội dung chữ; cấu hình tương tác và bộ chấm bài đã phát hành được giữ nguyên.',
          ),
          const SizedBox(height: 24),
          if (_authored)
            Card(
              elevation: 0,
              color: BrilliantPalette.successSurface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Soạn bài cùng Gemini',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mô tả kiến thức, độ tuổi và độ khó. Gemini điền bản nháp theo mẫu lựa chọn + giải thích vào form bên dưới. Bạn kiểm tra, chơi thử rồi mới phát hành.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const ValueKey('lesson-ai-prompt'),
                      controller: field('ai_prompt'),
                      enabled: !_saving,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 3000,
                      decoration: const InputDecoration(
                        labelText: 'Bạn muốn tạo bài học gì?',
                        hintText: 'Ví dụ: Tạo bài phân số lớp 4 về chia bánh pizza thành 8 phần, chọn một nửa và giải thích.',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        key: const ValueKey('generate-lesson'),
                        onPressed: _saving ? null : _generate,
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(
                          _saving ? 'Đang xử lý…' : 'Tạo bản nháp bằng Gemini',
                        ),
                      ),
                    ),
                    if (_aiError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_aiError!),
                      ),
                    if (_generated)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Đã điền bản nháp AI. Chưa xuất bản; hãy kiểm tra đáp án và chơi thử.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                input('title', 'Tên bài học', max: 160),
                input('stage', 'Giai đoạn', max: 100),
                input('prompt', 'Câu hỏi / yêu cầu', max: 10000, lines: 3),
                if (_authored) ...[
                  input(
                    'knowledge',
                    'Kiến thức nền',
                    max: 10000,
                    lines: 3,
                    required: false,
                  ),
                  input(
                    'choices',
                    'Các đáp án',
                    lines: 3,
                    helper: 'Mỗi dòng là một đáp án, từ 2 đến 8 dòng.',
                    validate: (_) =>
                        lines('choices').length >= 2 &&
                            lines('choices').length <= 8
                        ? null
                        : 'Nhập từ 2 đến 8 đáp án.',
                  ),
                  input(
                    'answer',
                    'Số thứ tự đáp án đúng',
                    max: 1,
                    validate: (v) {
                      final n = int.tryParse(v ?? '');
                      return n != null && n > 0 && n <= lines('choices').length
                          ? null
                          : 'Chọn số thứ tự đáp án hợp lệ.';
                    },
                  ),
                  input(
                    'reasons',
                    'Các lý do',
                    lines: 3,
                    helper: 'Mỗi dòng là một lý do, từ 2 đến 8 dòng.',
                    validate: (_) =>
                        lines('reasons').length >= 2 &&
                            lines('reasons').length <= 8
                        ? null
                        : 'Nhập từ 2 đến 8 lý do.',
                  ),
                  input(
                    'reason',
                    'Số thứ tự lý do đúng',
                    max: 1,
                    validate: (v) {
                      final n = int.tryParse(v ?? '');
                      return n != null && n > 0 && n <= lines('reasons').length
                          ? null
                          : 'Chọn số thứ tự lý do hợp lệ.';
                    },
                  ),
                ],
                input('hint', 'Gợi ý', lines: 2),
                input(
                  'explanation',
                  'Giải thích sau bài học',
                  max: 10000,
                  lines: 3,
                ),
                if (_authored)
                  input(
                    'source',
                    'Nguồn tham khảo',
                    max: 2000,
                    required: false,
                  ),
                input(
                  'sort_order',
                  'Thứ tự hiển thị (bắt đầu từ 0)',
                  max: 6,
                  validate: (v) {
                    final n = int.tryParse(v ?? '');
                    return n != null && n >= 0 && n <= 100000
                        ? null
                        : 'Nhập số từ 0 đến 100000.';
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, key: const ValueKey('lesson-error')),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (_authored)
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _preview,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Chơi thử'),
                      ),
                    FilledButton.icon(
                      key: const ValueKey('publish-lesson'),
                      onPressed: _saving
                          ? null
                          : () {
                              if (_status == 'archived') {
                                setState(() => _status = 'active');
                              }
                              _save();
                            },
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        _saving
                            ? 'Đang lưu…'
                            : _status == 'archived'
                            ? 'Khôi phục và phát hành'
                            : 'Lưu và phát hành',
                      ),
                    ),
                    if (widget.lesson != null && _status != 'archived')
                      TextButton.icon(
                        key: const ValueKey('archive-lesson'),
                        onPressed: _saving ? null : _archive,
                        icon: const Icon(Icons.archive_outlined),
                        label: const Text('Xóa / lưu trữ bài'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ),
  );
}
