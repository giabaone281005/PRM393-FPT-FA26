import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_state_provider.dart';

class AddKidDialog extends StatefulWidget {
  final AppStateProvider state;

  const AddKidDialog({super.key, required this.state});

  @override
  State<AddKidDialog> createState() => _AddKidDialogState();
}

class _AddKidDialogState extends State<AddKidDialog> {
  final _nameController = TextEditingController();
  int _selectedGrade = 1;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Vui lòng nhập biệt danh của bé');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await widget.state.addKidProfile(name, _selectedGrade);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đã tạo hồ sơ cho $name (Lớp $_selectedGrade)!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } else {
      setState(
        () => _error =
            'Chưa tạo được hồ sơ. Kiểm tra mạng và giới hạn ${widget.state.maxAllowedKids} bé của gói hiện tại.',
      );
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
            child: const Icon(
              Icons.person_add_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thêm Hồ Sơ Bé (BR-04)',
            style: AppTypography.titleLarge.copyWith(fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mỗi phụ huynh được quản lý tối đa 3 hồ sơ học sinh (Lớp 1 đến Lớp 5).',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Biệt danh của bé (VD: Bé Miu, Bo, Bắp)',
                prefixIcon: const Icon(Icons.face_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                errorText: _error,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _selectedGrade,
              decoration: InputDecoration(
                labelText: 'Khối Lớp',
                prefixIcon: const Icon(Icons.school_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: [1, 2, 3, 4, 5].map((g) {
                return DropdownMenuItem(
                  value: g,
                  child: Text('Toán Lớp $g (Tiểu học)'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedGrade = val);
              },
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Tạo Hồ Sơ'),
        ),
      ],
    );
  }
}
