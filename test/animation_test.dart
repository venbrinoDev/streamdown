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
      // ignore: deprecated_member_use_from_same_package
      expect(config.sep, AnimationSeparator.word);
      // ignore: deprecated_member_use_from_same_package
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

    test('streaming prose remains one continuous TextSpan', () {
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
      expect(out, hasLength(1));
      expect(out.single, isA<TextSpan>());
      expect((out.single as TextSpan).text, 'hello world');
    });

    test('deprecated char separator does not fragment prose', () {
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
      expect(out, hasLength(1));
      expect((out.single as TextSpan).text, 'ab c');
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

    test('previous content length does not fragment the text run', () {
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
      expect(out, hasLength(1));
      expect((out.single as TextSpan).text, 'ab cd');
    });

    test('new content after an existing prefix remains continuous', () {
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

      expect(out, hasLength(1));
      expect((out.single as TextSpan).text, 'old new words');
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
      expect(out, hasLength(1));
      expect((out.single as TextSpan).text, 'a😊b');
    });

    test('deprecated stagger does not fragment prose', () {
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
      expect(out, hasLength(1));
      expect((out.single as TextSpan).text, 'one two three');
    });
  });
}
