import 'package:flutter/material.dart';

import '../../learning_engine/screens/learning_progress_screen.dart';
import '../../learning_engine/screens/review_wrong_answers_screen.dart';
import '../../learning_engine/study_screen.dart';
import 'math_flappy_game_screen.dart';

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
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MathFlappyGameScreen()),
              ),
              icon: const Icon(Icons.flight_takeoff_rounded),
              label: const Text('Chơi Math Flappy'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StudyScreen(kind: 'practice'),
                ),
              ),
              child: const Text('Luyện tập câu hỏi'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.history_edu_rounded),
              label: const Text('Xem lại câu trả lời sai'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReviewWrongAnswersScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Tiến độ học tập'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LearningProgressScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
