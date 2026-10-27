import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/engine_config.dart';
import '../models/learning_modules.dart';
import '../repositories/engine_registry.dart';
import 'engine_contracts.dart';
import 'engine_http.dart';

class HttpCodeEngine implements CodeExecutionEngine {
  HttpCodeEngine(
    this.selection, {
    http.Client? client,
    Future<void> Function(Duration)? wait,
  }) : transport = EngineHttp(selection, client: client),
       wait = wait ?? ((duration) => Future<void>.delayed(duration));
  final EngineSelection selection;
  final EngineHttp transport;
  final Future<void> Function(Duration) wait;
  @override
  Future<ExecutionResult> execute(CodeRequest request) async {
    final config = selection.config;
    final secret = selection.credential;
    final headers = <String, String>{
      if (secret != null)
        (config.provider == EngineProvider.judge0
            ? 'X-Auth-Token'
            : 'Authorization'): config.provider == EngineProvider.judge0
            ? secret
            : 'Bearer $secret',
    };
    if (config.provider == EngineProvider.docker) {
      final result = await transport.json(
        'POST',
        config.endpoint,
        headers: headers,
        body: {
          'source': request.source,
          'language': request.language,
          'stdin': request.stdin,
          'limits': {'cpuSeconds': 2, 'memoryMb': 128, 'network': false},
        },
      );
      try {
        return ExecutionResult(
          stdout: result['stdout'] as String? ?? '',
          stderr: result['stderr'] as String? ?? '',
          error: result['error'] as String?,
          exitCode: result['exitCode'] as int?,
        );
      } catch (_) {
        throw const EngineFailure(
          'Dịch vụ chạy mã trả về kết quả chưa đọc được. Hãy thử lại hoặc đổi kết nối.',
        );
      }
    }
    if (config.provider != EngineProvider.judge0 ||
        request.judge0LanguageId == null) {
      throw const EngineFailure(
        'Nhập language ID tương ứng với ngôn ngữ trên server Judge0 của bạn.',
      );
    }
    final submission = await transport.json(
      'POST',
      config.endpoint.replace(
        queryParameters: {'base64_encoded': 'true', 'wait': 'false'},
      ),
      headers: headers,
      body: {
        'source_code': base64Encode(utf8.encode(request.source)),
        'stdin': base64Encode(utf8.encode(request.stdin)),
        'language_id': request.judge0LanguageId,
        'cpu_time_limit': 2,
        'memory_limit': 128000,
        'enable_network': false,
      },
    );
    final token = submission['token'];
    if (token is! String || !RegExp(r'^[a-zA-Z0-9-]{1,128}$').hasMatch(token)) {
      throw const EngineFailure(
        'Chưa nhận được mã lượt chạy từ dịch vụ. Hãy thử lại sau ít phút.',
      );
    }
    final pollUri = config.endpoint.replace(
      path: '${config.endpoint.path.replaceFirst(RegExp(r'/$'), '')}/$token',
      queryParameters: {'base64_encoded': 'true'},
    );
    for (var attempt = 0; attempt < 120; attempt++) {
      await wait(const Duration(milliseconds: 500));
      final result = await transport.json('GET', pollUri, headers: headers);
      try {
        final status = (result['status'] as Map)['id'] as int;
        if (status < 3) continue;
        String decode(String key) => result[key] == null
            ? ''
            : utf8.decode(base64Decode(result[key] as String));
        return ExecutionResult(
          stdout: decode('stdout'),
          stderr: decode('stderr'),
          error: status == 3
              ? null
              : [
                  decode('compile_output'),
                  decode('message'),
                  (result['status'] as Map)['description'] as String? ??
                      'Execution failed',
                ].where((text) => text.isNotEmpty).join('\n'),
          exitCode: result['exit_code'] as int?,
        );
      } on EngineFailure {
        rethrow;
      } catch (_) {
        throw const EngineFailure(
          'Kết quả từ Judge0 chưa đọc được. Hãy thử lại hoặc kiểm tra kết nối đã chọn.',
        );
      }
    }
    throw const EngineFailure(
      'Chương trình chưa hoàn tất trong thời gian chờ. Bạn có thể thử lại hoặc rút gọn chương trình.',
    );
  }

  @override
  void dispose() => transport.dispose();
}
