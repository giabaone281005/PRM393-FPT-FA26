import 'app_layout.dart';
import 'data/models/learning_modules.dart';
import 'data/models/app_failure.dart';
import 'features/tutor/shared_canvas.dart';

import 'package:flutter/material.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.fromLearner});
  final String text;
  final bool fromLearner;
}

/// Connect a backend here when ready. Credentials belong in that backend.
typedef ChatResponder = Future<String> Function(List<ChatMessage> messages);
typedef CanvasChatResponder = Future<String> Function(
  List<ChatMessage> messages,
  SharedCanvasDocument canvas,
);

class HomeChatBox extends StatefulWidget {
  const HomeChatBox({super.key, this.onSend, this.onCanvasSend});
  final ChatResponder? onSend;
  final CanvasChatResponder? onCanvasSend;
  @override
  State<HomeChatBox> createState() => _HomeChatBoxState();
}

class _HomeChatBoxState extends State<HomeChatBox> {
  final _input = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _busy = false;
  String? _error;
  bool _showCanvas = false;
  SharedCanvasDocument _canvas = SharedCanvasDocument();
  bool get _connected => widget.onSend != null || widget.onCanvasSend != null;
  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy || !_connected) return;
    final question = ChatMessage(text: text, fromLearner: true);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final messages = List<ChatMessage>.unmodifiable([..._messages, question]);
      final response = _showCanvas && widget.onCanvasSend != null
          ? await widget.onCanvasSend!(messages, _canvas)
          : widget.onSend != null
          ? await widget.onSend!(messages)
          : await widget.onCanvasSend!(messages, SharedCanvasDocument());
      if (response.trim().isEmpty) throw StateError('Empty response');
      if (!mounted) return;
      setState(() {
        _messages.addAll([
          question,
          ChatMessage(text: response, fromLearner: false),
        ]);
        _input.clear();
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              '${friendlyError(error, fallback: 'Chưa gửi được.')} Câu hỏi vẫn ở đây để bạn thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      key: const ValueKey('home-chat'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Color.alphaBlend(
              color.withValues(alpha: .055),
              Theme.of(context).colorScheme.surface,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        border: Border.all(color: color.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .05),
            blurRadius: 22,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: color, size: 19),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Cùng tìm ra lời giải',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.onCanvasSend != null) ...[
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => setState(() => _showCanvas = !_showCanvas),
              icon: const Icon(Icons.draw_outlined),
              label: Text(_showCanvas ? 'Ẩn bảng vẽ' : 'Cùng Koji vẽ lời giải'),
            ),
            if (_showCanvas)
              SharedCanvas(
                document: _canvas,
                onChanged: (value) => setState(() => _canvas = value),
              ),
          ],
          if (_messages.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - 1 - index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: message.fromLearner
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message.fromLearner
                              ? color.withValues(alpha: .1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(message.text),
                      ),
                    ),
                  );
                },
              ),
            ),
          TextField(
            key: const ValueKey('chat-input'),
            controller: _input,
            enabled: !_busy,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Bạn đang muốn hiểu điều gì?',
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final prompt in [
                'Gợi ý một cách làm',
                'Giải thích đơn giản',
                'Học lập trình',
              ])
                ActionChip(
                  label: Text(prompt, softWrap: true),
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _input.text = prompt;
                          _input.selection = TextSelection.collapsed(
                            offset: prompt.length,
                          );
                          _error = null;
                        }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _error ??
                      (!_connected
                          ? 'Trợ lý chưa được kết nối.'
                          : _busy
                          ? 'Đang suy nghĩ…'
                          : 'Hỏi một chút, hiểu thêm một điều.'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const ValueKey('chat-send'),
                tooltip: 'Gửi câu hỏi',
                onPressed: !_connected || _busy || _input.text.trim().isEmpty
                    ? null
                    : _send,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
