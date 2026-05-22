// Token stream → AST.
//
// Design:
//   * The parser owns a [DocumentNode] root and a small set of "trailing
//     open" pointers (the leaf, the current list, the current blockquote,
//     the current table). Only these may mutate.
//   * Every node gets a monotonic [AstNode.id] for stable widget keying.
//   * Provisional rendering is supported: a CodeBlockNode without a closing
//     fence stays `isComplete: false`, and the renderer paints it anyway.
//
// v0.1 simplifications (accepted):
//   * Single-level blockquotes (no nested `>>` AST — tokenizer captures
//     depth, but the AST flattens).
//   * Lists close on any blank line. (No CommonMark loose-list distinction.)
//   * Lists close on any non-list block-starter (heading, HR, fence, table).
//   * Tables require a header row + separator row (standard GFM).

import 'ast.dart';
import 'token.dart';

class Parser {
  Parser() : _doc = DocumentNode(0) {
    _nextId = 1;
  }

  final DocumentNode _doc;
  int _nextId = 1;

  // Trailing open pointers — each may be null when no such block is active.
  AstNode? _openLeaf; // ParagraphNode | CodeBlockNode | TableNode (set _openTable too)
  ListNode? _openList;
  ListItemNode? _openItem;
  BlockquoteNode? _openQuote;
  TableNode? _openTable;

  // Lookahead state: a TableRowToken is held until we know whether the next
  // token is a TableSeparatorToken (in which case it's a table header) or
  // not (in which case it's just paragraph text).
  TableRowToken? _pendingRow;

  /// Root document. Children accumulate as tokens are fed in.
  DocumentNode get document => _doc;

  /// Feed a batch of tokens (typically what `Tokenizer.feed` returned).
  void feed(List<Token> tokens) {
    for (final token in tokens) {
      _handle(token);
    }
  }

  /// Finalize the AST. Closes "naturally complete" trailing nodes (paragraphs,
  /// lists, tables, blockquotes). An unclosed code block stays `isComplete:
  /// false` as a signal that the stream ended mid-block.
  void complete() {
    _flushPendingRowAsParagraph();
    _closeListIfOpen();
    _closeTableIfOpen();
    _closeQuoteIfOpen();
    final leaf = _openLeaf;
    if (leaf is ParagraphNode) {
      leaf.isComplete = true;
      _openLeaf = null;
    }
    _doc.isComplete = true;
  }

  // ──────────────────────────────────────────────────────────────────────

  void _handle(Token token) {
    // Pending-row lookahead must run before any other dispatch.
    if (_pendingRow != null) {
      if (token is TableSeparatorToken) {
        _startTable(_pendingRow!, token);
        _pendingRow = null;
        return;
      }
      _flushPendingRowAsParagraph();
    }

    switch (token) {
      case HeadingToken(:final level, :final text):
        _closeListIfOpen();
        _closeTableIfOpen();
        _closeLeafIfOpen();
        final h = HeadingNode(_id(), level: level, text: text)
          ..isComplete = true;
        _appendBlock(h);

      case HorizontalRuleToken():
        _closeListIfOpen();
        _closeTableIfOpen();
        _closeLeafIfOpen();
        _appendBlock(HorizontalRuleNode(_id()));

      case BlankLineToken():
        _closeListIfOpen();
        _closeTableIfOpen();
        _closeQuoteIfOpen();
        _closeLeafIfOpen();

      case FenceOpenToken(:final language):
        _closeListIfOpen();
        _closeTableIfOpen();
        _closeLeafIfOpen();
        final code = CodeBlockNode(_id(), language: language);
        _appendBlock(code);
        _openLeaf = code;

      case CodeLineToken(:final content):
        final leaf = _openLeaf;
        if (leaf is CodeBlockNode) {
          leaf.lines.add(content);
        }
        // Stray code line outside a fence is a tokenizer bug — ignore.

      case FenceCloseToken():
        final leaf = _openLeaf;
        if (leaf is CodeBlockNode) {
          leaf.isComplete = true;
          _openLeaf = null;
        }

      case TextLineToken(:final text):
        _handleTextLine(text);

      case ListMarkerToken(
          :final indent,
          :final ordered,
          :final number,
          :final isTask,
          :final isChecked,
        ):
        _closeTableIfOpen();
        _closeLeafIfOpen();
        _closeItemOnly();
        var list = _openList;
        if (list == null || list.ordered != ordered) {
          _closeListIfOpen();
          list = ListNode(_id(), ordered: ordered, startNumber: number);
          _appendBlock(list);
          _openList = list;
        }
        final item = ListItemNode(
          _id(),
          indent: indent,
          isTask: isTask,
          isChecked: isChecked,
        );
        list.items.add(item);
        _openItem = item;

      case BlockquoteMarkerToken():
        if (_openQuote == null) {
          _closeListIfOpen();
          _closeTableIfOpen();
          _closeLeafIfOpen();
          final q = BlockquoteNode(_id(), depth: 1);
          _appendBlock(q);
          _openQuote = q;
        }
      // The rest of the line's content (text/heading/etc.) follows as
      // subsequent tokens and is appended via _appendBlock, which routes
      // into the open blockquote when one is active.

      case TableRowToken(:final cells):
        final table = _openTable;
        if (table != null) {
          table.rows.add(cells);
        } else {
          _pendingRow = TableRowToken(cells);
        }

      case TableSeparatorToken():
        // Stray separator with no preceding row — ignore.
        break;

      // Inline tokens are produced by InlineTokenizer at render time, not by
      // the block tokenizer. They should never appear in this stream.
      case InlineTextToken() ||
            StrongDelimToken() ||
            EmphasisDelimToken() ||
            StrikeDelimToken() ||
            CodeSpanToken() ||
            LinkToken() ||
            AutolinkToken() ||
            HardBreakToken():
        break;
    }
  }

  void _handleTextLine(String text) {
    // If we're inside a list item, the text goes into that item's paragraph.
    final item = _openItem;
    if (item != null) {
      _appendToItemParagraph(item, text);
      return;
    }

    // Continuation of an open paragraph?
    final leaf = _openLeaf;
    if (leaf is ParagraphNode) {
      leaf.appendLine(text);
      return;
    }

    // New paragraph.
    _closeLeafIfOpen();
    final p = ParagraphNode(_id(), text: text);
    _appendBlock(p);
    _openLeaf = p;
  }

  void _appendToItemParagraph(ListItemNode item, String text) {
    final lastChild = item.children.isEmpty ? null : item.children.last;
    if (lastChild is ParagraphNode && !lastChild.isComplete) {
      lastChild.appendLine(text);
    } else {
      final p = ParagraphNode(_id(), text: text);
      item.children.add(p);
    }
  }

  void _appendBlock(AstNode node) {
    final quote = _openQuote;
    if (quote != null) {
      quote.children.add(node);
    } else {
      _doc.children.add(node);
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Closers
  // ──────────────────────────────────────────────────────────────────────

  void _closeLeafIfOpen() {
    final leaf = _openLeaf;
    if (leaf != null) {
      leaf.isComplete = true;
      _openLeaf = null;
    }
  }

  void _closeItemOnly() {
    final item = _openItem;
    if (item != null) {
      for (final child in item.children) {
        child.isComplete = true;
      }
      item.isComplete = true;
      _openItem = null;
    }
  }

  void _closeListIfOpen() {
    _closeItemOnly();
    final list = _openList;
    if (list != null) {
      list.isComplete = true;
      _openList = null;
    }
  }

  void _closeTableIfOpen() {
    final table = _openTable;
    if (table != null) {
      table.isComplete = true;
      _openTable = null;
      if (identical(_openLeaf, table)) _openLeaf = null;
    }
  }

  void _closeQuoteIfOpen() {
    final quote = _openQuote;
    if (quote != null) {
      // Close any nested content inside the quote.
      for (final child in quote.children) {
        child.isComplete = true;
      }
      quote.isComplete = true;
      _openQuote = null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Table helpers
  // ──────────────────────────────────────────────────────────────────────

  void _startTable(TableRowToken header, TableSeparatorToken sep) {
    _closeListIfOpen();
    _closeLeafIfOpen();
    final table = TableNode(
      _id(),
      headers: header.cells,
      alignments: sep.alignments,
    );
    _appendBlock(table);
    _openTable = table;
    _openLeaf = table;
  }

  void _flushPendingRowAsParagraph() {
    final row = _pendingRow;
    if (row == null) return;
    _pendingRow = null;
    // Reconstruct the line — render the cells joined with `|` for visibility.
    // (Not a perfect inverse of the original input, but rare in practice.)
    final text = row.cells.join(' | ');
    _handleTextLine(text);
  }

  int _id() => _nextId++;
}
