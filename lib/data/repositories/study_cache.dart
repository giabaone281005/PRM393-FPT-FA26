import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/study_session.dart';

/// Cached learning data is provisional. Only a server response can grade or award.
class StudyCache {
  static String get _prefix =>
      'study:${SupabaseService.currentUser?.id ?? "signed_out"}:';
  static Future<void> save(StudySession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_prefix}session:${session.id}',
      jsonEncode(session.data),
    );
    await prefs.setString(
      '${_prefix}last:${session.kidId}:${session.kind}:${session.data['lesson_id'] ?? ""}',
      session.id,
    );
  }

  static Future<StudySession?> read(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_prefix}session:$id');
    if (raw == null) return null;
    final data = Map<String, dynamic>.from(jsonDecode(raw));
    final expires = DateTime.tryParse(data['offline_until']?.toString() ?? '');
    if (expires == null || !expires.isAfter(DateTime.now())) return null;
    final deadline = DateTime.parse(data['updated_at'])
        .add(Duration(seconds: (data['remaining_seconds'] as num).toInt()));
    final left = deadline.difference(DateTime.now()).inSeconds.clamp(0, 86400);
    return StudySession({...data, 'remaining_seconds': left, 'offline': true});
  }

  static Future<StudySession?> last(
    String kid,
    String kind,
    String? lesson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('${_prefix}last:$kid:$kind:${lesson ?? ""}');
    return id == null ? null : read(id);
  }

  static Future<Map<String, dynamic>?> pending(String session) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_prefix}pending:$session');
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  static Future<void> enqueue(
    String session,
    Map<String, dynamic> params,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}pending:$session', jsonEncode(params));
  }

  static Future<void> acknowledge(String session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefix}pending:$session');
  }

  static Future<void> clearAccount(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs
            .getKeys()
            .where((k) => k.startsWith('study:$uid:') || k == 'family:$uid')
            .toList()) {
      await prefs.remove(key);
    }
  }
}
