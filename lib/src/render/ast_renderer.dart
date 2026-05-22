// AST → Flutter widget tree.
//
// Each AstNode becomes one widget keyed by `ValueKey(node.id)` so Flutter's
// element diff never rebuilds closed nodes when new nodes are appended.
//
// Code-block syntax highlighting lands in Phase 4.
// Table layout polish lands in Phase 5.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../parser/ast.dart';
import 'code_block.dart';
import 'inline_spans.dart';
import 'syntax_theme.dart';

/// Walks a [DocumentNode] and emits a [Column] of block widgets. Stateful
/// so it can own the [GestureRecognizer]s created for link taps (and dispose
/// them when the widget is removed).
class AstRenderer extends StatefulWidget {
  const AstRenderer({
    super.key,
    required this.document,
    required this.syntaxTheme,
    this.textStyle,
    this.onLinkTap,
    this.codeBlockBuilder,
  });

  final DocumentNode document;
  final TextStyle? textStyle;
  final void Function(Uri uri)? onLinkTap;
  final SyntaxTheme syntaxTheme;
  final CodeBlockBuilder? codeBlockBuilder;

  @override
  State<AstRenderer> createState() => _AstRendererState();
}

class _AstRendererState extends State<AstRenderer> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];

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
    // Recognizers from the previous build are now stale — dispose & reset.
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: <Widget>[
        for (final node in widget.document.children)
          _renderBlock(context, node),
      ],
    );
  }

  Widget _renderBlock(BuildContext context, AstNode node) {
    return switch (node) {
      HeadingNode() => _Heading(
          key: ValueKey<int>(node.id),
          node: node,
          baseStyle: widget.textStyle,
          recognizers: _recognizers,
          onLinkTap: widget.onLinkTap,
        ),
      ParagraphNode() => _Paragraph(
          key: ValueKey<int>(node.id),
          node: node,
          baseStyle: widget.textStyle,
          recognizers: _recognizers,
          onLinkTap: widget.onLinkTap,
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
          recognizers: _recognizers,
          onLinkTap: widget.onLinkTap,
        ),
      ListNode() => _List(
          key: ValueKey<int>(node.id),
          node: node,
          baseStyle: widget.textStyle,
          recognizers: _recognizers,
          onLinkTap: widget.onLinkTap,
        ),
      CodeBlockNode() => CodeBlockWidget(
          key: ValueKey<int>(node.id),
          node: node,
          syntaxTheme: widget.syntaxTheme,
          builder: widget.codeBlockBuilder,
        ),
      TableNode() => _Table(
          key: ValueKey<int>(node.id),
          node: node,
        ),
      DocumentNode() ||
      ListItemNode() =>
        // These should never appear at top level.
        const SizedBox.shrink(),
    };
  }
}

// ──────────────────────────────────────────────────────────────────────
// Block-level widgets
// ──────────────────────────────────────────────────────────────────────

class _Heading extends StatelessWidget {
  const _Heading({
    super.key,
    required this.node,
    required this.recognizers,
    this.baseStyle,
    this.onLinkTap,
  });

  final HeadingNode node;
  final TextStyle? baseStyle;
  final List<GestureRecognizer> recognizers;
  final void Function(Uri uri)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = switch (node.level) {
      1 => theme.textTheme.headlineLarge,
      2 => theme.textTheme.headlineMedium,
      3 => theme.textTheme.headlineSmall,
      4 => theme.textTheme.titleLarge,
      5 => theme.textTheme.titleMedium,
      6 => theme.textTheme.titleSmall,
      _ => theme.textTheme.bodyLarge,
    };
    final merged = (baseStyle ?? const TextStyle()).merge(headingStyle);

    return Text.rich(
      TextSpan(
        children: buildInlineSpans(
          node.text,
          context,
          baseStyle: merged,
          onLinkTap: onLinkTap,
          recognizers: recognizers,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({
    super.key,
    required this.node,
    required this.recognizers,
    this.baseStyle,
    this.onLinkTap,
  });

  final ParagraphNode node;
  final TextStyle? baseStyle;
  final List<GestureRecognizer> recognizers;
  final void Function(Uri uri)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: buildInlineSpans(
          node.text,
          context,
          baseStyle: baseStyle,
          onLinkTap: onLinkTap,
          recognizers: recognizers,
        ),
      ),
    );
  }
}

class _Blockquote extends StatelessWidget {
  const _Blockquote({
    super.key,
    required this.node,
    required this.recognizers,
    this.baseStyle,
    this.onLinkTap,
  });

  final BlockquoteNode node;
  final TextStyle? baseStyle;
  final List<GestureRecognizer> recognizers;
  final void Function(Uri uri)? onLinkTap;

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
          for (final child in node.children)
            _renderInner(context, child),
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
          recognizers: recognizers,
          onLinkTap: onLinkTap,
        ),
      HeadingNode() => _Heading(
          key: ValueKey<int>(child.id),
          node: child,
          baseStyle: baseStyle,
          recognizers: recognizers,
          onLinkTap: onLinkTap,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _List extends StatelessWidget {
  const _List({
    super.key,
    required this.node,
    required this.recognizers,
    this.baseStyle,
    this.onLinkTap,
  });

  final ListNode node;
  final TextStyle? baseStyle;
  final List<GestureRecognizer> recognizers;
  final void Function(Uri uri)? onLinkTap;

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
            recognizers: recognizers,
            onLinkTap: onLinkTap,
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
    required this.recognizers,
    this.baseStyle,
    this.onLinkTap,
  });

  final ListItemNode node;
  final String marker;
  final TextStyle? baseStyle;
  final List<GestureRecognizer> recognizers;
  final void Function(Uri uri)? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 24,
          child: Text(marker, textAlign: TextAlign.right),
        ),
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
                    recognizers: recognizers,
                    onLinkTap: onLinkTap,
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

class _Table extends StatelessWidget {
  const _Table({super.key, required this.node});

  final TableNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant;
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder.all(color: borderColor, width: 1),
      children: <TableRow>[
        TableRow(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          children: <Widget>[
            for (final h in node.headers)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  h,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        for (final row in node.rows)
          TableRow(
            children: <Widget>[
              for (var i = 0; i < node.headers.length; i++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(i < row.length ? row[i] : ''),
                ),
            ],
          ),
      ],
    );
  }
}
