import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/learning_history.dart';

class LearningHistoryRepository {
  LearningHistoryRepository({SupabaseClient? client}) : _injected = client;
  final SupabaseClient? _injected;
  SupabaseClient get _client =>
      _injected ??
      SupabaseService.client ??
      (throw StateError('Cần đăng nhập để xem lịch sử học.'));

  Future<List<LearningHistoryEntry>> fetch(
    String kidId, {
    String? kind,
    String? status,
    int page = 0,
  }) async {
    final data = await _client.rpc(
      'learning_session_history',
      params: {
        'p_kid': kidId,
        'p_kind': kind,
        'p_status': status,
        'p_page': page,
      },
    );
    return (data as List)
        .map(
          (row) => LearningHistoryEntry.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<List<LearningAttempt>> review(String sessionId) async {
    final data = await _client.rpc(
      'learning_session_review',
      params: {'p_session': sessionId},
    );
    return (data['attempts'] as List)
        .map(
          (row) =>
              LearningAttempt.fromMap(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }
}
