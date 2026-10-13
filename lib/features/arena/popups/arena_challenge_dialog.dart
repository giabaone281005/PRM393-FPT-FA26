import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';

class ArenaChallengeDialog extends StatefulWidget {
  final AppStateProvider state;
  final VoidCallback onScoreSubmitted;

  const ArenaChallengeDialog({
    super.key,
    required this.state,
    required this.onScoreSubmitted,
  });

  @override
  State<ArenaChallengeDialog> createState() => _ArenaChallengeDialogState();
}

class _ArenaChallengeDialogState extends State<ArenaChallengeDialog> {
  final List<Map<String, dynamic>> _questions = [
    {'q': '7 × 8 = ?', 'options': [54, 56, 58], 'ans': 56},
    {'q': '64 ÷ 8 = ?', 'options': [7, 8, 9], 'ans': 8},
    {'q': '150 + 250 = ?', 'options': [380, 400, 420], 'ans': 400},
  ];

  int _currentIndex = 0;
  int _correctCount = 0;
  bool _isFinished = false;
  bool _isSubmitting = false;

  void _chooseAnswer(int ans) {
    if (ans == _questions[_currentIndex]['ans']) {
      _correctCount++;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finishChallenge();
    }
  }

  Future<void> _finishChallenge() async {
    setState(() {
      _isFinished = true;
      _isSubmitting = true;
    });

    final xpEarned = _correctCount * 30 + 10; // e.g. up to 100 XP
    await widget.state.submitArenaScore(xpEarned);

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    widget.onScoreSubmitted();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFinished) {
      final xpEarned = _correctCount * 30 + 10;
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.accentGold, size: 28),
            const SizedBox(width: 10),
            Text('Kết Quả Thi Đấu!', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bé đã trả lời đúng $_correctCount / ${_questions.length} câu hỏi!'),
            const SizedBox(height: 16),
            if (_isSubmitting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGold),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, color: Color(0xFFB45309), size: 28),
                        const SizedBox(width: 4),
                        Text(
                          '+$xpEarned XP ĐẤU TRƯỜNG',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đã gửi điểm lên Supabase & cập nhật BXH!',
                      style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('XEM BẢNG XẾP HẠNG MỚI', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    final q = _questions[_currentIndex];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: AppColors.accentGold),
              const SizedBox(width: 6),
              Text('Đấu Trường Nhanh', style: AppTypography.titleMedium),
            ],
          ),
          Text(
            'Câu ${_currentIndex + 1}/${_questions.length}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                q['q'] as String,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: (q['options'] as List<int>).map((opt) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6D28D9),
                  side: const BorderSide(color: Color(0xFFDDD6FE)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _chooseAnswer(opt),
                child: Text('$opt', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Thoát'),
        ),
      ],
    );
  }
}
