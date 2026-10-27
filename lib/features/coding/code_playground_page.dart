import 'package:flutter/material.dart';

import '../../app_layout.dart';
import '../../data/models/engine_config.dart';
import '../../data/models/learning_modules.dart';
import '../../data/models/app_failure.dart';
import '../../data/repositories/engine_registry.dart';
import '../../data/repositories/engine_runtime.dart';
import 'code_editor.dart';
import '../shared/app_notice.dart';

class CodePlaygroundPage extends StatefulWidget {
  const CodePlaygroundPage({super.key, required this.runtime});
  final EngineRuntime runtime;
  @override
  State<CodePlaygroundPage> createState() => _CodePlaygroundPageState();
}

class _CodePlaygroundPageState extends State<CodePlaygroundPage> {
  final _source = CodeEditingController(text: projectTemplates.first.source);
  final _stdin = TextEditingController(), _languageId = TextEditingController();
  String _language = 'python';
  String? _error;
  ExecutionResult? _result;
  String? _resultEngineName;
  bool _busy = false;
  @override
  void dispose() {
    _source.dispose();
    _stdin.dispose();
    _languageId.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _resultEngineName = widget.runtime.registry.active(EngineKind.code)?.name;
    });
    try {
      final result = await widget.runtime.execute(
        CodeRequest(
          source: _source.text,
          language: _language,
          stdin: _stdin.text,
          judge0LanguageId: int.tryParse(_languageId.text),
        ),
      );
      if (mounted) setState(() => _result = result);
    } on EngineFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ArgumentError {
      if (mounted) {
        setState(
          () => _error = 'Chương trình hoặc đầu vào chưa hợp lệ. Kiểm tra nội dung và ngôn ngữ rồi thử lại.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa hoàn tất chạy chương trình. Bạn có thể thử lại; bản nháp vẫn ở đây.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.runtime.registry,
    builder: (context, _) {
      final engine = widget.runtime.registry.active(EngineKind.code);
      return Scaffold(
        appBar: const AppPageHeader(title: Text('Thử một ý tưởng bằng mã')),
        body: AppPageBody(
          children: [
            Text(
              engine == null
                  ? 'Chọn engine chạy mã trong cài đặt để thực thi.'
                  : 'Engine: ${engine.name}',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final template in projectTemplates)
                  ActionChip(
                    label: Text(template.title),
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _source.text = template.source;
                            _language = template.language;
                            _result = null;
                          }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_language),
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Ngôn ngữ'),
              items: const [
                DropdownMenuItem(value: 'python', child: Text('Python')),
                DropdownMenuItem(
                  value: 'javascript',
                  child: Text('JavaScript'),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _language = value!),
            ),
            const SizedBox(height: 16),
            CodeEditor(controller: _source, enabled: !_busy),
            TextField(
              controller: _stdin,
              enabled: !_busy,
              maxLength: 10000,
              decoration: const InputDecoration(
                labelText: 'Đầu vào stdin (nếu cần)',
              ),
            ),
            if (engine?.provider == EngineProvider.judge0)
              TextField(
                controller: _languageId,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Language ID của server Judge0',
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy || engine == null ? null : _run,
              icon: const Icon(Icons.play_arrow),
              label: Text(_busy ? 'Đang chạy…' : 'Chạy chương trình'),
            ),
            if (_error != null)
              AppNotice(message: _error!, kind: NoticeKind.error),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text(
                'Kết quả lần chạy gần nhất',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (_resultEngineName != null)
                Text('Chạy bằng $_resultEngineName'),
              AppNotice(
                message:
                    _result!.error != null ||
                        (_result!.exitCode != null && _result!.exitCode != 0)
                    ? 'Chương trình chưa hoàn tất. Xem chi tiết bên dưới để biết thêm.'
                    : _result!.exitCode == 0
                    ? 'Chương trình đã chạy xong.'
                    : 'Đã nhận kết quả từ dịch vụ chạy mã.',
                kind:
                    _result!.error != null ||
                        (_result!.exitCode != null && _result!.exitCode != 0)
                    ? NoticeKind.error
                    : _result!.exitCode == 0
                    ? NoticeKind.success
                    : NoticeKind.info,
              ),
              SelectableText(
                'stdout\n${_result!.stdout}\nstderr\n${_result!.stderr}'
                '${_result!.error == null ? '' : '\n${_result!.error}'}\nexit: ${_result!.exitCode ?? '—'}',
                style: const TextStyle(
                  fontFamily: 'SourceCodePro',
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Bản nháp ở màn hình này chưa được lưu. Chương trình chỉ chạy khi bạn bấm Chạy.',
            ),
          ],
        ),
      );
    },
  );
}
