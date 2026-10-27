import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Only explicitly authored messages may cross from an exception into the UI.
/// Never expose raw server bodies, exception.toString(), tokens or SQL details.
class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Retains the StateError contract of LearningStore while marking its authored
/// validation/storage messages as safe to show to the learner.
class LocalLearningFailure extends StateError implements AppFailure {
  LocalLearningFailure(super.message);
}

class BackupFormatFailure extends FormatException implements AppFailure {
  const BackupFormatFailure(super.message);
}

enum NoticeKind { info, success, error }

String friendlyError(Object error, {required String fallback}) {
  if (error is AppFailure) return error.message;
  if (error is TimeoutException) {
    return 'Dịch vụ phản hồi quá thời gian chờ. Bạn có thể thử lại.';
  }
  if (error is http.ClientException) {
    return 'Chưa kết nối được dịch vụ. Hãy kiểm tra mạng rồi thử lại.';
  }
  if (error is AuthException) {
    final status = int.tryParse(error.statusCode ?? '');
    if (status != null && status >= 500) {
      return 'Dịch vụ tài khoản đang gặp sự cố. Vui lòng thử lại sau ít phút.';
    }
    if (error is AuthRetryableFetchException) {
      return 'Chưa kết nối được dịch vụ tài khoản. Hãy kiểm tra mạng rồi thử lại.';
    }
    return switch (error.code) {
      'invalid_credentials' =>
        'Email hoặc mật khẩu chưa đúng. Kiểm tra lại rồi thử nhé.',
      'email_not_confirmed' =>
        'Email chưa được xác nhận. Nhập mã trong email để tiếp tục.',
      'otp_expired' =>
        'Mã chưa đúng hoặc đã hết hạn. Kiểm tra lại hoặc gửi mã mới.',
      'otp_disabled' => 'Xác nhận bằng mã hiện chưa khả dụng. Vui lòng thử lại sau hoặc liên hệ hỗ trợ.',
      'over_email_send_rate_limit' =>
        'Đã đạt giới hạn gửi email. Chờ thêm một lúc rồi chọn Gửi lại mã.',
      'over_request_rate_limit' =>
        'Có nhiều yêu cầu trong thời gian ngắn. Chờ một chút rồi thử lại nhé.',
      'request_timeout' =>
        'Dịch vụ phản hồi quá thời gian chờ. Bạn có thể thử lại.',
      'weak_password' => 'Mật khẩu chưa đáp ứng yêu cầu. Dùng mật khẩu dài hơn và tránh mật khẩu dễ đoán.',
      'user_already_exists' || 'email_exists' =>
        'Email đã có tài khoản. Hãy đăng nhập bằng mật khẩu đã tạo.',
      'email_address_invalid' || 'validation_failed' =>
        'Thông tin chưa hợp lệ. Kiểm tra email và các ô đã nhập.',
      'email_address_not_authorized' => 'Hệ thống email chưa được cấu hình để gửi đến địa chỉ này. Vui lòng liên hệ hỗ trợ.',
      'signup_disabled' => 'Hệ thống đang tạm ngừng đăng ký mới. Nếu đã có tài khoản, hãy chọn Đăng nhập.',
      'email_provider_disabled' => 'Đăng nhập bằng email hiện chưa khả dụng. Vui lòng thử lại sau hoặc liên hệ hỗ trợ.',
      'user_banned' =>
        'Tài khoản đang bị tạm khóa. Vui lòng liên hệ hỗ trợ để được kiểm tra.',
      'session_expired' ||
      'refresh_token_not_found' ||
      'refresh_token_already_used' ||
      'invalid_jwt' =>
        'Phiên đăng nhập không còn hợp lệ. Hãy đăng nhập lại để tiếp tục.',
      'user_not_found' => 'Chưa tìm thấy tài khoản cho thao tác này. Kiểm tra email hoặc đăng ký tài khoản nhé.',
      _ => fallback,
    };
  }
  if (error is PostgrestException) {
    return switch (error.code) {
      '42501' => 'Tài khoản chưa được phép thực hiện thao tác này. Vui lòng đăng nhập lại hoặc liên hệ hỗ trợ.',
      'PGRST301' || 'PGRST302' || 'PGRST303' || '28000' =>
        'Phiên đăng nhập không còn hợp lệ. Hãy đăng nhập lại để tiếp tục.',
      'PGRST202' || '42883' || '42P01' =>
        'Tính năng này chưa sẵn sàng trên hệ thống. Bạn có thể thử lại sau.',
      '53300' || '57014' => 'Dịch vụ đang bận. Chờ một chút rồi thử lại nhé.',
      _ => fallback,
    };
  }
  return fallback;
}

String engineHttpMessage(int status) => switch (status) {
  400 || 422 => 'Dịch vụ chưa chấp nhận yêu cầu. Kiểm tra model, ngôn ngữ hoặc cấu hình kết nối rồi thử lại.',
  401 => 'Khóa hoặc token của kết nối chưa hợp lệ. Hãy cập nhật trong Engine học tập.',
  403 => 'Kết nối này chưa có quyền sử dụng dịch vụ hoặc model đã chọn. Hãy kiểm tra quyền truy cập.',
  404 => 'Chưa tìm thấy dịch vụ hoặc model này. Hãy kiểm tra endpoint và model trong Engine học tập.',
  408 || 504 => 'Dịch vụ phản hồi quá thời gian chờ. Bạn có thể thử lại.',
  413 => 'Nội dung gửi quá lớn. Hãy rút gọn câu hỏi, bảng vẽ hoặc chương trình rồi thử lại.',
  429 => 'Dịch vụ đang giới hạn yêu cầu hoặc đã hết hạn mức. Chờ thêm một lúc hoặc kiểm tra hạn mức của kết nối.',
  >= 500 => 'Dịch vụ đang gặp sự cố. Vui lòng thử lại sau ít phút.',
  >= 300 && < 400 => 'Địa chỉ kết nối đang yêu cầu chuyển hướng. Hãy cập nhật endpoint trong Engine học tập.',
  _ =>
    'Dịch vụ chưa hoàn tất yêu cầu. Hãy thử lại hoặc kiểm tra kết nối đã chọn.',
};
