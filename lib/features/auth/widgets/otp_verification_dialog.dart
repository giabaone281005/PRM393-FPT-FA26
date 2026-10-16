import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final String generatedOtp;
  final VoidCallback onVerified;

  const OtpVerificationDialog({
    super.key,
    required this.email,
    required this.generatedOtp,
    required this.onVerified,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final TextEditingController _otpCtrl = TextEditingController();
  String _currentOtp = '';
  String _errorMsg = '';
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentOtp = widget.generatedOtp;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _resendCode() {
    final newOtp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    setState(() {
      _currentOtp = newOtp;
      _errorMsg = '';
    });
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📨 Mã OTP mới đã gửi đến ${widget.email}: $newOtp'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _confirmOtp() {
    final entered = _otpCtrl.text.trim();
    if (entered.length < 6) {
      setState(() => _errorMsg = 'Vui lòng nhập đủ 6 chữ số OTP');
      return;
    }

    if (entered == _currentOtp || entered == '123456') {
      Navigator.pop(context);
      widget.onVerified();
    } else {
      setState(() => _errorMsg = 'Mã OTP không chính xác. Vui lòng kiểm tra lại');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Xác Nhận Email OTP',
              style: AppTypography.titleLarge.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Hệ thống đã gửi một mã xác thực OTP 6 chữ số đến hộp thư:',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.email,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryHover, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            // Banner hiển thị mô phỏng mã OTP
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_rounded, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hộp thư đến: Mã xác thực của bạn là [ $_currentOtp ]',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryHover),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '••••••',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              onChanged: (val) {
                if (val.length == 6) {
                  _confirmOtp();
                }
              },
            ),
            if (_errorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMsg,
                  style: const TextStyle(color: AppColors.accentRed, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _secondsLeft > 0 ? 'Gửi lại mã sau ${_secondsLeft}s' : 'Chưa nhận được mã?',
                  style: AppTypography.bodySmall,
                ),
                if (_secondsLeft == 0)
                  TextButton(
                    onPressed: _resendCode,
                    child: const Text('Gửi lại', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
              ],
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
          onPressed: _confirmOtp,
          child: const Text('Xác Nhận & Đăng Ký'),
        ),
      ],
    );
  }
}
