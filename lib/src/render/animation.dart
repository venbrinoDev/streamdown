// Streaming animation helpers.
//
// Prose must remain a continuous TextSpan run. Wrapping individual words in
// WidgetSpans changes Flutter's line-breaking and produces fragmented chat
// output on narrow screens. Animation therefore happens at block level.

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

  /// Retained for source compatibility. Inline word/character animation was
  /// removed because WidgetSpan-based splitting breaks native text wrapping.
  @Deprecated('Streaming animation is block-level; sep is no longer used.')
  final AnimationSeparator sep;

  /// Retained for source compatibility. Block animation has no stagger.
  @Deprecated('Streaming animation is block-level; stagger is no longer used.')
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

/// Builds a native, continuous [TextSpan] for a plain-text run.
///
/// The animation-related arguments remain in the signature for compatibility
/// with callers while animation is applied by [StreamdownAnimatedBlock].
int buildAnimatedSpans(
  String text,
  TextStyle style, {
  required AnimateConfig? config,
  required bool streaming,
  required int prevContentLength,
  required int charOffset,
  required List<InlineSpan> out,
}) {
  out.add(TextSpan(text: text, style: style));
  return charOffset + text.length;
}

// ──────────────────────────────────────────────────────────────────────────
// Block-level helpers (kept from earlier)
// ──────────────────────────────────────────────────────────────────────────

class StreamdownAnimatedBlock extends StatefulWidget {
  const StreamdownAnimatedBlock({
    super.key,
    required this.child,
    this.enabled = false,
    this.config,
  });

  final Widget child;
  final bool enabled;
  final AnimateConfig? config;

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
    final config = widget.config;
    if (config == null) {
      return widget.child.animate().fadeIn(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
    return Animate(effects: config.effects(0), child: widget.child);
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
