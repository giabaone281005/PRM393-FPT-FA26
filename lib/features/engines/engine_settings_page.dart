import 'package:flutter/material.dart';

import '../../app_layout.dart';
import '../../app_motion.dart';
import '../../data/models/engine_config.dart';
import '../../data/models/app_failure.dart';
import '../../data/repositories/engine_registry.dart';
import '../../data/repositories/engine_runtime.dart';
import '../coding/code_playground_page.dart';
import '../shared/app_notice.dart';

class EngineSettingsPage extends StatefulWidget {
  const EngineSettingsPage({super.key, required this.runtime});
  final EngineRuntime runtime;
  @override
  State<EngineSettingsPage> createState() => _EngineSettingsPageState();
}

class _EngineSettingsPageState extends State<EngineSettingsPage> {
  bool _busy = false;
  String? _message;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on EngineFailure catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Chưa cập nhật được engine. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit([EngineConfig? config]) {
    Navigator.push(
      context,
      DiscoveryRoute<void>(
        builder: (_) =>
            _EngineEditor(registry: widget.runtime.registry, config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.runtime.registry,
    builder: (context, _) {
      final registry = widget.runtime.registry;
      return Scaffold(
        appBar: const AppPageHeader(title: Text('Engine học tập')),
        body: AppPageBody(
          children: [
            Text(
              'Chọn cách Koji\ncùng bạn khám phá.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'Lưu nhiều kết nối và chuyển đổi bất cứ lúc nào. Khóa chỉ lưu trong bộ nhớ bảo mật của thiết bị, riêng cho tài khoản này.',
            ),
            const SizedBox(height: 24),
            if (!registry.loaded) ...[
              Text(registry.loadError ?? 'Đang tải cấu hình bảo mật…'),
              if (registry.loadError != null)
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(registry.initialize),
                  child: const Text('Tải lại'),
                ),
            ] else ...[
              for (final kind in EngineKind.values) ...[
                Text(
                  kind == EngineKind.tutor ? 'Gia sư AI' : 'Chạy chương trình',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (registry.engines
                    .where((engine) => engine.kind == kind)
                    .isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Chưa có kết nối. Thêm engine để bắt đầu.'),
                  ),
                for (final engine in registry.engines.where(
                  (engine) => engine.kind == kind,
                ))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              engine.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${engine.provider.name}${engine.model.isEmpty ? '' : ' · ${engine.model}'}',
                            ),
                            if (registry.active(kind)?.id == engine.id)
                              const Text('Đang sử dụng'),
                            if (!widget.runtime.supports(engine.provider))
                              const Text(
                                'Pyodide chưa khả dụng trên thiết bị này. Hãy chọn kết nối chạy mã khác.',
                              ),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton(
                                  key: ValueKey('activate-${engine.id}'),
                                  onPressed:
                                      _busy ||
                                          !widget.runtime.supports(
                                            engine.provider,
                                          ) ||
                                          registry.active(kind)?.id == engine.id
                                      ? null
                                      : () => _run(
                                          () => registry.activate(
                                            kind,
                                            engine.id,
                                          ),
                                        ),
                                  child: const Text('Sử dụng'),
                                ),
                                TextButton(
                                  onPressed: _busy ? null : () => _edit(engine),
                                  child: const Text('Chỉnh sửa'),
                                ),
                                TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                          () => registry.remove(engine.id),
                                        ),
                                  child: const Text('Xóa kết nối'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                key: const ValueKey('add-engine'),
                onPressed: _busy ? null : () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Thêm engine'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => Navigator.push(
                        context,
                        DiscoveryRoute<void>(
                          builder: (_) =>
                              CodePlaygroundPage(runtime: widget.runtime),
                        ),
                      ),
                icon: const Icon(Icons.code),
                label: const Text('Thử chạy mã'),
              ),
            ],
            if (_busy) const LinearProgressIndicator(),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: AppNotice(message: _message!, kind: NoticeKind.error),
              ),
          ],
        ),
      );
    },
  );
}

class _EngineEditor extends StatefulWidget {
  const _EngineEditor({required this.registry, this.config});
  final EngineRegistry registry;
  final EngineConfig? config;
  @override
  State<_EngineEditor> createState() => _EngineEditorState();
}

class _EngineEditorState extends State<_EngineEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _endpoint, _model;
  final _credential = TextEditingController();
  late EngineProvider _provider;
  bool _busy = false, _clearCredential = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _name = TextEditingController(text: config?.name);
    _endpoint = TextEditingController(text: config?.endpoint.toString());
    _model = TextEditingController(text: config?.model);
    _provider = config?.provider ?? EngineProvider.koji;
  }

  @override
  void dispose() {
    _name.dispose();
    _endpoint.dispose();
    _model.dispose();
    _credential.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final config = EngineConfig(
        id:
            widget.config?.id ??
            'engine-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        provider: _provider,
        endpoint: Uri.parse(_endpoint.text.trim()),
        model: _model.text.trim(),
        timeoutSeconds: widget.config?.timeoutSeconds ?? 60,
      );
      final secret = _credential.text.isEmpty ? null : _credential.text;
      if (widget.config == null) {
        await widget.registry.register(config, credential: secret);
      } else {
        await widget.registry.update(
          config,
          credential: secret,
          clearCredential: _clearCredential,
        );
      }
      _credential.clear();
      if (mounted) Navigator.pop(context);
    } on EngineConfigException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on FormatException {
      if (mounted) {
        setState(
          () => _error = 'Địa chỉ kết nối chưa hợp lệ. Kiểm tra lại URL và số cổng rồi thử nhé.',
        );
      }
    } on EngineFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa lưu được kết nối. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppPageHeader(title: Text('Cấu hình engine')),
    body: AppPageBody(
      children: [
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Tên kết nối'),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Nhập tên kết nối.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EngineProvider>(
                initialValue: _provider,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Engine'),
                items: [
                  for (final provider in EngineProvider.values)
                    if (widget.config == null ||
                        widget.config!.kind == provider.kind)
                      DropdownMenuItem(
                        value: provider,
                        child: Text(provider.name),
                      ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _provider = value!;
                        if (_provider == EngineProvider.gemini) {
                          _endpoint.text = 'https://generativelanguage.googleapis.com/v1beta';
                          _model.text = 'gemini-3.5-flash-lite';
                          if (_name.text.trim().isEmpty) {
                            _name.text = 'Gemini 3.5 Flash-Lite';
                          }
                        }
                      }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _endpoint,
                enabled: !_busy,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Endpoint đầy đủ',
                  hintText: _provider == EngineProvider.pyodide
                      ? 'embedded:pyodide'
                      : 'https://your-server.example/endpoint',
                ),
                validator: (value) =>
                    value!.trim().isEmpty ? 'Nhập endpoint.' : null,
              ),
              if (_provider.kind == EngineKind.tutor) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model,
                  enabled: !_busy,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Model'),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Nhập model.' : null,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _credential,
                enabled: !_busy && !_clearCredential,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: widget.config == null
                      ? 'Khóa/token (nếu cần)'
                      : 'Khóa mới (bỏ trống để giữ khóa cũ)',
                ),
              ),
              if (widget.config != null &&
                  widget.registry.hasCredential(widget.config!.id))
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Xóa khóa đã lưu'),
                  value: _clearCredential,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                          _clearCredential = value!;
                          _credential.clear();
                        }),
                ),
              const SizedBox(height: 16),
              const Text(
                'Nội dung chat/mã sẽ được gửi tới endpoint bạn chọn. Dùng gateway của bạn và token riêng; khóa nhà cung cấp dùng chung thuộc về backend.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: AppNotice(message: _error!, kind: NoticeKind.error),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Đang lưu…' : 'Lưu kết nối'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
