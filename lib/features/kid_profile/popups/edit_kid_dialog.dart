import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
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
  late final TextEditingController _nameController;
  late int _selectedGrade;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kid.nickname);
    _selectedGrade = widget.kid.grade;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    await widget.state.updateKidProfile(
      widget.kid.id,
      nickname: name,
      grade: _selectedGrade,
    );
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã cập nhật thông tin bé thành công!'),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa hồ sơ?'),
        content: Text(
          'Bạn có chắc muốn xóa hồ sơ "${widget.kid.nickname}"? Toàn bộ tiến độ học và sao của bé sẽ bị xóa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final ok = await widget.state.deleteKidProfile(widget.kid.id);
      if (!mounted) return;
      Navigator.pop(context);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa hồ sơ ${widget.kid.nickname}.'),
            backgroundColor: AppColors.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa! Cần giữ lại ít nhất 1 hồ sơ bé.'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Chỉnh Sửa Hồ Sơ', style: AppTypography.titleLarge.copyWith(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Biệt danh của bé',
                prefixIcon: const Icon(Icons.face_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            // Khối Lớp Cố Định (Không cho phép đổi khối lớp khi đã đăng ký ban đầu)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: Color(0xFF64748B), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Khối Lớp (Đã cố định theo đăng ký)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Lớp $_selectedGrade (Tiểu học)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ),
                  const Tooltip(
                    message: 'Không thể đổi khối lớp khi đã đăng ký ban đầu',
                    child: Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '🔒 Quy tắc: Khối lớp được cố định theo lộ trình đăng ký ban đầu của phụ huynh để đảm bảo đúng tiến độ học của bé.',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _isLoading ? null : _deleteProfile,
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed, size: 20),
                label: const Text('Xóa hồ sơ bé này', style: TextStyle(color: AppColors.accentRed)),
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
          onPressed: _isLoading ? null : _saveChanges,
          child: const Text('Lưu Thay Đổi'),
        ),
      ],
    );
  }
}
