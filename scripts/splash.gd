extends "res://scripts/screen.gd"
## Animated splash: a field of rainbow bubbles grows in, pops in a ripple from the middle,
## and the "Pop It" wordmark pops in with confetti. A tap skips it. Hands over to Home.

const COLS := 5
const ROWS := 9
const GROW_S := 0.7
const RING_STEP := 0.11
const HOLD_S := 0.75

var board: Board

var _logo: Control
var _done := false
var _skippable := false


func padding() -> Array:
	return [24, 24, 24]


func build() -> void:
	body.add_child(UI.spacer())
	board = Board.new(COLS, ROWS)
	board.fx = fx
	board.input_enabled = false
	var colors := []
	for i in board.count():
		var hue := (i % COLS + i / COLS) * 360.0 / (COLS + ROWS - 1) + 330.0
		colors.append(P.hsl(hue, 0.82, 0.62))
	board.set_colors(colors)
	body.add_child(board)
	body.add_child(UI.spacer())

	var title := UI.label("Pop It", 96, 700, P.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", UI.font(700, false, -2))
	var tagline := UI.label("Pop. Race. Beat your best.", 19, 500, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var stack := UI.vbox(0)
	stack.add_child(title)
	stack.add_child(tagline)
	_logo = stack
	_logo.modulate.a = 0.0
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_logo)
	stage.add_child(center)

	_play()


## One tween drives the whole timeline, so leaving early (tap, back) cancels everything with it.
func _play() -> void:
	Audio.start_music()
	board.intro(0.05)

	var mid := Vector2((COLS - 1) / 2.0, (ROWS - 1) / 2.0)
	var rings := {}
	for i in board.count():
		var d := roundi(Vector2(i % COLS, i / COLS).distance_to(mid))
		if not rings.has(d):
			rings[d] = []
		rings[d].append(i)
	var order := rings.keys()
	order.sort()

	var t := create_tween()
	t.tween_callback(func() -> void: _skippable = true).set_delay(0.3)
	t.tween_interval(GROW_S - 0.3)
	for d in order:
		t.tween_callback(_pop_ring.bind(rings[d], d))
		t.tween_interval(RING_STEP)
	t.tween_interval(0.35)
	t.tween_callback(func() -> void:
		create_tween().tween_property(board, "modulate:a", 0.0, 0.35))
	t.tween_interval(HOLD_S)
	t.tween_callback(_finish)


func _pop_ring(cells: Array, ring: int) -> void:
	for i in cells:
		create_tween().tween_callback(board.pop.bind(i)).set_delay(randf_range(0.0, 0.05))
	Audio.pop()
	Haptics.tap()
	if ring == 1:
		_reveal_logo()


func _reveal_logo() -> void:
	_logo.pivot_offset = _logo.size / 2.0
	_logo.scale = Vector2(0.4, 0.4)
	var t := create_tween().set_parallel()
	t.tween_property(_logo, "modulate:a", 1.0, 0.25)
	t.tween_property(_logo, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Audio.sparkle()
	Haptics.success()
	fx.confetti(get_viewport_rect().size / 2.0, 40, 1.0, 760.0)


func _finish() -> void:
	if _done:
		return
	_done = true
	Router.go(Router.HOME)


func go_back() -> void:
	_finish()


func _input(event: InputEvent) -> void:
	if _done or not _skippable:
		return
	var tapped := false
	if event is InputEventScreenTouch:
		tapped = (event as InputEventScreenTouch).pressed
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		tapped = mb.pressed and mb.device != InputEvent.DEVICE_ID_EMULATION
	if tapped:
		_finish()
