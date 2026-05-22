# Publishing streamdown to pub.dev

Status checks already passed:

- ✅ `flutter analyze` — 0 issues
- ✅ `flutter test` — 224 passed
- ✅ `dart format --set-exit-if-changed lib test` — 0 changed
- ✅ `dart pub publish --dry-run` — 0 warnings
- ✅ `pana .` — **160/160 pub points**

What's left is two manual steps + the launch.

---

## Step 1 — Record the hero GIF (5 minutes)

The single most important launch asset. See [`example/screenshots/RECORDING.md`](example/screenshots/RECORDING.md) for tool recommendations and exact dimensions.

Quick path:

```bash
cd example
flutter run -d macos   # or windows / linux

# In the app: open "1. Comparison demo" → press "Stream again" → record
```

Save the GIF as `example/screenshots/split_screen_demo.gif` and then uncomment the screenshot block in `pubspec.yaml`:

```yaml
screenshots:
  - description: 'Split-screen demo: flutter_markdown (left, janky) vs streamdown (right, smooth).'
    path: example/screenshots/split_screen_demo.gif
```

Commit the GIF before publishing:

```bash
git add example/screenshots/split_screen_demo.gif pubspec.yaml
git commit -m "docs: add hero demo GIF"
git push
```

---

## Step 2 — Publish to pub.dev

```bash
cd "/Users/limbanijayhasmukhbhai/Downloads/jayu pcakage/streamdown"

# Final sanity check
dart pub publish --dry-run

# When dry-run is happy, ship it.
dart pub publish
```

`dart pub publish` opens a Google account login in your browser the first time. Use whichever account you want to be the verified publisher.

After publishing, verify on pub.dev:

- URL: <https://pub.dev/packages/streamdown>
- The "Scores" tab should show **160/160** within ~5 minutes (it takes a few minutes for pana to run on their side).
- Confirm topics (`ai`, `markdown`, `streaming`, `llm`, `chat`) appear.
- Confirm the screenshot displays in the sidebar.

---

## Step 3 — Launch posts

### Tweet (draft — copy into X / Bluesky)

> I just shipped **streamdown** on pub.dev — flicker-free streaming markdown for Flutter AI apps.
>
> `flutter_markdown` re-parses the whole string on every chunk. Streamdown is **188× faster** on chunked input — closed blocks never re-render.
>
> Drop-in replacement, one line of code:
>
> `Streamdown(stream: openai.responseStream)`
>
> 🎬 [embed GIF]
> 📦 https://pub.dev/packages/streamdown
> 🐙 https://github.com/jayu1023/streamdown

Tag `@FlutterDev` and `@vercel` (since their JS [streamdown.ai](https://streamdown.ai/) inspired the idea).

### r/FlutterDev post (draft)

**Title:** I built a flicker-free streaming markdown renderer for AI chat apps (188× faster than re-parsing)

```
Hey r/FlutterDev,

Every time I built a ChatGPT-style app with `flutter_markdown`, the same
problem: each new token triggers a full re-parse of the entire response,
so code blocks flash unstyled → styled → unstyled, tables jitter, and
the whole thing feels jittery.

I just shipped **streamdown**, a drop-in replacement that keeps an
append-only AST. Closed blocks never re-render. Provisional rendering
handles half-finished code fences. Stable monotonic widget keys mean
Flutter's element diff doesn't tear down what's already on screen.

The headline benchmark: 188× faster than naive re-parse on 5KB markdown
with 4-char chunks (about what OpenAI streams).

Drop-in usage:

  Streamdown(stream: openai.responseStream)

That's the whole API for the common case. There's also Streamdown.text()
for cached content, optional syntax themes, a codeBlockBuilder hook for
full customization, latex flag for $..$ and $$..$$ math, and selectable
text via SelectionArea by default.

Repo:    https://github.com/jayu1023/streamdown
Pub.dev: https://pub.dev/packages/streamdown
Demo:    [embed GIF here]

Built it as a solo-dev side project. Feedback welcome — especially edge
cases in markdown variants I haven't covered.
```

### Flutter Weekly newsletter

Submit at: <https://flutterweekly.net/submissions>

- **Title:** streamdown — flicker-free streaming markdown for Flutter AI apps
- **URL:** https://pub.dev/packages/streamdown
- **Description:** 188× faster than naive re-parse. Drop-in `Streamdown(stream:…)` widget. 224 tests, full CI, pub-points 160/160.

### Engagement (first 24 hours)

- Reply to every comment on the Tweet and Reddit post.
- Open a GitHub issue / discussion stub for "Ideas welcome" so newcomers have a place to land.
- Pin the repo on your GitHub profile: `gh repo edit --add-topic flutter --add-topic dart --add-topic ai --add-topic markdown jayu1023/streamdown`

---

## Step 4 — After launch

- Write a technical blog post on the incremental-parsing approach. Hacker News bait.
- Apply for `dart pub publisher` verification on pub.dev (visible bonus points + trust signal).
- Watch issues for the first week. Address any 🔴 P0 bugs within 24 hours; minor stuff within a week.
- Tag `v0.0.1` on GitHub after publish so the release page links the commit.

---

## Phase 9 task checklist

- [x] Pre-publish quality gates (analyze, test, format, dry-run)
- [x] pana scoring (160/160)
- [x] Public API dartdoc (Streamdown, SyntaxTheme, CodeBlockBuilder)
- [x] CHANGELOG 0.0.1 entry
- [x] This handoff document
- [ ] **YOU**: record the hero GIF
- [ ] **YOU**: `dart pub publish`
- [ ] **YOU**: launch tweet + Reddit + Flutter Weekly
- [ ] **YOU**: monitor first 24h
