import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';

class SupportRepository {
  SupportRepository({SupabaseClient? client}) : _injectedClient = client;
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client {
    final client = _injectedClient ?? SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Cần đăng nhập để dùng hỗ trợ.');
    }
    return client;
  }

  static String? validateMessage(String? value) {
    final length = (value ?? '').trim().runes.length;
    return length < 5 || length > 2000
        ? 'Nội dung cần từ 5 đến 2000 ký tự.'
        : null;
  }

  Future<List<Map<String, dynamic>>> fetch({
    bool admin = false,
    String? orderId,
    int page = 0,
  }) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final client = _client;
    var query = client.from('support_requests').select();
    if (!admin) query = query.eq('parent_id', client.auth.currentUser!.id);
    if (orderId != null) query = query.eq('order_id', orderId);
    return await query
        .order('status')
        .order('created_at', ascending: false)
        .order('id')
        .range(page * 20, page * 20 + 19);
  }

  Future<void> request({
    required String message,
    required String requestId,
    required String parentToken,
    String? orderId,
  }) async {
    if (validateMessage(message) != null || parentToken.isEmpty) {
      throw ArgumentError('Cần nội dung hợp lệ và mở cổng phụ huynh.');
    }
    final id = await _client.rpc(
      'request_support',
      params: {
        'p_order': orderId,
        'p_message': message.trim(),
        'p_key': requestId,
        'p_token': parentToken,
      },
    );
    if (id is! String || id.isEmpty) throw StateError('Chưa xác nhận yêu cầu.');
  }

  Future<void> resolve(String id, String reply) async {
    if (validateMessage(reply) != null) {
      throw ArgumentError('Phản hồi không hợp lệ.');
    }
    await _client.rpc(
      'resolve_support',
      params: {'p_id': id, 'p_reply': reply.trim()},
    );
  }
}
