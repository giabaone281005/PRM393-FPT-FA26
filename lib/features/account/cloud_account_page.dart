import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_layout.dart';
import '../../app_motion.dart';
import '../../data/providers/cloud_backup_controller.dart';
import '../shared/app_notice.dart';
import 'learning_sync_scope.dart';
import 'password_recovery_page.dart';

class CloudScope extends InheritedNotifier<CloudBackupController> {
  const CloudScope({
    super.key,
    required CloudBackupController controller,
    required super.child,
  }) : super(notifier: controller);
  static CloudBackupController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CloudScope>()?.notifier;
}

class CloudAccountButton extends StatelessWidget {
  const CloudAccountButton({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = CloudScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return ListTile(
      key: const ValueKey('cloud-account'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        controller.signedIn ? Icons.cloud_outlined : Icons.cloud_off_outlined,
      ),
      title: const Text('Tài khoản & sao lưu'),
      subtitle: Text(
        controller.busy
            ? 'Đang xử lý…'
            : controller.message ??
                  (controller.signedIn
                      ? controller.store.profile == null
                            ? 'Đã đăng nhập · chọn hồ sơ để tự lưu'
                            : (controller.currentBinding?['revision'] as num? ??
                                      0) >
                                  0
                            ? 'Đã có bản cloud · tự lưu khi có mạng'
                            : 'Hồ sơ đang chờ sao lưu lên cloud'
                      : 'Đăng nhập để lưu và khôi phục trên điện thoại khác'),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        DiscoveryRoute<void>(
          builder: (_) => CloudAccountPage(controller: controller),
        ),
      ),
    );
  }
}

class CloudAccountPage extends StatefulWidget {
  const CloudAccountPage({super.key, required this.controller});
  final CloudBackupController controller;
  @override
  State<CloudAccountPage> createState() => _CloudAccountPageState();
}

class _CloudAccountPageState extends State<CloudAccountPage> {
  final _email = TextEditingController(), _password = TextEditingController();
  final _code = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  Timer? _countdown;
  bool _register = false;
  bool _obscure = true;
  bool _verifying = false, _resending = false;
  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.controller.verificationEmail != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _countdown?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await widget.controller.signIn(
      _email.text,
      _password.text,
      register: _register,
    );
    if (mounted &&
        (widget.controller.signedIn ||
            widget.controller.verificationEmail != null)) {
      _password.clear();
    }
  }

  Future<void> _verify() async {
    if (!_codeForm.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);
    try {
      await widget.controller.verifyEmailCode(_code.text);
      if (mounted && widget.controller.signedIn) _code.clear();
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final processed = await widget.controller.resendConfirmation();
      if (mounted && processed) _code.clear();
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Widget _verificationForm(CloudBackupController controller) => Form(
    key: _codeForm,
    child: AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppLayout.panel(context),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(AppLayout.tileRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMAIL XÁC NHẬN',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  controller.verificationEmail!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const ValueKey('cloud-otp'),
            controller: _code,
            enabled: !controller.busy,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(letterSpacing: 4),
            decoration: const InputDecoration(
              labelText: 'Mã xác nhận',
              hintText: 'Mã số trong email',
            ),
            validator: (value) =>
                RegExp(r'^\d{6,10}$').hasMatch(value?.trim() ?? '')
                ? null
                : 'Nhập đầy đủ mã số trong email (6–10 chữ số).',
            onFieldSubmitted: (_) {
              if (!controller.busy) _verify();
            },
          ),
          const SizedBox(height: 20),
          if (controller.message != null) ...[
            AppNotice(
              message: controller.message!,
              kind: controller.noticeKind,
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            key: const ValueKey('cloud-verify'),
            onPressed: controller.busy ? null : _verify,
            child: Text(_verifying ? 'Đang xác nhận…' : 'Xác nhận & tiếp tục'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const ValueKey('cloud-resend'),
            onPressed: controller.busy || controller.resendSecondsRemaining > 0
                ? null
                : _resend,
            child: Text(
              _resending
                  ? 'Đang yêu cầu mã mới…'
                  : controller.resendSecondsRemaining > 0
                  ? 'Gửi lại mã sau ${controller.resendSecondsRemaining}s'
                  : 'Gửi lại mã',
            ),
          ),
          TextButton(
            onPressed: controller.busy
                ? null
                : () {
                    _code.clear();
                    controller.cancelEmailVerification();
                    setState(() => _register = false);
                  },
            child: const Text('Đổi email / quay lại đăng nhập'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Kiểm tra cả thư Spam. Mã chỉ dùng một lần; nếu gửi lại, hãy nhập mã mới nhất.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final verifying =
          !controller.signedIn && controller.verificationEmail != null;
      return Scaffold(
        appBar: const AppPageHeader(title: Text('Tài khoản & sao lưu')),
        body: AppPageBody(
          children: [
            Icon(
              verifying
                  ? Icons.mark_email_unread_outlined
                  : Icons.cloud_done_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              verifying
                  ? 'Một mã nhỏ.\nTiếp tục khám phá.'
                  : 'Giữ lại những khám phá.',
              style: verifying
                  ? Theme.of(context).textTheme.headlineLarge
                  : Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              verifying
                  ? 'Mở email Matlingo và nhập mã xác nhận ngay bên dưới. Bạn sẽ được đăng nhập sau khi xác nhận thành công.'
                  : 'Đăng nhập để bắt đầu học. Hồ sơ, bài đang học và lịch sử tự động lưu lên tài khoản khi có mạng.',
            ),
            const SizedBox(height: 24),
            if (verifying)
              _verificationForm(controller)
            else if (!controller.signedIn)
              Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const ValueKey('cloud-email'),
                        controller: _email,
                        enabled: !controller.busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Nhập email hợp lệ.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('cloud-password'),
                        controller: _password,
                        enabled: !controller.busy,
                        obscureText: _obscure,
                        autofillHints: [
                          _register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            (value ?? '').isEmpty ||
                                (_register && value!.length < 8)
                            ? 'Nhập mật khẩu${_register ? ' từ 8 ký tự' : ''}.'
                            : null,
                        onFieldSubmitted: (_) {
                          if (!controller.busy) _submit();
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: controller.busy ? null : _submit,
                        child: Text(
                          controller.busy
                              ? _register
                                    ? 'Đang tạo tài khoản…'
                                    : 'Đang đăng nhập…'
                              : _register
                              ? 'Tạo tài khoản'
                              : 'Đăng nhập',
                        ),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () => setState(() => _register = !_register),
                        child: Text(
                          _register
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký',
                        ),
                      ),
                      if (!_register &&
                          controller.createPasswordRecovery != null)
                        TextButton(
                          key: const ValueKey('cloud-forgot-password'),
                          onPressed: controller.busy
                              ? null
                              : () {
                                  _password.clear();
                                  Navigator.push(
                                    context,
                                    DiscoveryRoute<void>(
                                      builder: (_) => PasswordRecoveryPage(
                                        createRepository:
                                            controller.createPasswordRecovery!,
                                        initialEmail: _email.text,
                                      ),
                                    ),
                                  );
                                },
                          child: const Text('Quên mật khẩu?'),
                        ),
                      TextButton.icon(
                        key: const ValueKey('cloud-enter-code'),
                        onPressed: controller.busy
                            ? null
                            : () {
                                _code.clear();
                                _password.clear();
                                controller.beginEmailVerification(_email.text);
                              },
                        icon: const Icon(Icons.password_outlined),
                        label: const Text('Đã có mã xác nhận? Nhập mã'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              const LearningSyncStatus(),
              Text(
                controller.email ?? 'Đã đăng nhập',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (controller.store.profile != null &&
                  controller.canUseProfile(controller.store.profile!.id)) ...[
                Text('Hồ sơ đang mở: ${controller.store.profile!.name}'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('cloud-save'),
                  onPressed: controller.busy || controller.conflict
                      ? null
                      : () => controller.saveCurrent(),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Lưu lại ngay'),
                ),
                const Text(
                  'Hồ sơ đang mở tự động lưu khi có mạng. Khi offline, tiến độ được giữ trên thiết bị để gửi lại sau.',
                  style: TextStyle(fontSize: 13),
                ),
              ] else
                const Text('Mở hoặc tạo hồ sơ trên thiết bị để lưu lên cloud.'),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: controller.busy ? null : controller.refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại danh sách cloud'),
              ),
              const SizedBox(height: 16),
              Text(
                'Hồ sơ đã sao lưu',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (controller.backups.isEmpty && !controller.busy)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Chưa có bản sao lưu trong tài khoản này.'),
                ),
              for (final backup in controller.backups)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        backup.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Đã lưu: ${_date(backup.updatedAt.toLocal())}'),
                      OutlinedButton.icon(
                        key: ValueKey('restore-${backup.key}'),
                        onPressed: controller.busy
                            ? null
                            : () => controller.restore(backup),
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Khôi phục thành hồ sơ riêng'),
                      ),
                    ],
                  ),
                ),
              const Text(
                'Khôi phục tạo thêm hồ sơ trên thiết bị, giữ nguyên các bài chưa gửi ở hồ sơ cũ.',
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: controller.busy ? null : controller.signOut,
                child: const Text('Đăng xuất tài khoản cloud'),
              ),
            ],
            if (controller.busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LinearProgressIndicator(),
              ),
            if (controller.message != null && !verifying)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: AppNotice(
                  message: controller.message!,
                  kind: controller.noticeKind,
                ),
              ),
            const SizedBox(height: 16),
            if (controller.signedIn)
              const Text(
                'Điểm XP trong bản sao lưu là kết quả học cá nhân; chưa được server xác minh.',
                style: TextStyle(fontSize: 12),
              ),
          ],
        ),
      );
    },
  );
  String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
