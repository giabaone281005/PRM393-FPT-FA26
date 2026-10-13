import 'package:flutter/material.dart';
import '../../../core/theme/app_typography.dart';

class LeagueRulesSheet extends StatelessWidget {
  const LeagueRulesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFF8B5CF6)),
              ),
              const SizedBox(width: 12),
              Text('Thể Lệ Đấu Trường 30 Bạn', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleItem('1', 'Giải đấu hàng tuần', 'Mỗi bảng gồm đúng 30 học sinh cùng khối lớp trên toàn quốc.'),
          const SizedBox(height: 12),
          _buildRuleItem('2', 'Cách tính điểm XP', 'Làm bài học hàng ngày (+30 XP) và tham gia Thử Thách Đấu Trường (+50 XP).'),
          const SizedBox(height: 12),
          _buildRuleItem('3', 'Phần thưởng danh hiệu', 'Top 1-3 nhận danh hiệu "Nhà Bác Học Nhí", "Thám Tử Toán Học" cùng 100 Sao đổi trang phục Cú.'),
          const SizedBox(height: 12),
          _buildRuleItem('4', 'Mốc chốt kết quả', 'Bảng xếp hạng tổng kết và reset vào 21:00 tối Chủ Nhật hàng tuần.'),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('ĐÃ HIỂU THỂ LỆ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFFEDE9FE),
          child: Text(num, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}
