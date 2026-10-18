import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';

class FamilyReportRepository {
  static Future<Map<String, dynamic>> fetch({SupabaseClient? client}) async {
    final cloud = client ?? SupabaseService.client;
    if (cloud == null ||
        (client == null && cloud.auth.currentSession == null)) {
      throw StateError('Cần đăng nhập để xem báo cáo gia đình.');
    }
    final report = Map<String, dynamic>.from(await cloud.rpc('family_report'));
    final kids = (report['kids'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    if (kids.isEmpty) return {...report, 'kids': kids};
    final profiles = await cloud
        .from('kid_profiles')
        .select('id,screen_time_limit_minutes')
        .inFilter('id', kids.map((kid) => kid['id']).toList());
    final limits = {
      for (final row in profiles) row['id']: row['screen_time_limit_minutes'],
    };
    await Future.wait(
      kids.map((kid) async {
        final session = await cloud
            .from('study_sessions')
            .select(
              'id,kind,status,lesson_id,started_at,updated_at,last_heartbeat_at,last_active,duration_seconds',
            )
            .eq('kid_id', kid['id'])
            .order('updated_at', ascending: false)
            .limit(1)
            .maybeSingle();
        kid['screen_time_limit_minutes'] = limits[kid['id']];
        if (session != null) {
          final previous = Map<String, dynamic>.from(
            kid['last_session'] as Map? ?? {},
          );
          kid['last_session'] = {
            ...previous,
            ...session,
            if (previous['lesson_id'] != session['lesson_id'])
              'title': session['kind'] == 'practice'
                  ? 'Luyện tập'
                  : session['kind'] == 'arena'
                  ? 'Đấu trường'
                  : 'Bài học',
          };
        } else {
          kid['last_session'] = null;
        }
      }),
    );
    return {...report, 'kids': kids};
  }
}
