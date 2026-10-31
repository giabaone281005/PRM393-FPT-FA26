import 'dart:async';

import '../engines/engine_contracts.dart';
import '../engines/http_ai_engine.dart';
import '../engines/http_code_engine.dart';
import '../models/engine_config.dart';
import '../models/learning_modules.dart';
import 'engine_registry.dart';

/// Resolve at request time: switching engines affects the next request without
/// rebuilding the app. In-flight work keeps its original engine and credential.
class EngineRuntime {
  EngineRuntime(this.registry, {this.createDefaultTutor}) {
    for (final provider in EngineProvider.values) {
      if (provider.kind == EngineKind.tutor) {
        _ai[provider] = (selection) => HttpAiEngine(selection);
      } else if (provider != EngineProvider.pyodide) {
        _code[provider] = (selection) => HttpCodeEngine(selection);
      }
    }
  }
  final EngineRegistry registry;
  final AiEngine Function()? createDefaultTutor;
  bool get hasTutor =>
      registry.active(EngineKind.tutor) != null || createDefaultTutor != null;
  final _ai = <EngineProvider, AiEngineFactory>{};
  final _code = <EngineProvider, CodeEngineFactory>{};
  final _running = <void Function()>{};
  bool _disposed = false;
  bool supports(EngineProvider provider) =>
      _ai.containsKey(provider) || _code.containsKey(provider);
  void registerAiAdapter(EngineProvider provider, AiEngineFactory factory) {
    if (provider.kind != EngineKind.tutor) {
      throw ArgumentError('Không phải AI engine.');
    }
    _ai[provider] = factory;
  }

  void registerCodeAdapter(EngineProvider provider, CodeEngineFactory factory) {
    if (provider.kind != EngineKind.code) {
      throw ArgumentError('Không phải code engine.');
    }
    _code[provider] = factory;
  }

  void attachPyodide(EmbeddedCodeRunner runner) {
    registerCodeAdapter(EngineProvider.pyodide, (_) => _EmbeddedEngine(runner));
  }

  Future<T> _request<T>(
    Future<T> Function() run,
    void Function() close,
    int seconds,
  ) async {
    if (_disposed) {
      close();
      throw const EngineFailure(
        'Phiên kết nối đã kết thúc. Mở lại màn hình để tiếp tục.',
      );
    }
    _running.add(close);
    try {
      final result = await run().timeout(Duration(seconds: seconds));
      if (_disposed) {
        throw const EngineFailure(
          'Tài khoản đang dùng đã thay đổi. Hãy gửi lại yêu cầu trong tài khoản hiện tại.',
        );
      }
      return result;
    } on EngineFailure {
      rethrow;
    } on TimeoutException {
      throw const EngineFailure(
        'Dịch vụ phản hồi quá thời gian chờ. Bạn có thể thử lại.',
      );
    } catch (_) {
      throw const EngineFailure(
        'Dịch vụ chưa hoàn tất yêu cầu. Bạn có thể thử lại.',
      );
    } finally {
      if (_running.remove(close)) close();
    }
  }

  Future<TutorReply> respond(TutorRequest request) {
    if (registry.active(EngineKind.tutor) == null &&
        createDefaultTutor != null) {
      final engine = createDefaultTutor!();
      return _request(() => engine.respond(request), engine.dispose, 60);
    }
    final selection = registry.resolve(EngineKind.tutor);
    final factory = _ai[selection.config.provider];
    if (factory == null) {
      throw const EngineFailure(
        'Kết nối gia sư này chưa khả dụng trên thiết bị. Chọn kết nối khác trong Engine học tập.',
      );
    }
    final engine = factory(selection);
    return _request(
      () => engine.respond(request),
      engine.dispose,
      selection.config.timeoutSeconds,
    );
  }

  Future<ExecutionResult> execute(CodeRequest request) {
    final selection = registry.resolve(EngineKind.code);
    final factory = _code[selection.config.provider];
    if (factory == null) {
      throw const EngineFailure(
        'Chạy mã bằng Pyodide chưa khả dụng trên thiết bị. Chọn kết nối chạy mã khác trong Engine học tập.',
      );
    }
    final engine = factory(selection);
    return _request(
      () => engine.execute(request),
      engine.dispose,
      selection.config.timeoutSeconds,
    );
  }

  void dispose() {
    _disposed = true;
    for (final close in _running.toList()) {
      close();
    }
    _running.clear();
  }
}

class _EmbeddedEngine implements CodeExecutionEngine {
  _EmbeddedEngine(this.runner);
  final EmbeddedCodeRunner runner;
  @override
  Future<ExecutionResult> execute(CodeRequest request) => runner(request);
  @override
  void dispose() {}
}
