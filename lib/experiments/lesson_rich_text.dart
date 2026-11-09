import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Same $...$ convention as the web player; oversized/invalid TeX falls back to text.
class LessonRichText extends StatelessWidget {
  const LessonRichText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final matches = RegExp(r'\$([^$\n]+)\$').allMatches(text).toList();
    if (matches.isEmpty) return Text(text, style: style);
    final children = <Widget>[];
    var offset = 0;
    for (final match in matches) {
      if (match.start > offset) {
        children.add(Text(text.substring(offset, match.start), style: style));
      }
      final expression = match.group(1)!;
      children.add(
        expression.length > 500
            ? Text(expression, style: style)
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Math.tex(
                    expression,
                    textStyle: style ?? Theme.of(context).textTheme.bodyLarge,
                    onErrorFallback: (_) => Text(expression, style: style),
                  ),
                ),
              ),
      );
      offset = match.end;
    }
    if (offset < text.length) {
      children.add(Text(text.substring(offset), style: style));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
