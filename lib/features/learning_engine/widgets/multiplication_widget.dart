import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MultiplicationWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;

  const MultiplicationWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
  });

  @override
  State<MultiplicationWidget> createState() => _MultiplicationWidgetState();
}

class _MultiplicationWidgetState extends State<MultiplicationWidget> {
  int? _selectedAnswer;
  late int _factorA;
  late int _factorB;
  late List<int> _options;

  @override
  void initState() {
    super.initState();
    _factorA = widget.data['factorA'] ?? 7;
    _factorB = widget.data['factorB'] ?? 8;
    _options = List<int>.from(widget.data['options'] ?? [48, 54, 56, 63]);
  }

  @override
  Widget build(BuildContext context) {
    final correctAnswer = _factorA * _factorB;

    return Column(
      children: [
        // Khối hiển thị phép tính nổi bật
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '$_factorA × $_factorB = ?',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chọn kết quả đúng trong bảng cửu chương',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Lưới các lựa chọn đáp án
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount: _options.length,
          itemBuilder: (context, index) {
            final option = _options[index];
            final isSelected = _selectedAnswer == option;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAnswer = option;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? AppColors.primary.withAlpha(60) : Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$option',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primaryHover : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _selectedAnswer == null
              ? null
              : () {
                  widget.onAnswerSubmitted(_selectedAnswer == correctAnswer);
                },
          child: const Text('XÁC NHẬN ĐÁP ÁN', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
