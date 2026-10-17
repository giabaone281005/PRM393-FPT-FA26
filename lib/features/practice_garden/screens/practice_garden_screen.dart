import 'package:flutter/material.dart';

import '../../learning_engine/study_screen.dart';

class PracticeGardenScreen extends StatelessWidget {
  const PracticeGardenScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vườn luyện tập')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.park, size: 80, color: Colors.green),
            const Text('Làm đúng 5 câu để hồi đầy đủ tim. Luôn miễn phí.'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudyScreen(kind: 'practice'),
                ),
              ),
              child: const Text('Bắt đầu luyện tập'),
            ),
          ],
        ),
      ),
    ),
  );
}
