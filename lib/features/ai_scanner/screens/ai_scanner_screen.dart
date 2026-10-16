import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../popups/sample_math_dialog.dart';
import '../popups/socratic_steps_sheet.dart';

class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> {
  bool _isFlashOn = false;
  bool _isScanning = false;
  String _currentProblem = 'Một mảnh vườn hình chữ nhật có chiều dài 12m và chiều rộng 8m. Tính diện tích và chu vi của mảnh vườn đó.';
  String _currentTitle = 'Toán Hình Học Lớp 4';

  void _triggerScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isScanning = false);
      _openSocraticSheet();
    });
  }

  void _openSocraticSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SocraticStepsSheet(
        problemText: _currentProblem,
        problemTitle: _currentTitle,
      ),
    );
  }

  void _openSampleProblems() {
    showDialog(
      context: context,
      builder: (_) => SampleMathDialog(
        onSelectProblem: (problem, title, grade) {
          setState(() {
            _currentProblem = problem;
            _currentTitle = title;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📷 Đã nhận diện bài toán: $title'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accentGold, AppColors.primary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('MathLingo', style: AppTypography.titleMedium.copyWith(fontSize: 16)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'QUÉT ĐỀ AI',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryHover),
                      ),
                    ),
                  ],
                ),
                Text('Nhận diện đề toán & Gia sư Socratic', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: AppColors.accentGold),
            tooltip: 'Bật/Tắt Flash',
            onPressed: () {
              setState(() => _isFlashOn = !_isFlashOn);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Khung Ngắm Quét Đề
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderSubtle),
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
                  // Viewfinder Frame
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(240),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentProblem,
                                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (_isScanning)
                          const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Actions row: Chọn bài mẫu hoặc Quét ảnh
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _openSampleProblems,
                          icon: const Icon(Icons.menu_book_rounded, size: 18),
                          label: const Text('Chọn Đề Mẫu SGK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _isScanning ? null : _triggerScan,
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Chụp & Quét AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Gia Sư Socratic
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/owl_mascot.jpg',
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Text('🦉', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Phương Pháp Socratic Math AI', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI không giải hộ đáp án số mà chia nhỏ đề bài thành các câu hỏi gợi mở, giúp bé tự tư duy và tìm ra cách giải đúng nhất!',
                    style: AppTypography.bodySmall.copyWith(color: const Color(0xFF5B21B6)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openSocraticSheet,
                    child: const Text('MỞ HƯỚNG DẪN BƯỚC GIẢI'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
