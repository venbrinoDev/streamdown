# streamdown

[![pub package](https://img.shields.io/pub/v/streamdown.svg)](https://pub.dev/packages/streamdown)
[![License: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

**Flicker-free streaming markdown renderer for Flutter AI apps.**

A drop-in replacement for `flutter_markdown` that handles partial code fences, half-finished tables, and mid-stream LaTeX without re-parsing the prefix on every chunk. Built for ChatGPT-style apps where every token counts.

> ⚠️ **Pre-release.** Currently scaffolding — API surface is locked, implementation lands across Phases 1–9. See [`PHASES.md`](PHASES.md).

---

## Why streamdown?

`flutter_markdown` re-parses the entire string on every chunk. For a 2000-token GPT response, that's ~400 re-parses + full re-highlight of code blocks + LaTeX re-renders. Result: visible flicker, jumping cursor, code blocks that flash unstyled → styled.

**streamdown** keeps an append-only AST, renders incomplete blocks provisionally (e.g., a half-finished ` ```dart ` becomes a code block immediately), and uses stable widget keys so Flutter's diff doesn't tear down + rebuild on every token.

|  | `flutter_markdown` | `streamdown` |
|---|---|---|
| Re-parse on every chunk | ✅ (slow) | ❌ (incremental) |
| Provisional code fence rendering | ❌ | ✅ |
| Provisional table rows | ❌ | ✅ |
| Stable widget keys during stream | ❌ | ✅ |
| Per-line syntax highlighting cache | ❌ | ✅ |
| LaTeX (optional) | ✅ | ✅ |
| Bundle size | ~80KB | <50KB |

---

## Install

```yaml
dependencies:
  streamdown: ^0.0.1
```

---

## Basic usage

```dart
import 'package:streamdown/streamdown.dart';

// Streaming (typical AI chat use case)
Streamdown(stream: openai.responseStream)

// Static (non-stream) markdown
Streamdown.text(fullMarkdownString)
```

That's it. Theme, code highlighting, link tap, and selectable text Just Work out of the box.

---

## Advanced usage

```dart
Streamdown(
  stream: openai.responseStream,
  syntaxTheme: SyntaxTheme.githubDark,
  latex: true,
  selectable: true,
  onLinkTap: (uri) => launchUrl(uri),
  codeBlockBuilder: (lang, code, isComplete) => MyCustomCodeBlock(...),
)
```

See [`example/`](example/) for six runnable scenarios including a side-by-side comparison with `flutter_markdown`.

---

## How it works

Three tricks combined:

1. **Incremental token-level parser** — new tokens extend the trailing AST node; the prefix is never re-tokenized.
2. **Provisional rendering** — an unclosed code fence renders as a code block immediately, then continues filling as lines stream in.
3. **Diff-stable widget keys** — every AST node gets a deterministic key so Flutter's element diff doesn't tear down existing widgets.

See [the architecture notes in CLAUDE.md](CLAUDE.md#architecture-the-moat).

---

## Status

| Feature category | Status |
|---|---|
| Streaming engine | 🚧 Phase 1–2 |
| Block-level markdown | 🚧 Phase 3 |
| Code blocks (incremental highlighting) | 🚧 Phase 4 |
| Tables | 🚧 Phase 5 |
| LaTeX | 🚧 Phase 6 |
| Example app + demo GIF | 🚧 Phase 7 |
| Tests + perf benchmarks | 🚧 Phase 8 |
| Pub.dev publish | 🎯 Phase 9 |

See [`TRACKER.md`](TRACKER.md) for live status.

---

## Contributing

Issues and PRs welcome. See [GitHub Issues](https://github.com/jayu1023/streamdown/issues).

## License

BSD-3-Clause. See [LICENSE](LICENSE).
