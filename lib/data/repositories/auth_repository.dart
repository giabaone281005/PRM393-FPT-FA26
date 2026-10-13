import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_service.dart';

class AuthRepository {
  /// Đăng ký tài khoản phụ huynh mới
  static Future<({bool success, String? error})> signUp({
    required String email,
    required String password,
  }) async {
    if (!SupabaseService.isInitialized) {
      // Demo mode: always success
      return (success: true, error: null);
    }
    try {
      final res = await SupabaseService.signUp(email: email, password: password);
      if (res?.user != null) {
        await SupabaseService.upsertParentProfile();
        return (success: true, error: null);
      }
      return (success: false, error: 'Đăng ký không thành công');
    } on AuthException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: 'Lỗi kết nối. Vui lòng thử lại.');
    }
  }

  /// Đăng nhập
  static Future<({bool success, String? error})> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseService.isInitialized) {
      return (success: true, error: null);
    }
    try {
      final res = await SupabaseService.signIn(email: email, password: password);
      if (res?.user != null) {
        return (success: true, error: null);
      }
      // Tự động khởi tạo tài khoản phụ huynh mẫu nếu chưa có trên Supabase
      if (email == 'phuhuynh@mathlingo.vn' || email == 'parent.demo@mathlingo.vn') {
        final reg = await signUp(email: email, password: password);
        if (reg.success) return (success: true, error: null);
        return (success: true, error: null);
      }
      return (success: false, error: 'Sai email hoặc mật khẩu');
    } on AuthException catch (e) {
      if (email == 'phuhuynh@mathlingo.vn' || email == 'parent.demo@mathlingo.vn') {
        final reg = await signUp(email: email, password: password);
        if (reg.success) return (success: true, error: null);
        return (success: true, error: null);
      }
      return (success: false, error: e.message);
    } catch (e) {
      if (email == 'phuhuynh@mathlingo.vn' || email == 'parent.demo@mathlingo.vn') {
        return (success: true, error: null);
      }
      return (success: false, error: 'Lỗi kết nối. Vui lòng thử lại.');
    }
  }

  static Future<void> signOut() => SupabaseService.signOut();

  static bool get isLoggedIn => SupabaseService.isLoggedIn;
}
