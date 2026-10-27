import '../models/learning_modules.dart';
import '../repositories/engine_registry.dart';

abstract interface class AiEngine {
  Future<TutorReply> respond(TutorRequest request);
  void dispose();
}

abstract interface class CodeExecutionEngine {
  Future<ExecutionResult> execute(CodeRequest request);
  void dispose();
}

typedef AiEngineFactory = AiEngine Function(EngineSelection selection);
typedef CodeEngineFactory = CodeExecutionEngine Function(
  EngineSelection selection,
);

/// Host-injected bridge for Pyodide/WebView/worker. No code is evaluated by Dart.
typedef EmbeddedCodeRunner = Future<ExecutionResult> Function(
  CodeRequest request,
);
