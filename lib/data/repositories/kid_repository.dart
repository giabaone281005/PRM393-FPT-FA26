import '../../core/supabase/supabase_service.dart';
import '../models/kid_profile.dart';

class KidRepository {
  static Future<List<KidProfile>> fetchKids() async {
    final uid = SupabaseService.currentUser?.id;
    if (!SupabaseService.isInitialized || uid == null) return [];
    final rows = await SupabaseService.client!
        .from('kid_profiles')
        .select('*, kid_streaks(streak_count, shields_available)')
        .eq('parent_id', uid)
        .order('created_at');
    return rows.map(KidProfile.fromJson).toList();
  }

  // Profile mutations require a parent token; use the verified RPCs in AppStateProvider.
  // Learning stats and rewards are written only through StudyRepository sessions.
  static Future<Set<DateTime>> fetchStudyDays(String kidId) async {
    if (!SupabaseService.isInitialized || SupabaseService.currentUser == null) {
      return {};
    }

    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - (now.weekday - 1),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    String formatDate(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final rows = await SupabaseService.client!
        .from('study_daily_usage')
        .select('study_date, total_seconds')
        .eq('kid_id', kidId)
        .gte('study_date', formatDate(startOfWeek))
        .lt('study_date', formatDate(endOfWeek));

    return rows
        .where((row) => (row['total_seconds'] as num? ?? 0) > 0)
        .map((row) => DateTime.parse(row['study_date'] as String))
        .toSet();
  }
}
