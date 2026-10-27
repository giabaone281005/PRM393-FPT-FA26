import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_failure.dart';

class LearningApiFailure extends AppFailure {
  const LearningApiFailure(this.code, super.message);
  final String code;
}

abstract class LearningRepository {
  Future<Map<String, dynamic>?> profile(String owner, String id);
  Future<Map<String, dynamic>> catalog(String owner);
  Future<Map<String, dynamic>> mutate(
    String owner,
    String operation,
    String kind,
    Map<String, dynamic> payload,
  );
  Future<Map<String, dynamic>> attempt(
    String owner,
    String operation,
    Map<String, dynamic> payload,
  );
  Future<Map<String, dynamic>> progress(String owner, String profileId);
}

class SupabaseLearningRepository implements LearningRepository {
  SupabaseLearningRepository({
    required this.client,
    required this.url,
    required this.publishableKey,
    http.Client? transport,
  }) : _http = transport ?? http.Client();
  final SupabaseClient client;
  final String url, publishableKey;
  final http.Client _http;

  Future<dynamic> _request(
    String owner,
    String path, {
    Map<String, dynamic>? body,
    bool refreshed = false,
  }) async {
    if (client.auth.currentUser?.id != owner ||
        client.auth.currentSession == null) {
      throw const LearningApiFailure(
        'authentication_required',
        'Đăng nhập lại để tiếp tục đồng bộ. Tiến độ trên máy vẫn được giữ.',
      );
    }
    // Bind every request to the captured owner/token. An account switch must
    // never send an old user's queued payload with a new user's credentials.
    final token = client.auth.currentSession!.accessToken;
    final request =
        http.Request(body == null ? 'GET' : 'POST', Uri.parse('$url$path'))
          ..followRedirects = false
          ..headers.addAll({
            'apikey': publishableKey,
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          });
    if (body != null) request.body = jsonEncode(body);
    final response = await _http
        .send(request)
        .timeout(const Duration(seconds: 20));
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 20),
    )) {
      if (bytes.length + chunk.length > 2097152) {
        throw const LearningApiFailure(
          'response_limit',
          'Dữ liệu đồng bộ quá lớn. Hãy thử lại hoặc cập nhật ứng dụng.',
        );
      }
      bytes.addAll(chunk);
    }
    if (response.statusCode == 401 &&
        !refreshed &&
        client.auth.currentUser?.id == owner) {
      await client.auth.refreshSession();
      return _request(owner, path, body: body, refreshed: true);
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const LearningApiFailure(
        'server_unavailable',
        'Chưa đọc được phản hồi đồng bộ. Tiến độ trên máy vẫn được giữ.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = data is Map && data['error'] is Map
          ? data['error']['code'] as String?
          : null;
      throw LearningApiFailure(code ?? 'server_unavailable', switch (code) {
        'authentication_required' =>
          'Phiên đăng nhập đã hết hạn. Đăng nhập lại để đồng bộ.',
        'access_denied' || 'account_unavailable' => 'Tài khoản chưa được phép đồng bộ dữ liệu này. Tiến độ trên máy vẫn được giữ.',
        'revision_conflict' || 'operation_mismatch' => 'Dữ liệu đã thay đổi trên máy khác. Bản trên thiết bị vẫn được giữ; tải lại thông tin trước khi đồng bộ tiếp.',
        'activities_incomplete' => 'Còn hoạt động chưa được máy chủ xác nhận. Hoàn thành các bước trong bài rồi thử đồng bộ lại.',
        'lesson_unavailable' ||
        'unsupported_lesson_version' ||
        'unsupported_activity' => 'Phiên bản bài học này chưa thể đồng bộ. Tiến độ vẫn được giữ; hãy cập nhật ứng dụng.',
        'session_closed' =>
          'Phiên học đã kết thúc trên máy chủ. Hãy mở một phiên học mới.',
        _ => 'Chưa đồng bộ được với máy chủ. Tiến độ trên thiết bị vẫn được giữ và sẽ thử lại.',
      });
    }
    return data;
  }

  Future<Map<String, dynamic>> _api(
    String owner,
    String route, {
    Map<String, dynamic>? body,
  }) async => Map<String, dynamic>.from(
    await _request(owner, '/functions/v1/learning-api/$route', body: body)
        as Map,
  );
  @override
  Future<Map<String, dynamic>?> profile(String owner, String id) async {
    final rows = await _request(
      owner,
      '/rest/v1/learner_profiles?select=*&id=eq.$id&owner_user_id=eq.$owner&deleted_at=is.null',
    ) as List;
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.single as Map);
  }

  @override
  Future<Map<String, dynamic>> catalog(String owner) =>
      _api(owner, 'catalog?app_version=1.3.1');
  @override
  Future<Map<String, dynamic>> mutate(
    String owner,
    String operation,
    String kind,
    Map<String, dynamic> payload,
  ) => _api(
    owner,
    'mutate',
    body: {
      'operation_id': operation,
      'operation_type': kind,
      'payload': payload,
    },
  );
  @override
  Future<Map<String, dynamic>> attempt(
    String owner,
    String operation,
    Map<String, dynamic> payload,
  ) => _api(
    owner,
    'attempts',
    body: {'operation_id': operation, 'payload': payload},
  );
  @override
  Future<Map<String, dynamic>> progress(String owner, String profileId) =>
      _api(owner, 'progress?profile_id=$profileId');
  void dispose() => _http.close();
}
