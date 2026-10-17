import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SocraticStepsSheet extends StatefulWidget {
  final String problemText;
  final String problemTitle;

  const SocraticStepsSheet({
    super.key,
    required this.problemText,
    required this.problemTitle,
  });

  @override
  State<SocraticStepsSheet> createState() => _SocraticStepsSheetState();
}

class _SocraticStepsSheetState extends State<SocraticStepsSheet> {
  int _activeStep = 0;

  final List<Map<String, String>> _steps = [
    {
      'title': 'Bước 1: Tóm Tắt & Phân Tích Đề Bài',
      'owl': 'Chào bé! Trước khi tính, bạn Cú cùng bé xem đề bài cho ta những dữ kiện gì đã biết và câu hỏi yêu cầu tìm gì nhé!',
      'hint': 'Gạch chân dưới các con số và từ khóa quan trọng (như "tất cả", "còn lại", "gấp mấy lần").',
    },
    {
      'title': 'Bước 2: Xác Định Phép Tính',
      'owl': 'Để tìm câu trả lời, chúng mình nên dùng phép cộng, trừ, nhân hay chia nhỉ?',
      'hint': 'Nếu gộp thêm thì dùng phép Cộng (+), nếu bớt đi dùng phép Trừ (-), nếu gấp lên nhiều lần thì dùng phép Nhân (×)!',
    },
    {
      'title': 'Bước 3: Thực Hiện & Kiểm Tra',
      'owl': 'Bé hãy đặt phép tính ra nháp và tính cẩn thận từng hàng nhé!',
      'hint': 'Sau khi có kết quả, đừng quên kiểm tra lại xem con số có hợp lý với thực tế không nhé!',
    },
  ];

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accentPurple, Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🦉', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gia Sư Cú Socratic Hướng Dẫn',
                      style: AppTypography.titleLarge.copyWith(fontSize: 16),
                    ),
                    Text(widget.problemTitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Problem quote card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              widget.problemText,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Step Stepper
          Row(
            children: List.generate(_steps.length, (idx) {
              final isDone = idx <= _activeStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: idx < _steps.length - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.accentPurple
                        : AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Step content
          Text(
            _steps[_activeStep]['title']!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDDD6FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💬', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _steps[_activeStep]['owl']!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5B21B6),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '💡 Gợi ý: ${_steps[_activeStep]['hint']!}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Next / Close button
          Row(
            children: [
              if (_activeStep > 0)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => setState(() => _activeStep--),
                    child: const Text('Bước Trước'),
                  ),
                ),
              if (_activeStep > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPurple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (_activeStep < _steps.length - 1) {
                      setState(() => _activeStep++);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    _activeStep < _steps.length - 1
                        ? 'Bước Tiếp Theo ➔'
                        : 'Bé Đã Hiểu Bài!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
