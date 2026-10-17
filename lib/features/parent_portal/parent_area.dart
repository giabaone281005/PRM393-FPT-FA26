import '../shared/widgets/role_ui.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/widgets/mascot_owl_3d.dart';

import 'popups/parent_gate_dialog.dart';

class ParentAreaLocked extends StatelessWidget {
  const ParentAreaLocked({super.key, this.onUnlocked});
  final VoidCallback? onUnlocked;
  @override
  Widget build(BuildContext context) => RoleScaffold(
    appBar: RoleAppBar(title: const Text('Khu vực phụ huynh')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ExcludeSemantics(child: MascotOwl3D(size: 90)),
                const SizedBox(height: 20),
                const Text(
                  'Không gian của phụ huynh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Nhập PIN để xem tiến độ học, quản lý hồ sơ bé và gói học của gia đình.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Nhập PIN để tiếp tục'),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) =>
                          ParentGateDialog(onUnlocked: onUnlocked ?? () {}),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
