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
      // Truy vấn danh sách parents kèm subscriptions và kid_profiles từ Supabase Cloud
      final List<dynamic> parentsData = await client
          .from('parents')
          .select('id, email, created_at')
          .order('created_at', ascending: false);

      // Lấy toàn bộ subscriptions
      List<dynamic> allSubs = [];
      try {
        allSubs = await client.from('subscriptions').select();
      } catch (_) {}

      // Lấy toàn bộ kid_profiles để đếm số bé thật
      List<dynamic> allKids = [];
      try {
        allKids = await client.from('kid_profiles').select('id, parent_id');
      } catch (_) {}

      final results = parentsData.map<AdminParentUser>((item) {
        final parentId = item['id']?.toString() ?? '';
        final subMap = allSubs.cast<Map<String, dynamic>?>().firstWhere(
          (s) => s != null && s['parent_id'] == parentId,
          orElse: () => null,
        );

        final subscription = subMap != null
            ? SubscriptionModel.fromMap(subMap)
            : SubscriptionModel.defaultBasic(parentId);

        final kidCount = allKids.where((k) => k['parent_id'] == parentId).length;

        return AdminParentUser(
          id: parentId,
          email: item['email']?.toString() ?? 'Không có email',
          createdAt: DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now(),
          subscription: subscription,
          kidCount: kidCount,
        );
      }).toList();

      // Áp dụng bộ lọc
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
      return [];
    }
  }
}
