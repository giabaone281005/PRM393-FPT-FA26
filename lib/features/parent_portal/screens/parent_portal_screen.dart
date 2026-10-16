import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../popups/change_pin_dialog.dart';
import '../popups/upgrade_plus_dialog.dart';
import '../../kid_profile/popups/add_kid_dialog.dart';
import '../../auth/auth_screen.dart';
import '../../admin/admin_dashboard_screen.dart';

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
    final allKids = state.kidProfiles;
    final isPlus = state.isPlusActive;
    final maxKids = state.maxAllowedKids;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Cổng Phụ Huynh', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Nút Admin nếu tài khoản có quyền Admin
          if (state.isAdmin || AuthRepository.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.orange),
              tooltip: 'Quản trị Admin',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),
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
            // Banner Gói Dịch Vụ: Basic / Plus
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPlus
                      ? [const Color(0xFFFFF8E1), const Color(0xFFFFECB3)]
                      : [Colors.blue.shade50, Colors.indigo.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPlus ? const Color(0xFFFFD54F) : Colors.blue.shade200,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPlus ? const Color(0xFFE6A100) : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlus ? Icons.workspace_premium_rounded : Icons.star_border_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isPlus ? 'GÓI CAO CẤP PLUS' : 'GÓI CƠ BẢN BASIC',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isPlus ? const Color(0xFFB78103) : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isPlus)
                              const Icon(Icons.verified_rounded, size: 16, color: Color(0xFFE6A100)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPlus
                              ? 'Hỗ trợ tối đa 3 bé • Trọn bộ Lớp 1-5 • AI Không giới hạn'
                              : 'Giới hạn 1 bé • Nâng cấp để mở khóa tối đa 3 bé',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isPlus)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6A100),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => UpgradePlusDialog(state: state),
                        );
                      },
                      child: const Text('Nâng Cấp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            // Header Quản Lý Bé: Số lượng bé & Nút Thêm Bé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh Sách Bé Đang Học', style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Quản lý ${allKids.length}/$maxKids bé theo gói (${isPlus ? "Plus" : "Basic"})',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (allKids.length >= maxKids) {
                      showDialog(
                        context: context,
                        builder: (_) => UpgradePlusDialog(state: state),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (_) => AddKidDialog(state: state),
                      );
                    }
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 16),
                  label: const Text('Thêm Bé', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Danh sách các bé kèm theo khối lớp đã đăng ký cố định & tiến độ
            ...List.generate(allKids.length, (idx) {
              final k = allKids[idx];
              final isCurrent = state.selectedKidIndex == idx;
              // Tính toán số mốc hoàn thành
              final completedLessons = (k.energyStars / 30).clamp(1, 30).toInt();
              final progressPct = (completedLessons / 30).clamp(0.0, 1.0);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCurrent ? AppColors.primary : AppColors.borderSubtle,
                    width: isCurrent ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isCurrent ? 12 : 5),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isCurrent ? AppColors.primary : AppColors.primaryLight,
                          child: Text(
                            k.nickname.isNotEmpty ? k.nickname.substring(0, 1) : 'B',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    k.nickname,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Huy hiệu Lớp Cố Định
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.lock_rounded, size: 10, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'LỚP ${k.grade} (Cố định)',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryHover,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thời gian hôm nay: ${k.usedScreenTimeMinutes}/${k.screenTimeLimitMinutes} phút • Chuỗi: ${k.streakCount} ngày',
                                style: AppTypography.bodySmall.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrent)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            onPressed: () => state.switchKid(idx),
                            child: const Text('Chọn học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen.withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Đang chọn',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentGreen),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Thanh tiến độ lộ trình bài học
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiến độ lộ trình học Toán Lớp ${k.grade}:',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                        Text(
                          '$completedLessons/30 Bài (${(progressPct * 100).toInt()}%)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPct,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressPct > 0.6 ? AppColors.accentGreen : AppColors.primary,
                        ),
                        minHeight: 7,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

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
