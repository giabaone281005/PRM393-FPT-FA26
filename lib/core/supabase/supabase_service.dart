import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool _isInitialized = false;
  static String? _initializationError;

  static bool get isInitialized => _isInitialized;
  static String? get initializationError =>
      _initializationError ??
      configurationErrorFor(url: supabaseUrl, key: anonKey);

  static String? configurationErrorFor({
    required String url,
    required String key,
  }) {
    if (url.trim().isEmpty || key.trim().isEmpty) {
      return 'Bản chạy chưa có cấu hình kết nối. Vui lòng nhờ nhóm thiết lập lại ứng dụng.';
    }
    if (url.contains('YOUR_') || key.contains('YOUR_')) {
      return 'Bản chạy vẫn dùng cấu hình mẫu. Vui lòng nhờ nhóm điền thông tin máy chủ thật.';
    }
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        !['https', 'http'].contains(uri.scheme)) {
      return 'Địa chỉ máy chủ trong cấu hình không hợp lệ. Vui lòng nhờ nhóm kiểm tra lại.';
    }
    return null;
  }

  static SupabaseClient? _client;

  static Future<void> initialize() async {
    _initializationError = configurationErrorFor(
      url: supabaseUrl,
      key: anonKey,
    );
    if (_initializationError != null) return;
    try {
      await Supabase.initialize(url: supabaseUrl, publishableKey: anonKey);
      _client = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      // Configuration failure keeps authentication unavailable.
      _isInitialized = false;
      _initializationError = 'Không khởi tạo được kết nối. Vui lòng kiểm tra cấu hình và khởi động lại ứng dụng.';
    }
  }

  static SupabaseClient? get client => _isInitialized ? _client : null;

  static User? get currentUser => _client?.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  /// Sign up parent account
  static Future<AuthResponse?> signUp({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) return null;
    try {
      return await _client!.auth.signUp(email: email, password: password);
    } catch (_) {
      return null;
    }
  }

  /// Sign in parent account
  static Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) return null;
    try {
      return await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> signOut() async {
    if (!_isInitialized) return;
    await _client?.auth.signOut();
  }

  /// Create or update parent record in DB after sign-up
  static Future<void> upsertParentProfile() async {
    final uid = currentUser?.id;
    if (uid == null || !_isInitialized) return;
    try {
      await _client!.from('parents').upsert({
        'id': uid,
        'email': currentUser!.email,
      });
    } catch (_) {}
  }
}
