extends Node
## Developer self-test. Inert unless the game is launched with `-- --autotest`.
## Drives the real UI with synthetic taps, plays every level through the auto-advance chain,
## checks the core rules, saves screenshots to user://autotest (or --out=<dir>) and quits
## with exit code 0 on success.

## Levels 2 to CHAIN_END (or --chain-end=N) are played back to back through the auto-advance chain. The final
## level of levels.json is then played separately, after jumping straight to it.
const CHAIN_END := 13

var _chain_end := CHAIN_END

var _out := "user://autotest"
var _failures := 0
var _size_logged := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--autotest" not in args:
		return
	for a in args:
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--chain-end="):
			_chain_end = int(a.substr(12))
	DirAccess.make_dir_recursive_absolute(_out)
	_run.call_deferred()


func _run() -> void:
	print("AUTOTEST start, screenshots in ", ProjectSettings.globalize_path(_out))
	# The game opens on the animated splash, which hands over to Home by itself.
	await _wait(0.45)
	await _shot("00_splash_grow")
	await _wait(0.85)
	await _shot("00_splash_pop")
	await _wait(0.6)
	await _shot("00_splash_title")
	_check(Audio.is_music_playing(), "background music is playing")
	_check(await _wait_scene("Home", 4.0), "splash hands over to home")
	await _wait(1.6)
	await _shot("01_home")

	await _click_text("Play levels")
	await _wait(1.0)
	await _shot("02_levels_fresh")
	_check(Game.is_unlocked(0) and not Game.is_unlocked(1), "only level 0 is open on a fresh save")

	# Level 0, cleared slowly on purpose: the time must never gate the next level.
	await _click_node("Card0")
	await _wait(1.3)
	var lvl: Node = _scene()
	var b: Control = lvl.board
	await _shot("03_level0")
	for i in _non_targets(b).slice(0, 4):
		await _tap(b, i)
		await _wait(0.12)
	await _shot("04_wrong_taps")
	_check(lvl._wrong_taps == 4 and lvl._penalty_ms == 4000, "each wrong tap adds 1.000s")
	await _clear_board(lvl)
	_check(await _wait_scene("Result", 4.0), "result screen opens")
	var t0 := Time.get_ticks_msec()
	_check(SaveData.get_best(0) >= 4000, "slow clear is saved as the best time")
	_check(Game.is_unlocked(1), "slow clear still unlocks the next level")
	await _wait(1.0)
	await _shot("05_result_loading")
	var fill := _find(_scene(), func(n: Node) -> bool: return n is Button and n.get("progress") != null)
	_check(fill != null and fill.progress > 0.2 and fill.progress < 0.95, "next level button is filling")
	var started := await _wait_scene("Level", 4.0)
	var ms := Time.get_ticks_msec() - t0
	_check(started and Game.current_level_id == 1, "level 1 starts by itself")
	_check(ms > 1500 and ms < 3000, "auto start takes about 2 s (%d ms)" % ms)

	# Level 1: leaving the result screen while the bar fills cancels the auto start.
	await _play_level(1)
	await _wait(0.3)
	await _click_text("Levels")
	_check(await _wait_scene("LevelSelect", 2.0), "Levels button leaves the result screen")
	await _wait(3.0)
	_check(_scene().name == "LevelSelect", "leaving cancels the auto start")
	await _shot("06_levels_after_cancel")
	await _click_node("Card2")
	_check(await _wait_scene("Level", 3.0), "level card opens its level")

	# Levels 2 to CHAIN_END chain into each other by themselves.
	for id in range(2, _chain_end + 1):
		await _play_level(id)
		var ok := await _wait_scene("Level", 5.0)
		_check(ok and Game.current_level_id == id + 1, "level %d starts level %d by itself" % [id, id + 1])

	# Jump to the very last level of the list.
	var last := Game.levels.size() - 1
	print("  info %d levels in levels.json" % Game.levels.size())
	_check(Game.levels.size() >= 100, "at least 100 levels are defined")
	await _wait(1.3)
	await _click_back()
	_check(await _wait_scene("LevelSelect", 3.0), "back to level select")
	SaveData.unlock(last)
	await _wait(0.5)
	await _click_back()
	await _wait(1.2)
	await _click_text("Play levels")
	await _wait(2.2)
	var sel := _scene()
	await _shot("20_levels_last")
	_check(sel.scroll.scroll_vertical > 1000, "level list scrolled down to the newest level")
	_check(Game.is_unlocked(last), "last level is unlocked")
	await _click_node("Card%d" % last)
	_check(await _wait_scene("Level", 3.0), "last level opens")
	await _play_level(last)
	_check(_find(_scene(), func(n: Node) -> bool: return n is Button and n.text == "Next level") == null,
		"last level has no next button")
	await _wait(3.0)
	_check(_scene().name == "Result", "last level stays on the result screen")
	await _click_text("Levels")
	_check(await _wait_scene("LevelSelect", 3.0), "back to level select")
	await _wait(1.2)
	sel = _scene()
	sel.scroll.scroll_vertical = 0
	await _wait(0.2)
	await _shot("21_levels_top")

	await _click_back()
	await _wait(1.2)
	await _click_text("Free pop")
	await _wait(1.3)
	var fp: Node = _scene()
	b = fp.board
	for i in [1, 4, 7, 8, 10, 12, 16, 19, 21, 23, 25, 28, 30, 33]:
		await _tap(b, i)
		await _wait(0.06)
	await _wait(0.5)
	await _shot("30_freepop")
	_check(fp._count == 14, "free pop counts pops")
	await _click_node("Chip_candy")
	await _wait(0.9)
	await _shot("31_freepop_candy")
	await _click_node("Chip_ocean")
	await _wait(0.6)
	for i in b.count():
		if not b.cells[i].popped:
			await _tap(b, i)
			await _wait(0.03)
	await _wait(0.35)
	await _shot("32_freepop_cleared")
	await _wait(2.4)
	_check(fp._count == 0 and b.popped_count() == 0, "full board auto-flips to a fresh one")

	var was_muted: bool = Settings.muted
	await _click_mute()
	_check(Settings.muted != was_muted, "mute toggles")
	await _wait(0.3)
	await _shot("33_muted")
	await _click_mute()
	await _click_node("Chip_rainbow")

	# A tap skips the splash.
	Router.go(Router.SPLASH)
	_check(await _wait_scene("Splash", 3.0), "splash scene opens")
	await _wait(0.9)
	await _click_at(Vector2(195, 400))
	_check(await _wait_scene("Home", 1.5), "tap skips the splash")

	if _failures == 0:
		print("AUTOTEST PASSED")
	else:
		print("AUTOTEST FAILED: %d check(s)" % _failures)
	get_tree().quit(1 if _failures else 0)


## Plays the level that just opened to its result screen, checking its mode on the way.
func _play_level(id: int) -> void:
	await _wait(1.3)
	var lvl: Node = _scene()
	var b: Control = lvl.board
	var data: Dictionary = lvl.level
	_check(data.id == id, "level %d loaded (%s)" % [id, data.mode])
	# Blinking levels: wait for the rings to be visible so the frame shows them.
	if data.mode in ["flash", "flash_move"]:
		for k in 60:
			if b.ring_alpha(_targets(b)[0]) > 0.95:
				break
			await _wait(0.03)
	await _shot("L%02d_start" % id)
	var first := _targets(b)
	_check(first.size() == data.targets, "level %d has %d targets" % [id, data.targets])

	if data.mode in ["flash", "flash_move"]:
		var lo := 1.0
		var hi := 0.0
		for k in 24:
			var a: float = b.ring_alpha(first[0])
			lo = minf(lo, a)
			hi = maxf(hi, a)
			await _wait(0.05)
		_check(lo < 0.1 and hi > 0.9, "level %d targets blink (ring alpha %.2f to %.2f)" % [id, lo, hi])

	await _tap(b, first[0])
	# Marketing frame: timer running, one or two bubbles already popped.
	await _wait(0.35)
	var more := _targets(b)
	if more.size() > 1:
		await _tap(b, more[0])
		await _wait(0.25)
	await _shot("L%02d_run" % id)
	if data.mode in ["move", "flash_move"]:
		await _wait(2.8)
		var moved := false
		for i in _targets(b):
			if i not in first:
				moved = true
		_check(moved, "level %d targets slide to new cells" % id)
		await _shot("L%02d_moving" % id)

	for k in data.boards:
		await _clear_board(lvl)
		if k < data.boards - 1:
			await _wait(1.3)
			_check(lvl._board_pill.text == "Board %d of %d" % [k + 2, data.boards],
				"level %d board %d starts" % [id, k + 2])
			if k == 0:
				await _shot("L%02d_board2" % id)
	_check(await _wait_scene("Result", 5.0), "level %d result opens" % id)
	await _wait(0.5)
	await _shot("L%02d_result" % id)


## Pops targets until the level has none left on the current board. Re-reads the targets
## before every tap because they may be sliding.
func _clear_board(lvl: Node) -> void:
	var guard := 0
	while lvl._targets_left > 0 and not lvl._finished and guard < 400:
		guard += 1
		var t := _targets(lvl.board)
		if t.is_empty():
			await _wait(0.05)
			continue
		await _tap(lvl.board, t[0])
		await _wait(0.12)


func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		_failures += 1


func _scene() -> Node:
	return get_tree().current_scene


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


## Waits until the current scene's root has this name. Returns false on timeout.
func _wait_scene(scene_name: String, timeout: float) -> bool:
	var waited := 0.0
	while waited < timeout:
		var s := _scene()
		if s and s.name == scene_name:
			return true
		await _wait(0.05)
		waited += 0.05
	return false


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if not _size_logged:
		_size_logged = true
		print("  info screenshots are %dx%d" % [img.get_width(), img.get_height()])
	img.save_png(_out.path_join(name + ".png"))


func _targets(b: Control) -> Array:
	var out := []
	for i in b.count():
		if b.cells[i].target and not b.cells[i].popped:
			out.append(i)
	return out


func _non_targets(b: Control) -> Array:
	var out := []
	for i in b.count():
		if not b.cells[i].target and not b.cells[i].popped:
			out.append(i)
	return out


func _tap(b: Control, i: int) -> void:
	await _click_at(b.global_center(i))


func _click_text(text: String) -> void:
	var btn := _find(_scene(), func(n: Node) -> bool: return n is Button and n.text == text)
	_check(btn != null, "found button '%s'" % text)
	if btn:
		await _click_at((btn as Control).get_global_rect().get_center())


func _click_node(name: String) -> void:
	var n := _find(_scene(), func(x: Node) -> bool: return x.name == name)
	_check(n != null, "found node '%s'" % name)
	if n:
		await _click_at((n as Control).get_global_rect().get_center())


func _click_back() -> void:
	var n := _find(_scene(), func(x: Node) -> bool: return x is Button and x.get("icon_kind") == "back")
	if n:
		await _click_at((n as Control).get_global_rect().get_center())


func _click_mute() -> void:
	var n := _find(_scene(), func(x: Node) -> bool: return x is Button and x.get("icon_kind") in ["sound", "muted"])
	if n:
		await _click_at((n as Control).get_global_rect().get_center())


func _find(root: Node, pred: Callable) -> Node:
	if pred.call(root):
		return root
	for c in root.get_children():
		var hit := _find(c, pred)
		if hit:
			return hit
	return null


## Presses and releases the left mouse button at a point in viewport coordinates.
func _click_at(pos: Vector2) -> void:
	var win := get_viewport().get_final_transform() * pos
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = win
		e.global_position = win
		Input.parse_input_event(e)
		await get_tree().process_frame
