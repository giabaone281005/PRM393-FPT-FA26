import 'package:flutter/material.dart';

import '../../data/models/app_failure.dart';

/// Icon and readable text communicate status without relying on color alone.
class AppNotice extends StatelessWidget {
  const AppNotice({
    super.key,
    required this.message,
    this.kind = NoticeKind.info,
  });
  final String message;
  final NoticeKind kind;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kind == NoticeKind.success
              ? colors.primaryContainer
              : colors.surfaceContainerLowest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              switch (kind) {
                NoticeKind.success => Icons.check_circle_outline,
                NoticeKind.error => Icons.error_outline,
                NoticeKind.info => Icons.info_outline,
              },
              size: 20,
              semanticLabel: switch (kind) {
                NoticeKind.success => 'Thành công',
                NoticeKind.error => 'Chưa hoàn tất',
                NoticeKind.info => 'Thông tin',
              },
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(height: 1.5))),
          ],
        ),
      ),
    );
  }
}
