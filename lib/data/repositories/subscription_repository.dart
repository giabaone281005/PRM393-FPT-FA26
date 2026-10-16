import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_service.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  /// Lấy gói dịch vụ hiện tại của phụ huynh
  static Future<SubscriptionModel> fetchCurrentSubscription({String? parentId}) async {
    final client = SupabaseService.client;
    final uid = parentId ?? SupabaseService.currentUser?.id;

    if (client == null || uid == null) {
      return SubscriptionModel.defaultBasic(uid ?? 'offline_user');
    }

    try {
      final res = await client
          .from('subscriptions')
          .select()
          .eq('parent_id', uid)
          .maybeSingle();

      if (res != null) {
        return SubscriptionModel.fromMap(res);
      }
      return SubscriptionModel.defaultBasic(uid);
    } catch (e) {
      return SubscriptionModel.defaultBasic(uid);
    }
  }

  /// Kiểm tra xem user hiện tại có phải là Admin hay không
  static Future<bool> checkIfAdmin() async {
    final client = SupabaseService.client;
    final uid = SupabaseService.currentUser?.id;
    final email = SupabaseService.currentUser?.email;

    // Hardcode fallback cho email admin demo
    if (email == 'admin@mathlingo.vn') return true;

    if (client == null || uid == null) return false;

    try {
      final res = await client
          .from('user_roles')
          .select()
          .eq('user_id', uid)
          .eq('role', 'admin')
          .maybeSingle();

      return res != null;
    } catch (_) {
      return false;
    }
  }

  /// Nâng cấp hoặc đổi gói (gọi RPC trên Supabase nếu là Admin)
  static Future<({bool success, String? error})> upgradeSubscription({
    required String parentId,
    required SubscriptionTier tier,
    int? durationDays,
    String? notes,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      return (success: false, error: 'Chưa kết nối Supabase Cloud');
    }

    try {
      await client.rpc('admin_upgrade_subscription', params: {
        'target_parent_id': parentId,
        'new_tier': tier.name,
        'duration_days': durationDays,
        'upgrade_notes': notes,
      });
      return (success: true, error: null);
    } on PostgrestException catch (e) {
      return (success: false, error: e.message);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }
}
