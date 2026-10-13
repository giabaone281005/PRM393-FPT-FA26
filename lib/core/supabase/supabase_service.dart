import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://seoswmcldwwytdrfrrrb.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlb3N3bWNsZHd3eXRkcmZycnJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE4NjkxMjEsImV4cCI6MjEwNzQ0NTEyMX0.DblsRXX1FznXbEd2hIosnWbbW_bjwSjRGo6CpOdjfKE';

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? _client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: anonKey,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
    } catch (e) {
      // Offline/Demo mode
      _isInitialized = false;
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
