import 'package:flutter/material.dart';

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/learning_history.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/learning_history_repository.dart';
import '../../../data/repositories/account_live_sync.dart';
import '../../shared/widgets/role_ui.dart';
import '../study_screen.dart';

class LearningHistoryScreen extends StatefulWidget {
  const LearningHistoryScreen({
    super.key,
    required this.kidId,
    this.repository,
    this.studyBuilder,
  });
  final String kidId;
  final LearningHistoryRepository? repository;
  final Widget Function(LearningHistoryEntry, bool resume)? studyBuilder;
  @override
  State<LearningHistoryScreen> createState() => _LearningHistoryScreenState();
}

class _LearningHistoryScreenState extends State<LearningHistoryScreen> {
  late final _repository = widget.repository ?? LearningHistoryRepository();
  List<LearningHistoryEntry> _entries = [];
  bool _loading = true;
  String? _error, _kind, _status;
  int _page = 0, _request = 0;
  StreamSubscription<Set<String>>? _live;
  @override
  void initState() {
    super.initState();
    _load();
    _live = AccountLiveSync.watch({'study_sessions'}, () {
      if (!_loading && mounted) _load();
    });
  }

  @override
  void dispose() {
    _live?.cancel();
    _request++;
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repository.fetch(
        widget.kidId,
        kind: _kind,
        status: _status,
        page: _page,
      );
      if (mounted && request == _request) setState(() => _entries = rows);
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _error = 'Chưa tải được lịch sử học. Hãy thử lại.');
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(LearningHistoryEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningSessionReviewScreen(
          entry: entry,
          repository: _repository,
          studyBuilder: widget.studyBuilder,
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) => RoleScaffold(
    appBar: RoleAppBar(
      title: const Text('Lịch sử học tập'),
      actions: [
        IconButton(
          tooltip: 'Tải lại lịch sử',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const RoleIntroCard(
            icon: Icons.history_edu_rounded,
            title: 'Hành trình của em',
            description: 'Xem lại từng lần làm bài hoặc tiếp tục đúng phiên đang học. Kết quả do máy chủ xác nhận.',
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                value: _kind ?? '',
                hint: const Text('Hoạt động'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả hoạt động')),
                  DropdownMenuItem(value: 'lesson', child: Text('Bài học')),
                  DropdownMenuItem(value: 'practice', child: Text('Luyện tập')),
                  DropdownMenuItem(value: 'arena', child: Text('Đấu trường')),
                ],
                onChanged: _loading
                    ? null
                    : (v) {
                        _kind = v == '' ? null : v;
                        _page = 0;
                        _load();
                      },
              ),
              DropdownButton<String>(
                isExpanded: true,
                value: _status ?? '',
                hint: const Text('Trạng thái'),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Mọi trạng thái')),
                  DropdownMenuItem(
                    value: 'unfinished',
                    child: Text('Đang học'),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Text('Hoàn thành'),
                  ),
                ],
                onChanged: _loading
                    ? null
                    : (v) {
                        _status = v == '' ? null : v;
                        _page = 0;
                        _load();
                      },
              ),
            ],
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!, semanticsLabel: _error),
            TextButton(
              onPressed: _loading ? null : _load,
              child: const Text('Thử lại'),
            ),
          ] else if (!_loading && _entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa có phiên học phù hợp. Hãy bắt đầu một bài học nhé.',
              ),
            ),
          if (!_loading && _error == null)
            for (final entry in _entries)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    entry.completed
                        ? Icons.task_alt_rounded
                        : Icons.play_circle_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(entry.title),
                  subtitle: Text(
                    '${entry.kindLabel} · ${entry.statusLabel}\n'
                    '${DateFormat('dd/MM/yyyy HH:mm').format(entry.updatedAt.toLocal())}\n'
                    '${entry.questionIndex}/${entry.questionCount} câu · ${entry.durationSeconds ~/ 60} phút ${entry.durationSeconds % 60} giây'
                    '${entry.completed ? '\n${entry.accuracy ?? 0}% · +${entry.xp} XP · +${entry.stars} sao' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(entry),
                ),
              ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Trang trước',
                onPressed: _loading || _page == 0
                    ? null
                    : () {
                        _page--;
                        _load();
                      },
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Trang ${_page + 1}'),
              IconButton(
                tooltip: 'Trang sau',
                onPressed: _loading || _entries.length < 20
                    ? null
                    : () {
                        _page++;
                        _load();
                      },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class LearningSessionReviewScreen extends StatefulWidget {
  const LearningSessionReviewScreen({
    super.key,
    required this.entry,
    required this.repository,
    this.studyBuilder,
  });
  final LearningHistoryEntry entry;
  final LearningHistoryRepository repository;
  final Widget Function(LearningHistoryEntry, bool resume)? studyBuilder;
  @override
  State<LearningSessionReviewScreen> createState() =>
      _LearningSessionReviewScreenState();
}

class _LearningSessionReviewScreenState
    extends State<LearningSessionReviewScreen> {
  List<LearningAttempt> _attempts = [];
  bool _loading = true, _onlyWrong = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.repository.review(widget.entry.id);
      if (mounted) setState(() => _attempts = rows);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa xem được phiên học. Kiểm tra kết nối và quyền truy cập bài học.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _study() async {
    final e = widget.entry;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            widget.studyBuilder?.call(e, e.canResume) ??
            StudyScreen(
              sessionId: e.canResume ? e.id : null,
              lessonId: e.lessonId,
              kind: e.kind,
            ),
      ),
    );
    if (!mounted) return;
    final state = context.read<AppStateProvider?>();
    if (state != null) await state.refreshFromCloud();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final shown = _attempts.where((a) => !_onlyWrong || !a.correct).toList();
    return RoleScaffold(
      appBar: RoleAppBar(title: const Text('Xem lại phiên học')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoleIntroCard(
            icon: Icons.menu_book_rounded,
            title: entry.title,
            description:
                '${entry.kindLabel} · ${entry.statusLabel}\n'
                '${entry.correctCount}/${entry.attemptCount} lần trả lời đúng · ${entry.questionIndex}/${entry.questionCount} câu hoàn thành',
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
          if (!_loading && _error == null) ...[
            if (entry.canResume || entry.completed)
              FilledButton.icon(
                onPressed: _study,
                icon: Icon(entry.canResume ? Icons.play_arrow : Icons.replay),
                label: Text(
                  entry.canResume ? 'Tiếp tục phiên học' : 'Luyện lại',
                ),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Chỉ xem câu trả lời sai'),
              value: _onlyWrong,
              onChanged: (v) => setState(() => _onlyWrong = v),
            ),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Chưa có câu trả lời trong bộ lọc này.'),
              ),
            for (var i = 0; i < shown.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            shown[i].correct
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: shown[i].correct
                                ? AppColors.accentGreen
                                : AppColors.accentRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lần ${_attempts.indexOf(shown[i]) + 1} · ${shown[i].correct ? 'Đúng' : 'Chưa đúng'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        shown[i].prompt,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Em đã trả lời: ${shown[i].answer}'),
                      Text('Đã dùng ${shown[i].hintsUsed} gợi ý'),
                      if (shown[i].hints.isNotEmpty)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Cách suy nghĩ'),
                          children: [
                            for (final hint in shown[i].hints)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(hint),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
