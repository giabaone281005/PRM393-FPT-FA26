import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';

enum LessonIntroAction { startLesson, unlockForParent }

class LessonIntroSheet extends StatelessWidget {
  final Lesson lesson;
  const LessonIntroSheet({super.key, required this.lesson});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final paid = lesson.requiresPlus && !state.isPlusActive;
    final locked = lesson.status == LessonStatus.locked;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(lesson.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(lesson.subtitle),
              Text(
                'Khoảng ${lesson.estimatedMinutes} phút · ${lesson.xpReward} XP · ${lesson.starReward} sao khi hoàn thành lần đầu',
              ),
              const SizedBox(height: 16),
              if (paid) ...[
                const Text(
                  'Bài này cần phụ huynh mở quyền học. Thành tích đã có của em vẫn được giữ.',
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, LessonIntroAction.unlockForParent),
                  child: const Text('Nhờ phụ huynh mở bài học'),
                ),
              ] else if (locked)
                const Text(
                  'Hãy hoàn thành các bài trước trong chủ đề để mở bài này.',
                )
              else
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, LessonIntroAction.startLesson),
                  child: Text(
                    lesson.status == LessonStatus.completed
                        ? 'Ôn lại bài (không nhận thưởng lần hai)'
                        : 'Bắt đầu / học tiếp',
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Để sau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
