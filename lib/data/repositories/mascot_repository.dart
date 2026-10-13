import '../../core/supabase/supabase_service.dart';

class MascotRepository {
  /// Cập nhật trang phục linh vật Cú (Mũ, Kính) lên Supabase
  static Future<bool> saveMascotGear({
    required String kidId,
    required String hat,
    required String glasses,
  }) async {
    if (!SupabaseService.isInitialized) return true;
    try {
      final avatarDescriptor = '$hat|$glasses';
      await SupabaseService.client!
          .from('kid_profiles')
          .update({
            'avatar_id': avatarDescriptor,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', kidId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Lấy trang phục đã trang bị của bé
  static Future<({String hat, String glasses})> fetchMascotGear(String kidId) async {
    if (!SupabaseService.isInitialized) {
      return (hat: 'Mũ Thám Tử', glasses: 'Kính Tri Thức');
    }
    try {
      final data = await SupabaseService.client!
          .from('kid_profiles')
          .select('avatar_id')
          .eq('id', kidId)
          .maybeSingle();

      final descriptor = data?['avatar_id'] as String?;
      if (descriptor != null && descriptor.contains('|')) {
        final parts = descriptor.split('|');
        return (hat: parts[0], glasses: parts[1]);
      }
      return (hat: 'Mũ Thám Tử', glasses: 'Kính Tri Thức');
    } catch (_) {
      return (hat: 'Mũ Thám Tử', glasses: 'Kính Tri Thức');
    }
  }
}
