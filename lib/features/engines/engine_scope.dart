import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../data/engines/engine_contracts.dart';
import '../../data/models/learning_modules.dart';
import '../../data/repositories/engine_registry.dart';
import '../../data/repositories/engine_runtime.dart';
import '../../data/repositories/engine_storage.dart';
import '../../home_chat_box.dart';
import '../account/cloud_account_page.dart';

class EngineScope extends InheritedNotifier<EngineRegistry> {
  EngineScope({super.key, required this.runtime, required super.child})
    : super(notifier: runtime.registry);
  final EngineRuntime runtime;
  static EngineScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EngineScope>();
  ChatResponder? get chatResponder {
    if (!runtime.registry.loaded || !runtime.hasTutor) {
      return null;
    }
    return (messages) async => (await runtime.respond(
      TutorRequest(
        messages: messages
            .map(
              (message) => TutorMessage(
                message.fromLearner ? TutorRole.user : TutorRole.assistant,
                message.text,
              ),
            )
            .toList(),
      ),
    )).text;
  }

  CanvasChatResponder? get canvasChatResponder {
    if (chatResponder == null) return null;
    return (messages, canvas) async => (await runtime.respond(
      TutorRequest(
        messages: messages
            .map(
              (message) => TutorMessage(
                message.fromLearner ? TutorRole.user : TutorRole.assistant,
                message.text,
              ),
            )
            .toList(),
        canvas: canvas,
      ),
    )).text;
  }
}

/// Leaves the existing LearnApp/CloudScope intact; switches device credentials
/// with the authenticated account and closes outstanding work on account change.
class EngineHost extends StatefulWidget {
  const EngineHost({super.key, required this.child, this.createDefaultTutor});
  final Widget child;
  final AiEngine Function(String account)? createDefaultTutor;
  @override
  State<EngineHost> createState() => _EngineHostState();
}

class _EngineHostState extends State<EngineHost> {
  String? _account;
  EngineRuntime? _runtime;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cloud = CloudScope.maybeOf(context);
    final account = cloud == null ? 'device' : cloud.userId ?? 'signed-out';
    if (account == _account) return;
    _runtime?.dispose();
    _runtime?.registry.dispose();
    _account = account;
    final registry = EngineRegistry(SecureEngineStorage(account));
    _runtime = EngineRuntime(
      registry,
      createDefaultTutor:
          cloud?.signedIn == true && widget.createDefaultTutor != null
          ? () => widget.createDefaultTutor!(account)
          : null,
    );
    unawaited(registry.initialize());
  }

  @override
  void dispose() {
    _runtime?.dispose();
    _runtime?.registry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      EngineScope(runtime: _runtime!, child: widget.child);
}
