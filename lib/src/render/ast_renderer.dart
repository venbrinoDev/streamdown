// AST → Flutter widget tree.
//
// Each AstNode becomes one widget keyed by `ValueKey(node.id)` so Flutter's
// element diff never rebuilds closed nodes when new nodes are appended.
// Uses ListView.builder for deferred off-screen rendering.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../parser/ast.dart';
import 'animation.dart';
import 'code_block.dart';
import 'inline_spans.dart';
import 'syntax_theme.dart';
import 'table.dart' as table_widget;

class AstRenderer extends StatefulWidget {
  const AstRenderer({
    super.key,
    required this.document,
    required this.syntaxTheme,
    this.textStyle,
    this.onLinkTap,
    this.codeBlockBuilder,
    this.latex = false,
    this.cjk = false,
    this.lineNumbers = true,
    this.animated = true,
    this.showCaret = false,
    this.animateConfig,
  });

  final DocumentNode document;
  final TextStyle? textStyle;
  final void Function(Uri uri)? onLinkTap;
  final SyntaxTheme syntaxTheme;
  final CodeBlockBuilder? codeBlockBuilder;
  final bool latex;
  final bool cjk;
  final bool lineNumbers;
  final bool animated;
  final bool showCaret;
  final AnimateConfig? animateConfig;

  @override
  State<AstRenderer> createState() => _AstRendererState();
}

class _AstRendererState extends State<AstRenderer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        for (final node in widget.document.children)
          StreamdownAnimatedBlock(
            key: ValueKey<int>(node.id),
            enabled: widget.animated && !node.isComplete,
            child: _renderBlock(context, node),
          ),
        if (widget.showCaret) const StreamdownCaret(),
      ],
    );
  }

  Widget _renderBlock(BuildContext context, AstNode node) {
    return switch (node) {
      HeadingNode() => _Heading(
        key: ValueKey<int>(node.id),
        node: node,
        baseStyle: widget.textStyle,
        onLinkTap: widget.onLinkTap,
        latex: widget.latex,
        cjk: widget.cjk,
        animateConfig: widget.animateConfig,
        streaming: widget.animateConfig != null,
      ),
      ParagraphNode() => _Paragraph(
        key: ValueKey<int>(node.id),
        node: node,
        baseStyle: widget.textStyle,
        onLinkTap: widget.onLinkTap,
        latex: widget.latex,
        cjk: widget.cjk,
        animateConfig: widget.animateConfig,
        streaming: widget.animateConfig != null,
      ),
      HorizontalRuleNode() => Padding(
        key: ValueKey<int>(node.id),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(
          color: Theme.of(context).colorScheme.outlineVariant,
          height: 1,
        ),
      ),
      BlockquoteNode() => _Blockquote(
        key: ValueKey<int>(node.id),
        node: node,
        baseStyle: widget.textStyle,
        onLinkTap: widget.onLinkTap,
        latex: widget.latex,
        cjk: widget.cjk,
        animateConfig: widget.animateConfig,
        streaming: widget.animateConfig != null,
      ),
      ListNode() => _List(
        key: ValueKey<int>(node.id),
        node: node,
        baseStyle: widget.textStyle,
        onLinkTap: widget.onLinkTap,
        latex: widget.latex,
        cjk: widget.cjk,
        animateConfig: widget.animateConfig,
        streaming: widget.animateConfig != null,
      ),
      CodeBlockNode() => CodeBlockWidget(
        key: ValueKey<int>(node.id),
        node: node,
        syntaxTheme: widget.syntaxTheme,
        builder: widget.codeBlockBuilder,
        showLineNumbers: widget.lineNumbers,
      ),
      TableNode() => table_widget.TableWidget(
        key: ValueKey<int>(node.id),
        node: node,
        baseStyle: widget.textStyle,
        onLinkTap: widget.onLinkTap,
        latex: widget.latex,
      ),
      DocumentNode() || ListItemNode() =>
        const SizedBox.shrink(),
    };
  }
}

// ──────────────────────────────────────────────────────────────────────
// Block-level widgets
// ──────────────────────────────────────────────────────────────────────

class _Heading extends StatefulWidget {
  const _Heading({
    super.key,
    required this.node,
    this.baseStyle,
    this.onLinkTap,
    this.latex = false,
    this.cjk = false,
    this.animateConfig,
    this.streaming = false,
  });

  final HeadingNode node;
  final TextStyle? baseStyle;
  final void Function(Uri uri)? onLinkTap;
  final bool latex;
  final bool cjk;
  final AnimateConfig? animateConfig;
  final bool streaming;

  @override
  State<_Heading> createState() => _HeadingState();
}

class _HeadingState extends State<_Heading> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  Widget? _cached;
  int _lastTextLength = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cached = null;
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.node.isComplete && _cached != null) {
      return _cached!;
    }

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final theme = Theme.of(context);
    final headingStyle = switch (widget.node.level) {
      1 => theme.textTheme.headlineLarge,
      2 => theme.textTheme.headlineMedium,
      3 => theme.textTheme.headlineSmall,
      4 => theme.textTheme.titleLarge,
      5 => theme.textTheme.titleMedium,
      6 => theme.textTheme.titleSmall,
      _ => theme.textTheme.bodyLarge,
    };
    final merged = (widget.baseStyle ?? const TextStyle()).merge(headingStyle);

    final (:spans, :renderedLength) = buildInlineSpans(
      widget.node.text,
      context,
      baseStyle: merged,
      onLinkTap: widget.onLinkTap,
      recognizers: _recognizers,
      latex: widget.latex,
      cjk: widget.cjk,
      animateConfig: widget.animateConfig,
      streaming: widget.streaming,
      prevContentLength: _lastTextLength,
    );

    final result = Text.rich(TextSpan(children: spans));

    _lastTextLength = renderedLength;

    if (widget.node.isComplete) {
      _cached = result;
    }

    return result;
  }
}

class _Paragraph extends StatefulWidget {
  const _Paragraph({
    super.key,
    required this.node,
    this.baseStyle,
    this.onLinkTap,
    this.latex = false,
    this.cjk = false,
    this.animateConfig,
    this.streaming = false,
  });

  final ParagraphNode node;
  final TextStyle? baseStyle;
  final void Function(Uri uri)? onLinkTap;
  final bool latex;
  final bool cjk;
  final AnimateConfig? animateConfig;
  final bool streaming;

  @override
  State<_Paragraph> createState() => _ParagraphState();
}

class _ParagraphState extends State<_Paragraph> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  Widget? _cached;
  int _lastTextLength = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cached = null;
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.node.isComplete && _cached != null) {
      return _cached!;
    }

    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final (:spans, :renderedLength) = buildInlineSpans(
      widget.node.text,
      context,
      baseStyle: widget.baseStyle,
      onLinkTap: widget.onLinkTap,
      recognizers: _recognizers,
      latex: widget.latex,
      cjk: widget.cjk,
      animateConfig: widget.animateConfig,
      streaming: widget.streaming,
      prevContentLength: _lastTextLength,
    );

    final result = Text.rich(TextSpan(children: spans));

    _lastTextLength = renderedLength;

    if (widget.node.isComplete) {
      _cached = result;
    }

    return result;
  }
}

class _Blockquote extends StatelessWidget {
  const _Blockquote({
    super.key,
    required this.node,
    this.baseStyle,
    this.onLinkTap,
    this.latex = false,
    this.cjk = false,
    this.animateConfig,
    this.streaming = false,
  });

  final BlockquoteNode node;
  final TextStyle? baseStyle;
  final void Function(Uri uri)? onLinkTap;
  final bool latex;
  final bool cjk;
  final AnimateConfig? animateConfig;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          for (final child in node.children) _renderInner(context, child),
        ],
      ),
    );
  }

  Widget _renderInner(BuildContext context, AstNode child) {
    return switch (child) {
      ParagraphNode() => _Paragraph(
        key: ValueKey<int>(child.id),
        node: child,
        baseStyle: baseStyle,
        onLinkTap: onLinkTap,
        latex: latex,
        cjk: cjk,
        animateConfig: animateConfig,
        streaming: streaming,
      ),
      HeadingNode() => _Heading(
        key: ValueKey<int>(child.id),
        node: child,
        baseStyle: baseStyle,
        onLinkTap: onLinkTap,
        latex: latex,
        cjk: cjk,
        animateConfig: animateConfig,
        streaming: streaming,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _List extends StatelessWidget {
  const _List({
    super.key,
    required this.node,
    this.baseStyle,
    this.onLinkTap,
    this.latex = false,
    this.cjk = false,
    this.animateConfig,
    this.streaming = false,
  });

  final ListNode node;
  final TextStyle? baseStyle;
  final void Function(Uri uri)? onLinkTap;
  final bool latex;
  final bool cjk;
  final AnimateConfig? animateConfig;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final start = node.startNumber ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: <Widget>[
        for (var i = 0; i < node.items.length; i++)
          _ListItem(
            key: ValueKey<int>(node.items[i].id),
            node: node.items[i],
            marker: _markerFor(node, i, start),
            baseStyle: baseStyle,
            onLinkTap: onLinkTap,
            latex: latex,
            cjk: cjk,
            animateConfig: animateConfig,
            streaming: streaming,
          ),
      ],
    );
  }

  String _markerFor(ListNode list, int index, int start) {
    final item = list.items[index];
    if (item.isTask) {
      return item.isChecked ? '☑' : '☐';
    }
    return list.ordered ? '${start + index}.' : '•';
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({
    super.key,
    required this.node,
    required this.marker,
    this.baseStyle,
    this.onLinkTap,
    this.latex = false,
    this.cjk = false,
    this.animateConfig,
    this.streaming = false,
  });

  final ListItemNode node;
  final String marker;
  final TextStyle? baseStyle;
  final void Function(Uri uri)? onLinkTap;
  final bool latex;
  final bool cjk;
  final AnimateConfig? animateConfig;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: 24, child: Text(marker, textAlign: TextAlign.right)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: <Widget>[
              for (final child in node.children)
                if (child is ParagraphNode)
                  _Paragraph(
                    key: ValueKey<int>(child.id),
                    node: child,
                    baseStyle: baseStyle,
                    onLinkTap: onLinkTap,
                    latex: latex,
                    cjk: cjk,
                    animateConfig: animateConfig,
                    streaming: streaming,
                  )
                else
                  const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
