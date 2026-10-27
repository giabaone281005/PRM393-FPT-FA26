import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_failure.dart';
import '../repositories/password_recovery_repository.dart';

enum RecoveryStep { email, code, password, complete }

class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController(this.repository, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final PasswordRecoveryRepository repository;
  final DateTime Function() _now;
  RecoveryStep step = RecoveryStep.email;
  String email = '';
  String? message;
  NoticeKind noticeKind = NoticeKind.info;
  bool busy = false, _disposed = false;
  DateTime? _sendAfter;

  int get resendSecondsRemaining {
    final milliseconds = _sendAfter?.difference(_now()).inMilliseconds ?? 0;
    return milliseconds <= 0 ? 0 : (milliseconds + 999) ~/ 1000;
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy || _disposed) return;
    busy = true;
    message = null;
    _emit();
    try {
      await action();
    } catch (error) {
      if (_disposed) return;
      noticeKind = NoticeKind.error;
      message = friendlyError(
        error,
        fallback: 'Chưa hoàn tất khôi phục mật khẩu. Hãy thử lại.',
      );
    } finally {
      busy = false;
      _emit();
    }
  }

  Future<void> sendCode(String address) async {
    if (busy ||
        _disposed ||
        resendSecondsRemaining > 0 ||
        (step != RecoveryStep.email && step != RecoveryStep.code)) {
      return;
    }
    final trimmed = _validEmail(address);
    if (trimmed == null) return;
    _sendAfter = _now().add(const Duration(seconds: 60));
    await _run(() async {
      await repository.requestCode(trimmed);
      if (_disposed) return;
      email = trimmed;
      step = RecoveryStep.code;
      noticeKind = NoticeKind.info;
      message = 'Yêu cầu đã được xử lý. Nếu email có tài khoản, hãy kiểm tra hộp thư và Spam để lấy mã khôi phục. Không chia sẻ mã với người khác.';
    });
  }

  String? _validEmail(String address) {
    final trimmed = address.trim();
    if (trimmed.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
      message = 'Nhập email hợp lệ.';
      noticeKind = NoticeKind.error;
      _emit();
      return null;
    }
    return trimmed;
  }

  void enterExistingCode(String address) {
    if (busy || _disposed || step != RecoveryStep.email) return;
    final trimmed = _validEmail(address);
    if (trimmed == null) return;
    email = trimmed;
    step = RecoveryStep.code;
    noticeKind = NoticeKind.info;
    message = 'Nhập mã khôi phục mới nhất trong email. Nếu mã hết hạn, chọn Gửi lại mã.';
    _emit();
  }

  Future<void> verifyCode(String code) async {
    if (step != RecoveryStep.code || busy || _disposed) return;
    if (!RegExp(r'^\d{6,10}$').hasMatch(code.trim())) {
      message = 'Nhập đầy đủ mã số trong email (6–10 chữ số).';
      noticeKind = NoticeKind.error;
      _emit();
      return;
    }
    await _run(() async {
      await repository.verifyCode(email, code.trim());
      if (_disposed) return;
      step = RecoveryStep.password;
      noticeKind = NoticeKind.info;
    });
  }

  Future<void> updatePassword(String password) async {
    if (step != RecoveryStep.password || busy || _disposed) return;
    if (password.length < 8) {
      message = 'Nhập mật khẩu mới từ 8 ký tự.';
      noticeKind = NoticeKind.error;
      _emit();
      return;
    }
    await _run(() async {
      await repository.updatePassword(password);
      if (_disposed) return;
      step = RecoveryStep.complete;
      noticeKind = NoticeKind.success;
      message = 'Đã đổi mật khẩu. Quay lại đăng nhập bằng mật khẩu mới.';
    });
  }

  void changeEmail() {
    if (busy || _disposed || step == RecoveryStep.complete) return;
    step = RecoveryStep.email;
    message = null;
    _emit();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(repository.dispose());
    super.dispose();
  }
}
