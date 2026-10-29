extends "res://scripts/screen.gd"
## Free pop: no timer, no targets. Every pop reveals a little shape.

const SHAPES := ["star", "heart", "diamond"]

var board: Board
var _count := 0
var _count_label: Label
var _chips := {}
var _theme: Dictionary
var _offset := 0.0
var _reverse := false
var _celebrating := false
var _flipping := false


func padding() -> Array:
	return [56, 24, 28]


func build() -> void:
	body.add_child(top_bar(go_back, UI.label("Free pop", 24, 600)))

	var counter := UI.hbox(12)
	var left := UI.vbox(0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_label = UI.label("0", 44, 700)
	_count_label.add_theme_font_override("font", UI.font(700, true))
	_count_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.add_child(_count_label)
	left.add_child(UI.label("popped. No timer, just pop.", 15, 400, P.MUTED))
	counter.add_child(left)
	var flip := UI.pill_button("Flip board", false, 48, 18, 20)
	flip.name = "FlipButton"
	flip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flip.pressed.connect(_flip)
	counter.add_child(flip)
	body.add_child(counter)
	appear(counter, 0.05)

	_theme = Game.theme(Settings.theme_id)
	board = Board.new(5, 7)
	board.fx = fx
	board.multi_touch = true
	board.popped_scale = 0.82
	board.cell_pressed.connect(_on_cell_pressed)
	_apply_colors()
	body.add_child(board)
	board.intro(0.1)

	body.add_child(UI.spacer())
	var chips := UI.hbox(10)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	for t in Game.themes:
		var chip := _chip(t)
		_chips[t.id] = chip
		chips.add_child(chip)
	body.add_child(chips)
	appear(chips, 0.35)
	_sync_chips()


func go_back() -> void:
	Router.go(Router.HOME)


func _on_cell_pressed(i: int) -> void:
	var c := board.cells[i]
	if c.popped or _celebrating:
		return
	c.shape = SHAPES[_count % SHAPES.size()]
	board.pop(i)
	Audio.pop()
	Haptics.tap()
	_count += 1
	_count_label.text = str(_count)
	_count_label.pivot_offset = _count_label.size / 2.0
	_count_label.scale = Vector2(1.15, 1.15)
	create_tween().tween_property(_count_label, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _count == board.count():
		_celebrate()


## Whole board popped: confetti, chime, then a fresh board.
func _celebrate() -> void:
	_celebrating = true
	Audio.chime()
	Haptics.success()
	var vp := get_viewport_rect().size
	fx.confetti(Vector2(vp.x * 0.5, vp.y * 0.75), 70, 0.8, 950.0)
	await get_tree().create_timer(1.1).timeout
	await _flip()
	_celebrating = false


func _flip() -> void:
	if _flipping:
		return
	_flipping = true
	_offset = randf()
	_reverse = randf() < 0.5
	Audio.sparkle()
	await board.flip(_fresh_board)
	_flipping = false


func _fresh_board() -> void:
	board.reset_cells()
	_apply_colors()
	_count = 0
	_count_label.text = "0"


func _set_theme(id: String) -> void:
	if id == _theme.id:
		return
	Settings.theme_id = id
	_theme = Game.theme(id)
	_sync_chips()
	board.recolor(_colors(), _shape_colors(_colors()))


func _apply_colors() -> void:
	var colors := _colors()
	board.set_colors(colors)
	var shapes := _shape_colors(colors)
	for i in board.count():
		board.cells[i].shape_color = shapes[i]


func _colors() -> Array:
	var out := []
	var n := board.count()
	for i in n:
		var u := float(i) / n
		if _reverse:
			u = 1.0 - u
		u = fposmod(u + _offset, 1.0)
		if _theme.type == "hue":
			out.append(P.hsl(round(u * 360.0), _theme.saturation, _theme.lightness))
		else:
			var stops: Array = _theme.colors
			var x := u * stops.size()
			var k := int(x)
			var a := Color(stops[k % stops.size()])
			var b := Color(stops[(k + 1) % stops.size()])
			out.append(a.lerp(b, x - k))
	return out


func _shape_colors(colors: Array) -> Array:
	var out := []
	for c: Color in colors:
		out.append(Color.from_hsv(c.h, minf(c.s * 1.05, 1.0), 1.0).lerp(Color.WHITE, 0.12))
	return out


func _chip(t: Dictionary) -> Button:
	var b := Button.new()
	b.name = "Chip_%s" % t.id
	b.text = t.name
	b.custom_minimum_size.y = 44
	b.add_theme_font_override("font", UI.font(500))
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_constant_override("h_separation", 8)
	b.add_theme_constant_override("icon_max_width", 14)
	b.icon = _dot_texture(t.dot)
	UI.add_press_feedback(b)
	b.pressed.connect(_set_theme.bind(t.id))
	return b


func _sync_chips() -> void:
	for id in _chips:
		var b: Button = _chips[id]
		var border := P.TEXT if id == _theme.id else Color.TRANSPARENT
		UI.style_button(b, UI.box(P.SURFACE, 22, 2, border, 16),
			UI.box(P.SURFACE_PRESSED, 22, 2, border, 16), P.TEXT)


## Small conic-gradient swatch like the mock's theme dots.
func _dot_texture(hexes: Array) -> Texture2D:
	var px := 42
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var stops: Array[Color] = []
	for h in hexes:
		stops.append(Color(h))
	var c := Vector2(px, px) / 2.0
	for y in px:
		for x in px:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var d := p.length()
			var a := clampf(px / 2.0 - d, 0.0, 1.0)
			var u := fposmod(atan2(p.x, -p.y) / TAU, 1.0) * stops.size()
			var k := int(u)
			var col := stops[k % stops.size()].lerp(stops[(k + 1) % stops.size()], u - k)
			col.a = a
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
