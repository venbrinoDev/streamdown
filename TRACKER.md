# streamdown — Phase Tracker

Living document. Update at the end of every working session.

**Source of truth for:** What's done, what's in flight, what's blocked, current velocity.

**Last updated:** 2026-05-22

---

## At-a-glance

| Metric | Value |
|---|---|
| Current phase | Phase 0 — Foundation |
| Phase progress | 5 / 13 tasks ✅ |
| Days elapsed | 1 |
| Days remaining (est.) | 9 |
| Target ship date | 2026-06-01 |
| 🔴 features done | 0 / 62 |
| 🔴 features in progress | 5 (F-DX-01, F-DX-06, F-DX-07, F-DX-09, F-DIST-05 — Phase 0) |
| Test coverage | n/a (no impl yet) |
| Open blockers | 0 |

---

## Phase status board

| # | Phase | Status | Start | End | Days | Tasks done | Blocker |
|---|---|---|---|---|---|---|---|
| 0 | Foundation | 🟡 In progress | 2026-05-22 | — | 0.5 | 5 / 13 | — |
| 1 | Tokenizer | ⚪ Not started | — | — | — | 0 / 8 | Phase 0 |
| 2 | Parser & AST | ⚪ Not started | — | — | — | 0 / 6 | Phase 1 |
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

## Phase 0 — Foundation (current)

| Task | Status | Notes |
|---|---|---|
| `flutter create --template=package streamdown` | 🟢 | Done 2026-05-22 |
| Write `CLAUDE.md` | 🟢 | Done 2026-05-22 |
| Write `FEATURES.md` | 🟢 | Done 2026-05-22 |
| Write `PHASES.md` | 🟢 | Done 2026-05-22 |
| Write `TRACKER.md` (this file) | 🟢 | Done 2026-05-22 |
| Update `pubspec.yaml` (desc/topics/repo/screenshots) | ⚪ | Next |
| Add prod deps: `flutter_highlight`, `url_launcher` | ⚪ | |
| Add optional dep (commented): `flutter_math_fork` | ⚪ | |
| Add dev deps: `flutter_lints`, `test` | ⚪ | (already present) |
| Strict lint config in `analysis_options.yaml` | ⚪ | |
| Replace placeholder `Calculator` in `lib/streamdown.dart` | ⚪ | |
| Create target folder structure | ⚪ | `lib/src/{parser,render,theme}/` |
| First commit | ⚪ | `chore: scaffold streamdown v0.0.1` |

---

## Feature progress (rolled up)

| Category | Total | Done | In progress | Blocked |
|---|---|---|---|---|
| Core Rendering | 7 | 0 | 0 | 0 |
| Streaming Engine | 8 | 0 | 0 | 0 |
| Block-level Markdown | 13 | 0 | 0 | 0 |
| Inline Markdown | 12 | 0 | 0 | 0 |
| Code Blocks | 11 | 0 | 0 | 0 |
| Tables | 6 | 0 | 0 | 0 |
| Math / LaTeX | 4 | 0 | 0 | 0 |
| Customization | 9 | 0 | 0 | 0 |
| Performance | 5 | 0 | 0 | 0 |
| Developer Experience | 9 | 0 | 5 | 0 |
| Quality / Testing | 8 | 0 | 0 | 0 |
| Distribution | 6 | 0 | 1 | 0 |
| Launch / Viral | 7 | 0 | 0 | 0 |
| **Total** | **88** | **0** | **6** | **0** |

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
| 2026-05-22 | 0 | 0.5 | Scaffold + 4 planning docs |

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
