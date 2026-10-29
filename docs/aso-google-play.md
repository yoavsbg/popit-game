# Pop It: Google Play ASO metadata

Copy-paste ready for Play Console. Character counts were checked by script (limits in brackets).
Companion file for the App Store: `aso-app-store.md`.

## How Google Play indexes (why the copy looks like this)

- Unlike Apple there is **no keyword field**. Play indexes the **title, short description, full description**
  (all of it, not just the first lines), the developer name, and package-level signals like category and
  tags. Installs, retention, ratings and uninstalls influence rank as much as text.
- So the description is both for people and for ranking: the main phrases ("pop it", "bubble pop", "fidget",
  "satisfying", "reaction time") appear **naturally 3-5 times** across the full description, with variants
  and long-tail phrases around them. Do not stuff: Google flags repetitive keyword lists and ranks them down.
- Title rules: max 30 chars, no emojis, no ALL CAPS gimmicks, no "free", "best", "#1", "top", no
  price/promo wording (Metadata policy: rejection risk).
- The first ~170 characters of the full description show on the listing before "read more": front-load the
  hook and the main keywords there.
- Package name is permanent and is a ranking signal: `com.yoavsbg.popitgame` (set; cannot change after publishing).

## Fields

| Field | Value | Count |
|---|---|---|
| App name (title) | `Pop It: Fidget Bubble Pop Toy` | 29 / 30 |
| Short description | `Pop the ringed bubbles, beat the clock and chase your best time. 200 levels!` | 76 / 80 |
| Category | Game > **Casual** (second best fit: Puzzle) | |
| Tags (up to 5) | Casual, Puzzle, Relaxing (if offered), Offline, Single player | |
| Content rating | IARC questionnaire, expected **Everyone / PEGI 3** | |
| Price | Free | |
| Contact email | required; use `yoavsbg17@gmail.com` or a dedicated one | |
| Website / Privacy policy URL | privacy policy URL is required (see "Still to do") | |

Alternative titles to test with **Store listing experiments** (Play Console > Grow > Store listing experiments):

1. `Pop It: Fidget Bubble Pop Toy` (current; "fidget toy" is the high-volume query, and Play already knows it is a game from the category)
2. `Pop It: Fidget Bubble Pop Race` (30, stresses the timed play)
3. `Pop It Rush: Speed Bubble Tap` (29, brand-forward)

Alternative short descriptions:

- `Satisfying bubble pop fidget game. Tap the ringed bubbles. 200 levels, no ads.` (78 as written here without "fast"; with "fast" it is 83 and too long)
- `Relax with bubble popping or race the clock. A satisfying pop it fidget game.` (77)

(Only claim "no ads" while the build truly contains none.)

### Full description (4000 max)

```
Pop the bubbles. Beat the clock. Chase a faster time.

Pop It is a satisfying bubble pop game with a competitive twist. Only the ringed bubbles count: tap them as fast as you can, avoid the wrong ones (every mistake adds a full second), and set a new personal best. It is a pop it fidget game for people who like their relaxing games with a little speed.

HOW TO PLAY
• Find the ringed bubbles and tap them
• A tap on a plain bubble adds 1.000 seconds to your time
• Clear every target to finish the level
• Your best time is saved for each level, so you can always beat your own record

200 LEVELS, GETTING SMARTER
• Warm-up levels to learn the feel
• More targets, more boards and one running timer
• Flashing targets: the rings blink on and off, but the bubble is still a target
• Moving targets: they slide across the board while you race
• Mixed levels that flash and move at the same time
• Clear a level and the next one starts automatically, so you never lose the flow
• Never stuck: a slow clear still unlocks the next level

FREE POP MODE: RELAX AND FIDGET
No timer, no pressure. Pop, flip and repeat. Choose Rainbow, Candy or Ocean bubble colors and enjoy the soft pops and gentle haptics. It works like a digital fidget toy or bubble wrap, perfect for a calm break, stress relief or a quick sensory reset.

FEELS SO GOOD
• Juicy pop animations with particles and confetti
• Satisfying pop sounds that rise in pitch as you chain pops
• Upbeat looping background music, with a one-tap mute
• Haptic feedback on every pop
• Bright, clean, colorful design

PLAY YOUR WAY
• Works offline, no internet needed
• No account or sign-up
• Quick 10-second rounds or long relaxing sessions
• Easy to learn, hard to master, great for all ages

If you enjoy pop it toys, bubble wrap, reaction time challenges or quick puzzle games, you will love Pop It. Download it now and see how fast you can pop.
```

## Keyword plan (what to make sure the text covers)

Primary (title + short + 3-5 mentions in the full text): pop it, bubble pop, fidget, satisfying, bubble.
Secondary (1-3 mentions): relaxing games, stress relief, reaction time, fidget toy, bubble wrap, pop it game, offline.
Long tail (1 mention): sensory, haptics, time challenge, brain, casual, puzzle.
Not in the text on purpose: competitor names, trademarks, "best", "free".

Recheck every 2-3 weeks in Play Console > Statistics > Acquisition > Search terms; move winning phrases into the title/short
description and drop non-performing ones.

## Graphics (Play Console > Store listing)

| Asset | Spec |
|---|---|
| App icon | 512x512 PNG (export `assets/icon_1024.png` down), 32-bit, no rounded corners |
| Feature graphic | 1024x500: the rainbow bubble board, a wordmark "Pop It" and "Beat the clock" |
| Phone screenshots | 2 to 8, 9:16 portrait, min 320px, max 3840px; use 1080x1920 or 1290x2796 |
| Promo video (YouTube URL) | optional; 15-30 s, the same story as the iOS preview |

Screenshot order and captions are the same as in `aso-app-store.md` (benefit first: "Pop the ringed bubbles",
"Beat the clock", "200 levels", "Flashing and moving targets", "Relax in Free Pop", "New best!"). Play surfaces the
first 3 in search results.

## Play Console checklist

- Data safety form: **No data collected, no data shared** (progress is stored on the device; no ads, analytics or
  network use in v1.0). Revisit if an SDK is added.
- App access: all functionality available without login.
- Ads: **No ads** (while true). Target audience: 13+ is simplest; choosing under-13 triggers Families Policy
  requirements, so only select it deliberately.
- Release: build an **AAB** (not the debug APK), signed with a **release keystore** and Play App Signing (not
  set up yet; the current `build/android/PopIt.apk` is debug-signed for sideloading). Needs Gradle build
  template, `target API` level per Play policy, and a Play developer account (one-time 25 USD fee). Personal
  accounts created after Nov 2023 must run a **closed test with 12+ testers for 14 days** before production.
- Pre-launch report: leave on; it catches crashes on real devices.
- Localization: start with **English (United States)**. Then add localized title, short and full descriptions for
  es-419, es-ES, pt-BR, de, fr, ru, ja, ko, he; Play indexes each locale's text for that market.
- In-app review prompt (Play In-App Review API) after a **New best** or 5 cleared levels. (Not implemented yet.)
- Android vitals: keep crash rate and ANR rate low; ranking is penalized above the bad-behavior thresholds.

## Still to do

- Privacy policy URL (same page as for iOS).
- Release keystore, AAB export, closed testing track.
- Screenshots (1080x1920), feature graphic, optional video.
