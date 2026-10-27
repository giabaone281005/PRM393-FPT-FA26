import 'dart:convert';

import 'package:http/http.dart' as http;

import '../repositories/engine_registry.dart';
import '../models/app_failure.dart';

/// Never follows redirects with credentials or exposes response bodies in errors.
class EngineHttp {
  EngineHttp(this.selection, {http.Client? client})
    : client = client ?? http.Client();
  final EngineSelection selection;
  final http.Client client;
  Future<Map<String, dynamic>> json(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    Map<String, String> headers = const {},
  }) async {
    if (uri.origin != selection.config.endpoint.origin) {
      throw const EngineFailure(
        'Engine không được chuyển thông tin tới host khác.',
      );
    }
    final request = http.Request(method, uri)..followRedirects = false;
    request.headers.addAll({'content-type': 'application/json', ...headers});
    if (body != null) request.body = jsonEncode(body);
    try {
      final response = await client.send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw EngineFailure(engineHttpMessage(response.statusCode));
      }
      final bytes = <int>[];
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (bytes.length > 1024 * 1024) {
          throw const EngineFailure('Kết quả engine quá lớn.');
        }
      }
      return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
    } on EngineFailure {
      rethrow;
    } catch (error) {
      throw EngineFailure(
        friendlyError(
          error,
          fallback: 'Dịch vụ trả về kết quả chưa đọc được. Hãy thử lại hoặc kiểm tra kết nối đã chọn.',
        ),
      );
    }
  }

  void dispose() => client.close();
}
