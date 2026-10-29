# Store listing assets

Generated images for both stores. Copy text (name, subtitle, descriptions, keywords) is in
`../aso-app-store.md` and `../aso-google-play.md`; the captions below are the on-image text that goes with it.

## App Store (`app-store/`)

| File / folder | Size | Notes |
|---|---|---|
| `app-icon-1024x1024.png` | 1024x1024 | Opaque, no alpha (required). Same file the iOS export uses. |
| `screenshots-6.9in-1290x2796/` | 1290x2796 | **Required** 6.9" iPhone set (7 images, PNG, no alpha). |
| `screenshots-6.5in-1284x2778/` | 1284x2778 | 6.5" iPhone set. Optional, since App Store Connect scales the 6.9" set down, but supplied so the layout is exact. |

The app is iPhone-only (`targeted_device_family=0`), so no iPad screenshots are needed.
Upload order = file order (the first three decide most installs).

## Google Play (`google-play/`)

| File / folder | Size | Notes |
|---|---|---|
| `app-icon-512x512.png` | 512x512 | 32-bit PNG, under 1 MB. Play applies its own rounded mask, so the art is a full square. |
| `feature-graphic-1024x500.png` | 1024x500 | Required feature graphic (opaque PNG). Keep text away from the edges; it is cropped on some surfaces. |
| `phone-screenshots-1080x1920/` | 1080x1920 | 9:16 phone screenshots (7 images, 2 to 8 allowed, 320 to 3840 px per side). |

Play's tablet (7" and 10") screenshots are optional and not generated. Add them only if you want tablet featuring.

## Captions (on-image text, ASO-first)

| # | Headline | Sub-line | Frame |
|---|---|---|---|
| 1 | POP THE / RINGED BUBBLES | Tap fast. Pure fidget fun. | Level 3, targets blinking, 2/5 done |
| 2 | BEAT THE / CLOCK | Every wrong tap costs +1 second | Level 0 with the +1.000s penalty chip |
| 3 | 200 / LEVELS | Each one trickier than the last | Level select with best times |
| 4 | FLASHING & / MOVING TARGETS | Stay sharp. Stay fast. | Level 5, flash + slide |
| 5 | RELAX IN / FREE POP | No timer. Just satisfying pops. | Free pop, Candy theme |
| 6 | CHASE YOUR / BEST TIME | The next level starts by itself | Result screen, confetti, next-level bar |
| 7 | SO / SATISFYING | Great pops, haptics and music | Splash ripple with the wordmark |

Why these: short two-line headlines in big, high-contrast type (white, then the brand yellow for the key
phrase) read at thumbnail size in search results; each one sells one benefit; the order is
hook (the core mechanic), then the competitive loop, then depth, then variety, then relaxation, then retention,
then feel.

## Where the frames come from

`raw/` holds real game frames, 1290x2796, captured by the autotest running the actual APK on an Android
emulator whose display was set to that size (macOS windows are limited to the screen, so they max out lower).
These are unedited game output; everything else is composed around them.

## Regenerate

1. Capture frames (only when the UI changes): build the APK with the temporary extra argument
   `-- --autotest --out=user://shots --chain-end=5` (preset option `command_line/extra_args`), install it on
   the emulator after `adb shell wm size 1290x2796`, wait for `AUTOTEST PASSED` in `adb logcat -s godot`, pull
   `files/shots` with `adb exec-out run-as com.yoavsbg.popitgame cat ...`, then reset the preset and
   `adb shell wm size reset`. Copy the chosen frames into `raw/`.
2. Compose everything: `godot --path . -s tools/make_store_assets.gd` (needs a real window, not `--headless`).
   Edit the `SHOTS` list in that script to change captions, order or glow colors.
