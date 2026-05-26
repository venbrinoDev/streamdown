# streamdown — Quick Wins (Free + Fast)

**Total time: ~30 minutes. Total cost: $0.** Everything here is free and quick. Bigger items (custom domain, v0.2 build) live in [`USER_ACTIONS.md`](USER_ACTIONS.md).

**Updated:** 2026-05-26 (post v0.1.0 ship)

---

## ⏱ 30-minute sprint order

| # | Action | Time | Cost |
|---|---|---|---|
| 1 | Verify publisher domain (DNS TXT record) | 5 min | $0 |
| 2 | Submit Awesome Flutter PR | 10 min | $0 |
| 3 | Deploy demo to GitHub Pages | 5 min | $0 |
| 4 | Tweet `@fluttertap` | 30 sec | $0 |
| 5 | Post in Flutter Discord `#showcase` | 1 min | $0 |
| 6 | Email Flutter Digest | 2 min | $0 |
| 7 | Email Flutter Insider | 2 min | $0 |
| 8 | Post in r/Flutter (next morning 8 AM EDT) | 3 min | $0 |

---

# 1. Verify publisher domain *(5 min)*

Removes "unverified uploader" label on pub.dev — biggest trust lift.

1. Go to https://pub.dev/packages/streamdown/admin
2. Click **Verify publisher** → enter `dev.jayu`
3. Copy the `pub-verification=...` TXT record pub.dev gives you
4. Add it to your DNS provider as a TXT record on `@` (root)
5. Wait 5 min, click **Verify** on pub.dev

✅ Done when verified badge appears next to publisher name.

---

# 2. Submit Awesome Flutter PR *(10 min)*

Permanent Google-indexed backlink.

1. Fork https://github.com/Solido/awesome-flutter
2. Edit `README.md` → find `### Markdown` section
3. Add this line (alphabetical, after `markdown_widget`):

```markdown
* [streamdown](https://github.com/jayu1023/streamdown) - Flicker-free streaming markdown renderer for Flutter AI apps. 188× faster than `flutter_markdown` on chunked input. Drop-in API for ChatGPT-style streaming UIs.
```

4. Commit, click **Compare & pull request**

**PR title:**
```
Add streamdown — streaming markdown renderer for Flutter AI apps
```

**PR body:**
```
Hi! Adding a new entry under **Markdown**:

**streamdown** — a flicker-free streaming markdown renderer purpose-built for Flutter AI chat apps. It replaces `flutter_markdown`'s "re-parse every chunk" approach with an append-only AST + stable widget keys, so closed blocks never re-render mid-stream.

- 📦 pub.dev: https://pub.dev/packages/streamdown (160/160 pub points)
- 🐙 Source: https://github.com/jayu1023/streamdown
- 📊 Benchmark: ~188× faster than naive re-parse on 5KB markdown streamed in 4-char chunks
- ⚙️ Drop-in API: `Streamdown(stream: openai.responseStream)`
- 🪪 License: BSD-3-Clause

Demo GIF: https://github.com/jayu1023/streamdown/blob/main/example/screenshots/split_screen_demo.gif

Thanks for maintaining this list!
```

5. ⭐ Star the repo + reply to maintainer within 24h

---

# 3. Deploy demo to GitHub Pages *(5 min)*

Web build is already done at `example/build/web/`. Just push it.

```bash
cd "/Users/limbanijayhasmukhbhai/Downloads/jayu pcakage/streamdown/example/build/web"
git init && git checkout -b gh-pages
git add . && git commit -m "Deploy streamdown demo"
git remote add origin https://github.com/jayu1023/streamdown.git
git push -f origin gh-pages
```

Then on GitHub: **Settings → Pages → Source: `gh-pages` branch / `/root`** → Save.

✅ Demo live at `https://jayu1023.github.io/streamdown/` in ~2 min.

---

# 4. Flutter Tap tweet *(30 sec)*

Tweet this with the demo GIF attached:

```
@fluttertap might be useful for your readers — shipped streamdown 0.1.0 today, a flicker-free streaming markdown renderer for Flutter AI apps. 188× faster than flutter_markdown on chunked input. Drop-in API:

Streamdown(stream: openai.responseStream)

📦 https://pub.dev/packages/streamdown
```

GIF path: `example/screenshots/split_screen_demo.gif`

---

# 5. Flutter Discord post *(1 min)*

Join https://discord.gg/flutter → `#showcase` channel → paste:

````
Just shipped **streamdown 0.1.0** — a flicker-free streaming markdown renderer for Flutter AI chat apps 📦

It's a drop-in replacement for `flutter_markdown` that doesn't re-parse on every chunk. ~188× faster on chunked input. Closed blocks never re-render mid-stream.

```dart
Streamdown(stream: openai.responseStream)
```

That's the entire API for the common case. Theme, syntax highlighting, link tap, and selectable text Just Work.

📦 pub.dev: https://pub.dev/packages/streamdown
🐙 source: https://github.com/jayu1023/streamdown

Feedback welcome — especially edge cases I haven't hit yet 🙏
````

Attach the demo GIF.

---

# 6. Flutter Digest email *(2 min)*

Submit at https://flutterdigest.substack.com or DM the curator on Twitter.

**Subject:**
```
Package submission: streamdown — streaming markdown for Flutter AI apps
```

**Body:**
```
Hi,

Just shipped streamdown 0.1.0 on pub.dev — a streaming markdown renderer
built for Flutter AI chat apps. Think drop-in replacement for
flutter_markdown, but with no flicker on partial code fences, tables, or
LaTeX. ~188× faster than naive re-parse on chunked input.

Drop-in API:
    Streamdown(stream: openai.responseStream)

Would love to be included in an upcoming issue if it fits.

📦 https://pub.dev/packages/streamdown
🐙 https://github.com/jayu1023/streamdown
📊 Benchmark + writeup: https://github.com/jayu1023/streamdown#why-streamdown

Thanks!
— Jayu
```

---

# 7. Flutter Insider email *(2 min)*

Same body as Flutter Digest. Subject:

```
streamdown 0.1.0 — flicker-free streaming markdown for AI chat apps
```

---

# 8. r/Flutter post *(3 min — tomorrow 8–10 AM EDT)*

⚠️ Post in **r/Flutter** (NOT r/FlutterDev — different sub, fresh audience).

Go to https://reddit.com/r/Flutter/submit → Text post.

**Title:**
```
Engineering writeup: how I made markdown rendering 188× faster for Flutter streaming AI apps
```

**Body:**
````
Cross-posting the engineering side of a package I shipped last week
(originally r/FlutterDev got the launch announcement — this one's a
deeper dive on the technique).

The problem: flutter_markdown re-parses the entire response on every
streamed token. For a 2000-token GPT reply that's ~400 full re-parses +
re-highlight passes. You see it as flicker, jumping cursors, and code
blocks flashing unstyled → styled.

The fix is three tricks stacked:

1. **Incremental tokenizer** — new tokens extend the trailing AST node;
   the prefix is never re-scanned.
2. **Provisional rendering** — an unclosed ```dart fence renders as a
   code block *immediately*, then fills in as lines stream. No flash.
3. **Diff-stable widget keys** — every AST node gets a monotonic ID used
   as the Flutter widget key. Flutter's element diff doesn't tear down
   what's already on screen.

Result: 188× faster than naive re-parse on 5KB markdown with 4-char
chunks (roughly OpenAI's stream cadence). 100KB stream parses end-to-end
in under 10ms.

Source + benchmark code:
https://github.com/jayu1023/streamdown
https://pub.dev/packages/streamdown

Happy to dig into any of the three tricks if anyone's curious.
````

**Rules:**
- Don't beg for upvotes — Reddit penalizes it
- Reply to every comment within 30 min for the first 2 hours

---

## 📅 Recommended pacing (don't blast all at once)

| When | Do |
|---|---|
| **Right now** | Steps 1–3 (DNS, PR, GH Pages) |
| **Today morning** | Steps 4 + 6 (Twitter + Flutter Digest email) |
| **Today evening** | Step 5 (Discord) |
| **Tomorrow morning** | Step 7 (Flutter Insider) |
| **Tomorrow 8–10 AM EDT** | Step 8 (r/Flutter) |

Spread = compound impressions across 48 hours = more sustained traffic spike than a single-day blast.

---

## Bigger items (parked in [`USER_ACTIONS.md`](USER_ACTIONS.md))

Skipped from this doc because they cost money OR take more than 30 min:

- ⏳ Custom domain `streamdown.dev` ($12/yr)
- ⏳ v0.2 feature decision + build (1–2 weeks)
- ⏳ Influencer + integration seeding (ongoing outreach)
