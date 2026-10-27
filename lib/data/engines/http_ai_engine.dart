import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/engine_config.dart';
import '../models/learning_modules.dart';
import '../repositories/engine_registry.dart';
import 'engine_contracts.dart';
import 'engine_http.dart';

class HttpAiEngine implements AiEngine {
  HttpAiEngine(this.selection, {http.Client? client})
    : transport = EngineHttp(selection, client: client);
  final EngineSelection selection;
  final EngineHttp transport;
  @override
  Future<TutorReply> respond(TutorRequest request) async {
    if (request.messages.isEmpty ||
        request.messages.length > 60 ||
        request.messages.fold<int>(
              0,
              (count, message) => count + message.text.length,
            ) >
            50000) {
      throw const EngineFailure(
        'Cuộc trò chuyện quá dài. Hãy bắt đầu câu hỏi mới.',
      );
    }
    const system =
        'Bạn là Koji, gia sư hướng dẫn bằng câu hỏi và gợi ý từng bước. '
        'Trả lời bằng ngôn ngữ của người học. Không tự nhận đã xác thực mastery hay cấp XP.';
    final config = selection.config;
    final messages = request.messages
        .map((message) => message.toJson())
        .toList();
    final context = request.canvas == null
        ? ''
        : '\nCanvas (tọa độ 0..1): ${jsonEncode(request.canvas!.toJson())}';
    if (utf8.encode(context).length > 256 * 1024) {
      throw const EngineFailure(
        'Bảng vẽ quá lớn. Hãy xóa bớt nét trước khi gửi.',
      );
    }
    final secret = selection.credential;
    final headers = <String, String>{
      if (secret != null && config.provider != EngineProvider.gemini)
        'Authorization': 'Bearer $secret',
    };
    var endpoint = config.endpoint;
    late final Map<String, Object?> body;
    switch (config.provider) {
      case EngineProvider.gemini:
        if (secret == null || secret.isEmpty) {
          throw const EngineFailure(
            'Thêm API key Gemini trong Engine học tập rồi thử lại.',
          );
        }
        headers['x-goog-api-key'] = secret;
        endpoint = config.endpoint.replace(
          path:
              '${config.endpoint.path.replaceFirst(RegExp(r'/+$'), '')}/models/${config.model}:generateContent',
        );
        body = {
          'systemInstruction': {
            'parts': [
              {'text': system + context},
            ],
          },
          'contents': [
            for (final message in request.messages)
              {
                'role': message.role == TutorRole.assistant ? 'model' : 'user',
                'parts': [
                  {'text': message.text},
                ],
              },
          ],
          'generationConfig': {'maxOutputTokens': 2048},
        };
      case EngineProvider.openai:
        body = {
          'model': config.model,
          'instructions': system + context,
          'input': messages,
          'store': false,
        };
      case EngineProvider.anthropic:
        headers['anthropic-version'] = '2023-06-01';
        body = {
          'model': config.model,
          'system': system + context,
          'messages': messages,
          'max_tokens': 1024,
        };
      case EngineProvider.ollama:
        body = {
          'model': config.model,
          'stream': false,
          'messages': [
            {'role': 'system', 'content': system + context},
            ...messages,
          ],
        };
      case EngineProvider.koji:
        body = {
          'model': config.model,
          'messages': messages,
          'instructions': system,
          if (request.canvas != null) 'canvas': request.canvas!.toJson(),
        };
      default:
        throw const EngineFailure(
          'Kết nối này không hỗ trợ gia sư. Chọn kết nối AI khác trong Engine học tập.',
        );
    }
    final result = await transport.json(
      'POST',
      endpoint,
      body: body,
      headers: headers,
    );
    try {
      final text = switch (config.provider) {
        EngineProvider.gemini =>
          (((result['candidates'] as List).first as Map)['content']['parts']
                  as List)
              .whereType<Map>()
              .where(
                (part) => part['thought'] != true && part['text'] is String,
              )
              .map((part) => part['text'] as String)
              .join('\n'),
        EngineProvider.openai =>
          (result['output'] as List)
              .whereType<Map>()
              .where((item) => item['type'] == 'message')
              .expand((item) => item['content'] as List)
              .whereType<Map>()
              .where((item) => item['type'] == 'output_text')
              .map((item) => item['text'] as String)
              .join('\n'),
        EngineProvider.anthropic =>
          (result['content'] as List)
              .whereType<Map>()
              .where((item) => item['type'] == 'text')
              .map((item) => item['text'] as String)
              .join('\n'),
        EngineProvider.ollama =>
          (result['message'] as Map)['content'] as String,
        _ => result['text'] as String,
      };
      if (text.trim().isEmpty) throw const FormatException();
      return TutorReply(text);
    } catch (_) {
      throw const EngineFailure(
        'Chưa nhận được câu trả lời hợp lệ từ trợ lý. Bạn có thể thử lại hoặc chọn kết nối khác.',
      );
    }
  }

  @override
  void dispose() => transport.dispose();
}
