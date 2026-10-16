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
import '../widgets/essay_problem_widget.dart';
import '../widgets/mini_game_widget.dart';
import '../widgets/socratic_owl_sheet.dart';
import '../popups/out_of_hearts_dialog.dart';
import '../../reward/reward_screen.dart';

enum LearningMode { theory, quiz, essay, miniGame }

class LearningScreen extends StatefulWidget {
  final Lesson lesson;

  const LearningScreen({super.key, required this.lesson});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  int _currentQuestionIndex = 0;
  LearningMode _activeMode = LearningMode.theory; // Mặc định mở Lý Thuyết SGK trước
  bool _miniGameWon = false;
  bool _essayDone = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final totalQ = widget.lesson.questions.length;
    final progress = totalQ > 0 ? (_currentQuestionIndex + 1) / totalQ : 1.0;
    final currentQ = widget.lesson.questions.isNotEmpty
        ? widget.lesson.questions[_currentQuestionIndex]
        : Question(
            id: 'fallback',
            type: QuestionType.wordProblem,
            prompt: widget.lesson.title,
            subtitle: widget.lesson.subtitle,
            data: {'options': ['A', 'B', 'C', 'D'], 'correctAnswer': 'A'},
            correctAnswer: 'A',
            socraticHints: [],
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _activeMode == LearningMode.theory ? 0.25 : progress,
            backgroundColor: AppColors.surfaceSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 10,
          ),
        ),
        actions: [
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh 4 Tab Đầy Đủ: Lý Thuyết - Trắc Nghiệm - Tự Luận - Mini Game
              _buildModernTabBar(),
              const SizedBox(height: 18),

              if (_activeMode == LearningMode.theory) ...[
                _buildTheoryView(),
              ] else if (_activeMode == LearningMode.quiz) ...[
                _buildQuizView(totalQ, currentQ),
              ] else if (_activeMode == LearningMode.essay) ...[
                _buildEssayView(),
              ] else ...[
                _buildMiniGameView(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 4 Tabs phân khúc học tập đầy đủ
  Widget _buildModernTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTabButton(LearningMode.theory, Icons.menu_book_rounded, '1. Lý Thuyết SGK'),
          const SizedBox(width: 8),
          _buildTabButton(LearningMode.quiz, Icons.quiz_rounded, '2. Trắc Nghiệm'),
          const SizedBox(width: 8),
          _buildTabButton(LearningMode.essay, Icons.edit_note_rounded, '3. Tự Luận'),
          const SizedBox(width: 8),
          _buildTabButton(LearningMode.miniGame, Icons.sports_esports_rounded, '4. Mini Game 🎮'),
        ],
      ),
    );
  }

  Widget _buildTabButton(LearningMode mode, IconData icon, String label) {
    final isSel = _activeMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _activeMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSel ? AppColors.primary : const Color(0xFFE2E8F0)),
          boxShadow: isSel
              ? [BoxShadow(color: AppColors.primary.withAlpha(50), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSel ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: isSel ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 1: Lý Thuyết SGK dẫn dắt chi tiết
  Widget _buildTheoryView() {
    final theoryContent = widget.lesson.theory ?? 'Đang cập nhật nội dung lý thuyết cho bài học...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/owl_mascot.jpg',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Text('🦉', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bác Cú Giảng Bài Theo SGK',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          widget.lesson.title,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFEA580C), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              Text(
                theoryContent,
                style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          onPressed: () {
            setState(() {
              _activeMode = LearningMode.quiz;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('ĐÃ HIỂU LÝ THUYẾT ➔ SANG PHẦN TRẮC NGHIỆM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  /// Tab 2: Luyện Tập Trắc Nghiệm
  Widget _buildQuizView(int totalQ, Question currentQ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CÂU TRẮC NGHIỆM ${_currentQuestionIndex + 1}/$totalQ',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.lesson.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(currentQ.prompt, style: AppTypography.titleLarge),
        if (currentQ.subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(currentQ.subtitle, style: AppTypography.bodySmall),
        ],
        const SizedBox(height: 20),

        // Interactive Quiz Widget
        _buildQuestionWidget(currentQ),

        const SizedBox(height: 20),

        // Socratic Help
        Center(
          child: TextButton.icon(
            onPressed: () => _showSocraticHelp(currentQ),
            icon: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/owl_mascot.jpg',
                width: 22,
                height: 22,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Text('🦉', style: TextStyle(fontSize: 18)),
              ),
            ),
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
    );
  }

  /// Tab 3: Tự Luận
  Widget _buildEssayView() {
    return Column(
      children: [
        EssayProblemWidget(
          prompt: widget.lesson.essayPrompt ?? 'Trình bày lời giải bài toán theo đúng các bước học.',
          guidance: widget.lesson.essayGuidance,
          onSubmit: (done) {
            setState(() {
              _essayDone = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tuyệt vời! Bạn đã hoàn thành phần tự luận. Chuyển sang Mini Game nhé! 🌟'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) setState(() => _activeMode = LearningMode.miniGame);
            });
          },
        ),
      ],
    );
  }

  /// Tab 4: Mini Game
  Widget _buildMiniGameView() {
    return Column(
      children: [
        MiniGameWidget(
          title: widget.lesson.title,
          miniGameType: widget.lesson.miniGameType ?? 'number',
          onGameFinished: (won) {
            if (won) {
              setState(() {
                _miniGameWon = true;
              });
              // Cộng điểm thưởng
              context.read<AppStateProvider>().completeLesson(
                    widget.lesson.id,
                    widget.lesson.starReward,
                    widget.lesson.xpReward + 20,
                  );
            }
          },
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RewardScreen(lesson: widget.lesson),
              ),
            );
          },
          child: const Text('HOÀN THÀNH TOÀN BỘ BÀI HỌC ➔ NHẬN THƯỞNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildQuestionWidget(Question q) {
    switch (q.type) {
      case QuestionType.dragCounters:
        return DragCountersWidget(data: q.data, onAnswerSubmitted: _handleAnswer);
      case QuestionType.clockRotation:
        return ClockRotationWidget(data: q.data, onAnswerSubmitted: _handleAnswer);
      case QuestionType.multiplicationTable:
        return MultiplicationWidget(data: q.data, onAnswerSubmitted: _handleAnswer);
      case QuestionType.areaGrid:
        return AreaGridWidget(data: q.data, onAnswerSubmitted: _handleAnswer);
      case QuestionType.wordProblem:
        return WordProblemWidget(data: q.data, onAnswerSubmitted: _handleAnswer);
    }
  }

  void _handleAnswer(bool isCorrect) {
    final state = context.read<AppStateProvider>();

    if (isCorrect) {
      _showFeedbackDialog(true);
    } else {
      state.loseHeart();
      if (state.currentKid.currentHearts <= 0) {
        _showOutOfHeartsDialog();
      } else {
        _showFeedbackDialog(false);
      }
    }
  }

  void _showFeedbackDialog(bool isCorrect) {
    final isLastQuestion = _currentQuestionIndex >= widget.lesson.questions.length - 1;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        color: isCorrect ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? AppColors.accentGreen : AppColors.accentRed,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCorrect ? 'CHÍNH XÁC! TUYỆT VỜI! 🎉' : 'CHƯA ĐÚNG RỒI BẠN ƠI! 💡',
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isCorrect ? const Color(0xFF166534) : const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCorrect
                            ? (isLastQuestion
                                ? 'Bạn đã xuất sắc hoàn thành trọn vẹn 10 câu trắc nghiệm!'
                                : 'Bạn đã chọn đúng đáp án rồi đó, tiếp tục câu tiếp theo nhé!')
                            : 'Đừng nản lòng! Bé bị trừ 1 Tim ❤️. Hãy quan sát kỹ gợi ý và thử lại nhé!',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCorrect ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ],
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
                elevation: 3,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (isCorrect) {
                  if (!isLastQuestion) {
                    setState(() {
                      _currentQuestionIndex++;
                    });
                  } else {
                    // Đã xong cả 10 câu trắc nghiệm -> Tự động chuyển qua phần Tự Luận
                    setState(() {
                      _activeMode = LearningMode.essay;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Hoàn thành xuất sắc 10 câu trắc nghiệm! Chuyển sang phần Tự Luận!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                }
              },
              child: Text(
                isCorrect
                    ? (isLastQuestion ? 'HOÀN THÀNH ➔ SANG BÀI TỰ LUẬN' : 'TIẾP TỤC CÂU KẾ TIẾP ➔')
                    : 'THỬ LẠI CÂU NÀY',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
              ),
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
