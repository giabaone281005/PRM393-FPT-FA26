import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';

class ChangePinDialog extends StatefulWidget {
  final AppStateProvider state;

  const ChangePinDialog({super.key, required this.state});

  @override
  State<ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<ChangePinDialog> {
  final _oldPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  String? _error;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPin = _oldPinCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();

    if (oldPin != widget.state.parentPin) {
      setState(() => _error = 'Mã PIN hiện tại không chính xác');
      return;
    }
    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      setState(() => _error = 'Mã PIN mới phải gồm đúng 4 chữ số');
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = 'Mã PIN xác nhận không trùng khớp');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await widget.state.updateParentPinCode(newPin);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Đã đổi mã PIN phụ huynh thành công và đồng bộ đám mây!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } else {
      setState(() => _error = 'Lỗi lưu mã PIN. Vui lòng thử lại.');
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
            child: const Icon(Icons.pin_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text('Đổi Mã PIN Phụ Huynh', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mã PIN hiện tại (Mặc định: 1234)',
                prefixIcon: const Icon(Icons.lock_clock_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Mã PIN mới (4 số)',
                prefixIcon: const Icon(Icons.password_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nhập lại mã PIN mới',
                prefixIcon: const Icon(Icons.check_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Lưu Mã PIN'),
        ),
      ],
    );
  }
}
