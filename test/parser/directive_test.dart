import 'package:flutter_test/flutter_test.dart';
import 'package:streamdown/src/parser/ast.dart';
import 'package:streamdown/src/parser/parser.dart';
import 'package:streamdown/src/parser/tokenizer.dart';

void main() {
  test(
    'completed fields update an open directive without exposing partial lines',
    () {
      final tokenizer = Tokenizer(enableDirectives: true);
      final parser = Parser();
      parser.feed(tokenizer.feed('Before\n\n:::jv-place\ntitle: Colos'));
      final block = parser.document.children.last as DirectiveNode;
      expect(block.first('title'), isNull);
      expect(block.isComplete, isFalse);

      parser.feed(tokenizer.feed('seum\nsubtitle: Rome\n'));
      expect(block.first('title'), 'Colosseum');
      expect(block.first('subtitle'), 'Rome');
      expect(block.isComplete, isFalse);

      parser.feed(tokenizer.feed(':::\n\nAfter\n'));
      expect(block.isComplete, isTrue);
      expect(parser.document.children.last, isA<ParagraphNode>());
    },
  );

  test('directive-like text in a code fence remains code', () {
    final tokenizer = Tokenizer(enableDirectives: true);
    final parser = Parser();
    parser.feed(tokenizer.feed('```\n:::jv-place\ntitle: X\n:::\n```\n'));
    parser.feed(tokenizer.complete());
    parser.complete();
    expect(parser.document.children, hasLength(1));
    expect(parser.document.children.single, isA<CodeBlockNode>());
  });

  test('malformed line marks directive invalid and a new opener recovers', () {
    final tokenizer = Tokenizer(enableDirectives: true);
    final parser = Parser();
    parser.feed(
      tokenizer.feed(
        ':::jv-place\ntitle: A\nnot a field\n:::jv-story\ntitle: B\n:::\n',
      ),
    );
    final first = parser.document.children.first as DirectiveNode;
    final second = parser.document.children.last as DirectiveNode;
    expect(first.isValid, isFalse);
    expect(second.first('title'), 'B');
    expect(second.isComplete, isTrue);
  });

  test('invalid fields stay hidden until the closing marker', () {
    final tokenizer = Tokenizer(enableDirectives: true);
    final parser = Parser();
    parser.feed(
      tokenizer.feed(
        'Before\n\n:::jv-place\ntitle: A\nnot a field\nsubtitle: Hidden\n:::\n\nAfter\n',
      ),
    );
    parser.feed(tokenizer.complete());
    parser.complete();
    final block = parser.document.children[1] as DirectiveNode;
    expect(block.isValid, isFalse);
    expect(block.first('subtitle'), isNull);
    expect((parser.document.children.last as ParagraphNode).text, 'After');
  });

  test('directives remain Markdown when no renderer opted in', () {
    final tokenizer = Tokenizer();
    final parser = Parser();
    parser.feed(tokenizer.feed(':::jv-place\ntitle: A\n:::\n'));
    parser.feed(tokenizer.complete());
    parser.complete();
    expect(parser.document.children.whereType<DirectiveNode>(), isEmpty);
    expect(
      (parser.document.children.single as ParagraphNode).text,
      ':::jv-place\ntitle: A\n:::',
    );
  });
}
