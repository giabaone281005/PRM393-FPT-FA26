import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../popups/change_pin_dialog.dart';
import '../../kid_profile/popups/kid_switch_sheet.dart';
import '../../auth/auth_screen.dart';

class ParentPortalScreen extends StatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  bool _isSyncing = false;

  Future<void> _syncCloud(AppStateProvider state) async {
    setState(() => _isSyncing = true);
    await state.refreshFromCloud();
    if (!mounted) return;
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('☁️ Đã đồng bộ tiến độ học tập và hồ sơ với Supabase Cloud!'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final kid = state.currentKid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Cổng Phụ Huynh', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.sync_rounded, color: AppColors.primary),
            tooltip: 'Đồng bộ Supabase',
            onPressed: _isSyncing ? null : () => _syncCloud(state),
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
            tooltip: 'Khóa cổng phụ huynh',
            onPressed: () {
              state.lockParentPortal();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ Bé đang chọn + Nút đổi bé
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      kid.nickname.isNotEmpty ? kid.nickname.substring(0, 1) : 'B',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(kid.nickname, style: AppTypography.titleMedium),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'LỚP ${kid.grade}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryHover,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Hôm nay đã học: ${kid.usedScreenTimeMinutes}/${kid.screenTimeLimitMinutes} phút',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const KidSwitchSheet(),
                      );
                    },
                    child: const Text('Đổi Bé', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thiết lập giới hạn thời gian học (Screen Time Limit)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Giới hạn học/ngày', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${kid.screenTimeLimitMinutes} phút',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryHover),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: kid.screenTimeLimitMinutes.toDouble(),
                    min: 15,
                    max: 60,
                    divisions: 3,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.surfaceSubtle,
                    onChanged: (val) {
                      state.updateScreenTimeLimit(val.toInt());
                    },
                  ),
                  Text(
                    'Đã dùng: ${kid.usedScreenTimeMinutes}/${kid.screenTimeLimitMinutes} phút (Tự động khóa học khi vượt mốc bảo vệ thị lực)',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Các nút Tùy chọn Quản trị Bảo mật
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ChangePinDialog(state: state),
                      );
                    },
                    icon: const Icon(Icons.password_rounded, color: AppColors.primary, size: 18),
                    label: const Text('Đổi Mã PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _syncCloud(state),
                    icon: const Icon(Icons.cloud_sync_rounded, color: AppColors.accentGreen, size: 18),
                    label: const Text('Đồng Bộ DB', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Báo cáo chuyên đề Yếu / Mạnh theo Stitch Design
            Text('Bản Đồ Kỹ Năng & Chuyên Đề Học Tập', style: AppTypography.titleMedium),
            const SizedBox(height: 12),
            _buildSkillBar('Phép cộng & trừ phân số', 0.92, AppColors.accentGreen, 'Mạnh (92%)'),
            _buildSkillBar('Bảng cửu chương & Phép nhân', 0.85, AppColors.accentGreen, 'Khá tốt (85%)'),
            _buildSkillBar('Xoay kim đồng hồ & Thời gian', 0.68, AppColors.accentGold, 'Cần luyện thêm (68%)'),
            _buildSkillBar('Bài toán có lời văn & Tóm tắt', 0.58, AppColors.accentRed, 'Cần hỗ trợ (58%)'),

            const SizedBox(height: 24),

            // Cam kết COPPA & An toàn trẻ em
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.accentGreen, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'An Toàn Trẻ Em Đạt Chuẩn COPPA / GDPR-K',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'MathLingo không thu thập dữ liệu định danh của trẻ, không chứa quảng cáo và bảo vệ bằng Cổng Phụ Huynh mã PIN kép.',
                          style: AppTypography.bodySmall.copyWith(color: const Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Đăng xuất phụ huynh
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await AuthRepository.signOut();
                  if (!context.mounted) return;
                  state.lockParentPortal();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đăng xuất tài khoản phụ huynh')),
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.accentRed, size: 18),
                label: const Text('Đăng Xuất Tài Khoản Phụ Huynh', style: TextStyle(color: AppColors.accentRed)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillBar(String title, double progress, Color color, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
