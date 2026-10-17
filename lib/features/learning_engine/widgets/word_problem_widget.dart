import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class WordProblemWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;
  final ValueChanged<dynamic>? onAnswerValue;

  const WordProblemWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
    this.onAnswerValue,
  });

  @override
  State<WordProblemWidget> createState() => _WordProblemWidgetState();
}

class _WordProblemWidgetState extends State<WordProblemWidget> {
  String? _selectedOption;
  late List<String> _options;
  late String _correctAnswer;
  late String _highlightGiven;
  late String _highlightAction;
  late String _highlightTarget;

  @override
  void initState() {
    super.initState();
    final rawOptions = widget.data['options'] as List? ?? [];
    _options = rawOptions.map((e) => e.toString()).toList();
    _correctAnswer =
        (widget.data['correctAnswer'] ??
                widget.data['answer'] ??
                (_options.isNotEmpty ? _options.first : ''))
            .toString();

    _highlightGiven =
        widget.data['given']?.toString() ?? 'Dữ kiện đề bài toán đã cho';
    _highlightAction =
        widget.data['action']?.toString() ??
        'Phép tính hoặc thao tác phân tích';
    _highlightTarget =
        widget.data['target']?.toString() ?? 'Đáp án hoặc kết quả cần tìm';
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.psychology_alt_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PHÂN TÍCH TỪ KHÓA BÀI TOÁN',
                    style: AppTypography.labelSmall.copyWith(
                      color: const Color(0xFF1D4ED8),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: '• Dữ liệu đã cho: '),
                    TextSpan(
                      text: '$_highlightGiven\n',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryHover,
                      ),
                    ),
                    const TextSpan(text: '• Bản chất phép tính: '),
                    TextSpan(
                      text: '$_highlightAction\n',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const TextSpan(text: '• Mục tiêu: '),
                    TextSpan(
                      text: _highlightTarget,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Chọn đáp án chính xác nhất:',
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
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderSubtle,
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
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textMuted,
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
                  Expanded(
                    child: Text(
                      option,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 15,
                        color: isSelected
                            ? AppColors.primaryHover
                            : AppColors.textPrimary,
                      ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _selectedOption == null
              ? null
              : () {
                  final isRight =
                      _selectedOption?.trim() == _correctAnswer.trim();
                  if (widget.onAnswerValue != null) {
                    widget.onAnswerValue!(_selectedOption);
                  } else {
                    widget.onAnswerSubmitted(isRight);
                  }
                },
          child: const Text(
            'CHỌN ĐÁP ÁN NÀY',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
