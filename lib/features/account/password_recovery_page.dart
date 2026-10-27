import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_layout.dart';
import '../../data/models/app_failure.dart';
import '../../data/providers/password_recovery_controller.dart';
import '../../data/repositories/password_recovery_repository.dart';
import '../shared/app_notice.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({
    super.key,
    required this.createRepository,
    this.initialEmail = '',
  });
  final PasswordRecoveryRepository Function() createRepository;
  final String initialEmail;
  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  late final controller = PasswordRecoveryController(widget.createRepository());
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final Timer _countdown;
  bool _obscure = true;
  int _lastCooldown = 0;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = controller.resendSecondsRemaining;
      if (mounted && remaining != _lastCooldown) {
        _lastCooldown = remaining;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdown.cancel();
    controller.dispose();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false) || controller.busy) return;
    FocusScope.of(context).unfocus();
    switch (controller.step) {
      case RecoveryStep.email:
        await controller.sendCode(_email.text);
      case RecoveryStep.code:
        await controller.verifyCode(_code.text);
        if (controller.step == RecoveryStep.password) _code.clear();
      case RecoveryStep.password:
        await controller.updatePassword(_password.text);
        if (controller.step == RecoveryStep.complete) {
          _password.clear();
          _confirm.clear();
        }
      case RecoveryStep.complete:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Scaffold(
      appBar: const AppPageHeader(title: Text('Khôi phục mật khẩu')),
      body: AppPageBody(
        children: [
          Text(
            'Lấy lại tài khoản.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(switch (controller.step) {
            RecoveryStep.email =>
              'Nhập email tài khoản để yêu cầu mã khôi phục mật khẩu.',
            RecoveryStep.code => 'Mở email khôi phục và nhập mã bên dưới. Kiểm tra cả thư Spam nếu chưa thấy email.',
            RecoveryStep.password =>
              'Chọn mật khẩu mới từ 8 ký tự và nhập lại để xác nhận.',
            RecoveryStep.complete =>
              'Bạn có thể quay lại đăng nhập bằng mật khẩu mới.',
          }),
          const SizedBox(height: 24),
          if (controller.step != RecoveryStep.complete)
            Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controller.step == RecoveryStep.email)
                      TextFormField(
                        key: const ValueKey('recovery-email'),
                        controller: _email,
                        enabled: !controller.busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Email tài khoản',
                        ),
                        validator: (value) =>
                            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(value?.trim() ?? '')
                            ? null
                            : 'Nhập email hợp lệ.',
                      )
                    else
                      Text(
                        controller.email,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    if (controller.step == RecoveryStep.code) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('recovery-code'),
                        controller: _code,
                        enabled: !controller.busy,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Mã khôi phục',
                          helperText:
                              'Nhập mã số trong email khôi phục mật khẩu.',
                        ),
                        validator: (value) =>
                            RegExp(r'^\d{6,10}$').hasMatch(value ?? '')
                            ? null
                            : 'Nhập mã 6–10 chữ số.',
                      ),
                    ],
                    if (controller.step == RecoveryStep.email)
                      TextButton(
                        key: const ValueKey('recovery-enter-code'),
                        onPressed: controller.busy
                            ? null
                            : () {
                                if (_form.currentState!.validate()) {
                                  controller.enterExistingCode(_email.text);
                                }
                              },
                        child: const Text('Đã có mã khôi phục? Nhập mã'),
                      ),
                    if (controller.step == RecoveryStep.password) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('recovery-password'),
                        controller: _password,
                        enabled: !controller.busy,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu mới',
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
                        validator: (value) => (value?.length ?? 0) >= 8
                            ? null
                            : 'Dùng mật khẩu từ 8 ký tự.',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('recovery-confirm'),
                        controller: _confirm,
                        enabled: !controller.busy,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.newPassword],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: const InputDecoration(
                          labelText: 'Nhập lại mật khẩu mới',
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Hai mật khẩu chưa khớp.',
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      key: const ValueKey('recovery-submit'),
                      onPressed:
                          controller.busy ||
                              (controller.step == RecoveryStep.email &&
                                  controller.resendSecondsRemaining > 0)
                          ? null
                          : _submit,
                      child: Text(
                        controller.busy
                            ? 'Đang xử lý…'
                            : switch (controller.step) {
                                RecoveryStep.email =>
                                  controller.resendSecondsRemaining > 0
                                      ? 'Thử lại sau ${controller.resendSecondsRemaining}s'
                                      : 'Gửi mã khôi phục',
                                RecoveryStep.code => 'Xác nhận mã',
                                _ => 'Đổi mật khẩu',
                              },
                      ),
                    ),
                    if (controller.step == RecoveryStep.code) ...[
                      OutlinedButton(
                        key: const ValueKey('recovery-resend'),
                        onPressed:
                            controller.busy ||
                                controller.resendSecondsRemaining > 0
                            ? null
                            : () async {
                                await controller.sendCode(controller.email);
                                if (controller.noticeKind != NoticeKind.error) {
                                  _code.clear();
                                }
                              },
                        child: Text(
                          controller.resendSecondsRemaining > 0
                              ? 'Gửi lại sau ${controller.resendSecondsRemaining}s'
                              : 'Gửi lại mã',
                        ),
                      ),
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () {
                                _code.clear();
                                controller.changeEmail();
                              },
                        child: const Text('Đổi email'),
                      ),
                    ],
                    if (controller.step == RecoveryStep.password)
                      TextButton(
                        onPressed: controller.busy
                            ? null
                            : () {
                                _password.clear();
                                _confirm.clear();
                                controller.changeEmail();
                              },
                        child: const Text('Mã hết hạn? Bắt đầu lại'),
                      ),
                  ],
                ),
              ),
            ),
          if (controller.busy) const LinearProgressIndicator(),
          if (controller.message != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AppNotice(
                message: controller.message!,
                kind: controller.noticeKind,
              ),
            ),
          TextButton(
            key: const ValueKey('recovery-back'),
            onPressed: controller.busy ? null : () => Navigator.pop(context),
            child: const Text('Quay lại đăng nhập'),
          ),
        ],
      ),
    ),
  );
}
