import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AreaGridWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;
  final ValueChanged<dynamic>? onAnswerValue;

  const AreaGridWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
    this.onAnswerValue,
  });

  @override
  State<AreaGridWidget> createState() => _AreaGridWidgetState();
}

class _AreaGridWidgetState extends State<AreaGridWidget> {
  late int _rows;
  late int _cols;
  late String _correctAnswer;
  late List<String> _options;
  String? _selectedOption;
  final Set<int> _tappedCells = {};

  @override
  void initState() {
    super.initState();
    _rows = widget.data['rows'] ?? widget.data['gridHeight'] ?? 3;
    _cols = widget.data['cols'] ?? widget.data['gridWidth'] ?? 4;

    final rawOptions =
        widget.data['options'] as List? ??
        [
          (_rows * _cols).toString(),
          ((_rows * _cols) - 2).toString(),
          ((_rows * _cols) + 3).toString(),
          ((_rows * _cols) + 1).toString(),
        ];
    _options = rawOptions.map((e) => e.toString()).toList();
    _correctAnswer = (widget.data['correctAnswer'] ?? (_rows * _cols))
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lưới ô vuông tương tác
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Lưới hình chữ nhật ($_cols cột × $_rows hàng)',
                style: AppTypography.labelSmall.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Table(
                border: TableBorder.all(color: AppColors.primary, width: 2),
                children: List.generate(_rows, (rowIndex) {
                  return TableRow(
                    children: List.generate(_cols, (colIndex) {
                      final cellId = rowIndex * _cols + colIndex;
                      final isTapped = _tappedCells.contains(cellId);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isTapped) {
                              _tappedCells.remove(cellId);
                            } else {
                              _tappedCells.add(cellId);
                            }
                          });
                        },
                        child: Container(
                          height: 48,
                          color: isTapped
                              ? AppColors.accentGreen.withAlpha(120)
                              : Colors.transparent,
                          child: Center(
                            child: isTapped
                                ? const Icon(
                                    Icons.check,
                                    color: AppColors.accentGreen,
                                    size: 20,
                                  )
                                : Text(
                                    '${cellId + 1}',
                                    style: TextStyle(
                                      color: Colors.grey.withAlpha(140),
                                      fontSize: 11,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(
                'Chạm vào các ô vuông để đếm nhẩm số lượng ô',
                style: AppTypography.bodySmall.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Trắc nghiệm lựa chọn đáp án
        Text(
          'Chọn diện tích / số ô vuông chính xác:',
          style: AppTypography.titleMedium.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: _options.length,
          itemBuilder: (context, index) {
            final opt = _options[index];
            final isSel = _selectedOption == opt;

            return GestureDetector(
              onTap: () => setState(() => _selectedOption = opt),
              child: Container(
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.borderSubtle,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    opt.contains('cm') ? opt : '$opt ô vuông',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSel
                          ? AppColors.primaryHover
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),
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
            'KIỂM TRA ĐÁP ÁN',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
