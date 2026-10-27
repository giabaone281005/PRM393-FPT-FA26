import 'package:flutter/material.dart';

/// Lightweight lexical highlighting for the Python/JavaScript learning samples.
/// Execution/parsing remains the engine's responsibility; this never evaluates code.
class CodeEditingController extends TextEditingController {
  CodeEditingController({super.text});
  static final _tokens = RegExp(
    r'''("[^"\n]*"|'[^'\n]*'|\#[^\n]*|//[^\n]*|\b(?:def|return|if|else|for|in|while|import|from|class|let|const|function|true|false|True|False|None)\b|\b\d+(?:\.\d+)?\b)''',
  );
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (withComposing &&
        value.composing.isValid &&
        !value.composing.isCollapsed) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    final colors = Theme.of(context).colorScheme;
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in _tokens.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final token = match.group(0)!;
      final comment = token.startsWith('#') || token.startsWith('//');
      spans.add(
        TextSpan(
          text: token,
          style: TextStyle(
            color: comment ? colors.onSurfaceVariant : colors.primary,
            fontStyle: comment ? FontStyle.italic : null,
            fontWeight: comment ? null : FontWeight.w700,
          ),
        ),
      );
      cursor = match.end;
    }
    spans.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(style: style, children: spans);
  }
}

class CodeEditor extends StatelessWidget {
  const CodeEditor({super.key, required this.controller, this.enabled = true});
  final CodeEditingController controller;
  final bool enabled;
  @override
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('code-source'),
    controller: controller,
    enabled: enabled,
    minLines: 8,
    maxLines: 18,
    maxLength: 50000,
    autocorrect: false,
    enableSuggestions: false,
    keyboardType: TextInputType.multiline,
    style: const TextStyle(
      fontFamily: 'SourceCodePro',
      fontSize: 14,
      height: 1.5,
    ),
    decoration: const InputDecoration(
      labelText: 'Chương trình',
      alignLabelWithHint: true,
    ),
  );
}
