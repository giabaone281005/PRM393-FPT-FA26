import 'package:flutter/material.dart';

import '../../data/providers/learning_sync_controller.dart';
import '../../data/models/app_failure.dart';
import '../../learning_catalog.dart';
import '../shared/app_notice.dart';

class LearningSyncScope extends InheritedNotifier<LearningSyncController> {
  const LearningSyncScope({
    super.key,
    required LearningSyncController controller,
    required super.child,
  }) : super(notifier: controller);
  static LearningSyncController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LearningSyncScope>()?.notifier;
}

class LearningSyncStatus extends StatelessWidget {
  const LearningSyncStatus({super.key});
  @override
  Widget build(BuildContext context) {
    String interests(dynamic ids) {
      final values = ids is List ? ids : const [];
      final names = topics
          .where((topic) => values.contains(topic.id))
          .map((topic) => topic.title);
      return names.isEmpty ? 'Chưa chọn' : names.join(', ');
    }

    final sync = LearningSyncScope.maybeOf(context);
    if (sync == null || !sync.cloud.signedIn || sync.store.profile == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNotice(
          message: sync.busy
              ? 'Đang đồng bộ tiến độ học…'
              : sync.message ??
                    'Tiến độ được lưu trên máy và tự đồng bộ khi có mạng.',
          kind: sync.noticeKind,
        ),
        const SizedBox(height: 8),
        Text(
          '${sync.store.verifiedPoints} XP đã được máy chủ xác nhận',
          textAlign: TextAlign.center,
        ),
        TextButton.icon(
          onPressed: sync.busy ? null : sync.syncNow,
          icon: const Icon(Icons.sync),
          label: const Text('Đồng bộ tiến độ ngay'),
        ),
        if (sync.hasProfileConflict)
          OutlinedButton(
            onPressed: sync.busy
                ? null
                : () async {
                    try {
                      final remote = await sync.loadConflictProfile();
                      if (!context.mounted) return;
                      final useDevice = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Chọn thông tin hồ sơ'),
                          content: SingleChildScrollView(
                            child: Text(
                              'Trên máy: ${sync.store.profile?.name}\n${sync.store.profile?.dailyMinutes} phút/ngày\nQuan tâm: ${interests(sync.store.profile?.interests)}\n\nTrên cloud: ${remote['name']}\n${remote['daily_minutes']} phút/ngày\nQuan tâm: ${interests(remote['interest_topic_ids'])}\n\nLựa chọn này chỉ thay thông tin hồ sơ. Bài làm và bản nháp vẫn được giữ.',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Dùng bản cloud'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Dùng bản trên máy'),
                            ),
                          ],
                        ),
                      );
                      if (useDevice != null && context.mounted) {
                        await sync.resolveProfileConflict(
                          remote,
                          useDevice: useDevice,
                        );
                      }
                    } catch (failure) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              friendlyError(
                                failure,
                                fallback: 'Chưa xử lý được lựa chọn. Thông tin trên máy vẫn được giữ.',
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
            child: const Text('Xử lý thông tin hồ sơ khác nhau'),
          ),
      ],
    );
  }
}
