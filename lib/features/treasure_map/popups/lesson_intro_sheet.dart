import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../learning_engine/screens/learning_screen.dart';
import '../../parent_portal/popups/parent_gate_dialog.dart';

class LessonIntroSheet extends StatelessWidget {
  final Lesson lesson;
  const LessonIntroSheet({super.key, required this.lesson});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final paid = lesson.requiresPlus && !state.isPlusActive;
    final locked = lesson.status == LessonStatus.locked;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  showDialog(
                    context: nav.context,
                    builder: (_) => const ParentGateDialog(),
                  );
                },
                child: const Text('Nhờ phụ huynh mở bài học'),
              ),
            ] else if (locked)
              const Text(
                'Hãy hoàn thành các bài trước trong chủ đề để mở bài này.',
              )
            else
              FilledButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.push(
                    MaterialPageRoute(
                      builder: (_) => LearningScreen(lesson: lesson),
                    ),
                  );
                },
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
    );
  }
}
