import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/commerce_models.dart';

class DemoPaymentRepository {
  DemoPaymentRepository({SupabaseClient? client}) : _injected = client;
  final SupabaseClient? _injected;
  SupabaseClient get _client => _injected ?? SupabaseService.client!;

  Future<bool> available() async {
    try {
      return await _client.rpc('demo_payment_available') == true;
    } on PostgrestException catch (e) {
      if (['PGRST202', '42883'].contains(e.code)) return false;
      rethrow;
    }
  }

  Future<List<LearningOrder>> history({int page = 0}) async {
    try {
      final rows = await _client
          .from('demo_payment_transactions')
          .select()
          .order('created_at', ascending: false)
          .range(page * 20, page * 20 + 19);
      return rows.map(LearningOrder.fromMap).toList();
    } on PostgrestException catch (e) {
      if (['PGRST205', '42P01'].contains(e.code)) return [];
      rethrow;
    }
  }

  Future<LearningOrder> create({
    required String priceId,
    required String requestId,
    required String parentToken,
  }) async {
    final row = await _client.rpc(
      'create_demo_payment',
      params: {'p_price': priceId, 'p_key': requestId, 'p_token': parentToken},
    );
    return LearningOrder.fromMap(Map<String, dynamic>.from(row as Map));
  }

  Future<LearningOrder> confirm({
    required String transactionId,
    required String parentToken,
  }) async {
    final row = await _client.rpc(
      'confirm_demo_payment',
      params: {'p_transaction': transactionId, 'p_token': parentToken},
    );
    final order = LearningOrder.fromMap(Map<String, dynamic>.from(row as Map));
    if (order.status != 'paid' || !order.isDemo) {
      throw StateError('Hệ thống chưa xác nhận giao dịch mô phỏng.');
    }
    return order;
  }
}
