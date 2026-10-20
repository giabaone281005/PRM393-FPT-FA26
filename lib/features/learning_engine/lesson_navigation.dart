import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/lesson.dart';
import '../../data/providers/app_state_provider.dart';
import '../parent_portal/popups/parent_gate_dialog.dart';
import '../treasure_map/popups/lesson_intro_sheet.dart';
import 'screens/learning_screen.dart';

Future<void> openLearningLesson(BuildContext context, Lesson lesson) async {
  final state = context.read<AppStateProvider>();
  final kidId = state.currentKid.id;
  final action = await showModalBottomSheet<LessonIntroAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LessonIntroSheet(lesson: lesson),
  );
  if (!context.mounted || !state.hasKids || state.currentKid.id != kidId) {
    return;
  }
  switch (action) {
    case LessonIntroAction.startLesson:
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LearningScreen(lesson: lesson)),
      );
      if (context.mounted) await state.refreshFromCloud();
    case LessonIntroAction.unlockForParent:
      await showDialog(
        context: context,
        builder: (_) => const ParentGateDialog(),
      );
    case null:
      break;
  }
}
