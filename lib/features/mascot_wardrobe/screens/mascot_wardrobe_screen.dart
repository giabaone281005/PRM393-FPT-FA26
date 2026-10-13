import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../popups/item_buy_dialog.dart';

class MascotWardrobeScreen extends StatelessWidget {
  const MascotWardrobeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;

    final hats = [
      {'name': 'Mũ Thám Tử', 'cost': 0, 'icon': '🕵️'},
      {'name': 'Mũ Bác Học', 'cost': 40, 'icon': '🎓'},
      {'name': 'Mũ Phù Thủy', 'cost': 80, 'icon': '🧙'},
    ];

    final glasses = [
      {'name': 'Kính Tri Thức', 'cost': 0, 'icon': '👓'},
      {'name': 'Kính Ngôi Sao', 'cost': 35, 'icon': '🕶️'},
      {'name': 'Kính Thám Tử', 'cost': 60, 'icon': '🔍'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Kho Đồ Cú Toán Học', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGoldLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.star, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${kid.energyStars} Sao',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bục trưng bày Mascot 3D Cú
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🦉', style: TextStyle(fontSize: 60)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cú Toán Học - Thám Tử Nhí',
                    style: AppTypography.titleLarge.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Mũ: ${state.currentHat}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryHover),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Kính: ${state.currentGlasses}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentPurple),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tùy chọn Mũ (Hat)
            _buildGearSection(
              context,
              state: state,
              type: 'hat',
              title: '🎩 Bộ Sưu Tập Mũ Cho Cú',
              items: hats,
              selectedItem: state.currentHat,
            ),
            const SizedBox(height: 20),

            // Tùy chọn Kính (Glasses)
            _buildGearSection(
              context,
              state: state,
              type: 'glasses',
              title: '👓 Bộ Sưu Tập Kính Tri Thức',
              items: glasses,
              selectedItem: state.currentGlasses,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGearSection(
    BuildContext context, {
    required AppStateProvider state,
    required String type,
    required String title,
    required List<Map<String, dynamic>> items,
    required String selectedItem,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 16)),
          const SizedBox(height: 14),
          Row(
            children: items.map((item) {
              final name = item['name'] as String;
              final cost = item['cost'] as int;
              final icon = item['icon'] as String;
              final isEquipped = name == selectedItem;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ItemBuyDialog(
                        state: state,
                        gearType: type,
                        itemName: name,
                        costStars: cost,
                        isEquipped: isEquipped,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isEquipped ? AppColors.primaryLight : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEquipped ? AppColors.primary : AppColors.borderSubtle,
                        width: isEquipped ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isEquipped ? FontWeight.bold : FontWeight.w500,
                            color: isEquipped ? AppColors.primaryHover : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isEquipped ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isEquipped ? 'Đang đội' : (cost == 0 ? 'Có sẵn' : '$cost ⭐'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isEquipped ? Colors.white : const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
