// GFM table widget with copy controls.
//
// Each cell can contain inline markdown (bold, italic, links, inline code).
// Columns are sized from the viewport rather than the intrinsic width of
// every cell. This keeps streamed rows stable without repeatedly measuring
// the whole table.
//
// Wide tables wrap in a horizontal `SingleChildScrollView`. A copy dropdown
// above the table lets users export as CSV, TSV, or Markdown.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../parser/ast.dart';
import '../parser/token.dart';
import 'inline_spans.dart';

// ──────────────────────────────────────────────────────────────────────────
// Format utilities (exported for direct use)
// ──────────────────────────────────────────────────────────────────────────

String tableDataToCSV(TableNode node) {
  final buf = StringBuffer();
  if (node.headers.isNotEmpty) {
    buf.writeln(node.headers.map(_escapeCSV).join(','));
  }
  for (final row in node.rows) {
    final padded = _padRow(row, node.headers.length);
    buf.writeln(padded.map(_escapeCSV).join(','));
  }
  return buf.toString().trimRight();
}

String tableDataToTSV(TableNode node) {
  final buf = StringBuffer();
  if (node.headers.isNotEmpty) {
    buf.writeln(node.headers.map(_escapeTSV).join('\t'));
  }
  for (final row in node.rows) {
    final padded = _padRow(row, node.headers.length);
    buf.writeln(padded.map(_escapeTSV).join('\t'));
  }
  return buf.toString().trimRight();
}

String tableDataToMarkdown(TableNode node) {
  if (node.headers.isEmpty) return '';
  final buf = StringBuffer();
  final escaped = node.headers.map(_escapeMDCell).join(' | ');
  buf.writeln('| $escaped |');
  buf.writeln('| ${node.headers.map((_) => '---').join(' | ')} |');
  for (final row in node.rows) {
    final padded = _padRow(row, node.headers.length);
    buf.writeln('| ${padded.map(_escapeMDCell).join(' | ')} |');
  }
  return buf.toString().trimRight();
}

List<String> _padRow(List<String> row, int count) {
  if (row.length >= count) return row;
  return [...row, ...List.filled(count - row.length, '')];
}

String _escapeCSV(String v) {
  if (!v.contains(RegExp(r'["\n,]'))) return v;
  return '"${v.replaceAll('"', '""')}"';
}

String _escapeTSV(String v) =>
    v.replaceAll('\t', '\\t').replaceAll('\n', '\\n').replaceAll('\r', '\\r');

String _escapeMDCell(String v) =>
    v.replaceAll('\\', '\\\\').replaceAll('|', '\\|');

// ──────────────────────────────────────────────────────────────────────────
// Widget
// ──────────────────────────────────────────────────────────────────────────

class TableWidget extends StatefulWidget {
  const TableWidget({
    super.key,
    required this.node,
    this.baseStyle,
    this.onLinkTap,
    this.latex = false,
  });

  final TableNode node;
  final TextStyle? baseStyle;
  final void Function(Uri uri)? onLinkTap;
  final bool latex;

  @override
  State<TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<TableWidget> {
  final List<GestureRecognizer> _recognizers = <GestureRecognizer>[];
  bool _copied = false;
  Timer? _resetTimer;

  void _copy(String format) {
    final content = switch (format) {
      'csv' => tableDataToCSV(widget.node),
      'tsv' => tableDataToTSV(widget.node),
      _ => tableDataToMarkdown(widget.node),
    };
    Clipboard.setData(ClipboardData(text: content));
    setState(() {
      _copied = true;
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final theme = Theme.of(context);
    // outlineVariant is often tinted with an app's accent. Tables need quiet
    // structure, so derive their rules from the foreground instead.
    final borderColor = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    final headerBg = theme.colorScheme.surfaceContainerHigh;
    final columnCount = widget.node.headers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: PopupMenuButton<String>(
            tooltip: _copied ? 'Copied' : 'Copy table',
            onSelected: _copy,
            icon: Icon(
              _copied ? Icons.check : Icons.copy_outlined,
              size: 17,
              color: _copied
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'md', child: Text('Copy Markdown')),
              PopupMenuItem(value: 'csv', child: Text('Copy CSV')),
              PopupMenuItem(value: 'tsv', child: Text('Copy TSV')),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            if (columnCount == 0) return const SizedBox.shrink();
            final viewportWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 720.0;
            final columnWidth = (viewportWidth / columnCount).clamp(
              180.0,
              280.0,
            );
            final tableWidth = math.max(
              viewportWidth,
              columnWidth * columnCount,
            );
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    child: Table(
                      defaultColumnWidth: FixedColumnWidth(
                        tableWidth / columnCount,
                      ),
                      border: TableBorder(
                        horizontalInside: BorderSide(color: borderColor),
                      ),
                      children: <TableRow>[
                        TableRow(
                          decoration: BoxDecoration(color: headerBg),
                          children: <Widget>[
                            for (var i = 0; i < columnCount; i++)
                              _Cell(
                                text: widget.node.headers[i],
                                alignment: _safeAlignment(i),
                                recognizers: _recognizers,
                                baseStyle:
                                    (widget.baseStyle ?? const TextStyle())
                                        .copyWith(fontWeight: FontWeight.w600),
                                onLinkTap: widget.onLinkTap,
                                latex: widget.latex,
                              ),
                          ],
                        ),
                        for (final row in widget.node.rows)
                          TableRow(
                            children: <Widget>[
                              for (var i = 0; i < columnCount; i++)
                                _Cell(
                                  text: i < row.length ? row[i] : '',
                                  alignment: _safeAlignment(i),
                                  recognizers: _recognizers,
                                  baseStyle: widget.baseStyle,
                                  onLinkTap: widget.onLinkTap,
                                  latex: widget.latex,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  TableAlignment _safeAlignment(int column) =>
      column < widget.node.alignments.length
      ? widget.node.alignments[column]
      : TableAlignment.none;
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.text,
    required this.alignment,
    required this.recognizers,
    this.baseStyle,
    this.onLinkTap,
    this.latex = false,
  });

  final String text;
  final TableAlignment alignment;
  final TextStyle? baseStyle;
  final List<GestureRecognizer> recognizers;
  final void Function(Uri uri)? onLinkTap;
  final bool latex;

  @override
  Widget build(BuildContext context) {
    final result = buildInlineSpans(
      text,
      context,
      baseStyle: baseStyle,
      onLinkTap: onLinkTap,
      recognizers: recognizers,
      latex: latex,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text.rich(
        TextSpan(children: result.spans),
        textAlign: _textAlign(alignment),
      ),
    );
  }

  TextAlign _textAlign(TableAlignment a) => switch (a) {
    TableAlignment.left => TextAlign.left,
    TableAlignment.center => TextAlign.center,
    TableAlignment.right => TextAlign.right,
    TableAlignment.none => TextAlign.start,
  };
}
