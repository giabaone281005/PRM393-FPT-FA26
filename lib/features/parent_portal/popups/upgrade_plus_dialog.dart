import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/supabase/supabase_service.dart';
import '../../../data/repositories/subscription_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';

class UpgradePlusDialog extends StatelessWidget {
  final AppStateProvider state;

  const UpgradePlusDialog({super.key, required this.state});

  // Thanh toán QR MoMo/ZaloPay (sandbox):
  // 1) gọi Edge Function create-payment lấy ảnh QR
  // 2) hiện QR cho người dùng quét
  // 3) lắng nghe bảng payments, khi callback đổi status = paid thì nâng cấp gói Plus
  Future<void> _pay(BuildContext context, String provider) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      final client = SupabaseService.client!;
      final res = await client.functions.invoke('create-payment', body: {'provider': provider});
      final orderId = res.data['order_id'] as String;
      final bytes = base64Decode((res.data['qr_image'] as String).split(',').last);

      late StreamSubscription sub;
      sub = client.from('payments').stream(primaryKey: ['id']).eq('order_id', orderId).listen((rows) async {
        if (rows.isNotEmpty && rows.first['status'] == 'paid') {
          sub.cancel();
          state.updateLocalSubscription(await SubscriptionRepository.fetchCurrentSubscription());
          nav.pop(); // đóng dialog QR
          nav.pop(); // đóng dialog nâng cấp
          messenger.showSnackBar(const SnackBar(
            content: Text('🎉 Thanh toán thành công! Đã nâng cấp Gói Plus'),
            backgroundColor: AppColors.accentGreen,
          ));
        }
      });

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Quét mã ${provider == 'momo' ? 'MoMo' : 'ZaloPay'}'),
          content: Image.memory(bytes, width: 240),
        ),
      );
      sub.cancel();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Không tạo được QR: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header với icon vương miện
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFE6A100), size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nâng Cấp Gói Plus',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Mở khóa toàn bộ tiềm năng học toán cho bé',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Danh sách đặc quyền Gói Plus
            _buildFeatureRow(
              icon: Icons.groups_rounded,
              color: AppColors.primary,
              title: 'Hỗ trợ tối đa 3 hồ sơ học sinh (BR-04)',
              desc: 'Gói Basic chỉ cho phép 1 bé. Nâng cấp Plus để thêm đến 3 bé.',
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.menu_book_rounded,
              color: AppColors.accentGreen,
              title: 'Mở khóa 100% bài học Lớp 1 - 5',
              desc: 'Toàn quyền truy cập hơn 1500 câu hỏi và 5 widget tương tác đỉnh cao.',
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.document_scanner_rounded,
              color: const Color(0xFF8A2BE2),
              title: 'Không giới hạn lượt quét Socratic AI',
              desc: 'Giải toán thông minh, hướng dẫn từng bước mà không lo hết lượt.',
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.checkroom_rounded,
              color: const Color(0xFFFF6F00),
              title: 'Trọn bộ trang phục Cú Mathy huyền thoại',
              desc: 'Tự do hóa trang Cú Thám Tử, Cú Pháp Sư và nhiều phụ kiện đặc biệt.',
            ),
            const SizedBox(height: 20),

            // Card Báo giá ưu đãi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF9E6),
                    const Color(0xFFFFECB3).withValues(alpha: 0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6A100),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TIẾT KIỆM 40%',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Gói Trọn Năm',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '499.000 đ',
                        style: TextStyle(
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '~ 41.000 đ / tháng',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Nút Kích hoạt / Trải nghiệm ngay
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE6A100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (c) => SimpleDialog(
                  title: const Text('Chọn ví thanh toán'),
                  children: [
                    SimpleDialogOption(
                      onPressed: () { Navigator.pop(c); _pay(context, 'momo'); },
                      child: const Text('MoMo'),
                    ),
                    SimpleDialogOption(
                      onPressed: () { Navigator.pop(c); _pay(context, 'zalopay'); },
                      child: const Text('ZaloPay'),
                    ),
                  ],
                ),
              ),
              child: const Text(
                'Thanh Toán Bằng QR',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Để Sau', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}