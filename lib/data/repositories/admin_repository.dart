import '../../core/supabase/supabase_service.dart';
import '../models/subscription_model.dart';

class AdminParentUser {
  final String id;
  final String email;
  final DateTime createdAt;
  final SubscriptionModel subscription;
  final int kidCount;

  AdminParentUser({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.subscription,
    this.kidCount = 0,
  });
}

class AdminRepository {
  /// Lấy danh sách toàn bộ phụ huynh và gói subscription của họ
  static Future<List<AdminParentUser>> fetchAllParentsWithSubscriptions({
    String? searchQuery,
    SubscriptionTier? tierFilter,
  }) async {
    final client = SupabaseService.client;
    if (client == null) {
      // Mock data cho Admin khi test offline hoặc chưa có kết nối
      return [
        AdminParentUser(
          id: 'a0000000-0000-0000-0000-000000000001',
          email: 'phuhuynh@mathlingo.vn',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          subscription: SubscriptionModel(
            id: 'sub_1',
            parentId: 'a0000000-0000-0000-0000-000000000001',
            tier: SubscriptionTier.plus,
            maxKids: 3,
            startDate: DateTime.now().subtract(const Duration(days: 30)),
          ),
          kidCount: 3,
        ),
        AdminParentUser(
          id: 'a0000000-0000-0000-0000-000000000002',
          email: 'parent.demo@mathlingo.vn',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          subscription: SubscriptionModel(
            id: 'sub_2',
            parentId: 'a0000000-0000-0000-0000-000000000002',
            tier: SubscriptionTier.basic,
            maxKids: 1,
            startDate: DateTime.now().subtract(const Duration(days: 10)),
          ),
          kidCount: 1,
        ),
      ];
    }

    try {
      // Truy vấn danh sách parents kèm subscriptions và kid_profiles
      var query = client
          .from('parents')
          .select('id, email, created_at, subscriptions(*), kid_profiles(id)')
          .order('created_at', ascending: false);

      final List<dynamic> data = await query;

      final results = data.map<AdminParentUser>((item) {
        final subsList = item['subscriptions'];
        final subMap = (subsList is List && subsList.isNotEmpty)
            ? subsList.first as Map<String, dynamic>
            : (subsList is Map<String, dynamic> ? subsList : null);

        final subscription = subMap != null
            ? SubscriptionModel.fromMap(subMap)
            : SubscriptionModel.defaultBasic(item['id']);

        final kids = item['kid_profiles'];
        final kidCount = (kids is List) ? kids.length : 0;

        return AdminParentUser(
          id: item['id']?.toString() ?? '',
          email: item['email']?.toString() ?? 'Không có email',
          createdAt: DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now(),
          subscription: subscription,
          kidCount: kidCount,
        );
      }).toList();

      // Áp dụng bộ lọc bộ nhớ nếu có
      return results.where((u) {
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.toLowerCase().trim();
          if (!u.email.toLowerCase().contains(q) && !u.id.toLowerCase().contains(q)) {
            return false;
          }
        }
        if (tierFilter != null) {
          if (u.subscription.tier != tierFilter) return false;
        }
        return true;
      }).toList();
    } catch (e) {
      // Fallback danh sách mẫu nếu chưa cấu hình RLS Admin trên Cloud
      return [
        AdminParentUser(
          id: 'a0000000-0000-0000-0000-000000000001',
          email: 'phuhuynh@mathlingo.vn',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          subscription: SubscriptionModel(
            id: 'sub_1',
            parentId: 'a0000000-0000-0000-0000-000000000001',
            tier: SubscriptionTier.plus,
            maxKids: 3,
            startDate: DateTime.now().subtract(const Duration(days: 30)),
          ),
          kidCount: 3,
        ),
        AdminParentUser(
          id: 'a0000000-0000-0000-0000-000000000002',
          email: 'parent.demo@mathlingo.vn',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          subscription: SubscriptionModel(
            id: 'sub_2',
            parentId: 'a0000000-0000-0000-0000-000000000002',
            tier: SubscriptionTier.basic,
            maxKids: 1,
            startDate: DateTime.now().subtract(const Duration(days: 10)),
          ),
          kidCount: 1,
        ),
      ];
    }
  }
}
