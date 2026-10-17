import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import 'account_screen.dart';
import 'auth_screen.dart';
import 'widgets/auth_page_layout.dart';
import 'widgets/mascot_owl_3d.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.recovery,
    this.initiallySent = false,
  });
  final String email;
  final bool recovery, initiallySent;
  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _input = TextEditingController();
  Timer? _timer;
  StreamSubscription<AuthState>? _listener;
  DateTime? _resendAt;
  int _seconds = 0;
  bool _sending = false, _verifying = false, _completing = false, _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AuthRepository.verificationScreenOpen = true;
    _sent = widget.initiallySent;
    if (_sent) _cooldown();
    _listener = SupabaseService.client?.auth.onAuthStateChange.listen(
      (event) {
        if (_verifying || _completing || !mounted) return;
        final expected = widget.recovery
            ? AuthChangeEvent.passwordRecovery
            : AuthChangeEvent.signedIn;
        if (event.event == expected &&
            event.session?.user.email?.toLowerCase() ==
                widget.email.toLowerCase()) {
          _complete();
        }
      },
      onError: (Object error) {
        if (mounted) setState(() => _error = AuthRepository.emailError(error));
      },
    );
    if (!_sent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send();
      });
    }
  }

  @override
  void dispose() {
    AuthRepository.verificationScreenOpen = false;
    _timer?.cancel();
    _listener?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _cooldown() {
    _resendAt = DateTime.now().add(const Duration(seconds: 60));
    _seconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _resendAt!.difference(DateTime.now()).inSeconds;
      setState(() => _seconds = remaining > 0 ? remaining : 0);
      if (_seconds == 0) timer.cancel();
    });
  }

  Future<void> _send() async {
    if (_sending || _seconds > 0 || _completing) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (widget.recovery) {
        await AuthRepository.resetPassword(widget.email);
      } else {
        await AuthRepository.resendVerification(widget.email);
      }
      if (mounted) {
        setState(() {
          _sent = true;
          _cooldown();
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = AuthRepository.emailError(error);
          _cooldown();
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (_verifying || _completing) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await AuthRepository.verifyEmail(
        email: widget.email,
        input: _input.text,
        recovery: widget.recovery,
      );
      _input.clear();
      if (mounted) await _complete();
    } catch (error) {
      if (mounted) setState(() => _error = AuthRepository.emailError(error));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    try {
      if (widget.recovery) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AccountScreen(recovery: true),
          ),
        );
      } else {
        await AuthRepository.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AuthScreen(
              initialEmail: widget.email,
              initialMessage: 'Email đã xác minh. Bạn có thể đăng nhập rồi!',
            ),
          ),
          (_) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _completing = false;
          _error = AuthRepository.emailError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _sending || _verifying || _completing;
    return AuthPageLayout(
      register: !widget.recovery,
      message:
          _error ??
          (_sending
              ? 'Cú đang gửi email cho bạn…'
              : _completing
              ? 'Xác minh thành công rồi!'
              : _sent
              ? 'Mở email và nhập mã ở đây nhé. Đọc trên máy tính cũng được!'
              : 'Cùng lấy lại quyền truy cập tài khoản nhé.'),
      error: _error != null,
      notice: _sent && _error == null,
      mascotState: _completing
          ? MascotState.celebrate
          : busy
          ? MascotState.tapped
          : MascotState.idle,
      onMascotTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.recovery ? 'Lấy lại mật khẩu' : 'Xác minh email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            widget.email,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nhập mã trong email. Nếu email hiện tại chỉ có nút xác nhận, sao chép liên kết của nút đó và dán vào ô bên dưới; không cần mở link trên máy tính.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.6),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _input,
            enabled: !busy,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.text,
            autofillHints: const [AutofillHints.oneTimeCode],
            textInputAction: TextInputAction.done,
            maxLength: 8192,
            decoration: InputDecoration(
              labelText: 'Mã hoặc liên kết từ email',
              counterText: '',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onSubmitted: (_) => busy ? null : _verify(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy ? null : _verify,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
            ),
            child: Text(
              _verifying || _completing
                  ? 'Đang xác minh…'
                  : 'Xác minh & tiếp tục',
            ),
          ),
          TextButton(
            onPressed: busy || _seconds > 0 ? null : _send,
            child: Text(
              _seconds > 0
                  ? 'Có thể gửi lại sau ${_seconds}s'
                  : _sent
                  ? 'Gửi lại email'
                  : 'Gửi email xác minh',
            ),
          ),
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(context),
            child: const Text('Quay lại đăng nhập'),
          ),
        ],
      ),
    );
  }
}
