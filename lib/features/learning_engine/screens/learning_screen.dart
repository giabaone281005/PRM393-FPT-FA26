import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/lesson.dart';
import '../../../data/models/question.dart';
import '../../../data/providers/app_state_provider.dart';
import '../widgets/drag_counters_widget.dart';
import '../widgets/clock_rotation_widget.dart';
import '../widgets/multiplication_widget.dart';
import '../widgets/area_grid_widget.dart';
import '../widgets/word_problem_widget.dart';
import '../popups/socratic_owl_sheet.dart';
import '../popups/out_of_hearts_dialog.dart';
import '../../reward/reward_screen.dart';

class LearningScreen extends StatefulWidget {
  final Lesson lesson;

  const LearningScreen({super.key, required this.lesson});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _currentQuestionIndex = 0;
  int _consecutiveErrors = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final questions = widget.lesson.questions;
    final currentQ = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 10,
          ),
        ),
        actions: [
          // Hearts counter
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentRedLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: AppColors.heart, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${kid.currentHearts}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBE123C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prompt
              Text(currentQ.prompt, style: AppTypography.titleLarge),
              if (currentQ.subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(currentQ.subtitle, style: AppTypography.bodySmall),
              ],
              const SizedBox(height: 24),

              // Question Interactive Widget based on QuestionType
              _buildQuestionWidget(currentQ),

              const SizedBox(height: 20),

              // Socratic AI Help Trigger Button ("Hỏi bạn Cú")
              Center(
                child: TextButton.icon(
                  onPressed: () => _showSocraticHelp(currentQ),
                  icon: const Text('🦉', style: TextStyle(fontSize: 18)),
                  label: Text(
                    'Cần trợ giúp? Hỏi bạn Cú ngay',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(Question q) {
    switch (q.type) {
      case QuestionType.dragCounters:
        return DragCountersWidget(
          data: q.data,
          onAnswerSubmitted: _handleAnswer,
        );
      case QuestionType.clockRotation:
        return ClockRotationWidget(
          data: q.data,
          onAnswerSubmitted: _handleAnswer,
        );
      case QuestionType.multiplicationTable:
        return MultiplicationWidget(
          data: q.data,
          onAnswerSubmitted: _handleAnswer,
        );
      case QuestionType.areaGrid:
        return AreaGridWidget(
          data: q.data,
          onAnswerSubmitted: _handleAnswer,
        );
      case QuestionType.wordProblem:
        return WordProblemWidget(
          data: q.data,
          onAnswerSubmitted: _handleAnswer,
        );
    }
  }

  void _handleAnswer(bool isCorrect) {
    final state = context.read<AppStateProvider>();

    if (isCorrect) {
      _consecutiveErrors = 0;
      _showFeedbackDialog(true);
    } else {
      state.loseHeart();
      _consecutiveErrors++;

      if (state.currentKid.currentHearts <= 0) {
        _showOutOfHeartsDialog();
      } else if (_consecutiveErrors >= 2) {
        // Workflow 3: Tự động kích hoạt Socratic AI khi sai 2 lần liên tiếp
        _showSocraticHelp(widget.lesson.questions[_currentQuestionIndex]);
      } else {
        _showFeedbackDialog(false);
      }
    }
  }

  void _showFeedbackDialog(bool isCorrect) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? AppColors.accentGreen : AppColors.accentRed,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'CHÍNH XÁC! TUYỆT VỜI!' : 'CHƯA ĐÚNG RỒI BẠN ƠI',
                  style: AppTypography.titleLarge.copyWith(
                    color: isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCorrect ? AppColors.accentGreen : AppColors.accentRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (isCorrect) {
                  if (_currentQuestionIndex < widget.lesson.questions.length - 1) {
                    setState(() {
                      _currentQuestionIndex++;
                    });
                  } else {
                    // Hoàn thành bài học!
                    context.read<AppStateProvider>().completeLesson(
                          widget.lesson.id,
                          widget.lesson.starReward,
                          widget.lesson.xpReward,
                        );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RewardScreen(lesson: widget.lesson),
                      ),
                    );
                  }
                }
              },
              child: Text(isCorrect ? 'TIẾP TỤC' : 'THỬ LẠI'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSocraticHelp(Question q) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => SocraticOwlSheet(
        hints: q.socraticHints,
        onTryAgain: () {},
      ),
    );
  }

  void _showOutOfHeartsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OutOfHeartsDialog(),
    );
  }
}
