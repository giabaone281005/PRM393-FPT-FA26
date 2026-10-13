import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';
import '../screens/parent_portal_screen.dart';

class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key});

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  bool _useMultiplication = false;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _mathAnswerController = TextEditingController();

  late int _factorA;
  late int _factorB;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _generateMathProblem();
  }

  void _generateMathProblem() {
    final rand = Random();
    _factorA = rand.nextInt(15) + 11; // 11 to 25
    _factorB = rand.nextInt(8) + 11;  // 11 to 18
  }

  @override
  void dispose() {
    _pinController.dispose();
    _mathAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppStateProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text('Cổng Phụ Huynh (BR-01)', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Để bảo vệ an toàn cho trẻ, vui lòng xác thực danh tính phụ huynh:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),

            if (!_useMultiplication) ...[
              // Option A: PIN 4 số
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nhập mã PIN bí mật (Mặc định: 1234)',
                  prefixIcon: const Icon(Icons.password_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ] else ...[
              // Option B: Thử thách phép tính nhân 2 chữ số
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '$_factorA × $_factorB = ?',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.primaryHover,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mathAnswerController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nhập kết quả phép nhân',
                  prefixIcon: const Icon(Icons.calculate_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: AppColors.accentRed, fontSize: 12),
                ),
              ),

            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _useMultiplication = !_useMultiplication;
                  _errorMessage = '';
                });
              },
              child: Text(
                _useMultiplication
                    ? 'Dùng mã PIN bí mật thay thế'
                    : 'Dùng thử thách phép tính nhân 2 chữ số',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            bool success = false;
            if (!_useMultiplication) {
              success = state.verifyParentPin(_pinController.text.trim());
            } else {
              final val = int.tryParse(_mathAnswerController.text.trim()) ?? 0;
              success = state.verifyMultiplicationChallenge(val, _factorA * _factorB);
            }

            if (success) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParentPortalScreen()),
              );
            } else {
              setState(() {
                _errorMessage = _useMultiplication
                    ? 'Kết quả phép nhân chưa chính xác, thử lại nhé!'
                    : 'Mã PIN không đúng (Mặc định là 1234)';
              });
            }
          },
          child: const Text('Mở Khóa'),
        ),
      ],
    );
  }
}
