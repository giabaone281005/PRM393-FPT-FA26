import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../popups/heart_recovered_dialog.dart';

class PracticeGardenScreen extends StatefulWidget {
  const PracticeGardenScreen({super.key});

  @override
  State<PracticeGardenScreen> createState() => _PracticeGardenScreenState();
}

class _PracticeGardenScreenState extends State<PracticeGardenScreen> {
  final List<Map<String, dynamic>> _drills = [
    {'q': '3 + 4 = ?', 'options': [6, 7, 8], 'ans': 7},
    {'q': '10 - 6 = ?', 'options': [3, 4, 5], 'ans': 4},
    {'q': '5 + 5 = ?', 'options': [9, 10, 11], 'ans': 10},
    {'q': '8 - 3 = ?', 'options': [4, 5, 6], 'ans': 5},
    {'q': '7 + 2 = ?', 'options': [8, 9, 10], 'ans': 9},
    {'q': '6 + 4 = ?', 'options': [9, 10, 11], 'ans': 10},
    {'q': '9 - 5 = ?', 'options': [3, 4, 5], 'ans': 4},
  ];

  int _currentIndex = 0;
  int _drillsCompleted = 0;
  int _heartsRecovered = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;
    final currentDrill = _drills[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // Nền xanh lá tươi mát của khu vườn
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Vườn Luyện Tập (BR-03)',
          style: AppTypography.titleLarge.copyWith(color: const Color(0xFF166534)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF166534)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Banner Giải Thích BR-03
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hồi Phục Tim Miễn Phí',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                          Text(
                            'Làm đúng mỗi câu tính nhẩm để tưới mầm cây và hồi phục 1 Tim năng lượng nhé!',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Hiển thị số Tim hiện tại
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isFilled = index < kid.currentHearts;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isFilled ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFilled ? AppColors.heart : AppColors.textMuted,
                      size: 34,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '${kid.currentHearts}/5 Tim năng lượng',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Thẻ câu hỏi tính nhẩm
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Câu ${_currentIndex + 1} / ${_drills.length}',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.accentGreen),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentDrill['q'] as String,
                      style: AppTypography.displayMedium.copyWith(
                        color: const Color(0xFF166534),
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lựa chọn đáp án
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: (currentDrill['options'] as List<int>).map((opt) {
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDCFCE7),
                            foregroundColor: const Color(0xFF15803D),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _handleAnswer(opt == currentDrill['ans']),
                          child: Text(
                            '$opt',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('TRỞ VỀ BÀI HỌC', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAnswer(bool isCorrect) {
    final state = context.read<AppStateProvider>();

    if (isCorrect) {
      _drillsCompleted++;
      if (state.currentKid.currentHearts < 5) {
        _heartsRecovered++;
        state.restoreHeartsInGarden(1);
      }

      // Sync log to Supabase practice_garden_logs
      state.recordPracticeSession(_drillsCompleted, _heartsRecovered);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Chính xác! +1 Tim năng lượng ❤️'),
          duration: Duration(milliseconds: 900),
          backgroundColor: AppColors.accentGreen,
        ),
      );

      // Check if full hearts
      if (state.currentKid.currentHearts >= 5) {
        showDialog(
          context: context,
          builder: (_) => const HeartRecoveredDialog(),
        );
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đúng rồi! Bé thử tính lại nhé!'),
          duration: Duration(milliseconds: 900),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }

    if (_currentIndex < _drills.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      setState(() {
        _currentIndex = 0;
      });
    }
  }
}
