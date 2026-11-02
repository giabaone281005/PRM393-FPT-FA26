import 'package:flutter/material.dart';

import '../../data/providers/admin_dashboard_controller.dart';

/// UI gate mirrors Database authority; every repository RPC checks it again.
class AdminRoleGate extends StatelessWidget {
  const AdminRoleGate({
    super.key,
    required this.controller,
    required this.login,
    required this.dashboard,
  });
  final AdminDashboardController controller;
  final Widget login, dashboard;
  @override
  Widget build(BuildContext context) {
    if (!controller.signedIn) return login;
    if (controller.allowed) return dashboard;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.loading)
                  const CircularProgressIndicator()
                else
                  const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 24),
                Text(
                  controller.loading
                      ? 'Đang kiểm tra quyền quản trị…'
                      : 'Tài khoản chưa có quyền quản trị',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.message ?? 'Chỉ tài khoản Admin đang hoạt động mới truy cập được trang này.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: controller.loading ? null : controller.refresh,
                      child: const Text('Kiểm tra lại'),
                    ),
                    TextButton(
                      onPressed: controller.signOut,
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
