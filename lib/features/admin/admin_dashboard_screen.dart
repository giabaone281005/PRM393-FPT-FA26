import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/study_repository.dart';
import '../auth/auth_screen.dart';
import 'admin_commerce_screen.dart';
import 'admin_dashboard_view.dart';
import 'content_management_screen.dart';
import '../parent_portal/screens/support_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _parents = {}, _stats = {};
  String _search = '', _tier = '';
  int _page = 0, _revision = 0;
  bool _busy = true;
  String? _error;
  Timer? _debounce;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _revision++;
    super.dispose();
  }

  Future<void> _load() async {
    final revision = ++_revision;
    setState(() => _busy = true);
    try {
      final parents = await StudyRepository.rpc('admin_parents', {
            'p_search': _search,
            'p_tier': _tier,
            'p_page': _page,
          }),
          stats = await StudyRepository.rpc('admin_dashboard');
      if (mounted && revision == _revision) {
        setState(() {
          _parents = Map<String, dynamic>.from(parents);
          _stats = Map<String, dynamic>.from(stats);
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && revision == _revision) {
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : 'Không tải được quản trị.',
        );
      }
    } finally {
      if (mounted && revision == _revision) setState(() => _busy = false);
    }
  }

  Future<void> _action(Future<void> Function() fn) async {
    try {
      await fn();
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is PostgrestException
                  ? e.message
                  : 'Chưa thực hiện được. Kiểm tra quyền và kết nối.',
            ),
          ),
        );
      }
    }
  }

  Future<T?> _dialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
  }) async {
    final route = DialogRoute<T>(context: context, builder: builder);
    final result = await Navigator.of(context).push(route);
    // Controllers remain alive until the closing animation removes the fields.
    await route.completed;
    return result;
  }

  Future<String?> _reason(String title) async {
    final c = TextEditingController();
    final r = await _dialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Lý do bắt buộc'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, c.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    c.dispose();
    return r == null || r.length < 5 ? null : r;
  }

  Future<void> _support(Map<String, dynamic> p) async {
    final reason = await _reason('Cấp bù Plus 30 ngày cho ${p['email']}');
    if (reason == null) return;
    await _action(() async {
      await StudyRepository.rpc('admin_upgrade_subscription', {
        'target_parent_id': p['id'],
        'new_tier': 'plus',
        'duration_days': 30,
        'upgrade_notes': reason,
      });
    });
  }

  Future<void> _family(Map<String, dynamic> p) async {
    try {
      final data = await StudyRepository.rpc('admin_family', {
        'p_parent': p['id'],
      });
      if (!mounted) return;
      await _dialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(p['email']),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(data),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa tải được gia đình.')),
        );
      }
    }
  }

  Future<void> _role() async {
    final user = TextEditingController();
    String role = 'moderator';
    bool enabled = true;
    final chosen = await _dialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Phân quyền theo UID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: user,
                decoration: const InputDecoration(
                  labelText: 'UID tài khoản đã xác minh',
                ),
              ),
              DropdownButton<String>(
                value: role,
                items: const [
                  DropdownMenuItem(
                    value: 'moderator',
                    child: Text('Biên tập viên'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Quản trị viên'),
                  ),
                ],
                onChanged: (v) => set(() => role = v!),
              ),
              SwitchListTile(
                title: const Text('Cấp quyền'),
                value: enabled,
                onChanged: (v) => set(() => enabled = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
    final id = user.text.trim();
    user.dispose();
    if (chosen != true) return;
    final reason = await _reason(
      'Xác nhận ${enabled ? 'cấp' : 'thu hồi'} quyền $role',
    );
    if (reason == null) return;
    await _action(() async {
      await StudyRepository.rpc('set_user_role', {
        'p_user': id,
        'p_role': role,
        'p_enabled': enabled,
        'p_reason': reason,
      });
    });
  }

  Future<void> _ai() async {
    try {
      final cfg = await SupabaseService.client!
          .from('ai_settings')
          .select()
          .single();
      if (!mounted) return;
      bool enabled = cfg['enabled'];
      final basic = TextEditingController(text: cfg['basic_daily'].toString()),
          plus = TextEditingController(text: cfg['plus_daily'].toString());
      final ok = await _dialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: const Text('Hạn mức AI theo gia đình/ngày'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mỗi lần đọc ảnh hoặc tạo gợi ý tính một lượt. Chỉ bật sau khi cấu hình dịch vụ và kiểm thử.',
                ),
                SwitchListTile(
                  title: const Text('Cho phép sử dụng AI'),
                  value: enabled,
                  onChanged: (v) => set(() => enabled = v),
                ),
                TextField(
                  controller: basic,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Basic (0–100)'),
                ),
                TextField(
                  controller: plus,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Plus (0–1000)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Lưu'),
              ),
            ],
          ),
        ),
      );
      final b = int.tryParse(basic.text), p = int.tryParse(plus.text);
      basic.dispose();
      plus.dispose();
      if (ok != true || b == null || p == null) return;
      await _action(() async {
        await SupabaseService.client!
            .from('ai_settings')
            .update({'enabled': enabled, 'basic_daily': b, 'plus_daily': p})
            .eq('id', true);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không cập nhật được AI.')),
        );
      }
    }
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => AdminDashboardView(
    parents: _parents,
    stats: _stats,
    busy: _busy,
    error: _error,
    page: _page,
    tier: _tier,
    email: SupabaseService.currentUser?.email ?? 'Quản trị viên',
    onRefresh: _load,
    onSearch: (value) {
      _search = value;
      _page = 0;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 350), _load);
    },
    onTier: (value) {
      _tier = value;
      _page = 0;
      _load();
    },
    onPage: (value) {
      _page = value;
      _load();
    },
    onFamily: _family,
    onSupportFamily: _support,
    onCommerce: () => _open(const AdminCommerceScreen()),
    onContent: () => _open(const ContentManagementScreen()),
    onRoles: _role,
    onSupport: () => _open(const SupportScreen(admin: true)),
    onAi: _ai,
    onLogout: () async {
      await AuthRepository.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
      }
    },
  );
}
