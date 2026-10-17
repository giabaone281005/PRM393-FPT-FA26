/// Parses an email code or an unconsumed Supabase email link locally.
/// Never follows URLs or accepts an arbitrary auth server / redirect target.
class EmailVerificationInput {
  const EmailVerificationInput._({this.code, this.tokenHash});
  final String? code, tokenHash;

  factory EmailVerificationInput.parse(
    String value, {
    required String projectUrl,
    required bool recovery,
  }) {
    final input = value.trim();
    if (RegExp(r'^\d{6,10}$').hasMatch(input)) {
      return EmailVerificationInput._(code: input);
    }
    if (input.length > 8192) throw const FormatException('Liên kết quá dài.');
    var uri = Uri.tryParse(input);
    // Gmail may wrap the original link in a Google redirect.
    if (uri != null &&
        uri.scheme == 'https' &&
        const ['google.com', 'www.google.com'].contains(uri.host) &&
        uri.path == '/url') {
      uri = Uri.tryParse(
        uri.queryParameters['q'] ?? uri.queryParameters['url'] ?? '',
      );
    }
    final project = Uri.tryParse(projectUrl);
    if (uri == null ||
        project == null ||
        uri.scheme != 'https' ||
        uri.host != project.host ||
        uri.port != project.port ||
        uri.userInfo.isNotEmpty ||
        uri.path != '/auth/v1/verify' ||
        uri.hasFragment) {
      throw const FormatException(
        'Dán liên kết gốc từ email MathLingo hoặc nhập mã xác minh.',
      );
    }
    final query = uri.queryParametersAll;
    final tokens = query['token_hash'] ?? query['token'];
    final types = query['type'];
    if (tokens?.length != 1 ||
        types?.length != 1 ||
        (query.containsKey('token') && query.containsKey('token_hash')) ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(tokens!.single)) {
      throw const FormatException('Liên kết xác minh không hợp lệ.');
    }
    final type = types!.single;
    if (recovery
        ? type != 'recovery'
        : !const ['signup', 'email'].contains(type)) {
      throw FormatException(
        recovery
            ? 'Cần liên kết đặt lại mật khẩu, không phải liên kết đăng ký.'
            : 'Cần liên kết xác minh đăng ký, không phải liên kết đặt lại mật khẩu.',
      );
    }
    return EmailVerificationInput._(tokenHash: tokens.single);
  }
}
