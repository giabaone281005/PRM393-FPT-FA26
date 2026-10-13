import '../../core/supabase/supabase_service.dart';
import '../models/kid_profile.dart';

class KidRepository {

  /// Lấy danh sách hồ sơ bé từ Supabase
  static Future<List<KidProfile>> fetchKids() async {
    if (!SupabaseService.isInitialized) return [];
    try {
      final data = await SupabaseService.client!
          .from('kid_profiles')
          .select()
          .order('created_at');

      return (data as List).map((row) => KidProfile.fromJson(row)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Tạo hồ sơ bé mới
  static Future<KidProfile?> createKid({
    required String nickname,
    required int grade,
  }) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null || !SupabaseService.isInitialized) return null;
    try {
      final res = await SupabaseService.client!.from('kid_profiles').insert({
        'parent_id': uid,
        'nickname': nickname,
        'grade': grade,
      }).select().single();
      return KidProfile.fromJson(res);
    } catch (_) {
      return null;
    }
  }

  /// Cập nhật trái tim + sao của bé
  static Future<void> updateKidStats(
    String kidId, {
    int? hearts,
    int? energyStars,
    int? screenTimeLimitMinutes,
  }) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (hearts != null) updates['current_hearts'] = hearts;
      if (energyStars != null) updates['energy_stars'] = energyStars;
      if (screenTimeLimitMinutes != null) {
        updates['screen_time_limit_minutes'] = screenTimeLimitMinutes;
      }
      await SupabaseService.client!
          .from('kid_profiles')
          .update(updates)
          .eq('id', kidId);
    } catch (_) {}
  }

  /// Lưu progress bài học
  static Future<void> saveProgress({
    required String kidId,
    required String lessonId,
    required bool isCompleted,
    required int starsEarned,
    required int accuracyPercent,
  }) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await SupabaseService.client!.from('kid_progress').upsert({
        'kid_id': kidId,
        'lesson_id': lessonId,
        'is_completed': isCompleted,
        'stars_earned': starsEarned,
        'accuracy_percent': accuracyPercent,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      });
    } catch (_) {}
  }

  /// Cập nhật streak
  static Future<void> updateStreak(String kidId, int streakCount) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await SupabaseService.client!.from('kid_streaks').upsert({
        'kid_id': kidId,
        'streak_count': streakCount,
        'last_activity_date': DateTime.now().toIso8601String().substring(0, 10),
      });
    } catch (_) {}
  }

  /// Xóa hồ sơ bé
  static Future<bool> deleteKid(String kidId) async {
    if (!SupabaseService.isInitialized) return true;
    try {
      await SupabaseService.client!
          .from('kid_profiles')
          .delete()
          .eq('id', kidId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Đổi mã PIN cổng phụ huynh (BR-01)
  static Future<bool> updateParentPin(String newPin) async {
    final uid = SupabaseService.currentUser?.id;
    if (uid == null || !SupabaseService.isInitialized) return true;
    try {
      await SupabaseService.client!.from('parents').upsert({
        'id': uid,
        'parent_pin_hash': newPin,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ghi log phục hồi tim tại Vườn Luyện Tập (BR-03)
  static Future<void> logPracticeGarden({
    required String kidId,
    required int heartsRestored,
    required int mathDrillsCompleted,
  }) async {
    if (!SupabaseService.isInitialized) return;
    try {
      await SupabaseService.client!.from('practice_garden_logs').insert({
        'kid_id': kidId,
        'hearts_restored': heartsRestored,
        'math_drills_completed': mathDrillsCompleted,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
