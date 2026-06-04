// Inline tokens → Flutter [InlineSpan]s.
//
// CommonMark's "process emphasis" algorithm is replaced with a simpler
// stack-based pairing: every delimiter toggles a counter, and the current
// counter values determine the active text style at any point.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart' show Math, MathStyle;

import '../parser/inline_tokenizer.dart';
import '../parser/token.dart';
import 'animation.dart';

/// Tokenize [text] and return the corresponding [InlineSpan]s.
List<InlineSpan> buildInlineSpans(
  String text,
  BuildContext context, {
  TextStyle? baseStyle,
  void Function(Uri uri)? onLinkTap,
  required List<GestureRecognizer> recognizers,
  bool latex = false,
  bool cjk = false,
  AnimateConfig? animateConfig,
  bool streaming = false,
  int prevContentLength = 0,
}) {
  final tokens = InlineTokenizer.tokenize(text, latex: latex, cjk: cjk);
  final theme = Theme.of(context);
  final base = baseStyle ?? DefaultTextStyle.of(context).style;

  var strong = 0;
  var em = 0;
  var strike = 0;
  var charOffset = 0;

  TextStyle styleNow() {
    var s = base;
    if (strong > 0) s = s.copyWith(fontWeight: FontWeight.bold);
    if (em > 0) s = s.copyWith(fontStyle: FontStyle.italic);
    if (strike > 0) s = s.copyWith(decoration: TextDecoration.lineThrough);
    return s;
  }

  TextStyle codeSpanStyle() => styleNow().copyWith(
    fontFamily: 'monospace',
    fontFamilyFallback: const <String>['Courier', 'monospace'],
    backgroundColor: theme.colorScheme.surfaceContainerHighest,
  );

  TextStyle linkStyle() => styleNow().copyWith(
    color: theme.colorScheme.primary,
    decoration: TextDecoration.underline,
    decorationColor: theme.colorScheme.primary,
  );

  GestureRecognizer? makeTapRecognizer(String url) {
    if (onLinkTap == null) return null;
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        final uri = Uri.tryParse(url);
        if (uri != null) onLinkTap(uri);
      };
    recognizers.add(recognizer);
    return recognizer;
  }

  final spans = <InlineSpan>[];
  for (final token in tokens) {
    switch (token) {
      case InlineTextToken(:final text):
        charOffset = buildAnimatedSpans(
          text,
          styleNow(),
          config: animateConfig,
          streaming: streaming,
          prevContentLength: prevContentLength,
          charOffset: charOffset,
          out: spans,
        );
      case StrongDelimToken():
        if (strong > 0) { strong--; } else { strong++; }
      case EmphasisDelimToken():
        if (em > 0) { em--; } else { em++; }
      case StrikeDelimToken():
        if (strike > 0) { strike--; } else { strike++; }
      case CodeSpanToken(:final content):
        spans.add(TextSpan(text: content, style: codeSpanStyle()));
      case LinkToken(:final text, :final url, :final isImage):
        if (isImage) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Image.network(
                url,
                semanticLabel: text.isEmpty ? null : text,
                errorBuilder: (context, error, stackTrace) => Text(
                  '[$text]',
                  style: styleNow().copyWith(color: theme.disabledColor),
                ),
                frameBuilder: (context, child, frame, wasSyncLoaded) {
                  if (wasSyncLoaded || frame != null) return child;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4,
                    ),
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      text.isEmpty ? '...' : text,
                      style: styleNow().copyWith(color: theme.disabledColor),
                    ),
                  );
                },
              ),
            ),
          );
        } else {
          spans.add(
            TextSpan(
              text: text,
              style: linkStyle(),
              recognizer: makeTapRecognizer(url),
            ),
          );
        }
      case AutolinkToken(:final url):
        spans.add(
          TextSpan(
            text: url,
            style: linkStyle(),
            recognizer: makeTapRecognizer(url),
          ),
        );
      case HardBreakToken():
        spans.add(const TextSpan(text: '\n'));
      case MathToken(:final tex, :final isBlock):
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              tex,
              mathStyle: isBlock ? MathStyle.display : MathStyle.text,
              textStyle: styleNow(),
              onErrorFallback: (error) => Text(
                isBlock ? '\$\$$tex\$\$' : '\$$tex\$',
                style: styleNow().copyWith(color: theme.colorScheme.error),
              ),
            ),
          ),
        );
      case HeadingToken() ||
           HorizontalRuleToken() ||
           BlockquoteMarkerToken() ||
           ListMarkerToken() ||
           FenceOpenToken() ||
           FenceCloseToken() ||
           CodeLineToken() ||
           TableRowToken() ||
           TableSeparatorToken() ||
           TextLineToken() ||
           BlankLineToken():
        break;
    }
  }
  return spans;
}
