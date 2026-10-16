import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/question.dart';

class SocraticOwlSheet extends StatefulWidget {
  final List<SocraticHint> hints;
  final VoidCallback onTryAgain;

  const SocraticOwlSheet({
    super.key,
    required this.hints,
    required this.onTryAgain,
  });

  @override
  State<SocraticOwlSheet> createState() => _SocraticOwlSheetState();
}

class _SocraticOwlSheetState extends State<SocraticOwlSheet> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final currentHint = widget.hints.isNotEmpty && _currentStep < widget.hints.length
        ? widget.hints[_currentStep]
        : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với Cú Toán Học
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/owl_mascot.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('🦉', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cú Toán Học Trợ Giúp',
                          style: AppTypography.titleMedium.copyWith(fontSize: 17),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurpleLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'SOCRATIC AI',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Đừng nản lòng nhé! Cùng tớ suy nghĩ từng bước nào!',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Khối câu hỏi dẫn dắt Socratic
          if (currentHint != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BƯỚC ${_currentStep + 1}/${widget.hints.length}:',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentPurple,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentHint.questionText,
                    style: AppTypography.titleMedium.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentHint.hintText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: const Color(0xFF4C1D95),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Bạn đã đi qua tất cả gợi ý rồi! Bây giờ hãy tự tin thử giải lại bài toán nhé!',
                style: AppTypography.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Nút hành động
          Row(
            children: [
              if (widget.hints.length > 1 && _currentStep < widget.hints.length - 1)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: AppColors.accentPurple),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentStep++;
                      });
                    },
                    child: const Text(
                      'Gợi ý bước kế tiếp',
                      style: TextStyle(color: AppColors.accentPurple, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (widget.hints.length > 1 && _currentStep < widget.hints.length - 1)
                const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onTryAgain();
                  },
                  child: const Text('TỚ ĐÃ HIỂU, LÀM LẠI!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
