import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/subscription_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/subscription_repository.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<AdminParentUser> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SubscriptionTier? _selectedTier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await AdminRepository.fetchAllParentsWithSubscriptions(
      searchQuery: _searchQuery,
      tierFilter: _selectedTier,
    );
    if (!mounted) return;
    setState(() {
      _users = list;
      _isLoading = false;
    });
  }

  void _showUpgradeDialog(AdminParentUser user) {
    SubscriptionTier chosenTier = user.subscription.tier == SubscriptionTier.plus
        ? SubscriptionTier.basic
        : SubscriptionTier.plus;
    int durationDays = 30;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text('Quản Lý Gói Dịch Vụ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phụ huynh: ${user.email}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Chọn gói nâng cấp / thay đổi:'),
                    DropdownButton<SubscriptionTier>(
                      value: chosenTier,
                      isExpanded: true,
                      items: SubscriptionTier.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => chosenTier = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (chosenTier == SubscriptionTier.plus) ...[
                      const Text('Thời hạn áp dụng (ngày):'),
                      DropdownButton<int>(
                        value: durationDays,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 30, child: Text('30 Ngày (1 Tháng)')),
                          DropdownMenuItem(value: 90, child: Text('90 Ngày (3 Tháng)')),
                          DropdownMenuItem(value: 365, child: Text('365 Ngày (1 Năm)')),
                          DropdownMenuItem(value: 0, child: Text('Vĩnh Viễn (Không giới hạn)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => durationDays = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (Tùy chọn)',
                        hintText: 'Ví dụ: Kích hoạt hỗ trợ qua Zalo...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang xử lý nâng cấp gói...')),
                    );

                    final res = await SubscriptionRepository.upgradeSubscription(
                      parentId: user.id,
                      tier: chosenTier,
                      durationDays: durationDays == 0 ? null : durationDays,
                      notes: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    );

                    if (!mounted) return;
                    if (res.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ Đã cập nhật thành công gói cho ${user.email}!'),
                          backgroundColor: AppColors.accentGreen,
                        ),
                      );
                      _loadData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: ${res.error ?? "Không thể cập nhật"}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Xác Nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final plusCount = _users.where((u) => u.subscription.isPlusActive).length;
    final totalKids = _users.fold<int>(0, (sum, u) => sum + u.kidCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Bảng Quản Trị Hệ Thống (Admin)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hàng Thống Kê Tổng Quan
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tổng Phụ Huynh',
                            value: '${_users.length}',
                            icon: Icons.people_alt_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tài Khoản Plus',
                            value: '$plusCount',
                            icon: Icons.workspace_premium_rounded,
                            color: const Color(0xFFE6A100),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Tổng Số Bé',
                            value: '$totalKids',
                            icon: Icons.child_care_rounded,
                            color: AppColors.accentGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tìm kiếm và Bộ Lọc
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(
                                hintText: 'Tìm kiếm theo email phụ huynh...',
                                border: InputBorder.none,
                              ),
                              onChanged: (val) {
                                _searchQuery = val;
                                _loadData();
                              },
                            ),
                          ),
                          DropdownButton<SubscriptionTier?>(
                            value: _selectedTier,
                            underline: const SizedBox(),
                            hint: const Text('Tất cả gói', style: TextStyle(fontSize: 13)),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Tất cả')),
                              DropdownMenuItem(value: SubscriptionTier.basic, child: Text('Basic')),
                              DropdownMenuItem(value: SubscriptionTier.plus, child: Text('Plus')),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedTier = val);
                              _loadData();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Danh Sách User
                    Text('Danh Sách Tài Khoản Phụ Huynh (${_users.length})', style: AppTypography.titleMedium),
                    const SizedBox(height: 10),

                    if (_users.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text('Không tìm thấy phụ huynh nào phù hợp'),
                        ),
                      )
                    else
                      ..._users.map((user) {
                        final isPlus = user.subscription.isPlusActive;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPlus ? const Color(0xFFFFD54F) : Colors.grey.shade200,
                              width: isPlus ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isPlus
                                              ? const Color(0xFFFFF9E6)
                                              : Colors.blue.shade50,
                                          child: Icon(
                                            isPlus ? Icons.star_rounded : Icons.person_rounded,
                                            color: isPlus ? const Color(0xFFE6A100) : AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.email,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Số bé: ${user.kidCount} bé • Max cho phép: ${user.subscription.maxKids}',
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPlus ? const Color(0xFFE6A100) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isPlus ? '⭐ PLUS' : '🥉 BASIC',
                                      style: TextStyle(
                                        color: isPlus ? Colors.white : Colors.grey.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    user.subscription.expiresAt != null
                                        ? 'Hạn dùng: ${user.subscription.expiresAt!.day}/${user.subscription.expiresAt!.month}/${user.subscription.expiresAt!.year}'
                                        : 'Hạn dùng: Vĩnh viễn',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isPlus ? Colors.orange.shade700 : AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _showUpgradeDialog(user),
                                    icon: Icon(
                                      isPlus ? Icons.edit_note_rounded : Icons.upgrade_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      isPlus ? 'Điều Chỉnh Gói' : 'Nâng Cấp Plus',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
