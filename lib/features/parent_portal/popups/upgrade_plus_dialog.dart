import 'package:flutter/material.dart';

import '../../../data/providers/app_state_provider.dart';
import '../../subscriptions/learning_packages_screen.dart';

class UpgradePlusDialog extends StatelessWidget {
  final AppStateProvider state;
  const UpgradePlusDialog({super.key, required this.state});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Gói học tập cho gia đình'),
    content: const Text(
      'Plus hỗ trợ tối đa 3 bé. Xem giá, thời hạn và lịch sử mua tại Gói học tập. Vườn luyện tập hồi tim vẫn miễn phí.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Để sau'),
      ),
      FilledButton(
        onPressed: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.push(
            MaterialPageRoute(builder: (_) => const LearningPackagesScreen()),
          );
        },
        child: const Text('Xem gói'),
      ),
    ],
  );
}
