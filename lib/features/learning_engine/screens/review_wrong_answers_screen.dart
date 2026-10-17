import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/question.dart';
import '../../../data/models/wrong_answer_record.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/wrong_answer_repository.dart';

class ReviewWrongAnswersScreen extends StatefulWidget {
  final String? kidId;
  final String? lessonId;

  const ReviewWrongAnswersScreen({super.key, this.kidId, this.lessonId});

  @override
  State<ReviewWrongAnswersScreen> createState() =>
      _ReviewWrongAnswersScreenState();
}

class _ReviewWrongAnswersScreenState extends State<ReviewWrongAnswersScreen> {
  bool _loading = true;
  String? _error;
  List<WrongAnswerRecord> _records = [];
  String _filter = 'all'; // 'all', 'unresolved', 'resolved'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _resolveKidId() {
    if (widget.kidId != null && widget.kidId!.trim().isNotEmpty) {
      return widget.kidId!.trim();
    }
    try {
      final state = context.read<AppStateProvider>();
      if (state.hasKids) {
        return state.currentKid.id;
      }
    } catch (_) {
      // Handled if provider is not in widget hierarchy
    }
    return '';
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final kidId = _resolveKidId();
      if (kidId.isEmpty) {
        if (mounted) {
          setState(() {
            _records = [];
            _loading = false;
          });
        }
        return;
      }

      final list = await WrongAnswerRepository.getWrongAnswers(
        kidId,
        lessonId: widget.lessonId,
      );

      if (mounted) {
        setState(() {
          _records = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể tải danh sách câu trả lời sai. Vui lòng thử lại.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleResolved(WrongAnswerRecord record) async {
    final kidId = _resolveKidId();
    if (kidId.isEmpty) return;

    try {
      if (record.isResolved) {
        await WrongAnswerRepository.recordReviewAttempt(
          kidId,
          record.questionId,
          isCorrect: false,
        );
      } else {
        await WrongAnswerRepository.recordReviewAttempt(
          kidId,
          record.questionId,
          isCorrect: true,
        );
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              record.isResolved
                  ? 'Đã chuyển sang trạng thái cần ôn tập.'
                  : 'Đã hoàn thành ôn tập câu hỏi này!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái. Vui lòng thử lại.'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _markAllResolved() async {
    final kidId = _resolveKidId();
    if (kidId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đánh dấu tất cả'),
        content: const Text(
          'Đánh dấu tất cả các câu hỏi này là đã ôn tập xong?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await WrongAnswerRepository.markAllResolved(
          kidId,
          lessonId: widget.lessonId,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã đánh dấu tất cả câu hỏi là đã ôn tập.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể cập nhật. Vui lòng thử lại.'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteRecord(String questionId) async {
    final kidId = _resolveKidId();
    if (kidId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa câu sai'),
        content: const Text(
          'Em có chắc muốn xóa câu này khỏi danh sách ôn tập không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await WrongAnswerRepository.deleteWrongAnswer(kidId, questionId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa câu hỏi khỏi danh sách ôn tập.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể xóa câu hỏi. Vui lòng thử lại.'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearResolved() async {
    final kidId = _resolveKidId();
    if (kidId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dọn dẹp danh sách'),
        content: const Text(
          'Xóa tất cả các câu hỏi đã được đánh dấu là ôn tập xong?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await WrongAnswerRepository.clearResolved(
          kidId,
          lessonId: widget.lessonId,
        );
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã dọn dẹp các câu đã hoàn thành ôn tập.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể dọn dẹp danh sách. Vui lòng thử lại.'),
              backgroundColor: AppColors.accentRed,
            ),
          );
        }
      }
    }
  }

  String _formatUserAnswer(dynamic answer) {
    if (answer == null) return '(Chưa có)';
    if (answer is Map) {
      if (answer.containsKey('hour') && answer.containsKey('minute')) {
        final h = answer['hour'];
        final m = answer['minute'].toString().padLeft(2, '0');
        return '$h:$m';
      }
      return answer.entries.map((e) => '${e.key}: ${e.value}').join(', ');
    }
    if (answer is List) {
      return answer.join(', ');
    }
    return answer.toString();
  }

  String _typeLabel(QuestionType type) {
    return switch (type) {
      QuestionType.dragCounters => 'Kéo thả que tính',
      QuestionType.clockRotation => 'Xoay đồng hồ',
      QuestionType.multiplicationTable => 'Bảng nhân',
      QuestionType.areaGrid => 'Lưới diện tích',
      QuestionType.wordProblem => 'Toán có lời văn',
    };
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }

  List<WrongAnswerRecord> get _filteredRecords {
    if (_filter == 'unresolved') {
      return _records.where((r) => !r.isResolved).toList();
    }
    if (_filter == 'resolved') {
      return _records.where((r) => r.isResolved).toList();
    }
    return _records;
  }

  @override
  Widget build(BuildContext context) {
    final kidId = _resolveKidId();
    final unresolvedCount = _records.where((r) => !r.isResolved).length;
    final resolvedCount = _records.where((r) => r.isResolved).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Ôn tập câu trả lời sai'),
        actions: [
          if (unresolvedCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              tooltip: 'Đánh dấu tất cả đã ôn',
              onPressed: _markAllResolved,
            ),
          if (resolvedCount > 0)
            IconButton(
              icon: const Icon(Icons.cleaning_services_rounded),
              tooltip: 'Xóa câu đã ôn tập',
              onPressed: _clearResolved,
            ),
        ],
      ),
      body: SafeArea(child: _buildBody(kidId, unresolvedCount, resolvedCount)),
    );
  }

  Widget _buildBody(String kidId, int unresolvedCount, int resolvedCount) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải danh sách câu sai...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.accentRed,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.accentRed),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadData, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    if (kidId.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chưa chọn hồ sơ bé. Vui lòng chọn hồ sơ bé để xem danh sách câu sai.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_records.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 80),
            Icon(
              Icons.emoji_events_rounded,
              size: 80,
              color: AppColors.accentGold,
            ),
            SizedBox(height: 16),
            Text(
              'Không có câu sai nào!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bé làm bài rất tốt! Tất cả câu hỏi đều đã được trả lời chính xác hoặc đã hoàn thành ôn tập.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredRecords;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Tất cả (${_records.length})'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Chưa ôn tập ($unresolvedCount)'),
                  selected: _filter == 'unresolved',
                  onSelected: (_) => setState(() => _filter = 'unresolved'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Đã ôn tập ($resolvedCount)'),
                  selected: _filter == 'resolved',
                  onSelected: (_) => setState(() => _filter = 'resolved'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List of wrong answers
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _filter == 'unresolved'
                                ? Icons.task_alt_rounded
                                : Icons.history_toggle_off_rounded,
                            size: 48,
                            color: _filter == 'unresolved'
                                ? AppColors.accentGreen
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'unresolved'
                                ? 'Em đã ôn tập xong tất cả các câu sai!'
                                : 'Chưa có câu nào được đánh dấu đã ôn tập.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildWrongAnswerCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongAnswerCard(WrongAnswerRecord record) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.isResolved
              ? AppColors.accentGreen.withAlpha(90)
              : AppColors.borderSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Type badge & Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _typeLabel(record.questionType),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(record.timestamp),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: record.isResolved
                        ? AppColors.accentGreenLight
                        : AppColors.accentRedLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        record.isResolved
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 13,
                        color: record.isResolved
                            ? AppColors.accentGreen
                            : AppColors.accentRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.isResolved ? 'Đã ôn tập' : 'Cần ôn tập',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: record.isResolved
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Prompt
            Text(
              record.prompt.isEmpty
                  ? '(Không có nội dung đề bài)'
                  : record.prompt,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),

            // User Answer Box (No fake correct answer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentRedLight.withAlpha(120),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentRed.withAlpha(70)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Câu trả lời của em:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatUserAnswer(record.userAnswer),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentRed,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action row
            Row(
              children: [
                if (record.reviewCount > 0)
                  Text(
                    'Đã ôn: ${record.reviewCount} lần',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _toggleResolved(record),
                  icon: Icon(
                    record.isResolved
                        ? Icons.restart_alt_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(
                    record.isResolved ? 'Đánh dấu cần ôn' : 'Đánh dấu đã ôn',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'Xóa câu này',
                  onPressed: () => _deleteRecord(record.questionId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
