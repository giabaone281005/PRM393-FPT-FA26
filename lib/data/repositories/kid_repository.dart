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
}
