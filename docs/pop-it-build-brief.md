# Pop It: Godot build brief (v0)

Working title: "Pop It" (final name should follow the App Store search phrase).
Goal of v0: a polished, offline, iOS-first 2D game that also exports to Android. No ads, no in-app purchases, no accounts.

## 1. The game in one paragraph

A 5x7 board of glossy bubbles, each a unique color. In **Levels**, a few bubbles are highlighted with a pulsing white ring. The player pops only those, as fast as possible, against a millisecond timer. A wrong tap adds +1.000s. In **Free pop** there is no timer and no targets: just popping, with a different small picture revealed under every popped bubble. Every pop makes a sound (pitch rises with fast combos). A mute button is always visible. Best time per level is saved locally.

## 2. Tech

- Godot 4.x (latest stable), GDScript, 2D only. Renderer: Mobile.
- Portrait. Base viewport 390x844, stretch mode `canvas_items`, aspect `keep_width`, so it scales on all phones.
- Targets: iOS first, Android from the same project.
- Font: Fredoka (OFL license), bundle it.
- Everything works offline. Save data in `user://save.cfg` (ConfigFile).

## 3. Screens (flow)

Home -> Level select -> Level (playing) -> Level clear -> Next level / Retry / Level select
Home -> Free pop

1. **Home**: wordmark, decorative bubble cluster (two ringed), "Play levels", "Free pop", "Best on Level N" line, mute button.
2. **Level select**: 2-column cards. Number, name, detail, best time. Locked cards show a lock. Clearing a level unlocks the next.
3. **Level (playing)**: back button, level name, mute, big timer (3 decimals, tabular), progress dots (e.g. 2 / 5), board, hint "Wrong bubble adds 1.000s". Level 2 also shows "Board 1 of 2".
4. **Level clear**: "Level N clear", big final time, "New best" pill with previous best, stats (targets, wrong taps), buttons Next level / Retry / Levels. Light confetti burst.
5. **Free pop**: popped counter, "Flip board" button, board, theme chips (Rainbow, Candy, Ocean).

## 4. Design tokens

| Token | Value |
|---|---|
| Background | `#1B1340` |
| Surface (cards, buttons, popped holes) | `#2A1F5E` |
| Locked card | `#231A52` |
| Muted text | `#B9B1E6` |
| Accent / primary button | `#FFD23F` (text on it `#1B1340`) |
| Outline button border | `#8B7FD8` |
| Penalty / wrong tap | `#FF6B6B` |
| Text | `#FFFFFF` |

- Bubble color: hue = `index * 360 / 35`, saturation 82%, lightness 62%, plus a soft white highlight at the top-left (about 34% / 28%) and a slight dark inner shade at the bottom.
- Popped state: bubble scales to ~0.78 and becomes the surface color with an inner shadow (looks pressed in).
- Target ring: 3 px white ring, 3 px outside the bubble, pulsing its offset between 2 and 5 px (about 0.8 s, ping-pong). Never rely on color alone for targets.
- Wrong tap: 3 px `#FF6B6B` ring flash, short shake, penalty chip "+1.000s" next to the timer.
- Buttons: 60 px tall, fully rounded, 22 px semibold. Touch targets at least 44 px everywhere.

## 5. Project structure

```
project.godot
autoload/
  settings.gd      # muted flag, saved
  save_data.gd     # best times, unlocked levels (ConfigFile)
  audio.gd         # pop sounds, combo pitch, mute
  haptics.gd       # thin wrapper, easy to swap for a plugin later
data/
  levels.json      # level definitions (see section 6)
  themes.json      # palettes for free pop
scenes/
  home.tscn
  level_select.tscn
  level.tscn       # board + HUD + timer, driven by a level id
  result.tscn
  free_pop.tscn
  bubble.tscn      # one bubble (draw, states, tween)
  board.tscn       # grid of 35 bubbles
  ui/mute_button.tscn
  ui/primary_button.tscn
scripts/ ... (one script per scene)
assets/
  fonts/ sounds/ shapes/
```

Navigation: a small `Router` autoload (or `get_tree().change_scene_to_file`) with a fade or slide transition.

## 6. Level data

`data/levels.json`:

```json
[
  { "id": 0, "name": "Warm up",   "detail": "2 targets",           "targets": 2, "boards": 1, "mode": "static" },
  { "id": 1, "name": "Five targets", "detail": "5 targets",        "targets": 5, "boards": 1, "mode": "static" },
  { "id": 2, "name": "Two boards", "detail": "2 boards, one timer","targets": 5, "boards": 2, "mode": "static" },
  { "id": 3, "name": "Flashing",  "detail": "Targets blink",       "targets": 5, "boards": 1, "mode": "flash",  "flash_ms": 900 },
  { "id": 4, "name": "Moving",    "detail": "Targets slide around","targets": 5, "boards": 1, "mode": "move" },
  { "id": 5, "name": "Mixed",     "detail": "Flash and move",      "targets": 6, "boards": 1, "mode": "flash_move" }
]
```

v0 must ship levels 0, 1, 2 fully. Levels 3 to 5 may exist as locked cards only ("coming soon" is fine). Keep the `mode` field so they can be added without refactoring.

## 7. Core rules

- Board: 5 columns x 7 rows = 35 bubbles. Each new board picks `targets` random distinct cells.
- Timer starts on the first tap of the level, or after a short 3-2-1 (pick the simpler one; first-tap start is fine for v0). Use `Time.get_ticks_msec()`, display `seconds.mmm`.
- Tap a target: it pops, play pop sound, progress +1.
- Tap a non-target: penalty +1000 ms added to the displayed time, buzz sound, ring flash. The bubble does not pop.
- When all targets on a board are popped: if more boards remain (Level 2), show the next board immediately with the same running timer. Otherwise finish.
- Final time = elapsed ms + penalties. Compare with the saved best for that level. If better, save it and show "New best" on the result screen.
- Clearing level N unlocks level N+1.
- Ignore taps on already popped bubbles. Ignore multi-touch beyond the first finger on level screens.

## 8. Free pop rules

- No timer, no targets, no penalty. Count total pops on the current board.
- Each popped bubble reveals a small shape underneath (star, heart, diamond for v0). **Original art only**: no licensed characters or brand art.
- "Flip board" resets the board with fresh colors.
- Theme chips switch the palette (Rainbow, Candy, Ocean) from `themes.json`.

## 9. Sound and haptics

- Sound is a must. Pop sound: short soft "pop" sample, played with `pitch_scale` rising per fast consecutive pop (reset after about 0.9 s idle, cap at about 10 steps). Also: wrong-tap buzz, level-clear chime (3 rising notes).
- Use several pooled `AudioStreamPlayer` nodes so quick taps overlap cleanly.
- **Mute**: global toggle in the `settings` autoload, saved, shown top right on every screen, silences all sounds.
- Haptics: use `Input.vibrate_handheld()` through `haptics.gd`. iOS haptic quality in Godot is basic, so test on a real iPhone early. Keep the wrapper so a Core Haptics plugin can replace it later.
- Sound files: use royalty-free or self-made samples and record the license for each.

## 10. Juice (what makes it feel like a "big" game)

- Pop animation: quick scale-down tween with a tiny overshoot, plus 6 to 10 small particles in the bubble's color (`CPUParticles2D`).
- Timer text scales slightly on each correct pop.
- Level clear: confetti burst, count-up of the final time, "New best" pill pops in.
- Subtle screen shake on a wrong tap.
- All of it must stay at 60 fps on an older iPhone.

## 11. Out of scope for v0

Ads, in-app purchases, Game Center or any leaderboards, accounts or cloud save, flashing and moving levels (data only), localization (English first), analytics.

## 12. Milestones

1. Project setup, scaling, fonts, Router, settings and save autoloads.
2. `bubble` + `board` scenes with colors, pop animation, sound and haptics.
3. Level 1 playable: targets, ring pulse, ms timer, penalty, finish.
4. Result screen, best-time saving, unlocks, Level 0 and Level 2 from `levels.json`.
5. Home, Level select, Free pop, mute everywhere.
6. Polish pass: particles, transitions, sound tuning.
7. **Test on a real iPhone** (feel, haptics, performance), then an Android device.
8. Export builds: iOS via Xcode (needs the Apple developer account), Android as AAB (Play Console). Use placeholder bundle id `com.yoavsbg.popit` until the name is final.

## 13. Acceptance for v0

- Levels 0, 1, 2 playable start to finish; best times persist after restart.
- Mute works on every screen and survives restart.
- Free pop works with all three themes.
- No crashes on rapid tapping. No dropped frames on a mid-range phone.
- Runs fully offline.

## 14. Visual design reference (from the Claude Design mock)

The mock has 6 portrait screens at 390x844. Source files are in `pop-it-design/screens/` (HTML/CSS, read them for exact values, do not port them). Sample times in the mock (3.871, 4.215, 1.842) are placeholders. If PNG screenshots are added to `pop-it-design/screenshots/`, look at those first.

### Shared layout

- Screen padding: 56 top, 24 sides, 40 bottom (32 on the two level screens, 28 on Free pop).
- Square icon buttons (back, mute): 48x48, corner radius 16, surface color. Mute icon is a speaker with waves; muted state uses a speaker with a slash.
- Board: 5 columns, 12 gap, 4 padding, so each bubble is about 57 px at 390 width. Bubbles are circles that keep a 1:1 ratio.
- Font: Fredoka. Sizes below are in the 390-wide design space.

### 1. Home (`Main.dc.html`)

- Top row: mute button on the right.
- Middle, vertically centered, 36 gap: a 5x3 decorative bubble grid (15 bubbles, hue = index * 24 deg, bubbles 3 and 11 wear the white target ring), then the title block.
- Title "Pop It": 76 px bold, line height 0.95, letter spacing -1. Tagline: "Pop only the ringed bubbles. Beat your best time." 19 px, muted.
- Bottom, 14 gap: "Play levels" (primary yellow button), "Free pop" (outline button), then centered text "Best on Level 1: 4.215s" 15 px muted.
- Primary button: height 60, fully rounded, 22 px semibold, text `#1B1340` on `#FFD23F`. Outline button: same size, 2 px `#8B7FD8` border, white text.

### 2. Level select (`Levels.dc.html`)

- Top row: back (left), mute (right). Then title "Levels" 44 px bold and "Clear a level to unlock the next one." 17 px muted.
- 2-column grid, 14 gap, 6 cards. Card: min height 178, padding 16, radius 22, surface color, vertical stack with 6 gap.
- Unlocked card: 44 px number circle (hue 12, 48, 150 deg; number 24 px bold in `#1B1340`), name 20 px semibold, detail 15 px muted, and at the bottom the best time 15 px medium in yellow (or "Not played yet" in muted).
- Locked card: background `#231A52`, circle `#3A2E7A` with a lock icon, name `#D9D4F5`, detail muted, no best-time row.
- Cards in the mock: 0 Warm up (2 targets), 1 Five targets, 2 Two boards (2 boards, one timer), 3 Flashing, 4 Moving, 5 Mixed (last three locked).

### 3. Level playing (`Level1.dc.html`, `Level2.dc.html`)

- Top bar: back, centered title block ("Level 1" 24 px semibold; subtitle 14 px muted "Pop the ringed bubbles", Level 2 says "Clear 2 boards, one timer"), mute.
- Timer: 68 px semibold, tabular digits, three decimals, followed by "sec" 20 px muted. Centered.
- Progress row, 8 gap: five 12 px dots (filled `#FFD23F`, empty `#3A2E7A`) then "2 / 5" 16 px muted. Level 2 adds a pill "Board 1 of 2" (surface color, 14 px, radius 12, padding 3x10).
- Penalty chip, shown next to the timer for a moment after a wrong tap: "+1.000s", 16 px semibold, text `#FF9A9A` on `#4A2345`, radius 12, padding 4x10.
- Board states: normal = glossy colored bubble. Popped = surface color, scale 0.78, inner shadow. Target = normal bubble plus 3 px white ring, 3 px offset, pulsing offset 2 to 5 px. Wrong tap = 3 px `#FF6B6B` ring.
- Mock snapshots: Level 1 shows 2 popped and 3 ringed targets (cells 13, 27 popped; 6, 20, 33 ringed; timer 1.874). Level 2 shows 3 popped, 2 ringed, one wrong-tap ring (cells 8, 15, 30 popped; 2, 24 ringed; 19 wrong; timer 5.302).
- Bottom hint, centered, 15 px muted: "Wrong bubble adds 1.000s".

### 4. Level clear (`Result.dc.html`)

- Mute top right. Decorative confetti dots (8 to 16 px, rainbow hues) scattered in the upper half, behind the content.
- Centered stack, 14 gap: "Level 1 clear" 28 px semibold muted; final time 96 px bold with "sec" 24 px muted; row with a yellow "New best" pill (star icon, 18 px semibold, dark text, radius 20, padding 6x14) and "Previous 4.215s" 16 px muted.
- Two stat cards side by side (12 gap), surface color, radius 18, padding 14x16, label 14 px muted, value 26 px semibold: "Targets 5 / 5" and "Wrong taps 0".
- Bottom, 14 gap: primary "Next level"; below it a row of two outline buttons "Retry" and "Levels" (height 56, 20 px semibold).

### 5. Free pop (`FreePop.dc.html`)

- Top bar: back, title "Free pop" 24 px semibold, mute.
- Counter row: big count (44 px bold, tabular) with "popped. No timer, just pop." 15 px muted; on the right an outline "Flip board" button (height 48, 18 px semibold, 2 px `#8B7FD8` border).
- Board with no rings. Popped bubbles use the pressed look (scale 0.82) and show a 26 px shape in the bubble's hue at lightness 70% (star, heart, diamond, repeating).
- Bottom row of theme chips, 10 gap: Rainbow, Candy, Ocean. Chip: height 44, radius 22, surface color, 16 px medium, with a 14 px circular gradient dot. The selected chip has a 2 px white border.

### Not in the mock (decide while building)

Sound and haptic behavior, transitions between screens, the exact pop animation, and the muted icon state. Follow sections 9 and 10 for those.
