# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Pop It" is a Godot 4.7 (GDScript, 2D, Mobile renderer) portrait mobile game, iOS first and Android second. The spec is `docs/pop-it-build-brief.md`; `docs/pop-it-design/screens/*.dc.html` are the 390x844 HTML mocks (read them for sizes, colors and copy only). v0 implements levels 0 to 2, free pop, result screen, mute and best times.

## Commands

The Godot binary on this machine is `/Users/yoavs/Downloads/Godot.app/Contents/MacOS/Godot` (not on PATH). Export templates for 4.7.2 are installed.

- Re-import after adding assets or fonts: `godot --headless --path . --import`
- Run the game: `godot --path .`
- Self-test (drives the real UI with synthetic taps, plays levels 0 to 14 through the auto-advance chain, then jumps to and plays the last level in `levels.json`, checks rules, saves screenshots, exits 0 on pass; takes a few minutes): `godot --path . -- --autotest --out=<dir>`. It uses `user://autotest.cfg` instead of the real save file. Add `--keep-save` to keep progress between runs.
- Regenerate the iOS icon PNG from `icon.svg`: `godot --headless --path . -s tools/make_icon.gd`
- iOS export (Xcode project only, into `build/ios/`): `godot --headless --path . --export-debug "iOS" build/ios/PopIt.ipa`, then open `build/ios/PopIt.xcodeproj` in Xcode to sign and run on a device. Team `F8YZ8K7U34`, bundle id `com.yoavsbg.popitgame`. The earlier id `com.yoavsbg.popit` is retired: iOS had cached its Godot-logo launch screen under it, and nothing short of a new bundle id cleared it. The launch screen and the engine boot splash are both blank on purpose (`storyboard/custom_image@*` in `export_presets.cfg`, `boot_splash/show_image=false`); the visible splash is the animated one in `scripts/splash.gd`.

- Android export (APK, no Gradle, arm64-v8a only): `godot --headless --path . --export-debug "Android" build/android/PopIt.apk`. Package `com.yoavsbg.popitgame`. It needs the Android SDK (`~/Library/Android/sdk`), a JDK (set `export/android/java_sdk_path` in Godot's editor settings to the JBR 21 under `~/Library/Java/JavaVirtualMachines`) and the debug keystore at `~/Library/Application Support/Godot/keystores/debug.keystore` (password `android`, alias `androiddebugkey`; created with `keytool`). Unlike iOS, the Android emulator (AVD `Pixel_9_Pro`, arm64) runs the game fine: `adb install -r build/android/PopIt.apk`, then launch it. A Play Store build would need a release keystore and an AAB (Gradle build), which isn't set up.

- Store listing images (screenshots, icons, feature graphic) live in `docs/store/` (`.gdignore` keeps Godot from importing them). Compose them with `godot --path . -s tools/make_store_assets.gd` (needs a window, not headless; it can't use `ui_kit.gd` because that pulls in the `Audio` autoload). The raw 1290x2796 frames come from running the autotest on the Android emulator after `adb shell wm size 1290x2796`; `docs/store/README.md` has the steps. The autotest also takes `--chain-end=N` to shorten the level chain.

## iOS Simulator does not work

Don't spend time on it. Godot 4.7.2 templates ship only an x86_64 simulator library, and the iOS 26.5 simulator runtime rejects x86_64 apps. Retagging the arm64 device library as a simulator build (platform 2 to 7 in LC_BUILD_VERSION, plus stubs for `MTLIOErrorDomain` and `MTLTensorDomain`) does link. At runtime, though, the simulator's Metal lacks image cube arrays, which the Mobile renderer requires, and the `opengl3` driver fails to create a framebuffer. Test on a real iPhone. Use the macOS run and `--autotest` for everything else.

## Architecture

- **Screens are built in code.** Each `scenes/*.tscn` is just a root Control with a script. Every screen script extends `scripts/screen.gd`, which provides the background, safe-area-aware padding, the main column `body`, the `fx` effects layer, `appear()` for staggered entrance animations, `shake()` and `top_bar()`. Subclasses implement `build()`.
- **Helpers are loaded with `preload`, not `class_name`.** `scripts/palette.gd` holds the design tokens and `hsl()`. `scripts/ui_kit.gd` holds the Fredoka weights via `FontVariation` on the variable font, labels, pill buttons and press feedback. `scripts/ui/icons.gd` draws the mock's SVG icons and shapes.
- **`scripts/board.gd` is the core of the game.** Bubbles are data (`Cell`) rather than nodes. They are drawn in batched layers: rings on the board itself, then hole, gloss and decoration child layers using the shaders in `assets/shaders/`. All animation is done by tweening Cell fields. The board only animates and emits `cell_pressed`; screens decide what a tap means. Input goes through `_input` using ScreenTouch, plus real mouse events (emulated mouse events are ignored). `multi_touch` is off on level screens.
- **Autoloads:**
  - `SaveData` stores everything in one ConfigFile at `user://save.cfg`.
  - `Settings` holds mute (which also mutes the master bus) and the theme.
  - `Audio` synthesizes every sound at startup, so there are no audio files. It plays them through a player pool, and the pop pitch rises during combos.
  - `Audio` also owns the background music: `assets/music/loop.wav`, a 32 s seamless loop rendered by `python3 -I tools/make_music.py` (pure-Python synth; edit the score or constants there and re-run, then re-import). Its import is forward-loop and uncompressed (`assets/music/loop.wav.import`). It starts from the splash, fades in, sits at `MUSIC_DB` under the effects, pauses when the app loses focus, and follows the global mute.
  - `Haptics` wraps `vibrate_handheld`.
  - `Game` holds levels and themes from `data/*.json`, `current_level_id`, and `last_result` (passed from the level screen to the result screen).
  - `Router` changes scenes with a fade.
  - `Dev` is the autotest driver.
- **Splash.** The main scene is `scenes/splash.tscn`: a bubble field grows in, pops in a ripple, the wordmark pops in with confetti, then it hands over to Home (about 2.4 s; a tap skips it). It is driven by a single tween, so leaving early cancels all of it. Prefer that (or a `Timer` node) over `await get_tree().create_timer(...)` in screens, because awaiting a timer on a freed node logs "class instance is gone" errors.
- **Data-driven levels.** `data/levels.json` defines 200 levels. Levels 0 to 11 are hand-made; the rest are generated with a difficulty ramp by `python3 -I tools/gen_levels.py [total]`, which keeps the first 12 as they are in the file and rewrites everything after them (so for hand edits past level 11, edit the generator, not the JSON). Run it with a bigger number for more levels. Card names must stay within 12 characters and details within 19, since the cards don't wrap them. A level is just an entry: `targets`, `boards`, `mode` (`static`, `flash`, `move`, `flash_move`), optional `flash_ms` (blink period) and `move_ms` (slide interval), plus `name`, `detail` and `subtitle`. A mode missing from `Game.IMPLEMENTED_MODES` shows as a "Coming soon" card.
  - **Flash:** the ring blinks, but the bubble stays a target while the ring is hidden (`Board.set_blink`).
  - **Move:** once the timer runs, `level.gd` slides each target to a free neighbour every `move_ms`. The target flag moves immediately and the ring glides over (`Board.move_target`).
- **Progress is never time-gated.** Clearing a level always unlocks the next one. Best time only decides "New best". Keep it that way.
- **Auto-advance.** After a clear, the result screen's "Next level" is a `ProgressButton` that fills in about 2 s (`AUTO_NEXT_*` in `result.gd`), then starts the next level. Tapping it skips the wait. Leaving the screen any other way cancels it, and the last level has no next button.
- **Level select scrolls.** The cards sit in a ScrollContainer with `MOUSE_FILTER_PASS` so drags scroll while taps (under a 12 px slop) open the level. It scrolls to the newest unlocked level on entry.
- `export_presets.cfg` includes `data/*.json` explicitly, because non-resource files are otherwise dropped from exports.
