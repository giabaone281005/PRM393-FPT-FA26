import 'app_layout.dart';

import 'package:flutter/material.dart';

import 'app_motion.dart';
import 'app_theme.dart';
import 'learning_catalog.dart';
import 'learning_guidance.dart';
import 'learning_store.dart';

typedef OpenLearningTopic = void Function(BuildContext, LearningTopic);

class DiscoveryPath {
  const DiscoveryPath(this.title, this.subtitle, this.icon, this.topicIds);
  final String title, subtitle;
  final IconData icon;
  final List<String> topicIds;
}

const discoveryPaths = [
  DiscoveryPath(
    'Tư duy bằng hình',
    'Từ những phần bằng nhau đến quy luật và hình học.',
    Icons.gesture,
    ['math', 'logic', 'geometry', 'algebra'],
  ),
  DiscoveryPath(
    'Đọc dữ liệu, viết ý tưởng',
    'Quan sát dữ liệu, thử xác suất rồi xây thuật toán.',
    Icons.route_outlined,
    ['data', 'probability', 'coding', 'optimization'],
  ),
  DiscoveryPath(
    'Khám phá thế giới vật lý',
    'Thử chuyển động, khám phá mạch điện và xoay quả địa cầu.',
    Icons.bolt_outlined,
    ['science', 'circuits', 'geography'],
  ),
  DiscoveryPath(
    'Nghệ thuật & tư duy xã hội',
    'Quan sát tranh, đọc học thuyết và luyện giải thích bằng bằng chứng.',
    Icons.menu_book_outlined,
    ['painting', 'marxism'],
  ),
];

/// Curated routes through existing experiments, not new course content.
class LearningPathsPage extends StatelessWidget {
  const LearningPathsPage({
    super.key,
    required this.store,
    required this.onOpen,
  });
  final LearningStore store;
  final OpenLearningTopic onOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageHeader(title: Text('Lộ trình khám phá')),
    body: ListenableBuilder(
      listenable: store,
      builder: (context, _) => AppPageBody(
        children: [
          Text(
            'Một ý tưởng dẫn\nđến một ý tưởng mới.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Theo thứ tự gợi ý hoặc chạm vào bất kỳ chủ đề nào bạn tò mò. Từ khám phá đến vận dụng và thử thách.',
            style: TextStyle(
              color: BrilliantPalette.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          for (final path in discoveryPaths) ...[
            _path(context, path),
            const SizedBox(height: 18),
          ],
        ],
      ),
    ),
  );

  Widget _path(BuildContext context, DiscoveryPath path) {
    final completed = path.topicIds.where(store.completed.contains).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: paper,
        border: Border.all(color: BrilliantPalette.track),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(path.icon, size: 30),
          const SizedBox(height: 12),
          Text(path.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(path.subtitle, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          Text(
            '$completed/${path.topicIds.length} chủ đề đã khám phá',
            style: const TextStyle(
              fontSize: 12,
              color: BrilliantPalette.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: completed / path.topicIds.length),
              duration: AppMotion.duration(context),
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: green,
                backgroundColor: BrilliantPalette.track,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < path.topicIds.length; i++)
            _stop(context, path.topicIds[i], i + 1),
        ],
      ),
    );
  }

  Widget _stop(BuildContext context, String id, int index) {
    final topic = topicById(id);
    final done = store.completed.contains(id);
    final started = store.progress(id) != null;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: done
            ? BrilliantPalette.successSurface
            : BrilliantPalette.surface,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          key: ValueKey('path-topic-$id'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: paper,
            foregroundColor: ink,
            child: done ? const Icon(Icons.check, size: 20) : Text('$index'),
          ),
          title: Text(
            topic.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          subtitle: Text(
            started
                ? 'Tiếp tục phiên đang học'
                : done
                ? 'Đã khám phá • chạm để ôn lại'
                : '${topic.experiments.length} thí nghiệm • sẵn sàng khám phá',
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => onOpen(context, topic),
        ),
      ),
    );
  }
}

class PathsInvitation extends StatelessWidget {
  const PathsInvitation({super.key, required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: BrilliantPalette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: BrilliantPalette.track),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.route_outlined, size: 26),
        const SizedBox(height: 10),
        Text(
          'Tìm đường cho sự tò mò',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          '3 lộ trình kết nối 10 chủ đề. Luôn có thể chọn cách đi riêng.',
          style: TextStyle(height: 1.5),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          key: const ValueKey('open-learning-paths'),
          onPressed: onPressed,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Xem lộ trình'),
        ),
      ],
    ),
  );
}

class PracticeInsights extends StatelessWidget {
  const PracticeInsights({
    super.key,
    required this.store,
    required this.onOpen,
  });
  final LearningStore store;
  final OpenLearningTopic onOpen;
  @override
  Widget build(BuildContext context) {
    final practiced = topics
        .where((t) => store.completed.contains(t.id))
        .toList();
    practiced.sort((a, b) {
      final aa = topicActivity(store, a.id), bb = topicActivity(store, b.id);
      return (bb.needsReview ? 1 : 0).compareTo(aa.needsReview ? 1 : 0);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Những ý tưởng nên gặp lại',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ôn bằng thao tác, theo nhịp của bạn. Không cộng lại XP cho chủ đề đã hoàn thành.',
          style: TextStyle(color: BrilliantPalette.secondaryText, height: 1.5),
        ),
        if (practiced.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'Sau khám phá đầu tiên, bạn sẽ thấy gợi ý thực hành tại đây.',
            ),
          ),
        for (final topic in practiced) ...[
          const SizedBox(height: 10),
          _practice(context, topic),
        ],
      ],
    );
  }

  Widget _practice(BuildContext context, LearningTopic topic) {
    final activity = topicActivity(store, topic.id);
    return Material(
      color: activity.needsReview
          ? BrilliantPalette.successSurface
          : BrilliantPalette.surface,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        key: ValueKey('review-${topic.id}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(topic.icon),
        title: Text(
          topic.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${activity.practiceCount} phiên đã hoàn thành • ${activity.needsReview ? 'Gợi ý ôn lại' : 'Có thể thực hành lại'}',
        ),
        trailing: const Icon(Icons.replay, size: 20),
        onTap: () => onOpen(context, topic),
      ),
    );
  }
}
