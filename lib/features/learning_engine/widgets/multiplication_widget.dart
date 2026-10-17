import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class MultiplicationWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;
  final ValueChanged<dynamic>? onAnswerValue;

  const MultiplicationWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
    this.onAnswerValue,
  });

  @override
  State<MultiplicationWidget> createState() => _MultiplicationWidgetState();
}

class _MultiplicationWidgetState extends State<MultiplicationWidget> {
  String? _selectedAnswer;
  late String _expression;
  late String _correctAnswer;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    final factorA = widget.data['factorA'];
    final factorB = widget.data['factorB'];
    final formula = widget.data['formula']?.toString();

    if (formula != null && formula.isNotEmpty) {
      _expression = formula;
    } else if (factorA != null && factorB != null) {
      _expression = '$factorA × $factorB = ?';
    } else {
      _expression = widget.data['expression']?.toString() ?? 'Phép tính = ?';
    }

    final rawOptions = widget.data['options'] as List? ?? [];
    _options = rawOptions.map((e) => e.toString()).toList();

    _correctAnswer =
        (widget.data['correctAnswer'] ??
                widget.data['answer'] ??
                ((factorA is num && factorB is num)
                    ? (factorA * factorB).toString()
                    : (_options.isNotEmpty ? _options.first : '')))
            .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Khối hiển thị phép tính nổi bật
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
                _expression,
                textAlign: TextAlign.center,
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.primary,
                  letterSpacing: -1,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tính nhẩm và chọn kết quả đúng',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Grid 4 lựa chọn trắc nghiệm
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
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.borderSubtle,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.primary.withAlpha(30)
                          : Colors.black.withAlpha(5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    option,
                    style: AppTypography.titleLarge.copyWith(
                      color: isSelected
                          ? AppColors.primaryHover
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),

        // Nút kiểm tra đáp án
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _selectedAnswer == null
              ? null
              : () {
                  final isRight =
                      _selectedAnswer?.trim() == _correctAnswer.trim();
                  if (widget.onAnswerValue != null) {
                    widget.onAnswerValue!(_selectedAnswer);
                  } else {
                    widget.onAnswerSubmitted(isRight);
                  }
                },
          child: const Text(
            'KIỂM TRA ĐÁP ÁN',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
