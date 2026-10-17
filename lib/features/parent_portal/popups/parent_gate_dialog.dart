import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/providers/app_state_provider.dart';
import '../screens/parent_portal_screen.dart';

class ParentGateDialog extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const ParentGateDialog({super.key, this.onUnlocked});
  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    return AlertDialog(
      title: Text(
        state.hasParentPin ? 'Cổng phụ huynh' : 'Thiết lập PIN phụ huynh',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.hasParentPin
                ? 'Nhập PIN để quản lý gia đình và gói học tập.'
                : 'Tạo PIN 4 chữ số để bảo vệ khu vực phụ huynh. Không dùng 1234.',
          ),
          TextField(
            controller: _pin,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'PIN 4 chữ số'),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() {
                    _busy = true;
                    _error = null;
                  });
                  final ok = state.hasParentPin
                      ? await state.verifyParentPin(_pin.text.trim())
                      : await state.updateParentPinCode(_pin.text.trim());
                  if (!mounted) return;
                  setState(() => _busy = false);
                  if (!ok) {
                    setState(
                      () => _error = 'PIN không hợp lệ hoặc chưa kết nối. Sai 5 lần sẽ khóa 5 phút.',
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  if (widget.onUnlocked != null) {
                    widget.onUnlocked!();
                    return;
                  }
                  navigator.push(
                    MaterialPageRoute(
                      builder: (_) => const ParentPortalScreen(),
                    ),
                  );
                },
          child: Text(
            _busy
                ? 'Đang kiểm tra…'
                : state.hasParentPin
                ? 'Mở khóa'
                : 'Lưu PIN',
          ),
        ),
      ],
    );
  }
}
