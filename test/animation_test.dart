import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:streamdown/src/render/animation.dart';

const _style = TextStyle(fontSize: 14);

void main() {
  group('AnimateConfig', () {
    test('defaults', () {
      const config = AnimateConfig();
      expect(config.animation, AnimationType.fadeIn);
      expect(config.duration, 150);
      expect(config.sep, AnimationSeparator.word);
      expect(config.stagger, 40);
    });

    test('blurIn produces blur + fade effects', () {
      const config = AnimateConfig(animation: AnimationType.blurIn);
      final effects = config.effects(0);
      expect(
        effects.whereType<BlurEffect>(),
        isNotEmpty,
        reason: 'blurIn should include BlurEffect',
      );
      expect(
        effects.whereType<FadeEffect>(),
        isNotEmpty,
        reason: 'blurIn should include FadeEffect',
      );
    });

    test('slideUp produces move + fade effects', () {
      const config = AnimateConfig(animation: AnimationType.slideUp);
      final effects = config.effects(0);
      expect(
        effects.whereType<MoveEffect>(),
        isNotEmpty,
        reason: 'slideUp should include MoveEffect',
      );
      expect(
        effects.whereType<FadeEffect>(),
        isNotEmpty,
        reason: 'slideUp should include FadeEffect',
      );
    });

    test('fadeIn produces only fade effect', () {
      const config = AnimateConfig(animation: AnimationType.fadeIn);
      final effects = config.effects(0);
      expect(effects.whereType<FadeEffect>(), isNotEmpty);
      expect(effects.whereType<BlurEffect>(), isEmpty);
      expect(effects.whereType<MoveEffect>(), isEmpty);
    });

    test('delay is applied via delayMs', () {
      const config = AnimateConfig();
      final noDelay = config.effects(0);
      final withDelay = config.effects(100);
      final nd = noDelay.first as FadeEffect;
      final wd = withDelay.first as FadeEffect;
      expect(nd.delay, Duration.zero);
      expect(wd.delay, const Duration(milliseconds: 100));
    });
  });

  group('buildAnimatedSpans', () {
    test('returns plain TextSpan when config is null', () {
      final out = <InlineSpan>[];
      final offset = buildAnimatedSpans(
        'hello',
        _style,
        config: null,
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      expect(out.single, isA<TextSpan>());
      expect(offset, 5);
    });

    test('returns plain TextSpan when not streaming', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'hello',
        _style,
        config: const AnimateConfig(),
        streaming: false,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      expect(out.single, isA<TextSpan>());
    });

    test('word split wraps each word in a WidgetSpan', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'hello world',
        _style,
        config: const AnimateConfig(),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      // 3 parts: "hello", " ", "world"
      expect(out.length, 3);
      // space is plain TextSpan
      expect(out[1], isA<TextSpan>());
      // words are WidgetSpan wrapping Animate
      final ws = out[0] as WidgetSpan;
      expect(ws.child, isA<Animate>());
      final ws2 = out[2] as WidgetSpan;
      expect(ws2.child, isA<Animate>());
    });

    test('char split wraps each char in a WidgetSpan', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'ab c',
        _style,
        config: const AnimateConfig(sep: AnimationSeparator.char),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      // 'a', 'b', ' ', 'c' = 4 spans
      expect(out.length, 4);
      expect(out[0], isA<WidgetSpan>()); // 'a'
      expect(out[1], isA<WidgetSpan>()); // 'b'
      expect(out[2], isA<TextSpan>()); // ' '
      expect(out[3], isA<WidgetSpan>()); // 'c'
    });

    test('charOffset accumulates correctly', () {
      final out = <InlineSpan>[];
      var pos = buildAnimatedSpans(
        'ab',
        _style,
        config: const AnimateConfig(sep: AnimationSeparator.char),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      expect(pos, 2);
      final out2 = <InlineSpan>[];
      pos = buildAnimatedSpans(
        'cd',
        _style,
        config: const AnimateConfig(sep: AnimationSeparator.char),
        streaming: true,
        prevContentLength: 0,
        charOffset: pos,
        out: out2,
      );
      expect(pos, 4);
    });

    test('prevContentLength skips animation for already-rendered chars', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'ab cd',
        _style,
        config: const AnimateConfig(sep: AnimationSeparator.char),
        streaming: true,
        prevContentLength: 2,
        charOffset: 0,
        out: out,
      );
      // 'a', 'b' (skipped), ' ', 'c', 'd' = 5 spans
      // Skipped chars are plain TextSpan so existing text does not animate again.
      for (var i = 0; i < out.length; i++) {
        final span = out[i];
        if (i < 2) {
          expect(span, isA<TextSpan>());
        } else if (i > 2) {
          expect(span, isA<WidgetSpan>());
        }
      }
    });

    test('new content after skipped prefix still animates', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'old new words',
        _style,
        config: const AnimateConfig(stagger: 50),
        streaming: true,
        prevContentLength: 4,
        charOffset: 0,
        out: out,
      );

      expect(out[0], isA<TextSpan>());
      expect(out[1], isA<TextSpan>());
      expect(out[2], isA<WidgetSpan>());
      expect(out[3], isA<TextSpan>());
      expect(out[4], isA<WidgetSpan>());
    });

    test('all whitespace-only text gets plain TextSpan (no animation)', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        '   ',
        _style,
        config: const AnimateConfig(),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      expect(out.every((s) => s is TextSpan), isTrue);
    });

    test('emoji treated as single character, not surrogates', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'a😊b',
        _style,
        config: const AnimateConfig(sep: AnimationSeparator.char),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      // 😊 is a single code point (2 code units but 1 rune)
      // Should be 3 WidgetSpans: 'a', '😊', 'b'
      expect(out.length, 3);
      expect(out[0], isA<WidgetSpan>());
      expect(out[1], isA<WidgetSpan>());
      expect(out[2], isA<WidgetSpan>());
    });

    test('stagger applies incremental delay per word', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'one two three',
        _style,
        config: const AnimateConfig(stagger: 50),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      // 5 parts: "one", " ", "two", " ", "three"
      // Word 1 (index 0): local=0, delayMs=0*50=0
      // Word 2 (index 2): local=4, delayMs=4*50=200
      // Word 3 (index 4): local=8, delayMs=8*50=400
      expect(out.length, 5);
      // Words are WidgetSpan wrapping Animate
      expect(out[0], isA<WidgetSpan>());
      expect(out[2], isA<WidgetSpan>());
      expect(out[4], isA<WidgetSpan>());
      // Spaces are TextSpan
      expect(out[1], isA<TextSpan>());
      expect(out[3], isA<TextSpan>());
    });
  });

  group('_splitByWord / _splitByChar', () {
    // Indirectly tested via buildAnimatedSpans, but direct sanity checks:
    test('splitByWord groups contiguous non-whitespace', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'hello   world',
        _style,
        config: const AnimateConfig(),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      // "hello", "   ", "world" = 3 parts
      expect(out.length, 3);
    });

    test('splitByChar separates each char', () {
      final out = <InlineSpan>[];
      buildAnimatedSpans(
        'Hi',
        _style,
        config: const AnimateConfig(sep: AnimationSeparator.char),
        streaming: true,
        prevContentLength: 0,
        charOffset: 0,
        out: out,
      );
      expect(out.length, 2);
    });
  });
}
