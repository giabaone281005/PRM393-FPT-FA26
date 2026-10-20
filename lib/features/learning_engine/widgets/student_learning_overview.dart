import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/learning_history.dart';
import '../../../data/models/learning_overview.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/learning_history_repository.dart';
import '../screens/learning_history_screen.dart';
import '../screens/topic_learning_screen.dart';

class CurrentLearningOverview extends StatelessWidget {
  const CurrentLearningOverview({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kidId = state.currentKid.id;
    final reports = (state.familyReport['kids'] as List? ?? []).where(
      (r) => r['id'] == kidId,
    );
    return StudentLearningOverview(
      kidId: kidId,
      lessons: state.currentLessons,
      days: reports.isEmpty ? const [] : reports.first['days'] as List? ?? [],
      syncedAt: state.familyReportSyncedAt,
      loading: state.isLoadingFromCloud,
      error: state.syncError,
      revision: state.statsRevision,
      onRefresh: state.refreshFromCloud,
    );
  }
}

class StudentLearningOverview extends StatefulWidget {
  const StudentLearningOverview({
    super.key,
    required this.kidId,
    required this.lessons,
    required this.days,
    required this.onRefresh,
    this.syncedAt,
    this.loading = false,
    this.error,
    this.revision = 0,
    this.historyRepository,
  });
  final String kidId;
  final List<Lesson> lessons;
  final List days;
  final Future<void> Function() onRefresh;
  final DateTime? syncedAt;
  final bool loading;
  final String? error;
  final int revision;
  final LearningHistoryRepository? historyRepository;
  @override
  State<StudentLearningOverview> createState() =>
      _StudentLearningOverviewState();
}

class _StudentLearningOverviewState extends State<StudentLearningOverview> {
  late final _history = widget.historyRepository ?? LearningHistoryRepository();
  List<LearningHistoryEntry> _recent = [];
  bool _loadingHistory = true;
  String? _historyError;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant StudentLearningOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kidId != widget.kidId ||
        oldWidget.revision != widget.revision) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final request = ++_request;
    setState(() {
      _loadingHistory = true;
      _historyError = null;
      _recent = [];
    });
    try {
      final entries = await _history.fetch(widget.kidId);
      if (mounted && request == _request) {
        setState(() => _recent = entries.take(3).toList());
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() => _historyError = 'Chưa tải được hoạt động gần đây.');
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _loadingHistory = false);
      }
    }
  }

  Future<void> _refresh() async {
    await widget.onRefresh();
    if (mounted) await _loadHistory();
  }

  Future<void> _review(LearningHistoryEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LearningSessionReviewScreen(entry: entry, repository: _history),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final topics = TopicProgress.group(widget.lessons);
    final completed = topics.fold<int>(
      0,
      (sum, topic) => sum + topic.completed,
    );
    final days = LearningDay.week(widget.days);
    final totalSeconds = days.fold<int>(0, (sum, day) => sum + day.seconds);
    final maxSeconds = days.fold<int>(
      1,
      (max, day) => day.seconds > max ? day.seconds : max,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Tiến độ của em',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              tooltip: 'Cập nhật tiến độ',
              onPressed: widget.loading || _loadingHistory ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (widget.loading) const LinearProgressIndicator(),
        if (widget.error != null)
          Text(
            widget.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (widget.syncedAt != null)
          Text(
            'Cập nhật ${DateFormat('dd/MM HH:mm').format(widget.syncedAt!.toLocal())}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '$completed/${widget.lessons.length} bài đã hoàn thành',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: widget.lessons.isEmpty
                      ? 0
                      : completed / widget.lessons.length,
                  minHeight: 8,
                ),
                const SizedBox(height: 12),
                Text(
                  '7 ngày qua: ${totalSeconds ~/ 60} phút ${totalSeconds % 60} giây đã ghi nhận',
                ),
                if (totalSeconds == 0)
                  const Text('Chưa có thời lượng học trong 7 ngày qua.'),
                const SizedBox(height: 12),
                // Wrapping bars retain dated evidence and touch targets at large text.
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    for (final day in days)
                      Tooltip(
                        message:
                            '${DateFormat('dd/MM').format(day.date)}: ${day.duration}',
                        child: Semantics(
                          label:
                              '${DateFormat('dd/MM').format(day.date)}: ${day.duration}',
                          child: SizedBox(
                            width: 64,
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 55,
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: 20,
                                      height: day.seconds == 0
                                          ? 3
                                          : 8 + 47 * day.seconds / maxSeconds,
                                      decoration: BoxDecoration(
                                        color: day.seconds == 0
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .outlineVariant
                                            : AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM').format(day.date),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  day.seconds == 0
                                      ? '0'
                                      : day.seconds < 60
                                      ? '<1 phút'
                                      : '${day.seconds ~/ 60} phút',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Chủ đề đang học', style: Theme.of(context).textTheme.titleMedium),
        if (topics.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chưa có chủ đề khả dụng. Hãy tải lại tiến độ.'),
          ),
        for (final topic in topics)
          Card(
            child: ListTile(
              title: Text(topic.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${topic.completed}/${topic.lessons.length} bài · ${(topic.fraction * 100).round()}% hoàn thành',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: topic.fraction),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TopicLearningScreen(
                      topicId: topic.id,
                      title: topic.title,
                    ),
                  ),
                );
                if (mounted) await _refresh();
              },
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Hoạt động gần đây',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (_loadingHistory) const LinearProgressIndicator(),
        if (_historyError != null) ...[
          Text(_historyError!),
          TextButton(
            onPressed: _loadHistory,
            child: const Text('Thử tải lại hoạt động'),
          ),
        ],
        if (!_loadingHistory && _historyError == null && _recent.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Chưa có phiên học. Chọn một chủ đề để bắt đầu nhé.'),
          ),
        for (final entry in _recent)
          Card(
            child: ListTile(
              leading: Icon(
                entry.completed ? Icons.task_alt : Icons.play_circle_outline,
                color: AppColors.primary,
              ),
              title: Text(entry.title),
              subtitle: Text(
                '${entry.kindLabel} · ${entry.statusLabel} · ${entry.questionIndex}/${entry.questionCount} câu',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _review(entry),
            ),
          ),
        TextButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LearningHistoryScreen(
                  kidId: widget.kidId,
                  repository: _history,
                ),
              ),
            );
            if (mounted) await _refresh();
          },
          icon: const Icon(Icons.history),
          label: const Text('Xem toàn bộ lịch sử học'),
        ),
      ],
    );
  }
}
