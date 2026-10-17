import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/providers/app_state_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/mascot_owl_3d.dart';
import 'widgets/auth_page_layout.dart';
import 'email_verification_screen.dart';
import '../main/main_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../admin/content_management_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialEmail = '',
    this.initialMessage,
    this.initialNotice = true,
  });
  final String initialEmail;
  final String? initialMessage;
  final bool initialNotice;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController(), _password = TextEditingController();
  final _emailFocus = FocusNode(), _passwordFocus = FocusNode();
  bool _register = false, _busy = false;
  bool _showPassword = false, _notice = false, _celebrating = false;
  bool _owlTapped = false;
  bool _needsVerification = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail;
    _message = widget.initialMessage;
    _notice = widget.initialMessage != null && widget.initialNotice;
    _emailFocus.addListener(_focusChanged);
    _passwordFocus.addListener(_focusChanged);
  }

  void _focusChanged() {
    if (mounted) setState(() => _owlTapped = false);
  }

  void _typing(String value) => setState(() {
    _message = null;
    _notice = false;
    _owlTapped = false;
  });

  void _switchMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _register = !_register;
      _message = null;
      _notice = false;
      _showPassword = false;
    });
  }

  String _friendlyError(String? message) {
    if (message == null) return 'Vui lòng xác minh email rồi đăng nhập.';
    if (message.toLowerCase().contains('email rate limit')) {
      return 'Dịch vụ đang đạt giới hạn gửi email. Vui lòng thử lại sau.';
    }
    if (message.toLowerCase().contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu chưa đúng. Mình thử lại nhé!';
    }
    if (message.toLowerCase().contains('email not confirmed')) {
      return 'Bạn mở email xác minh tài khoản trước nhé!';
    }
    return message;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _notice = false;
    if (!_email.text.contains('@') || _password.text.length < 8) {
      setState(() => _message = 'Nhập email và mật khẩu ít nhất 8 ký tự.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    final result = _register
        ? await AuthRepository.signUp(
            email: _email.text.trim(),
            password: _password.text,
          )
        : await AuthRepository.signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
    if (!mounted) return;
    if (_register && result.success && !AuthRepository.isLoggedIn) {
      setState(() => _busy = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: _email.text.trim(),
            recovery: false,
            initiallySent: true,
          ),
        ),
      );
      return;
    }
    if (!result.success || !AuthRepository.isLoggedIn) {
      setState(() {
        _busy = false;
        _notice = result.success;
        _message = _friendlyError(result.error);
        _needsVerification =
            result.error?.toLowerCase().contains('email not confirmed') == true;
      });
      return;
    }
    final state = context.read<AppStateProvider>();
    setState(() => _celebrating = true);
    await state.refreshFromCloud();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => state.isAdmin
            ? const AdminDashboardScreen()
            : state.isStaff
            ? const ContentManagementScreen()
            : const MainScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (!_email.text.trim().contains('@')) {
      setState(() {
        _notice = false;
        _message = 'Nhập email để nhận mã đặt lại mật khẩu.';
      });
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EmailVerificationScreen(email: _email.text.trim(), recovery: true),
      ),
    );
  }

  MascotState get _mascotState {
    if (_celebrating) return MascotState.celebrate;
    if (_passwordFocus.hasFocus) {
      return MascotState.typingPassword;
    }
    if (_busy || _owlTapped) return MascotState.tapped;
    if (_emailFocus.hasFocus) {
      return MascotState.typingEmail;
    }
    return MascotState.idle;
  }

  String get _owlMessage {
    if (_message != null) return _message!;
    if (_celebrating) return 'Sẵn sàng rồi! Cùng Cú khám phá nhé!';
    if (_busy) return 'Cú đang chuẩn bị, bạn đợi một chút nhé…';
    if (_passwordFocus.hasFocus) {
      return 'Cú nhắm mắt rồi. Mật khẩu của bạn là bí mật!';
    }
    if (_owlTapped) return 'Hú hú! Cú luôn ở đây để đồng hành cùng bạn.';
    if (_emailFocus.hasFocus) {
      return 'Bạn nhớ kiểm tra email trước khi tiếp tục nhé!';
    }
    return _register
        ? 'Chào gia đình mới! Cùng tạo một khởi đầu thật vui nhé.'
        : 'Cú chờ bạn nãy giờ! Mình vào lớp thôi nào.';
  }

  InputDecoration _input(String hint, IconData icon, {Widget? suffix}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: dark ? AppColors.darkTextSecondary : AppColors.textMuted,
      ),
      filled: true,
      fillColor: dark ? AppColors.darkSurfaceSubtle : AppColors.surfaceSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textMuted),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: dark
              ? AppColors.darkBorderSubtle
              : AppColors.borderSubtle.withValues(alpha: .7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    return AuthPageLayout(
      register: _register,
      message: _owlMessage,
      error: _message != null && !_notice,
      notice: _notice,
      mascotState: _mascotState,
      onMascotTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _owlTapped = !_owlTapped);
      },
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _register ? 'Tạo tài khoản' : 'Đăng Nhập',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _register
                  ? 'Khởi đầu hành trình học tập cho bé.'
                  : 'Chào mừng gia đình trở lại!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Email phụ huynh',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _email,
              focusNode: _emailFocus,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(fontSize: 14),
              decoration: _input(
                'Nhập địa chỉ email',
                Icons.mail_outline_rounded,
              ),
              onChanged: _typing,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 17),
            Text(
              'Mật khẩu',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _password,
              focusNode: _passwordFocus,
              enabled: !_busy,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              autofillHints: [
                _register ? AutofillHints.newPassword : AutofillHints.password,
              ],
              style: const TextStyle(fontSize: 14),
              decoration: _input(
                'Ít nhất 8 ký tự',
                Icons.lock_outline_rounded,
                suffix: IconButton(
                  tooltip: _showPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
                  onPressed: _busy
                      ? null
                      : () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              onChanged: _typing,
              onSubmitted: (_) {
                if (!_busy) _submit();
              },
            ),
            if (!_register)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _reset,
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Quên mật khẩu?'),
                ),
              )
            else
              const SizedBox(height: 20),
            if (_needsVerification && !_register)
              TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmailVerificationScreen(
                            email: _email.text.trim(),
                            recovery: false,
                          ),
                        ),
                      ),
                child: const Text('Xác minh email / gửi lại mã'),
              ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    _busy
                        ? 'Đang xử lý…'
                        : _register
                        ? 'Tạo tài khoản'
                        : 'Đăng Nhập',
                  ),
                  if (!_busy) const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 17),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _register ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                TextButton(
                  onPressed: _busy ? null : _switchMode,
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(_register ? 'Đăng nhập' : 'Đăng ký ngay'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
