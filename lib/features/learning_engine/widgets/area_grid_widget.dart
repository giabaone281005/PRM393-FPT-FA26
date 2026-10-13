import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AreaGridWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;

  const AreaGridWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
  });

  @override
  State<AreaGridWidget> createState() => _AreaGridWidgetState();
}

class _AreaGridWidgetState extends State<AreaGridWidget> {
  late int _rows;
  late int _cols;
  final TextEditingController _answerController = TextEditingController();
  final Set<int> _tappedCells = {};

  @override
  void initState() {
    super.initState();
    _rows = widget.data['rows'] ?? 3;
    _cols = widget.data['cols'] ?? 5;
  }

  @override
  Widget build(BuildContext context) {
    final expectedArea = _rows * _cols;

    return Column(
      children: [
        // Lưới ô vuông tương tác
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: [
              Text(
                'Lưới hình chữ nhật ($_cols cột × $_rows hàng)',
                style: AppTypography.labelSmall.copyWith(fontSize: 12),
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
                          height: 38,
                          color: isTapped ? AppColors.accentGoldLight : AppColors.primaryLight.withAlpha(80),
                          child: Center(
                            child: isTapped
                                ? Text(
                                    '${cellId + 1}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryHover,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
              const SizedBox(height: 10),
              Text(
                'Gợi ý: Bạn có thể chạm vào từng ô để đếm (${_tappedCells.length} ô đã chọn)',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        TextField(
          controller: _answerController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Nhập diện tích (số ô vuông):',
            suffixText: 'ô vuông',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            final val = int.tryParse(_answerController.text.trim());
            widget.onAnswerSubmitted(val == expectedArea);
          },
          child: const Text('KIỂM TRA DIỆN TÍCH', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
