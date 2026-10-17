import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import 'add_kid_dialog.dart';
import '../../parent_portal/popups/parent_gate_dialog.dart';
import 'edit_kid_dialog.dart';

class KidSwitchSheet extends StatelessWidget {
  const KidSwitchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kids = state.kidProfiles;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.people_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Chọn Hồ Sơ Học Sinh',
                    style: AppTypography.titleLarge.copyWith(fontSize: 18),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${kids.length}/3 Bé (BR-04)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryHover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Chọn bé đang học hoặc thêm hồ sơ cho bé khác trong gia đình:',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),

          // List of Kid profiles
          ...List.generate(kids.length, (index) {
            final kid = kids[index];
            final isSelected = state.selectedKidIndex == index;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderSubtle,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                onTap: () {
                  state.switchKid(index);
                  Navigator.pop(context);
                },
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceSubtle,
                  child: Text(
                    kid.nickname.isNotEmpty
                        ? kid.nickname.substring(0, 1)
                        : 'B',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      kid.nickname,
                      style: AppTypography.titleMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LỚP ${kid.grade}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryHover,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '🔥 ${kid.streakCount} ngày Streak • ⭐ ${kid.energyStars} Sao',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => EditKidDialog(kid: kid, state: state),
                        );
                      },
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }),

          if (kids.length < 3) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ParentGateDialog(
                    onUnlocked: () => showDialog(
                      context: context,
                      builder: (_) => AddKidDialog(state: state),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Thêm hồ sơ bé mới (Tối đa 3 bé)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
