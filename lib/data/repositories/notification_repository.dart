import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/family_notification.dart';

class NotificationRepository {
  NotificationRepository({SupabaseClient? client}) : _injectedClient = client;
  final SupabaseClient? _injectedClient;

  SupabaseClient get _client {
    final client = _injectedClient ?? SupabaseService.client;
    if (client == null || client.auth.currentUser == null) {
      throw StateError('Cần đăng nhập để xem thông báo.');
    }
    return client;
  }

  Future<List<FamilyNotification>> fetch({int page = 0}) async {
    if (page < 0) throw ArgumentError.value(page, 'page');
    final client = _client;
    final rows = await client
        .from('notifications')
        .select('id,title,body,created_at,read_at')
        .eq('parent_id', client.auth.currentUser!.id)
        .order('created_at', ascending: false)
        .order('id')
        .range(page * 20, page * 20 + 19);
    return rows.map(FamilyNotification.fromMap).toList();
  }

  Future<void> markRead(String id) async {
    final client = _client;
    // Returning the row confirms that RLS allowed the update. Zero rows must
    // not be presented as a successful read acknowledgement.
    await client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('parent_id', client.auth.currentUser!.id)
        .eq('id', id)
        .select('id')
        .single();
  }
}
