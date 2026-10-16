import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class EssayProblemWidget extends StatefulWidget {
  final String prompt;
  final String? guidance;
  final Function(bool isSubmitted) onSubmit;

  const EssayProblemWidget({
    super.key,
    required this.prompt,
    this.guidance,
    required this.onSubmit,
  });

  @override
  State<EssayProblemWidget> createState() => _EssayProblemWidgetState();
}

class _EssayProblemWidgetState extends State<EssayProblemWidget> {
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _finalResultController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _solutionController.dispose();
    _finalResultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Khung đề bài tự luận
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'BÀI TẬP TỰ LUẬN TRÌNH BÀY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.prompt,
                style: AppTypography.titleMedium.copyWith(fontSize: 15, height: 1.4),
              ),
              if (widget.guidance != null && widget.guidance!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Color(0xFFF59E0B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '💡 Hướng dẫn của Cú: ${widget.guidance!}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Vùng nhập lời giải
        const Text(
          '1. Các bước giải chi tiết (Lời giải & Phép tính):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _solutionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ví dụ:\nBước 1: Quy đồng mẫu số 2 phân số...\nBước 2: Lấy tử cộng tử...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Vùng nhập đáp số
        const Text(
          '2. Đáp số cuối cùng:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _finalResultController,
          decoration: InputDecoration(
            hintText: 'Nhập đáp số (Ví dụ: 3/4 hoặc 60 km/h)',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_submitted) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bạn Cú đã chấm lời giải của bạn: Trình bày rất logic và mạch lạc!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            if (_finalResultController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng điền đáp số trước khi nộp bài nhé!')),
              );
              return;
            }
            setState(() {
              _submitted = true;
            });
            widget.onSubmit(true);
          },
          child: const Text('NỘP BÀI TỰ LUẬN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }
}
