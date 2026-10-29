extends "res://scripts/screen.gd"
## Level clear: count-up of the final time, new-best pill, stats and confetti.

const Icons := preload("res://scripts/ui/icons.gd")
const ProgressButton := preload("res://scripts/ui/progress_button.gd")
## The next level starts by itself: the button fills over AUTO_NEXT_S, after a short beat.
const AUTO_NEXT_DELAY := 0.35
const AUTO_NEXT_S := 1.7
## Decorative confetti dots from the mock: x, y, size.
const SPOTS := [
	[28, 120, 14], [96, 168, 10], [330, 132, 16], [286, 196, 10], [352, 250, 12],
	[40, 300, 12], [150, 112, 8], [236, 128, 12], [18, 214, 8], [372, 352, 8],
	[64, 408, 10], [322, 420, 14], [200, 92, 10], [120, 244, 8],
]

var _r: Dictionary
var _time_label: Label
var _best_row: Control
var _spots: Control
var _spot_t := 0.0
var _next_btn: ProgressButton
var _leaving := false


func build() -> void:
	_r = Game.last_result
	if _r.is_empty():
		_r = {"level_id": 1, "time_ms": 3871, "prev_best": 4215, "new_best": true, "targets": 5, "wrong": 0}

	_spots = Control.new()
	_spots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spots.set_anchors_preset(Control.PRESET_FULL_RECT)
	_spots.draw.connect(_draw_spots)
	_spots.modulate.a = 0.0
	stage.add_child(_spots)
	stage.move_child(_spots, 0)

	body.add_child(top_bar(Callable()))

	var middle := UI.vbox(14)
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(middle)

	var heading := UI.label("Level %d clear" % _r.level_id, 28, 600, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	middle.add_child(heading)
	appear(heading, 0.05)

	_time_label = UI.label("0.000", 96, 700)
	_time_label.add_theme_font_override("font", UI.font(700, true))
	var time_row := value_with_unit(_time_label, UI.label("sec", 24, 400, P.MUTED))
	middle.add_child(time_row)
	appear(time_row, 0.1)

	_best_row = UI.hbox(10)
	(_best_row as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	if _r.new_best:
		_best_row.add_child(_new_best_pill())
		if _r.prev_best >= 0:
			_best_row.add_child(UI.label("Previous %ss" % Game.format_ms(_r.prev_best), 16, 400, P.MUTED))
	else:
		_best_row.add_child(UI.label("Your best %ss" % Game.format_ms(_r.prev_best), 16, 400, P.MUTED))
	_best_row.modulate.a = 0.0
	middle.add_child(_best_row)

	var stats := UI.hbox(12)
	stats.add_child(_stat("Targets", "%d / %d" % [_r.targets, _r.targets]))
	stats.add_child(_stat("Wrong taps", str(_r.wrong)))
	var stats_box := MarginContainer.new()
	stats_box.add_theme_constant_override("margin_top", 10)
	stats_box.add_child(stats)
	middle.add_child(stats_box)
	appear(stats_box, 0.2)

	var bottom := UI.vbox(14)
	var next_id: int = _r.level_id + 1
	var row := UI.hbox(14)
	if Game.is_unlocked(next_id):
		_next_btn = ProgressButton.new("Next level")
		_next_btn.name = "NextButton"
		_next_btn.pressed.connect(_play.bind(next_id))
		_next_btn.finished.connect(_play.bind(next_id))
		bottom.add_child(_next_btn)
		row.add_child(_small_button("Retry", _play.bind(_r.level_id)))
		row.add_child(_small_button("Levels", _nav.bind(Router.LEVEL_SELECT)))
	else:
		if Game.level(next_id).is_empty():
			bottom.add_child(UI.label("You cleared every level. More coming soon!", 15, 400,
				P.MUTED, HORIZONTAL_ALIGNMENT_CENTER))
		var retry := UI.pill_button("Retry", true)
		retry.pressed.connect(_play.bind(_r.level_id))
		bottom.add_child(retry)
		row.add_child(_small_button("Levels", _nav.bind(Router.LEVEL_SELECT)))
		row.add_child(_small_button("Home", _nav.bind(Router.HOME)))
	bottom.add_child(row)
	body.add_child(bottom)
	appear(bottom, 0.3)

	_celebrate()


func go_back() -> void:
	_nav(Router.LEVEL_SELECT)


## Any way out of this screen also cancels the pending auto start.
func _nav(path: String) -> void:
	if _leaving:
		return
	_leaving = true
	if _next_btn:
		_next_btn.stop()
	Router.go(path)


func _play(id: int) -> void:
	if _leaving:
		return
	Game.current_level_id = id
	_nav(Router.LEVEL)


func _small_button(text: String, action: Callable) -> Button:
	var b := UI.pill_button(text, false, 56, 20)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	return b


func _stat(label: String, value: String) -> Control:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", UI.box(P.SURFACE, 18, 0, Color.TRANSPARENT, 16, 14))
	var v := UI.vbox(2)
	v.add_child(UI.label(label, 14, 400, P.MUTED))
	v.add_child(UI.label(value, 26, 600))
	card.add_child(v)
	return card


func _new_best_pill() -> Control:
	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_theme_stylebox_override("panel", UI.box(P.ACCENT, 20, 0, Color.TRANSPARENT, 14, 6))
	var h := UI.hbox(6)
	var star := Control.new()
	star.custom_minimum_size = Vector2(18, 18)
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star.draw.connect(func() -> void: Icons.draw(star, "star", star.size / 2.0, 18.0, P.BG))
	h.add_child(star)
	h.add_child(UI.label("New best", 18, 600, P.BG))
	pill.add_child(h)
	return pill


func _celebrate() -> void:
	await get_tree().process_frame
	if _next_btn:
		_next_btn.start(AUTO_NEXT_S, AUTO_NEXT_DELAY)
	var vp := get_viewport_rect().size
	fx.confetti(Vector2(vp.x * 0.2, vp.y * 0.62), 40, 0.6, 900.0)
	fx.confetti(Vector2(vp.x * 0.8, vp.y * 0.62), 40, 0.6, 900.0)
	create_tween().tween_property(_spots, "modulate:a", 1.0, 0.6)

	var total: int = _r.time_ms
	var count := create_tween()
	count.tween_method(func(v: float) -> void: _time_label.text = Game.format_ms(int(v)),
		0.0, float(total), 0.9).set_delay(0.15).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await count.finished
	_time_label.pivot_offset = _time_label.size / 2.0
	_time_label.scale = Vector2(1.08, 1.08)
	create_tween().tween_property(_time_label, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_best_row.pivot_offset = _best_row.size / 2.0
	_best_row.scale = Vector2(0.4, 0.4)
	var t := create_tween().set_parallel()
	t.tween_property(_best_row, "modulate:a", 1.0, 0.15)
	t.tween_property(_best_row, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _r.new_best:
		Audio.sparkle()
		Haptics.success()
		fx.burst(fx.to_local(_best_row.get_global_rect().get_center()), P.ACCENT, 14, 300.0, 5.0)


func _process(delta: float) -> void:
	_spot_t += delta
	_spots.queue_redraw()


## The mock's scattered dots, gently bobbing behind the content.
func _draw_spots() -> void:
	var sx := get_viewport_rect().size.x / 390.0
	for i in SPOTS.size():
		var s: Array = SPOTS[i]
		var bob := sin(_spot_t * 1.6 + i * 0.9) * 4.0
		var pos := Vector2(s[0] * sx, s[1] + bob)
		_spots.draw_circle(pos, s[2] / 2.0, P.hsl(round(i * 360.0 / SPOTS.size()), 0.82, 0.62), true, -1.0, true)
