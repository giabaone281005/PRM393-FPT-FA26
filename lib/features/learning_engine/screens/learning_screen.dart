import 'package:flutter/material.dart';

import '../../../data/models/lesson.dart';
import '../study_screen.dart';

class LearningScreen extends StatelessWidget {
  final Lesson lesson;
  const LearningScreen({super.key, required this.lesson});
  @override
  Widget build(BuildContext context) =>
      StudyScreen(lessonId: lesson.id, kind: 'lesson');
}
