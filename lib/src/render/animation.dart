// Inline text animation matching React's animate.ts.
//
// Splits text by word or char, wraps each segment in an Animate widget
// with configurable stagger/duration/easing. Tracks prevContentLength
// to skip re-animation of already-rendered text during streaming.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Mirrors React's AnimateOptions.animation.
enum AnimationType { fadeIn, blurIn, slideUp }

/// Controls how streaming text is split for inline animation.
enum AnimationSeparator { word, char }

/// Mirrors React's AnimateOptions.
class AnimateConfig {
  const AnimateConfig({
    this.animation = AnimationType.fadeIn,
    this.duration = 150,
    this.sep = AnimationSeparator.word,
    this.stagger = 40,
  });

  final AnimationType animation;
  final int duration;
  final AnimationSeparator sep;
  final int stagger;

  List<Effect<dynamic>> effects(double delayMs) {
    final d = Duration(milliseconds: duration);
    final delay = Duration(milliseconds: delayMs.round());
    switch (animation) {
      case AnimationType.blurIn:
        return [
          BlurEffect(begin: const Offset(0, 6), end: Offset.zero, delay: delay),
          FadeEffect(begin: 0, end: 1, duration: d, delay: delay),
        ];
      case AnimationType.slideUp:
        return [
          MoveEffect(begin: const Offset(0, 8), end: Offset.zero, delay: delay),
          FadeEffect(begin: 0, end: 1, duration: d, delay: delay),
        ];
      case AnimationType.fadeIn:
        return [FadeEffect(begin: 0, end: 1, duration: d, delay: delay)];
    }
  }
}

/// Builds animated [InlineSpan]s for a plain-text run.
/// [text] is the raw text content, [style] is the current text style.
/// [charOffset] is the cumulative character position across all spans
/// (used for stagger offset). Returns the new charOffset.
int buildAnimatedSpans(
  String text,
  TextStyle style, {
  required AnimateConfig? config,
  required bool streaming,
  required int prevContentLength,
  required int charOffset,
  required List<InlineSpan> out,
}) {
  if (config == null || !streaming) {
    out.add(TextSpan(text: text, style: style));
    return charOffset + text.length;
  }

  final parts = config.sep == AnimationSeparator.char
      ? _splitByChar(text)
      : _splitByWord(text);
  var local = 0;
  var newContentOffset = 0;

  for (final part in parts) {
    final pos = charOffset + local;
    final skip = prevContentLength > 0 && pos < prevContentLength;

    if (part.trim().isEmpty) {
      out.add(TextSpan(text: part, style: style));
    } else if (skip) {
      out.add(TextSpan(text: part, style: style));
    } else {
      final delayMs = newContentOffset * config.stagger;
      out.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Animate(
            effects: config.effects(delayMs.toDouble()),
            child: Text(part, style: style),
          ),
        ),
      );
      newContentOffset += part.length;
    }
    local += part.length;
  }

  return charOffset + text.length;
}

// ──────────────────────────────────────────────────────────────────────────
// Split utils (same algorithm as React's splitByWord / splitByChar)
// ──────────────────────────────────────────────────────────────────────────

List<String> _splitByWord(String text) {
  final parts = <String>[];
  var buf = StringBuffer();
  var inWs = false;
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    final isWs = ch == ' ' || ch == '\t' || ch == '\n';
    if (isWs != inWs && buf.isNotEmpty) {
      parts.add(buf.toString());
      buf = StringBuffer();
    }
    buf.write(ch);
    inWs = isWs;
  }
  if (buf.isNotEmpty) parts.add(buf.toString());
  return parts;
}

List<String> _splitByChar(String text) {
  final parts = <String>[];
  var wsBuf = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == ' ' || ch == '\t' || ch == '\n') {
      wsBuf.write(ch);
    } else {
      if (wsBuf.isNotEmpty) {
        parts.add(wsBuf.toString());
        wsBuf = StringBuffer();
      }
      parts.add(ch);
    }
  }
  if (wsBuf.isNotEmpty) parts.add(wsBuf.toString());
  return parts;
}

// ──────────────────────────────────────────────────────────────────────────
// Block-level helpers (kept from earlier)
// ──────────────────────────────────────────────────────────────────────────

class StreamdownAnimatedBlock extends StatefulWidget {
  const StreamdownAnimatedBlock({
    super.key,
    required this.child,
    this.enabled = false,
  });

  final Widget child;
  final bool enabled;

  @override
  State<StreamdownAnimatedBlock> createState() =>
      _StreamdownAnimatedBlockState();
}

class _StreamdownAnimatedBlockState extends State<StreamdownAnimatedBlock>
    with SingleTickerProviderStateMixin {
  var _animate = false;

  @override
  void initState() {
    super.initState();
    _animate = widget.enabled;
  }

  @override
  void didUpdateWidget(covariant StreamdownAnimatedBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.key != oldWidget.key || widget.enabled != oldWidget.enabled) {
      _animate = widget.enabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_animate) return widget.child;
    return widget.child.animate().fadeIn(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}

class StreamdownCaret extends StatefulWidget {
  const StreamdownCaret({super.key});

  @override
  State<StreamdownCaret> createState() => _StreamdownCaretState();
}

class _StreamdownCaretState extends State<StreamdownCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
      child: Text(' ▋', style: DefaultTextStyle.of(context).style),
    );
  }
}
