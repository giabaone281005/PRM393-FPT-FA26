import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import 'study_cache.dart';
import '../models/email_verification_input.dart';

class AuthRepository {
  // The verification screen handles its own auth events while it is mounted.
  static bool verificationScreenOpen = false;
  static SupabaseClient get _client =>
      SupabaseService.client ??
      (throw StateError(
        SupabaseService.initializationError ??
            'Chưa kết nối máy chủ. Vui lòng thử lại.',
      ));

  static Future<({bool success, String? error})> signUp({
    required String email,
    required String password,
  }) async {
    if (!SupabaseService.isInitialized) {
      return (
        success: false,
        error:
            SupabaseService.initializationError ??
            'Chưa kết nối máy chủ. Vui lòng thử lại.',
      );
    }
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'mathlingo://auth-callback',
      );
      return (
        success: response.user != null,
        error: response.session == null
            ? 'Vui lòng mở email xác minh tài khoản, sau đó đăng nhập.'
            : null,
      );
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (_) {
      return (success: false, error: 'Không thể kết nối máy chủ.');
    }
  }

  static Future<({bool success, String? error})> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseService.isInitialized) {
      return (
        success: false,
        error:
            SupabaseService.initializationError ??
            'Chưa kết nối máy chủ. Vui lòng thử lại.',
      );
    }
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return (success: response.session != null, error: null);
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (_) {
      return (success: false, error: 'Không thể kết nối máy chủ.');
    }
  }

  static Future<void> resetPassword(String email) => _client.auth
      .resetPasswordForEmail(email, redirectTo: 'mathlingo://auth-callback');

  static Future<void> resendVerification(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: 'mathlingo://auth-callback',
    );
  }

  static Future<AuthResponse> verifyEmail({
    required String email,
    required String input,
    required bool recovery,
  }) async {
    final parsed = EmailVerificationInput.parse(
      input,
      projectUrl: SupabaseService.supabaseUrl,
      recovery: recovery,
    );
    final response = await _client.auth.verifyOTP(
      type: recovery ? OtpType.recovery : OtpType.email,
      email: parsed.code == null ? null : email.trim(),
      token: parsed.code,
      tokenHash: parsed.tokenHash,
    );
    if (response.session == null) {
      throw const AuthException('Chưa xác minh được. Vui lòng yêu cầu mã mới.');
    }
    if (response.user?.email?.toLowerCase() != email.trim().toLowerCase()) {
      await _client.auth.signOut(scope: SignOutScope.local);
      throw const AuthException(
        'Liên kết thuộc email khác. Vui lòng kiểm tra lại.',
      );
    }
    return response;
  }

  static String emailError(Object error) {
    if (error is FormatException) return error.message;
    if (error is StateError && SupabaseService.initializationError != null) {
      return SupabaseService.initializationError!;
    }
    if (error is AuthException) {
      return switch (error.code) {
        'over_email_send_rate_limit' => 'Dịch vụ đang đạt giới hạn gửi email. Hãy thử lại sau; bạn vẫn có thể dùng mã hoặc liên kết đã nhận.',
        'over_request_rate_limit' =>
          'Bạn thao tác quá nhanh. Vui lòng chờ một chút rồi thử lại.',
        'otp_expired' =>
          'Mã hoặc liên kết đã hết hạn hay đã dùng. Hãy yêu cầu mã mới.',
        'email_address_not_authorized' => 'Dịch vụ email chưa được cấu hình để gửi đến địa chỉ này. Vui lòng liên hệ hỗ trợ.',
        'email_address_invalid' => 'Địa chỉ email không hợp lệ.',
        _ => 'Không xác minh được. Kiểm tra mã hoặc yêu cầu email mới.',
      };
    }
    return 'Không kết nối được máy chủ. Vui lòng thử lại.';
  }

  static Future<void> signOut() async {
    final uid = SupabaseService.currentUser?.id;
    await SupabaseService.signOut();
    if (uid != null) await StudyCache.clearAccount(uid);
  }

  static bool get isLoggedIn => SupabaseService.isLoggedIn;
}
