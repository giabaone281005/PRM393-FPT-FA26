import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_service.dart';
import '../models/wrong_answer_record.dart';

class WrongAnswerCloudRepository {
  static SupabaseClient _client(SupabaseClient? client) =>
      client ??
      SupabaseService.client ??
      (throw StateError('Chưa kết nối máy chủ.'));

  static Future<List<WrongAnswerRecord>> fetch(
    String kid, {
    String? lessonId,
    SupabaseClient? client,
  }) async {
    final records = <WrongAnswerRecord>[];
    for (var page = 0; ; page++) {
      final rows = await _client(client).rpc(
        'wrong_answer_history',
        params: {'p_kid': kid, 'p_lesson': lessonId, 'p_page': page},
      ) as List;
      records.addAll(
        rows.map(
          (row) =>
              WrongAnswerRecord.fromMap(Map<String, dynamic>.from(row as Map)),
        ),
      );
      if (rows.length < 100) return records;
    }
  }

  static Future<int> update(
    String kid,
    String action, {
    String? question,
    String? lessonId,
    SupabaseClient? client,
  }) async {
    final changed = await _client(client).rpc(
      'set_wrong_answer_review',
      params: {
        'p_kid': kid,
        'p_question': question,
        'p_action': action,
        'p_lesson': lessonId,
      },
    ) as int;
    if (question != null && changed == 0) {
      throw StateError('Câu hỏi đã thay đổi. Vui lòng tải lại danh sách.');
    }
    return changed;
  }
}
