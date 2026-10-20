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
    Map<String, dynamic> data;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      data = decoded;
    } on FormatException {
      return null;
    }
    final now = DateTime.now();
    final expires = DateTime.tryParse(data['offline_until']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(data['updated_at']?.toString() ?? '');
    final remaining = data['remaining_seconds'];
    if (expires == null ||
        !expires.isAfter(now) ||
        updatedAt == null ||
        remaining is! num) {
      return null;
    }
    // Keep one deadline across offline saves instead of subtracting elapsed
    // time repeatedly from an already reduced budget. Server TTL stays intact.
    final deadline =
        DateTime.tryParse(data['offline_budget_deadline']?.toString() ?? '') ??
        updatedAt.add(Duration(seconds: remaining.toInt()));
    final left = deadline
        .difference(now)
        .inSeconds
        .clamp(0, remaining.toInt().clamp(0, 86400));
    return StudySession({
      ...data,
      'remaining_seconds': left,
      'offline_budget_deadline': deadline.toIso8601String(),
      'offline': true,
    });
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
