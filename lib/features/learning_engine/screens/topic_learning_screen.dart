import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/lesson.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../shared/widgets/role_ui.dart';
import '../lesson_navigation.dart';

class TopicLearningScreen extends StatelessWidget {
  const TopicLearningScreen({
    super.key,
    required this.topicId,
    required this.title,
  });
  final String topicId, title;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final lessons = state.currentLessons
        .where((l) => l.topicId == topicId)
        .toList();
    final completed = lessons
        .where((l) => l.status == LessonStatus.completed)
        .length;
    return RoleScaffold(
      appBar: RoleAppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: state.refreshFromCloud,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            RoleIntroCard(
              icon: Icons.route_rounded,
              title: title,
              description:
                  '$completed/${lessons.length} bài đã hoàn thành. Chọn bài để xem nội dung, học tiếp hoặc ôn lại.',
            ),
            if (state.isLoadingFromCloud) const LinearProgressIndicator(),
            if (state.syncError != null) Text(state.syncError!),
            if (lessons.isEmpty)
              const Text('Chưa có bài học trong chủ đề này.'),
            for (final lesson in lessons)
              Card(
                child: ListTile(
                  leading: Icon(
                    lesson.status == LessonStatus.completed
                        ? Icons.task_alt
                        : lesson.status == LessonStatus.locked
                        ? Icons.lock_outline
                        : Icons.play_circle_outline,
                  ),
                  title: Text('Bài ${lesson.lessonNumber}: ${lesson.title}'),
                  subtitle: Text(
                    '${lesson.estimatedMinutes} phút · ${lesson.requiresPlus ? 'Plus · ' : ''}'
                    '${lesson.status == LessonStatus.completed
                        ? 'Đã hoàn thành · ${lesson.starsEarned} sao'
                        : lesson.status == LessonStatus.locked
                        ? 'Cần hoàn thành bài trước'
                        : 'Sẵn sàng học / tiếp tục'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openLearningLesson(context, lesson),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
