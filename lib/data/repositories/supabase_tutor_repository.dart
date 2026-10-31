import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../engines/engine_contracts.dart';
import '../models/learning_modules.dart';
import 'engine_registry.dart';

/// The shared provider key stays in Edge Function secrets, never on the device.
class SupabaseTutorRepository implements AiEngine {
  SupabaseTutorRepository({
    required this.client,
    required this.url,
    required this.publishableKey,
    required this.owner,
    http.Client? transport,
  }) : _http = transport ?? http.Client();

  final SupabaseClient client;
  final String url, publishableKey, owner;
  final http.Client _http;
  bool _disposed = false;

  void _checkAccount() {
    if (_disposed ||
        client.auth.currentUser?.id != owner ||
        client.auth.currentSession == null) {
      throw const EngineFailure('Hãy đăng nhập lại để trò chuyện với trợ lý.');
    }
  }

  @override
  Future<TutorReply> respond(TutorRequest request) async {
    try {
      return await _respond(request);
    } on EngineFailure {
      rethrow;
    } on TimeoutException {
      throw const EngineFailure('Trợ lý phản hồi quá lâu. Bạn có thể thử lại.');
    } catch (_) {
      throw const EngineFailure(
        'Chưa kết nối được trợ lý. Kiểm tra mạng rồi thử lại nhé.',
      );
    }
  }

  Future<TutorReply> _respond(
    TutorRequest request, {
    bool refreshed = false,
  }) async {
    _checkAccount();
    final payload = jsonEncode({
      'messages': request.messages.map((message) => message.toJson()).toList(),
      if (request.canvas != null) 'canvas': request.canvas!.toJson(),
    });
    if (utf8.encode(payload).length > 300000) {
      throw const EngineFailure(
        'Cuộc trò chuyện hoặc bảng vẽ quá lớn. Hãy bắt đầu câu hỏi mới.',
      );
    }
    final outgoing =
        http.Request('POST', Uri.parse('$url/functions/v1/tutor-chat'))
          ..followRedirects = false
          ..headers.addAll({
            'apikey': publishableKey,
            'Authorization':
                'Bearer ${client.auth.currentSession!.accessToken}',
            'Content-Type': 'application/json',
          })
          ..body = payload;
    final response = await _http
        .send(outgoing)
        .timeout(const Duration(seconds: 45));
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 45),
    )) {
      if (bytes.length + chunk.length > 1048576) {
        throw const EngineFailure(
          'Phản hồi quá lớn. Hãy thử câu hỏi ngắn hơn.',
        );
      }
      bytes.addAll(chunk);
    }
    _checkAccount();
    if (response.statusCode == 401 && !refreshed) {
      await client.auth.refreshSession();
      _checkAccount();
      return _respond(request, refreshed: true);
    }
    if (response.statusCode != 200) {
      throw EngineFailure(switch (response.statusCode) {
        401 => 'Phiên đăng nhập hết hạn. Hãy đăng nhập lại để hỏi trợ lý.',
        403 => 'Tài khoản hiện chưa thể sử dụng trợ lý.',
        429 => 'Trợ lý đang nhận nhiều câu hỏi. Chờ một chút rồi thử lại nhé.',
        _ => 'Trợ lý tạm thời chưa phản hồi. Bạn có thể thử lại sau.',
      });
    }
    final data = jsonDecode(utf8.decode(bytes));
    final text = data is Map ? data['text'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw const EngineFailure(
        'Chưa nhận được câu trả lời hợp lệ. Hãy thử lại nhé.',
      );
    }
    return TutorReply(text);
  }

  @override
  void dispose() {
    _disposed = true;
    _http.close();
  }
}
