import '../shared/widgets/role_ui.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/question.dart';
import '../../data/repositories/study_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../auth/auth_screen.dart';
import '../learning_engine/widgets/area_grid_widget.dart';
import '../learning_engine/widgets/clock_rotation_widget.dart';
import '../learning_engine/widgets/drag_counters_widget.dart';
import '../learning_engine/widgets/multiplication_widget.dart';
import '../learning_engine/widgets/word_problem_widget.dart';

class ContentManagementScreen extends StatefulWidget {
  const ContentManagementScreen({super.key});
  @override
  State<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState extends State<ContentManagementScreen> {
  int _grade = 1;
  Map<String, dynamic> _data = {};
  String? _error;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final data = await StudyRepository.rpc('staff_curriculum', {
        'p_grade': _grade,
      });
      if (mounted) setState(() => _data = Map<String, dynamic>.from(data));
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : 'Không tải được nội dung.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(
    Map<String, dynamic>? lesson, {
    Map<String, dynamic>? draft,
  }) async {
    try {
      final data =
          draft ??
          (lesson == null
              ? {
                  'grade': _grade,
                  'topic_id': (_data['topics'] as List).first['id'],
                  'title': '',
                  'theory': '',
                  'access_tier': 'basic',
                  'questions': <dynamic>[],
                }
              : Map<String, dynamic>.from(
                  await StudyRepository.rpc('staff_lesson', {
                    'p_lesson': lesson['id'],
                  }),
                ));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonEditorScreen(
            lessonId: lesson?['id'],
            content: Map<String, dynamic>.from(data),
            topics: List<Map<String, dynamic>>.from(
              (_data['topics'] as List).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            ),
          ),
        ),
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Chưa mở được bài. Cần tạo chủ đề trước.');
      }
    }
  }

  Future<void> _topic() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chủ đề mới'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Tên chủ đề'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await StudyRepository.rpc('create_topic', {
        'p_grade': _grade,
        'p_name': name,
      });
      await _load();
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : 'Không tạo được chủ đề.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => RoleScaffold(
    appBar: RoleAppBar(
      title: const Text('Biên tập nội dung'),
      actions: [
        IconButton(
          tooltip: 'Đăng xuất',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await AuthRepository.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            }
          },
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const RoleIntroCard(
          icon: Icons.auto_stories_rounded,
          title: 'Chăm chút từng bài học',
          description: 'Quản lý chủ đề, soạn bài và xem trước trải nghiệm học của bé trước khi xuất bản.',
        ),
        const SizedBox(height: 16),
        DropdownButton<int>(
          value: _grade,
          items: List.generate(
            5,
            (i) => DropdownMenuItem(value: i + 1, child: Text('Lớp ${i + 1}')),
          ),
          onChanged: _busy
              ? null
              : (v) {
                  _grade = v!;
                  _load();
                },
        ),
        Wrap(
          spacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _busy ? null : _topic,
              icon: const Icon(Icons.create_new_folder),
              label: const Text('Thêm chủ đề'),
            ),
            FilledButton.icon(
              onPressed: _busy || (_data['topics'] as List? ?? []).isEmpty
                  ? null
                  : () => _edit(null),
              icon: const Icon(Icons.add),
              label: const Text('Bài mới'),
            ),
          ],
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) Text(_error!),
        for (final l in _data['lessons'] as List? ?? [])
          Card(
            child: ListTile(
              title: Text(l['title']),
              subtitle: Text(
                '${l['published'] ? 'Đã xuất bản' : 'Đang ẩn'} · phiên bản ${l['content_version']} ${l['draft_id'] != null ? '· có nháp' : ''}',
              ),
              onTap: () => _edit(Map<String, dynamic>.from(l)),
              trailing: Switch(
                value: l['published'],
                onChanged: (v) async {
                  try {
                    await StudyRepository.rpc('set_lesson_published', {
                      'p_lesson': l['id'],
                      'p_published': v,
                    });
                    await _load();
                  } catch (e) {
                    if (mounted) {
                      setState(() => _error = 'Không đổi được trạng thái.');
                    }
                  }
                },
              ),
            ),
          ),
        for (final d in _data['drafts'] as List? ?? [])
          ListTile(
            leading: const Icon(Icons.drafts),
            title: Text(d['content']['title']?.toString() ?? 'Nháp'),
            onTap: () => _edit(
              null,
              draft: Map<String, dynamic>.from(d['content'])
                ..['draft_id'] = d['id'],
            ),
          ),
      ],
    ),
  );
}

class LessonEditorScreen extends StatefulWidget {
  final String? lessonId;
  final Map<String, dynamic> content;
  final List<Map<String, dynamic>> topics;
  const LessonEditorScreen({
    super.key,
    this.lessonId,
    required this.content,
    required this.topics,
  });
  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  late final TextEditingController _title, _theory, _essay, _answer;
  late String _topic, _tier;
  late List<Map<String, dynamic>> _questions;
  String? _draft, _message;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    final c = widget.content;
    _title = TextEditingController(text: c['title']);
    _theory = TextEditingController(text: c['theory']);
    _essay = TextEditingController(text: c['essay_prompt']);
    _answer = TextEditingController(text: c['essay_answer']);
    _topic = c['topic_id'];
    _tier = c['access_tier'] ?? 'basic';
    _draft = c['draft_id'];
    _questions = List<Map<String, dynamic>>.from(
      (c['questions'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _theory.dispose();
    _essay.dispose();
    _answer.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _content => {
    ...widget.content,
    'title': _title.text.trim(),
    'theory': _theory.text,
    'essay_prompt': _essay.text,
    'essay_answer': _answer.text,
    'topic_id': _topic,
    'access_tier': _tier,
    'questions': _questions,
  };
  Future<void> _save(bool publish) async {
    setState(() => _busy = true);
    try {
      _draft = await StudyRepository.rpc('save_lesson_draft', {
        'p_id': widget.lessonId,
        'p_content': {..._content, 'draft_id': _draft},
      });
      if (publish) {
        await StudyRepository.rpc('publish_lesson', {'p_draft': _draft});
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (mounted) {
        setState(() => _message = 'Đã lưu nháp. Học sinh chưa thấy thay đổi.');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is PostgrestException
              ? e.message
              : 'Không lưu được bài.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _templates = {
    'drag_counters': {'targetCount': 5, 'availableCount': 10, 'itemIcon': '🍎'},
    'clock_rotation': {'targetHour': 3, 'targetMinute': 30},
    'multiplication_table': {
      'factorA': 3,
      'factorB': 4,
      'correctAnswer': 12,
      'options': [9, 12, 15, 18],
    },
    'area_grid': {
      'rows': 3,
      'cols': 4,
      'correctAnswer': 12,
      'options': [7, 12, 14, 16],
    },
    'word_problem': {
      'problemText':
          'Lan có 3 quả táo và được thêm 2 quả. Lan có bao nhiêu quả?',
      'correctAnswer': 5,
      'options': [3, 4, 5, 6],
    },
  };
  Future<void> _question([int? index]) async {
    final original = index == null ? null : _questions[index];
    String type = original?['question_type'] ?? 'word_problem';
    final prompt = TextEditingController(text: original?['prompt'] ?? ''),
        payload = TextEditingController(
          text: const JsonEncoder.withIndent('  ')
              .convert(original?['payload'] ?? _templates[type]),
        ),
        hints = TextEditingController(
          text: const JsonEncoder.withIndent('  ').convert(
            original?['socratic_hints'] ??
                [
                  {'step': 1, 'hintText': 'Em hãy tìm các dữ kiện đã biết.'},
                ],
          ),
        );
    String? error;
    final q = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Câu hỏi tương tác'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    isExpanded: true,
                    value: type,
                    items: _templates.keys
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: (v) => set(() {
                      type = v!;
                      payload.text = const JsonEncoder.withIndent('  ')
                          .convert(_templates[type]);
                    }),
                  ),
                  TextField(
                    controller: prompt,
                    decoration: const InputDecoration(labelText: 'Đề bài'),
                  ),
                  TextField(
                    controller: payload,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Dữ liệu tương tác JSON (theo mẫu)',
                    ),
                  ),
                  TextField(
                    controller: hints,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Gợi ý từng bước JSON',
                    ),
                  ),
                  if (error != null) Text(error!),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final p = jsonDecode(payload.text),
                      h = jsonDecode(hints.text);
                  if (p is! Map || h is! List) throw const FormatException();
                  Navigator.pop(ctx, <String, dynamic>{
                    if (original?['id'] != null) 'id': original!['id'],
                    'question_type': type,
                    'prompt': prompt.text,
                    'payload': p,
                    'socratic_hints': h,
                  });
                } catch (_) {
                  set(
                    () => error = 'JSON không hợp lệ. Dữ liệu cần là object, gợi ý cần là danh sách.',
                  );
                }
              },
              child: const Text('Lưu câu hỏi'),
            ),
          ],
        ),
      ),
    );
    prompt.dispose();
    payload.dispose();
    hints.dispose();
    if (q != null && mounted) {
      setState(() {
        if (index == null) {
          _questions.add(q);
        } else {
          _questions[index] = q;
        }
      });
    }
  }

  void _preview(Map<String, dynamic> raw) {
    final q = Question.fromMap(raw);
    void answer(bool value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Đáp án đúng' : 'Đáp án sai')),
      );
    }

    final child = switch (q.type) {
      QuestionType.dragCounters => DragCountersWidget(
        data: q.data,
        onAnswerSubmitted: answer,
      ),
      QuestionType.clockRotation => ClockRotationWidget(
        data: q.data,
        onAnswerSubmitted: answer,
      ),
      QuestionType.multiplicationTable => MultiplicationWidget(
        data: q.data,
        onAnswerSubmitted: answer,
      ),
      QuestionType.areaGrid => AreaGridWidget(
        data: q.data,
        onAnswerSubmitted: answer,
      ),
      QuestionType.wordProblem => WordProblemWidget(
        data: q.data,
        onAnswerSubmitted: answer,
      ),
    };
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(q.prompt),
                child,
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng xem trước'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RoleScaffold(
    appBar: RoleAppBar(title: const Text('Bản nháp bài học')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Tên bài'),
        ),
        DropdownButton<String>(
          isExpanded: true,
          value: _topic,
          items: widget.topics
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t['id'],
                  child: Text(t['title']),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _topic = v!),
        ),
        DropdownButton<String>(
          value: _tier,
          items: const [
            DropdownMenuItem(value: 'basic', child: Text('Basic')),
            DropdownMenuItem(value: 'plus', child: Text('Plus')),
          ],
          onChanged: (v) => setState(() => _tier = v!),
        ),
        TextField(
          controller: _theory,
          maxLines: 7,
          decoration: const InputDecoration(labelText: 'Lý thuyết'),
        ),
        TextField(
          controller: _essay,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Đề tự luận (có thể bỏ trống)',
          ),
        ),
        TextField(
          controller: _answer,
          decoration: const InputDecoration(labelText: 'Đáp số tự luận chuẩn'),
        ),
        for (var i = 0; i < _questions.length; i++)
          Card(
            child: ListTile(
              title: Text('${i + 1}. ${_questions[i]['prompt']}'),
              subtitle: Text(_questions[i]['question_type']),
              onTap: () => _question(i),
              trailing: Wrap(
                children: [
                  IconButton(
                    tooltip: 'Xem trước',
                    onPressed: () => _preview(_questions[i]),
                    icon: const Icon(Icons.visibility),
                  ),
                  IconButton(
                    tooltip: 'Xóa khỏi bản nháp',
                    onPressed: () => setState(() => _questions.removeAt(i)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () => _question(),
          icon: const Icon(Icons.add),
          label: const Text('Thêm câu hỏi'),
        ),
        if (_message != null) Text(_message!),
        if (_busy) const LinearProgressIndicator(),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton(
              onPressed: _busy ? null : () => _save(false),
              child: const Text('Lưu nháp'),
            ),
            FilledButton(
              onPressed: _busy ? null : () => _save(true),
              child: const Text('Kiểm tra và xuất bản'),
            ),
          ],
        ),
      ],
    ),
  );
}
