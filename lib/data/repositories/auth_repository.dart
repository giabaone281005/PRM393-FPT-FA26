import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  String? get userId;
  String? get email;
  Stream<String?> get changes;
  Future<void> signIn(String email, String password);
  Future<bool> signUp(String email, String password);
  Future<void> verifyEmailCode(String email, String code);
  Future<void> resendConfirmation(String email);
  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  String? get email => client.auth.currentUser?.email;
  @override
  Stream<String?> get changes =>
      client.auth.onAuthStateChange.map((event) => event.session?.user.id);
  @override
  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUp(String email, String password) async {
    final result = await client.auth.signUp(email: email, password: password);
    return result.session != null;
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    final result = await client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    if (result.session == null) {
      throw const AuthException('Verification did not create a session.');
    }
  }

  @override
  Future<void> resendConfirmation(String email) async {
    await client.auth.resend(email: email, type: OtpType.signup);
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
}
