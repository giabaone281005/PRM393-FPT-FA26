import '../shared/widgets/role_ui.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/study_repository.dart';
import 'auth_screen.dart';
import '../parent_portal/parent_area.dart';

class AccountScreen extends StatefulWidget {
  final bool recovery;
  const AccountScreen({super.key, this.recovery = false});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _old = TextEditingController(),
      _new = TextEditingController(),
      _confirm = TextEditingController();
  bool _busy = false;
  String? _message;
  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_new.text.length < 8 || _new.text != _confirm.text) {
      setState(
        () => _message =
            'Mật khẩu mới cần ít nhất 8 ký tự và trùng phần xác nhận.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final client = SupabaseService.client;
      if (client == null) throw StateError('Không kết nối');
      if (!widget.recovery) {
        final state = context.read<AppStateProvider>();
        if (await StudyRepository.rpc('parent_authorized', {
              'p_token': state.parentToken,
            }) !=
            true) {
          throw StateError('Cần mở lại cổng phụ huynh');
        }
        await client.auth.signInWithPassword(
          email: client.auth.currentUser!.email!,
          password: _old.text,
        );
      }
      await client.auth.updateUser(UserAttributes(password: _new.text));
      if (!mounted) return;
      context.read<AppStateProvider>().lockParentPortal();
      setState(() => _message = 'Đã đổi mật khẩu. Vui lòng đăng nhập lại.');
      await AuthRepository.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is AuthException
              ? e.message
              : 'Không đổi được mật khẩu. Kiểm tra phiên đăng nhập hoặc PIN.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      !widget.recovery && !context.watch<AppStateProvider>().isParentUnlocked
      ? const ParentAreaLocked()
      : RoleScaffold(
          appBar: RoleAppBar(
            title: Text(
              widget.recovery ? 'Đặt lại mật khẩu' : 'Tài khoản phụ huynh',
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(SupabaseService.currentUser?.email ?? ''),
              if (!widget.recovery)
                TextField(
                  controller: _old,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu hiện tại',
                  ),
                ),
              TextField(
                controller: _new,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới (ít nhất 8 ký tự)',
                ),
              ),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu mới',
                ),
              ),
              if (_message != null) Text(_message!),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Đang lưu…' : 'Đổi mật khẩu'),
              ),
              if (!widget.recovery)
                TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          await AuthRepository.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(),
                              ),
                              (_) => false,
                            );
                          }
                        },
                  child: const Text('Đăng xuất khỏi thiết bị'),
                ),
            ],
          ),
        );
}
