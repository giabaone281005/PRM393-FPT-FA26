import 'package:flutter/material.dart';

import '../../../data/models/kid_profile.dart';
import '../../../data/providers/app_state_provider.dart';

class EditKidDialog extends StatefulWidget {
  final KidProfile kid;
  final AppStateProvider state;
  const EditKidDialog({super.key, required this.kid, required this.state});
  @override
  State<EditKidDialog> createState() => _EditKidDialogState();
}

class _EditKidDialogState extends State<EditKidDialog> {
  late final TextEditingController _name;
  late int _grade;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.kid.nickname);
    _grade = widget.kid.grade;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(bool archive) async {
    if (archive) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Lưu trữ hồ sơ?'),
          content: const Text(
            'Hồ sơ sẽ được ẩn khỏi danh sách học. Thành tích, sao và trang phục được giữ lại; phụ huynh có thể khôi phục sau.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu trữ'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    final saved = archive
        ? await widget.state.archiveKid(widget.kid.id, true)
        : await widget.state.updateKidProfile(
            widget.kid.id,
            nickname: _name.text.trim(),
            grade: _grade,
          );
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = 'Chưa lưu được. Kiểm tra kết nối, PIN và giới hạn gói.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Sửa hồ sơ bé'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Biệt danh'),
          ),
          DropdownButton<int>(
            value: _grade,
            items: List.generate(
              5,
              (i) =>
                  DropdownMenuItem(value: i + 1, child: Text('Lớp ${i + 1}')),
            ),
            onChanged: _busy ? null : (v) => setState(() => _grade = v!),
          ),
          const Text(
            'Đổi lớp sẽ hiển thị lộ trình mới. Tiến độ lớp cũ vẫn được giữ.',
          ),
          if (_error != null) Text(_error!),
          TextButton(
            onPressed: _busy ? null : () => _save(true),
            child: const Text('Lưu trữ hồ sơ'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _busy ? null : () => _save(false),
        child: Text(_busy ? 'Đang lưu…' : 'Lưu thay đổi'),
      ),
    ],
  );
}
