enum EngineKind { tutor, code }

enum EngineProvider {
  openai,
  anthropic,
  ollama,
  koji,
  docker,
  judge0,
  pyodide,
  gemini,
}

extension EngineProviderKind on EngineProvider {
  EngineKind get kind => switch (this) {
    EngineProvider.openai ||
    EngineProvider.gemini ||
    EngineProvider.anthropic ||
    EngineProvider.ollama ||
    EngineProvider.koji => EngineKind.tutor,
    _ => EngineKind.code,
  };
}

/// Public metadata only. Credentials are deliberately absent from this model.
class EngineConfig {
  EngineConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.endpoint,
    this.model = '',
    this.timeoutSeconds = 60,
  }) {
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(id) ||
        name.trim().isEmpty ||
        name.length > 80 ||
        model.length > 160 ||
        timeoutSeconds < 1 ||
        timeoutSeconds > 180) {
      throw const EngineConfigException(
        'Tên kết nối hoặc cấu hình chưa hợp lệ. Kiểm tra các ô đã nhập rồi thử lại.',
      );
    }
    if (provider == EngineProvider.pyodide) {
      if (endpoint.toString() != 'embedded:pyodide') {
        throw const EngineConfigException(
          'Pyodide dùng endpoint embedded:pyodide và cần bridge được tích hợp trong app.',
        );
      }
    } else {
      final local =
          provider == EngineProvider.ollama &&
          ['localhost', '127.0.0.1', '::1', '10.0.2.2'].contains(endpoint.host);
      if (endpoint.host.isEmpty ||
          endpoint.userInfo.isNotEmpty ||
          endpoint.hasQuery ||
          endpoint.hasFragment ||
          (endpoint.scheme != 'https' &&
              !(local && endpoint.scheme == 'http'))) {
        throw const EngineConfigException(
          'Dùng URL HTTPS đầy đủ, không chứa khóa hoặc query.',
        );
      }
    }
    if (provider.kind == EngineKind.tutor && model.trim().isEmpty) {
      throw const EngineConfigException(
        'Nhập model mà tài khoản của bạn hỗ trợ.',
      );
    }
    if (provider == EngineProvider.gemini &&
        (endpoint.host != 'generativelanguage.googleapis.com' ||
            ![
              '/v1beta',
              '/v1',
            ].contains(endpoint.path.replaceFirst(RegExp(r'/+$'), '')) ||
            !RegExp(r'^gemini-[a-z0-9][a-z0-9.\-]{0,130}$').hasMatch(model))) {
      throw const EngineConfigException(
        'Gemini dùng endpoint chính thức https://generativelanguage.googleapis.com/v1beta và tên model Gemini hợp lệ.',
      );
    }
  }

  final String id, name, model;
  final EngineProvider provider;
  final Uri endpoint;
  final int timeoutSeconds;
  EngineKind get kind => provider.kind;
  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'provider': provider.name,
    'endpoint': endpoint.toString(),
    'model': model,
    'timeoutSeconds': timeoutSeconds,
  };
  factory EngineConfig.fromJson(Map<String, dynamic> value) => EngineConfig(
    id: value['id'] as String,
    name: value['name'] as String,
    provider: EngineProvider.values.byName(value['provider'] as String),
    endpoint: Uri.parse(value['endpoint'] as String),
    model: value['model'] as String,
    timeoutSeconds: value['timeoutSeconds'] as int,
  );
}

class EngineConfigException extends FormatException {
  const EngineConfigException(super.message);
}
