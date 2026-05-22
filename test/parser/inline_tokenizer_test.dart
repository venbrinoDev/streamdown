import 'package:flutter_test/flutter_test.dart';
import 'package:streamdown/src/parser/inline_tokenizer.dart';
import 'package:streamdown/src/parser/token.dart';

void main() {
  group('InlineTokenizer — text & escapes', () {
    test('plain text → single InlineTextToken', () {
      expect(InlineTokenizer.tokenize('hello'), const [InlineTextToken('hello')]);
    });

    test('empty string → no tokens', () {
      expect(InlineTokenizer.tokenize(''), isEmpty);
    });

    test('backslash escape: \\* is literal *', () {
      expect(InlineTokenizer.tokenize(r'\*not bold\*'),
          const [InlineTextToken('*not bold*')]);
    });

    test('backslash before non-escapable is literal', () {
      expect(InlineTokenizer.tokenize(r'\a'), const [InlineTextToken(r'\a')]);
    });

    test('soft line break joins with a space', () {
      expect(InlineTokenizer.tokenize('one\ntwo'),
          const [InlineTextToken('one two')]);
    });

    test('hard break: trailing 2 spaces before \\n', () {
      final out = InlineTokenizer.tokenize('one  \ntwo');
      expect(out, const [
        InlineTextToken('one'),
        HardBreakToken(),
        InlineTextToken('two'),
      ]);
    });

    test('hard break: trailing \\ before \\n', () {
      final out = InlineTokenizer.tokenize('one\\\ntwo');
      expect(out, const [
        InlineTextToken('one'),
        HardBreakToken(),
        InlineTextToken('two'),
      ]);
    });
  });

  group('InlineTokenizer — code spans', () {
    test('single backtick code span', () {
      expect(InlineTokenizer.tokenize('`code`'), const [CodeSpanToken('code')]);
    });

    test('double backtick code span', () {
      expect(InlineTokenizer.tokenize('``co`de``'),
          const [CodeSpanToken('co`de')]);
    });

    test('code span strips one space on each side', () {
      expect(InlineTokenizer.tokenize('` a `'), const [CodeSpanToken('a')]);
    });

    test('unclosed backtick is literal', () {
      expect(InlineTokenizer.tokenize('`not a span'),
          const [InlineTextToken('`not a span')]);
    });

    test('code span before and after text', () {
      expect(InlineTokenizer.tokenize('a `b` c'), const [
        InlineTextToken('a '),
        CodeSpanToken('b'),
        InlineTextToken(' c'),
      ]);
    });
  });

  group('InlineTokenizer — emphasis & strong & strike', () {
    test('** emits two strong delims around the run', () {
      expect(InlineTokenizer.tokenize('**bold**'), const [
        StrongDelimToken(),
        InlineTextToken('bold'),
        StrongDelimToken(),
      ]);
    });

    test('* emits emphasis delims', () {
      expect(InlineTokenizer.tokenize('*em*'), const [
        EmphasisDelimToken('*'),
        InlineTextToken('em'),
        EmphasisDelimToken('*'),
      ]);
    });

    test('_ emits emphasis delims', () {
      expect(InlineTokenizer.tokenize('_em_'), const [
        EmphasisDelimToken('_'),
        InlineTextToken('em'),
        EmphasisDelimToken('_'),
      ]);
    });

    test('*** emits strong + emphasis', () {
      expect(InlineTokenizer.tokenize('***x***'), const [
        StrongDelimToken(),
        EmphasisDelimToken('*'),
        InlineTextToken('x'),
        StrongDelimToken(),
        EmphasisDelimToken('*'),
      ]);
    });

    test('strikethrough', () {
      expect(InlineTokenizer.tokenize('~~gone~~'), const [
        StrikeDelimToken(),
        InlineTextToken('gone'),
        StrikeDelimToken(),
      ]);
    });

    test('mixed inlines preserve order', () {
      expect(InlineTokenizer.tokenize('a *b* `c` **d**'), const [
        InlineTextToken('a '),
        EmphasisDelimToken('*'),
        InlineTextToken('b'),
        EmphasisDelimToken('*'),
        InlineTextToken(' '),
        CodeSpanToken('c'),
        InlineTextToken(' '),
        StrongDelimToken(),
        InlineTextToken('d'),
        StrongDelimToken(),
      ]);
    });
  });

  group('InlineTokenizer — links & images', () {
    test('basic link', () {
      expect(
        InlineTokenizer.tokenize('[text](https://x.com)'),
        const [LinkToken(text: 'text', url: 'https://x.com')],
      );
    });

    test('link with title', () {
      expect(
        InlineTokenizer.tokenize('[t](https://x.com "hi")'),
        const [LinkToken(text: 't', url: 'https://x.com', title: 'hi')],
      );
    });

    test('image syntax', () {
      expect(
        InlineTokenizer.tokenize('![alt](https://x.com/i.png)'),
        const [LinkToken(text: 'alt', url: 'https://x.com/i.png', isImage: true)],
      );
    });

    test('link with bracketed text inside', () {
      expect(
        InlineTokenizer.tokenize('[a [b] c](u)'),
        const [LinkToken(text: 'a [b] c', url: 'u')],
      );
    });

    test('unclosed link is literal', () {
      final out = InlineTokenizer.tokenize('[half(');
      // We don't bail to a Link; the `[` becomes part of plain text run.
      expect(out.first, isA<InlineTextToken>());
    });
  });

  group('InlineTokenizer — autolinks', () {
    test('http autolink', () {
      expect(InlineTokenizer.tokenize('<https://x.com>'),
          const [AutolinkToken('https://x.com')]);
    });

    test('mailto autolink', () {
      expect(InlineTokenizer.tokenize('<mailto:a@b.com>'),
          const [AutolinkToken('mailto:a@b.com')]);
    });

    test('non-autolink <foo> is literal', () {
      final out = InlineTokenizer.tokenize('<not a link>');
      expect(out.first, isA<InlineTextToken>());
    });
  });
}
