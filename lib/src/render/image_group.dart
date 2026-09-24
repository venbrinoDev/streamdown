import 'package:flutter/widgets.dart';

import '../parser/ast.dart';

/// An image and its nearby label/caption in a Markdown answer.
@immutable
class MarkdownImageGroupItem {
  const MarkdownImageGroupItem({
    required this.title,
    required this.alt,
    required this.url,
    this.caption,
  });

  final String title;
  final String alt;
  final String? url;
  final String? caption;
}

/// Replaces a run of standalone Markdown images with an app-owned widget.
/// The first complete image is offered immediately, before the run closes.
typedef MarkdownImageGroupBuilder =
    Widget Function(
      BuildContext context,
      List<MarkdownImageGroupItem> items,
      bool isComplete,
    );

class ImageGroupMatch {
  const ImageGroupMatch(this.items, this.endIndex, this.isComplete);

  final List<MarkdownImageGroupItem> items;
  final int endIndex;
  final bool isComplete;
}

final _imageRe = RegExp(
  r'^!\[([^\]]*)\]\((https?://[^\s)]+)(?:\s+"[^"]*")?\)$',
);
final _boldTitleRe = RegExp(r'^\*\*(.{2,90})\*\*$');

ImageGroupMatch? readImageGroup(List<AstNode> nodes, int startIndex) {
  final first = _readImageItem(nodes, startIndex);
  if (first == null) return null;
  final items = <MarkdownImageGroupItem>[first.item];
  var end = first.endIndex;
  while (end < nodes.length) {
    final next = _readImageItem(nodes, end);
    if (next == null) break;
    items.add(next.item);
    end = next.endIndex;
  }
  final complete = nodes
      .skip(startIndex)
      .take(end - startIndex)
      .every((node) => node.isComplete);
  return ImageGroupMatch(items, end, complete);
}

({MarkdownImageGroupItem item, int endIndex})? _readImageItem(
  List<AstNode> nodes,
  int startIndex,
) {
  if (startIndex >= nodes.length || nodes[startIndex] is! ParagraphNode) {
    return null;
  }
  var nodeIndex = startIndex;
  String? title;
  var lines = _lines((nodes[nodeIndex] as ParagraphNode).text);
  if (lines.length == 1) {
    final label = _boldTitleRe.firstMatch(lines.single)?.group(1);
    if (label != null &&
        nodeIndex + 1 < nodes.length &&
        nodes[nodeIndex + 1] is ParagraphNode) {
      title = label;
      nodeIndex++;
      lines = _lines((nodes[nodeIndex] as ParagraphNode).text);
    }
  }
  if (lines.isEmpty) return null;
  var imageIndex = 0;
  final inlineTitle = _boldTitleRe.firstMatch(lines.first)?.group(1);
  if (inlineTitle != null && lines.length > 1) {
    title ??= inlineTitle;
    imageIndex = 1;
  }
  final image = _imageRe.firstMatch(lines[imageIndex]);
  final unavailable = lines[imageIndex] == 'Image unavailable';
  if (image == null && !unavailable) return null;
  if (lines.length > imageIndex + 2) return null;
  final alt = image?.group(1)?.trim() ?? title ?? 'Image';
  title ??= alt.isEmpty ? 'Image' : alt;
  String? caption;
  if (lines.length == imageIndex + 2) {
    caption = lines.last;
  }
  var endIndex = nodeIndex + 1;
  if (caption == null &&
      endIndex < nodes.length &&
      nodes[endIndex] is ParagraphNode) {
    final possible = _lines((nodes[endIndex] as ParagraphNode).text);
    if (possible.length == 1 && _isCaption(possible.single)) {
      caption = possible.single;
      endIndex++;
    }
  }
  return (
    item: MarkdownImageGroupItem(
      title: title,
      alt: alt,
      url: image?.group(2),
      caption: caption,
    ),
    endIndex: endIndex,
  );
}

List<String> _lines(String text) => text
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();

bool _isCaption(String text) =>
    text.startsWith('[') ||
    text.startsWith('Photo:') ||
    text.startsWith('Image source') ||
    (text.startsWith('*') && !text.startsWith('**'));
