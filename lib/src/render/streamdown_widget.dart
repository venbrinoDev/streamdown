// Public Streamdown widget.
//
// Two construction modes:
//   * `Streamdown(stream: ...)` — incremental rendering of a token stream
//     emitting markdown chunks (typical AI chat use case).
//   * `Streamdown.text(...)` — render a complete markdown string in one shot.
//
// Both modes share the same incremental path internally; the static
// constructor just feeds the entire string and immediately completes.

import 'dart:async';

import 'package:flutter/material.dart';

import '../parser/parser.dart';
import '../parser/tokenizer.dart';
import 'ast_renderer.dart';
import 'syntax_theme.dart';

/// Flicker-free streaming markdown widget.
///
/// Drop-in replacement for `flutter_markdown` that handles partial code
/// fences, half-finished tables, and mid-stream inline formatting without
/// re-parsing the prefix on every chunk.
class Streamdown extends StatefulWidget {
  /// Streaming constructor — render markdown as chunks arrive on [stream].
  ///
  /// Chunks are append-only: each event should be the **new** text since the
  /// previous event, not a cumulative buffer. This matches OpenAI / Anthropic
  /// / Gemini SDK conventions.
  const Streamdown({
    super.key,
    required Stream<String> stream,
    this.textStyle,
    this.selectable = true,
    this.onLinkTap,
    this.padding,
    this.syntaxTheme,
    this.codeBlockBuilder,
  })  : _stream = stream,
        _text = null;

  /// Static constructor — render a complete markdown string. Uses the same
  /// incremental parser internally.
  const Streamdown.text(
    String text, {
    super.key,
    this.textStyle,
    this.selectable = true,
    this.onLinkTap,
    this.padding,
    this.syntaxTheme,
    this.codeBlockBuilder,
  })  : _stream = null,
        _text = text;

  final Stream<String>? _stream;
  final String? _text;

  /// Base text style for paragraph and inline text. Headings layer on the
  /// theme's textTheme above this.
  final TextStyle? textStyle;

  /// When true (default), the rendered text is selectable via
  /// [SelectionArea]. Set to false for tap-through layouts.
  final bool selectable;

  /// Called when a link or autolink is tapped.
  final void Function(Uri uri)? onLinkTap;

  /// Optional padding around the rendered document.
  final EdgeInsetsGeometry? padding;

  /// Override the syntax-highlight color scheme for fenced code blocks.
  /// Defaults to [SyntaxTheme.auto] (follows ambient brightness).
  final SyntaxTheme? syntaxTheme;

  /// Full override for code block rendering. When non-null, this is called
  /// instead of the default [CodeBlockWidget] for every fenced code block.
  /// Useful for line numbers, custom themes, or non-standard layouts.
  final CodeBlockBuilder? codeBlockBuilder;

  @override
  State<Streamdown> createState() => _StreamdownState();
}

class _StreamdownState extends State<Streamdown> {
  late Tokenizer _tokenizer;
  late Parser _parser;
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    _initPipeline();
  }

  @override
  void didUpdateWidget(covariant Streamdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final streamChanged = widget._stream != oldWidget._stream;
    final textChanged = widget._text != oldWidget._text;
    if (streamChanged || textChanged) {
      _sub?.cancel();
      _initPipeline();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _initPipeline() {
    _tokenizer = Tokenizer();
    _parser = Parser();
    final text = widget._text;
    if (text != null) {
      _consume(text);
      _completeStream();
      return;
    }
    final stream = widget._stream;
    if (stream != null) {
      _sub = stream.listen(
        _consume,
        onDone: _completeStream,
        // v0.1: errors are silently swallowed; Phase 6 will add errorBuilder.
        cancelOnError: false,
      );
    }
  }

  void _consume(String chunk) {
    _parser.feed(_tokenizer.feed(chunk));
    if (mounted) setState(() {});
  }

  void _completeStream() {
    _parser.feed(_tokenizer.complete());
    _parser.complete();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final renderer = AstRenderer(
      document: _parser.document,
      textStyle: widget.textStyle,
      onLinkTap: widget.onLinkTap,
      syntaxTheme: widget.syntaxTheme ?? SyntaxTheme.auto(context),
      codeBlockBuilder: widget.codeBlockBuilder,
    );
    final padded = widget.padding != null
        ? Padding(padding: widget.padding!, child: renderer)
        : renderer;
    return widget.selectable ? SelectionArea(child: padded) : padded;
  }
}
