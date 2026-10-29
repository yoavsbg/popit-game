extends "res://scripts/screen.gd"
## A timed level: pop only the ringed bubbles. Driven by Game.current_level_id.

const Dot := preload("res://scripts/ui/dot.gd")
const PENALTY_MS := 1000

var level: Dictionary
var board: Board

var _timer_label: Label
var _unit_label: Label
var _chip: PanelContainer
var _chip_tween: Tween
var _dots: Array = []
var _progress_label: Label
var _board_pill: Label

var _board_index := 0
var _targets_left := 0
var _wrong_taps := 0
var _started := false
var _finished := false
var _start_ms := 0
var _penalty_ms := 0
var _flash := false
var _move := false


func padding() -> Array:
	return [56, 24, 32]


func build() -> void:
	level = Game.level(Game.current_level_id)
	if level.is_empty():
		level = Game.levels[0]
	_flash = level.mode in ["flash", "flash_move"]
	_move = level.mode in ["move", "flash_move"]

	var title := UI.vbox(0)
	title.add_child(UI.label("Level %d" % level.id, 24, 600, P.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var subtitle: String = level.get("subtitle", "Pop the ringed bubbles")
	title.add_child(UI.label(subtitle, 14, 400, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	body.add_child(top_bar(go_back, title))

	var hud := UI.vbox(10)
	_timer_label = UI.label("0.000", 68, 600)
	_timer_label.add_theme_font_override("font", UI.font(600, true))
	_unit_label = UI.label("sec", 20, 400, P.MUTED)
	hud.add_child(value_with_unit(_timer_label, _unit_label))

	var progress := UI.hbox(8)
	progress.alignment = BoxContainer.ALIGNMENT_CENTER
	for k in level.targets:
		var d := Dot.new()
		_dots.append(d)
		progress.add_child(d)
	_progress_label = UI.label("", 16, 400, P.MUTED)
	var label_box := MarginContainer.new()
	label_box.add_theme_constant_override("margin_left", 6)
	label_box.add_child(_progress_label)
	progress.add_child(label_box)
	if level.boards > 1:
		var pill := PanelContainer.new()
		pill.add_theme_stylebox_override("panel", UI.box(P.SURFACE, 12, 0, Color.TRANSPARENT, 10, 3))
		_board_pill = UI.label("", 14, 400, P.TEXT)
		pill.add_child(_board_pill)
		var pill_box := MarginContainer.new()
		pill_box.add_theme_constant_override("margin_left", 6)
		pill_box.add_child(pill)
		progress.add_child(pill_box)
	hud.add_child(progress)
	body.add_child(hud)
	appear(hud, 0.05)

	board = Board.new(5, 7)
	board.fx = fx
	board.cell_pressed.connect(_on_cell_pressed)
	body.add_child(board)

	body.add_child(UI.spacer())
	var hint := UI.label("Wrong bubble adds 1.000s", 15, 400, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	body.add_child(hint)
	appear(hint, 0.5)

	_chip = PanelContainer.new()
	_chip.add_theme_stylebox_override("panel", UI.box(P.CHIP_BG, 12, 0, Color.TRANSPARENT, 10, 4))
	_chip.add_child(UI.label("+1.000s", 16, 600, P.CHIP_TEXT))
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.modulate.a = 0.0
	stage.add_child(_chip)

	_start_board()
	board.intro(0.1)


func go_back() -> void:
	Router.go(Router.LEVEL_SELECT)


func _process(_delta: float) -> void:
	if _started and not _finished:
		_timer_label.text = Game.format_ms(_elapsed())


func _elapsed() -> int:
	return Time.get_ticks_msec() - _start_ms + _penalty_ms


## Fresh rainbow board with `targets` random distinct cells ringed.
func _start_board(ring_delay := 0.55) -> void:
	board.reset_cells()
	var colors := []
	for i in board.count():
		colors.append(P.bubble(i, board.count()))
	board.set_colors(colors)
	var cells := range(board.count())
	cells.shuffle()
	var picked := cells.slice(0, level.targets)
	board.set_targets(picked, ring_delay)
	if _flash:
		var period := float(level.get("flash_ms", 900)) / 1000.0
		for k in picked.size():
			board.set_blink(picked[k], period, period * k / picked.size())
	_targets_left = level.targets
	for d in _dots:
		d.set_filled(false, false)
	_update_progress()


func _update_progress() -> void:
	_progress_label.text = "%d / %d" % [level.targets - _targets_left, level.targets]
	if _board_pill:
		_board_pill.text = "Board %d of %d" % [_board_index + 1, level.boards]


func _on_cell_pressed(i: int) -> void:
	if _finished or board.cells[i].popped:
		return
	if not _started:
		_started = true
		_start_ms = Time.get_ticks_msec()
		if _move:
			_move_loop()
	if board.cells[i].target:
		_hit(i)
	else:
		_miss(i)


## Moving levels: once the timer runs, every `move_ms` each target slides to a free neighbour.
func _move_loop() -> void:
	var every := float(level.get("move_ms", 1300)) / 1000.0
	while true:
		await get_tree().create_timer(every).timeout
		if _finished or not is_inside_tree():
			return
		if board.input_enabled:
			_move_targets()


func _move_targets() -> void:
	var ids := []
	for i in board.count():
		if board.cells[i].target and not board.cells[i].popped:
			ids.append(i)
	for i in ids:
		_slide_after(randf_range(0.0, 0.3), i)


func _slide_after(delay: float, from: int) -> void:
	await get_tree().create_timer(delay).timeout
	if _finished or not is_inside_tree() or not board.input_enabled:
		return
	var c := board.cells[from]
	if not c.target or c.popped:
		return
	var options := board.neighbors(from).filter(func(j: int) -> bool:
		return not board.cells[j].popped and not board.cells[j].target)
	if not options.is_empty():
		board.move_target(from, options.pick_random())


func _hit(i: int) -> void:
	board.pop(i)
	Audio.pop()
	Haptics.tap()
	_targets_left -= 1
	_dots[level.targets - _targets_left - 1].set_filled(true)
	_update_progress()
	_bump(_timer_label, 1.07)
	if _targets_left == 0:
		_board_done()


func _miss(i: int) -> void:
	_wrong_taps += 1
	_penalty_ms += PENALTY_MS
	board.wrong(i)
	Audio.wrong()
	Haptics.wrong()
	shake(5.0)
	_show_chip()
	_timer_label.add_theme_color_override("font_color", P.PENALTY)
	var t := create_tween()
	t.tween_interval(0.25)
	t.tween_callback(func() -> void: _timer_label.add_theme_color_override("font_color", P.TEXT))


func _board_done() -> void:
	_board_index += 1
	if _board_index < level.boards:
		board.input_enabled = false
		await get_tree().create_timer(0.2).timeout
		Audio.sparkle()
		await board.flip(_start_board.bind(0.05))
		board.input_enabled = true
		_update_progress()
		if _board_pill:
			_bump(_board_pill.get_parent() as Control, 1.15)
	else:
		_finish()


func _finish() -> void:
	_finished = true
	board.input_enabled = false
	var total := _elapsed()
	_timer_label.text = Game.format_ms(total)
	var prev := SaveData.get_best(level.id)
	var new_best := prev < 0 or total < prev
	if new_best:
		SaveData.set_best(level.id, total)
	# Clearing always unlocks the next level. Time only decides "New best", never progress.
	SaveData.unlock(level.id + 1)
	Game.last_result = {
		"level_id": level.id,
		"time_ms": total,
		"prev_best": prev,
		"new_best": new_best,
		"targets": level.targets * level.boards,
		"wrong": _wrong_taps,
	}
	Audio.chime()
	Haptics.success()
	_bump(_timer_label, 1.2)
	var r := _timer_label.get_global_rect()
	fx.burst(fx.to_local(r.get_center()), P.ACCENT, 18, 360.0, 6.0)
	await get_tree().create_timer(0.8).timeout
	Router.go(Router.RESULT)


func _bump(c: Control, amount: float) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2(amount, amount)
	create_tween().tween_property(c, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## "+1.000s" pops in beside the timer, then floats up and fades.
func _show_chip() -> void:
	if _chip_tween:
		_chip_tween.kill()
	_chip.reset_size()
	var unit := _unit_label.get_global_rect()
	var timer := _timer_label.get_global_rect()
	var x := minf(unit.end.x + 10.0, get_viewport_rect().size.x - _chip.size.x - 6.0)
	var y := timer.get_center().y - _chip.size.y / 2.0 - 4.0
	if x < unit.end.x + 2.0:
		y = timer.position.y - _chip.size.y + 6.0
	var base := stage.get_global_transform().affine_inverse() * Vector2(x, y)
	_chip.position = base
	_chip.pivot_offset = _chip.size / 2.0
	_chip.scale = Vector2(0.5, 0.5)
	_chip.modulate.a = 1.0
	_chip_tween = create_tween()
	_chip_tween.tween_property(_chip, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_chip_tween.tween_interval(0.6)
	_chip_tween.tween_property(_chip, "position:y", base.y - 14.0, 0.35)
	_chip_tween.parallel().tween_property(_chip, "modulate:a", 0.0, 0.35)
