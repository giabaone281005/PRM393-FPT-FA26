import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';

class ItemBuyDialog extends StatefulWidget {
  final AppStateProvider state;
  final String gearType; // 'hat' or 'glasses'
  final String itemName;
  final int costStars;
  final bool isEquipped;

  const ItemBuyDialog({
    super.key,
    required this.state,
    required this.gearType,
    required this.itemName,
    required this.costStars,
    required this.isEquipped,
  });

  @override
  State<ItemBuyDialog> createState() => _ItemBuyDialogState();
}

class _ItemBuyDialogState extends State<ItemBuyDialog> {
  bool _isLoading = false;

  Future<void> _equipOrBuy() async {
    setState(() => _isLoading = true);

    final success = await widget.state.buyAndEquipMascotItem(
      type: widget.gearType,
      name: widget.itemName,
      costStars: widget.costStars,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Bé đã trang bị thành công "${widget.itemName}" cho Cú!',
          ),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bé chưa đủ Sao! Cần thêm ${widget.costStars - widget.state.currentKid.energyStars} Sao nữa.',
          ),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStars = widget.state.currentKid.energyStars;
    final canAfford = currentStars >= widget.costStars;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Text('🦉', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Text(
            widget.itemName,
            style: AppTypography.titleLarge.copyWith(fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEquipped
                ? 'Món đồ này hiện đang được trang bị cho chú Cú của bé!'
                : (widget.costStars == 0
                      ? 'Món đồ miễn phí cơ bản. Bé có muốn trang bị ngay không?'
                      : 'Đổi ${widget.costStars} Sao Năng Lượng để mở khóa và trang bị món đồ thời trang này?'),
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sao hiện có:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.star,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$currentStars Sao',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        if (!widget.isEquipped)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford
                  ? AppColors.accentGold
                  : AppColors.surfaceSubtle,
              foregroundColor: canAfford ? Colors.white : AppColors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: canAfford && !_isLoading ? _equipOrBuy : null,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.costStars == 0
                        ? 'TRANG BỊ'
                        : 'MỞ KHÓA (${widget.costStars} ⭐)',
                  ),
          ),
      ],
    );
  }
}
