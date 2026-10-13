import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class DragCountersWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(bool isCorrect) onAnswerSubmitted;

  const DragCountersWidget({
    super.key,
    required this.data,
    required this.onAnswerSubmitted,
  });

  @override
  State<DragCountersWidget> createState() => _DragCountersWidgetState();
}

class _DragCountersWidgetState extends State<DragCountersWidget> {
  int _basketCount = 0;
  late int _targetCount;
  late int _availableCount;
  late String _itemIcon;

  @override
  void initState() {
    super.initState();
    _targetCount = widget.data['targetCount'] ?? 5;
    _availableCount = widget.data['availableCount'] ?? 8;
    _itemIcon = widget.data['itemIcon'] ?? '🍎';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rổ phép thuật nhận vật phẩm kéo thả (DragTarget)
        DragTarget<String>(
          onAcceptWithDetails: (details) {
            setState(() {
              if (_basketCount < _availableCount) {
                _basketCount++;
              }
            });
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;

            return Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: isHovering ? AppColors.accentGoldLight : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isHovering ? AppColors.accentGold : AppColors.borderSubtle,
                  width: isHovering ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🧺 RỔ PHÉP THUẬT',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryHover,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      _basketCount,
                      (i) => GestureDetector(
                        onTap: () {
                          // Chạm để lấy bớt ra
                          setState(() {
                            if (_basketCount > 0) _basketCount--;
                          });
                        },
                        child: Text(
                          _itemIcon,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  ),
                  if (_basketCount == 0)
                    Text(
                      'Kéo các quả vào rổ ở đây (Chạm vào quả trong rổ để gỡ bớt)',
                      style: AppTypography.bodySmall,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Đã có: $_basketCount / $_targetCount quả',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _basketCount == _targetCount
                          ? AppColors.accentGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Kho vật phẩm để kéo (Draggable)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'Chạm và kéo từng quả lên rổ phía trên:',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(
                  (_availableCount - _basketCount).clamp(0, _availableCount),
                  (i) => Draggable<String>(
                    data: _itemIcon,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Text(
                        _itemIcon,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: Text(_itemIcon, style: const TextStyle(fontSize: 32)),
                    ),
                    child: Text(_itemIcon, style: const TextStyle(fontSize: 32)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Nút Kiểm Tra
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            widget.onAnswerSubmitted(_basketCount == _targetCount);
          },
          child: const Text('KIỂM TRA ĐÁP ÁN', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
