# streamdown — Phase Tracker

Living document. Update at the end of every working session.

**Source of truth for:** What's done, what's in flight, what's blocked, current velocity.

**Last updated:** 2026-05-22 (end of Day 2 morning, Phase 1 complete)

---

## At-a-glance

| Metric | Value |
|---|---|
| Current phase | Phase 2 — Parser & AST (next) |
| Phase progress | Phase 0: 13 / 13 ✅ · Phase 1: 8 / 8 ✅ |
| Days elapsed | 2 |
| Days remaining (est.) | 8 |
| Target ship date | 2026-06-01 |
| 🔴 features done | 8 / 62 (Phase 0 + F-STREAM-01, F-STREAM-05, F-TEST-01) |
| 🔴 features in progress | 0 |
| Test coverage | 101 tests passing (tokenizer + inline tokenizer) |
| Open blockers | 0 |
| Commits | 2 |

---

## Phase status board

| # | Phase | Status | Start | End | Days | Tasks done | Blocker |
|---|---|---|---|---|---|---|---|
| 0 | Foundation | 🟢 Done | 2026-05-22 | 2026-05-22 | 0.5 | 13 / 13 | — |
| 1 | Tokenizer | 🟢 Done | 2026-05-22 | 2026-05-22 | 1.0 | 8 / 8 | — |
| 2 | Parser & AST | ⚪ Not started (ready) | — | — | — | 0 / 6 | — |
| 3 | Renderer Core | ⚪ Not started | — | — | — | 0 / 8 | Phase 2 |
| 4 | Code Blocks | ⚪ Not started | — | — | — | 0 / 10 | Phase 3 |
| 5 | Tables | ⚪ Not started | — | — | — | 0 / 6 | Phase 3 |
| 6 | Polish & Optional | ⚪ Not started | — | — | — | 0 / 8 | Phase 5 |
| 7 | Example App + Demo | ⚪ Not started | — | — | — | 0 / 10 | Phase 6 |
| 8 | Testing & Perf | ⚪ Not started | — | — | — | 0 / 8 | Phase 6 |
| 9 | Publish & Launch | ⚪ Not started | — | — | — | 0 / 12 | Phase 7+8 |
| 10 | Post-launch | ⚪ Not started | — | — | — | 0 / 5 | Phase 9 |

**Legend:** ⚪ Not started · 🟡 In progress · 🟢 Done · 🔴 Blocked · ⚫ Skipped

---

## Phase 0 — Foundation ✅ COMPLETE

| Task | Status | Notes |
|---|---|---|
| `flutter create --template=package streamdown` | 🟢 | Done 2026-05-22 |
| Write `CLAUDE.md` | 🟢 | Done 2026-05-22 |
| Write `FEATURES.md` | 🟢 | Done 2026-05-22 — 88 features tracked |
| Write `PHASES.md` | 🟢 | Done 2026-05-22 — 10 phases |
| Write `TRACKER.md` (this file) | 🟢 | Done 2026-05-22 |
| Update `pubspec.yaml` (desc/topics/repo/screenshots) | 🟢 | Done — topics: ai, markdown, streaming, llm, chat |
| Add prod deps: `flutter_highlight`, `url_launcher` | 🟢 | flutter_highlight 0.7.0 + url_launcher 6.3.2 |
| Add optional dep (commented): `flutter_math_fork` | 🟢 | Commented; uncomment in Phase 6 |
| Add dev deps: `flutter_lints`, `test` | 🟢 | flutter_lints 5.0.0 |
| Strict lint config in `analysis_options.yaml` | 🟢 | strict-casts, strict-inference, single-quotes, trailing-commas |
| Replace placeholder `Calculator` in `lib/streamdown.dart` | 🟢 | Library doc only — Phase 1+ adds real exports |
| Create target folder structure | 🟢 | `lib/src/{parser,render,theme}/`, `example/screenshots/`, `test/golden/` |
| First commit | 🟢 | `ad9310f chore: scaffold streamdown v0.0.1` |

**Phase 0 verification (DoD):**
- ✅ `flutter analyze` → 0 issues
- ✅ `flutter test` → 1 placeholder test passes
- ✅ Folder structure matches CLAUDE.md target layout
- ✅ Initial commit on `main`
- ✅ All deps resolve cleanly via `flutter pub get`

**Notes:**
- Git repo initialized inside `streamdown/` (separate from parent project folder)
- Identity used for commit: `jayu <hello@uplers.com>` (set via ephemeral `git -c`, not global config)
- TODO before publish: create actual GitHub repo at `https://github.com/jayu/streamdown` (currently a placeholder in pubspec)

---

## Feature progress (rolled up)

| Category | Total | Done | In progress | Blocked |
|---|---|---|---|---|
| Core Rendering | 7 | 0 | 0 | 0 |
| Streaming Engine | 8 | 2 | 0 | 0 |
| Block-level Markdown | 13 | 0 | 0 | 0 |
| Inline Markdown | 12 | 0 | 0 | 0 |
| Code Blocks | 11 | 0 | 0 | 0 |
| Tables | 6 | 0 | 0 | 0 |
| Math / LaTeX | 4 | 0 | 0 | 0 |
| Customization | 9 | 0 | 0 | 0 |
| Performance | 5 | 0 | 0 | 0 |
| Developer Experience | 9 | 4 | 0 | 0 |
| Quality / Testing | 8 | 1 | 0 | 0 |
| Distribution | 6 | 1 | 0 | 0 |
| Launch / Viral | 7 | 0 | 0 | 0 |
| **Total** | **88** | **8** | **0** | **0** |

---

## Decision log

Record any non-obvious decision here so future-you (or future-Claude) doesn't re-litigate it.

| Date | Decision | Rationale |
|---|---|---|
| 2026-05-22 | Build streamdown 1st, paywall_kit 2nd | streamdown solves universal AI-app pain, smaller scope, open lane, no existing dominant competitor on pub.dev |
| 2026-05-22 | Append-style chunk stream (not cumulative) as default API | Matches OpenAI/Anthropic/Gemini SDK conventions; cumulative would force O(n²) re-parse |
| 2026-05-22 | LaTeX behind a flag, not always-on | Keeps base bundle <50KB; most chat apps don't need math |
| 2026-05-22 | BSD-3-Clause license | Matches Flutter ecosystem default; less friction for adoption |
| 2026-05-22 | `flutter_highlight` for syntax highlighting (not roll our own) | Mature, 200+ langs, low maintenance burden |
| 2026-05-22 | Two-class tokenizer split: block tokenizer is incremental (line-based, append-only), inline tokenizer is pure/non-incremental | Block tokenization needs to handle stream boundaries; inline tokenization runs on short paragraph text and is fast enough to re-run from scratch on each chunk |
| 2026-05-22 | Emphasis/strong/strike emitted as raw delimiter tokens (`StrongDelimToken`, `EmphasisDelimToken`, `StrikeDelimToken`); parser pairs them | Avoids re-implementing CommonMark's "process emphasis" algorithm twice; pairing requires context only the parser has |

---

## Blocker log

| Date opened | Description | Phase | Status | Resolution |
|---|---|---|---|---|
| — | — | — | — | — |

(none yet)

---

## Velocity / time log

| Date | Phase | Hours worked | Notes |
|---|---|---|---|
| 2026-05-22 | 0 | 1.5 | Phase 0 complete: scaffold + 4 planning docs + deps + lints + folder structure + first commit. Analyze clean, test green. |
| 2026-05-22 | 1 | 1.0 | Phase 1 complete: Token sealed hierarchy (16 token types), incremental block Tokenizer (line-based state machine, fence-aware), InlineTokenizer (delimiters + code spans + links/images + autolinks + hard breaks). 101 tests passing — chunked-vs-whole equivalence verified across 10 samples × 3 chunk sizes + append-only invariant + perf benchmark. |

---

## Definition of "shippable"

The package is ready for `dart pub publish` when ALL of these are true:

- [ ] All 🔴 features in FEATURES.md have a checkbox somewhere here
- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] Test coverage ≥85%
- [ ] Example app runs on iOS + Android + web + macOS
- [ ] README has install + usage + comparison table + GIF
- [ ] Hero demo GIF exists in `example/screenshots/` and pubspec
- [ ] `dart pub publish --dry-run` shows 0 warnings
- [ ] Pub.dev pub points ≥130/140 (verified after publish)

---

## Session checklist (update at end of every working session)

Before closing the session:

1. Update the "At-a-glance" table
2. Move tasks from ⚪ → 🟡 → 🟢 in the current phase board
3. Update "Days elapsed" + "Days remaining"
4. If a decision was made, log it in the Decision log
5. If a blocker hit, log it in the Blocker log
6. Update "Last updated" date at top
