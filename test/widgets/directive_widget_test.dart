import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:streamdown/streamdown.dart';

void main() {
  testWidgets('plain Markdown does not consume a directive without a builder', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Streamdown.text(':::jv-place\ntitle: A\n:::\n')),
      ),
    );
    expect(find.textContaining(':::jv-place'), findsWidgets);
    expect(find.textContaining('Visual item unavailable'), findsNothing);
  });

  testWidgets('hides a split directive opener before its name is complete', (
    tester,
  ) async {
    final chunks = StreamController<String>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Streamdown(
            stream: chunks.stream,
            animated: false,
            directiveBuilder: (_, node) =>
                Text(node.first('title') ?? 'waiting'),
          ),
        ),
      ),
    );

    chunks.add('Before\n\n:::jv-');
    await tester.pump();
    expect(find.textContaining(':::jv-'), findsNothing);

    chunks.add('place\ntitle: A place\n');
    await tester.pump();
    await tester.pump();
    expect(find.text('A place'), findsOneWidget);
    await chunks.close();
  });

  testWidgets('updates an open native block as complete field lines stream', (
    tester,
  ) async {
    final chunks = StreamController<String>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Streamdown(
            stream: chunks.stream,
            animated: false,
            directiveBuilder: (_, node) =>
                Text(node.first('title') ?? 'waiting'),
          ),
        ),
      ),
    );

    chunks.add('Before\n\n:::jv-place\ntitle: Colo');
    await tester.pump();
    expect(find.text('waiting'), findsOneWidget);
    expect(find.textContaining('Colo'), findsNothing);
    expect(find.textContaining(':::jv'), findsNothing);

    chunks.add('sseum\nsubtitle: Rome\n');
    await tester.pump();
    await tester.pump();
    expect(find.text('Colosseum'), findsOneWidget);
    expect(find.textContaining('subtitle:'), findsNothing);

    chunks.add(':::\n\nAfter');
    await chunks.close();
    await tester.pump();
    expect(find.text('Colosseum'), findsOneWidget);
    expect(find.textContaining('After'), findsWidgets);
  });
}
