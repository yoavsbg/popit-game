# Pop It: App Store (iOS) ASO metadata

Copy-paste ready for App Store Connect. Character counts were checked by script (limits in brackets).
Companion file for Google Play: `aso-google-play.md`.

## How the App Store indexes (why the copy looks like this)

- Apple indexes **app name + subtitle + keyword field** (and the category). It does **not** index the
  description or promo text, so those are written for conversion, not keywords.
- Words repeated across name, subtitle and keywords are wasted. Each word appears **once** across the three.
  Apple combines words from different fields into phrases itself (e.g. "bubble" + "popper" + "fidget" + "toy"
  covers "fidget toy", "bubble pop", "pop it fidget").
- Plurals and singulars are matched automatically; no need for both. Spaces after commas waste characters.
- Do not include "game", "free", "best", "#1" or competitor names (rejection risk, and "game" is the category).
- Seed phrase strategy: own **"pop it"** (huge volume, high competition) with **"fidget"/"bubble"** (the genre),
  and win long-tail through **speed/reaction/timer/relaxing** where the game is genuinely different.

## Fields

| Field | Value | Count |
|---|---|---|
| App name | `Pop It: Fidget Bubble Popper` | 28 / 30 |
| Subtitle | `Satisfying Speed Tap Challenge` | 30 / 30 |
| Keywords | `relaxing,calm,sensory,stress,relief,toy,anxiety,asmr,bubbles,wrap,brain,focus,timer,reaction,kids` | 97 / 100 |
| Promotional text (editable any time, no review) | see below | 150 / 170 |
| Primary category | Games, subcategory **Casual** (add **Puzzle** as second subcategory) | |
| Secondary category | Games > Puzzle | |
| Age rating | 4+ (no objectionable content) | |
| Price | Free | |
| Support URL / Privacy URL | required, to create (see "Still to do") | |
| Copyright | `2026 Yoav Sabag` | |

Alternative names to A/B test (Product Page Optimization or a version swap) after 2-3 weeks of data:

1. `Pop It: Fidget Bubble Popper` (current, genre-forward)
2. `Pop It: Bubble Pop Fidget Toy` (29, leans on the "fidget toy" query; more crowded)
3. `Pop It Rush: Bubble Speed Tap` (29, brand-forward, more distinctive but loses "fidget")

Alternative subtitles: `Relaxing Reaction Time Race` (27), `Tap Fast. Relax. Beat the Clock` (31, too long, trim).

### Promotional text (170 max)

```
Pop only the ringed bubbles and race the clock. 200 levels of flashing and moving targets, plus a relaxing free-pop mode. Can you beat your best time?
```

### Description (4000 max, conversion copy; not indexed)

```
Pop the bubbles. Beat the clock. Chase a faster time.

Pop It is a satisfying bubble-popping game with a competitive twist. Only the ringed bubbles count. Pop them as fast as you can, avoid the wrong ones (each costs you a full second), and set a new personal best.

HOW IT WORKS
- Find the ringed bubbles and tap them
- A tap on a plain bubble adds 1.000 seconds to your time
- Clear every target to finish the level
- Your best time is saved for every level, so you can always beat yourself

200 LEVELS THAT KEEP GETTING SMARTER
- Warm-up levels to learn the feel
- More targets, more boards, one running timer
- Flashing targets whose rings blink on and off
- Moving targets that slide across the board
- Mixed levels that flash AND move
- Clear a level and the next one starts by itself, so you stay in the flow
- You are never blocked: a slow clear still unlocks the next level

FREE POP MODE
No timer, no pressure. Just pop, flip and relax. Switch between Rainbow, Candy and Ocean bubble themes and enjoy the soft pops and gentle haptics. Perfect for a calm moment, a break or a fidget fix.

MADE TO FEEL GOOD
- Juicy pop animations, particles and confetti
- Satisfying pop sounds that rise in pitch when you chain pops
- Upbeat looping music (and a one-tap mute)
- Haptic feedback on every pop
- Bright, clean design that is easy on the eyes

PLAY YOUR WAY
- Works offline, no internet needed
- No account, no sign-up
- Quick 10-second rounds or a long relaxing session
- Great for all ages

If you love pop-it fidget toys, bubble wrap, reaction-time challenges or quick brain-teasing puzzles, Pop It is made for you.

Download now and see how fast you can pop.
```

### What's New (version 1.0)

```
Welcome to Pop It! 200 levels, a relaxing free-pop mode, three bubble themes and great music. Pop fast, beat your best time.
```

## Keyword field rationale

| Keyword | Why |
|---|---|
| relaxing, calm, anxiety, stress, relief | big "stress relief / relaxing games" audience for fidget apps |
| sensory, asmr | "satisfying / sensory / asmr" discovery searches |
| toy | pairs with "fidget" in the name for "fidget toy" |
| bubbles, wrap | "bubble wrap" is the real-world analogue people search |
| brain, focus | puzzle / brain-training adjacent traffic |
| timer, reaction | the differentiators: timed, reaction-speed gameplay |
| kids | family traffic (the content is safe for it) |

Already covered by name/subtitle (do not repeat): pop, it, fidget, bubble, popper, satisfying, speed, tap, challenge.

Rotate in later by data: `puzzle` (if not in category list), `quick`, `offline`, `sound`, `rainbow`, `zen`, `speedrun`.
Change at most one or two words per release so results stay attributable.

## Screenshots (6.9" and 6.5", 1290x2796; up to 10)

Lead with benefit captions (large, 2-5 words, high contrast, big bubbles visible). The first 2-3 screenshots
decide most installs and are visible in search results.

1. **"Pop the ringed bubbles"**: Level screen, 2 ringed bubbles, timer big.
2. **"Beat the clock"**: timer mid-run, 0.xxx sec, targets counter.
3. **"200 levels"**: level-select grid with badges.
4. **"Flashing and moving targets"**: a flash_move level with rings in motion.
5. **"Relax in Free Pop"**: Free pop board, candy or ocean theme.
6. **"New best!"**: result screen with confetti and the yellow progress "Next level" button.

Also: an app preview video (15-30 s): splash pop, fast level clear, flash level, free pop. Sound-on works well for pop games.
Screenshots and the video can be captured from the macOS autotest (`--autotest --out=<dir>`) or from the device.

## Custom Product Pages (up to 35, for later ads or ASA)

- `relax`: Free pop screenshots first, "stress relief" captions.
- `speed`: timer and result screens first, "how fast are you" captions.
- `fidget`: rainbow board hero, "the digital pop it" captions.

## App Store Connect checklist

- App Privacy: **Data Not Collected** (the game stores progress on-device only; no analytics, ads or network
  calls in v1.0). Revisit this if an SDK is ever added.
- Export compliance: no encryption beyond standard OS (answer "No" to non-exempt encryption).
- Age rating questionnaire: all "None" gives 4+.
- Review notes: "No account needed. Tap Play levels to start; all levels unlock by playing."
- Localize at least **English (U.S.)** first. Later, localize name, subtitle and keywords (not just text) for
  Spanish (Mexico and Spain, both give more keyword space), German, French, Portuguese (Brazil), Japanese,
  Russian, Hebrew. In App Store Connect the **US storefront also indexes the Spanish (Mexico) localization's
  keywords**, so put extra English-relevant keywords there for free.
- Ratings prompt: ask via `SKStoreReviewController` only after a **New best** or after 5 cleared levels,
  never after a fail. (Not implemented yet.)

## Still to do (not ASO text, but required to submit)

- Support URL and Privacy Policy URL (a single GitHub Pages or Notion page is enough).
- App icon is already 1024x1024 (`assets/icon_1024.png`); check it has no transparency and no alpha channel.
- Screenshots and optional preview video.
