import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class WordProblemWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;

  const WordProblemWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
  });

  @override
  State<WordProblemWidget> createState() => _WordProblemWidgetState();
}

class _WordProblemWidgetState extends State<WordProblemWidget> {
  String? _selectedOption;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _options = List<String>.from(widget.data['options'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    const correctAnswer = '24 ÷ 4 = 6';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Khối tóm tắt đề bài & highlight từ khóa
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_alt_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'PHÂN TÍCH TỪ KHÓA BÀI TOÁN',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF1D4ED8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
                  children: [
                    TextSpan(text: '• Dữ liệu đã cho: Có tổng cộng '),
                    TextSpan(
                      text: '24 quả cam\n',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryHover),
                    ),
                    TextSpan(text: '• Hành động: Mẹ đem '),
                    TextSpan(
                      text: 'chia đều cho 4 người\n',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                    TextSpan(text: '• Mục tiêu: Tìm số cam của '),
                    TextSpan(
                      text: 'mỗi người.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Chọn phép tính phù hợp nhất để giải bài toán:',
          style: AppTypography.titleMedium.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),

        ..._options.map((option) {
          final isSelected = _selectedOption == option;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedOption = option;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    option,
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: 16,
                      color: isSelected ? AppColors.primaryHover : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _selectedOption == null
              ? null
              : () {
                  widget.onAnswerSubmitted(_selectedOption == correctAnswer);
                },
          child: const Text('CHỌN CÁCH GIẢI NÀY', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
