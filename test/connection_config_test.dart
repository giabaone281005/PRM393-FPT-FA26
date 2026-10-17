import 'package:flutter_test/flutter_test.dart';
import 'package:mathlingo/core/supabase/supabase_service.dart';
import 'package:mathlingo/data/repositories/auth_repository.dart';

void main() {
  test(
    'missing and example configuration are distinguished from network errors',
    () {
      expect(
        SupabaseService.configurationErrorFor(url: '', key: ''),
        contains('chưa có cấu hình'),
      );
      expect(
        SupabaseService.configurationErrorFor(
          url: 'https://YOUR_PROJECT_REF.supabase.co',
          key: 'YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY',
        ),
        contains('cấu hình mẫu'),
      );
      expect(
        SupabaseService.configurationErrorFor(
          url: 'wrong-address',
          key: 'test-public-key',
        ),
        contains('không hợp lệ'),
      );
      expect(
        SupabaseService.configurationErrorFor(
          url: 'https://example.supabase.co',
          key: 'test-public-key',
        ),
        isNull,
      );
      expect(
        SupabaseService.configurationErrorFor(
          url: 'http://127.0.0.1:54321',
          key: 'test-public-key',
        ),
        isNull,
      );
    },
  );

  test('login and signup without config explain setup failure without requesting authentication', () async {
    await SupabaseService.initialize();
    final login = await AuthRepository.signIn(
      email: 'parent@example.test',
      password: 'test-password',
    );
    final signup = await AuthRepository.signUp(
      email: 'parent@example.test',
      password: 'test-password',
    );
    expect(login.success, isFalse);
    expect(signup.success, isFalse);
    expect(login.error, contains('chưa có cấu hình'));
    expect(signup.error, login.error);
  });
}
