extends Control
## A grid of glossy bubbles. Bubbles are plain data (Cell) drawn in batched layers:
## rings (this node), holes, gloss and revealed shapes (child layers). Screens decide
## what a tap means and call pop(), wrong(), set_targets() and friends.

signal cell_pressed(index: int)

const P := preload("res://scripts/palette.gd")
const Icons := preload("res://scripts/ui/icons.gd")
const GLOSS := preload("res://assets/shaders/bubble_gloss.gdshader")
const HOLE := preload("res://assets/shaders/bubble_hole.gdshader")
const RING_PULSE_S := 0.8


class Cell:
	var color := Color.WHITE
	var shape := ""
	var shape_color := Color.WHITE
	var popped := false
	var target := false
	## Animated values.
	var scale := 1.0
	var hole := 0.0
	var shape_t := 0.0
	var ring := 0.0
	var wrong := 0.0
	var shake := 0.0
	var alpha := 1.0
	## Where the target ring sits relative to the cell (it glides here when a target moves).
	var ring_offset := Vector2.ZERO
	## Blinking targets: ring is visible for part of every `blink_period` seconds.
	var blink_period := 0.0
	var blink_phase := 0.0
	var tween: Tween
	var ring_tween: Tween
	var offset_tween: Tween


var cols := 5
var rows := 7
var gap := 12.0
var pad := 4.0
## Free pop allows several fingers; level screens only take the first one.
var multi_touch := false
var input_enabled := true
var popped_scale := 0.78
## Optional effects layer for particles.
var fx: Node2D

var cells: Array[Cell] = []
var cell_size := 57.0

var _time := 0.0
var _hole_layer := Node2D.new()
var _gloss_layer := Node2D.new()
var _deco_layer := Node2D.new()

static var _white: Texture2D


func _init(c := 5, r := 7) -> void:
	cols = c
	rows = r
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in cols * rows:
		cells.append(Cell.new())
	if _white == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	var gm := ShaderMaterial.new()
	gm.shader = GLOSS
	_gloss_layer.material = gm
	var hm := ShaderMaterial.new()
	hm.shader = HOLE
	_hole_layer.material = hm
	for layer in [_hole_layer, _gloss_layer, _deco_layer]:
		add_child(layer)
	_hole_layer.draw.connect(_draw_holes)
	_gloss_layer.draw.connect(_draw_gloss)
	_deco_layer.draw.connect(_draw_deco)
	_layout_for_width(342.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_for_width(size.x)


func _layout_for_width(w: float) -> void:
	cell_size = (w - pad * 2.0 - gap * (cols - 1)) / cols
	var h := rows * cell_size + gap * (rows - 1) + pad * 2.0
	if absf(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size.y = h
	pivot_offset = Vector2(w, h) / 2.0


func count() -> int:
	return cells.size()


func center(i: int) -> Vector2:
	var c := i % cols
	var r := i / cols
	return Vector2(pad + cell_size * 0.5 + c * (cell_size + gap),
		pad + cell_size * 0.5 + r * (cell_size + gap))


func global_center(i: int) -> Vector2:
	return get_global_transform() * center(i)


func radius() -> float:
	return cell_size * 0.5


func cell_at(local: Vector2) -> int:
	var step := cell_size + gap
	var c := int(floor((local.x - pad + gap * 0.5) / step))
	var r := int(floor((local.y - pad + gap * 0.5) / step))
	if c < 0 or c >= cols or r < 0 or r >= rows:
		return -1
	return r * cols + c


func popped_count() -> int:
	var n := 0
	for c in cells:
		if c.popped:
			n += 1
	return n


# --- State changes -------------------------------------------------------------------

func set_colors(colors: Array) -> void:
	for i in cells.size():
		cells[i].color = colors[i]


## Instantly returns every bubble to its fresh, unpopped state.
func reset_cells() -> void:
	for c in cells:
		_kill(c)
		if c.ring_tween:
			c.ring_tween.kill()
		if c.offset_tween:
			c.offset_tween.kill()
		c.popped = false
		c.target = false
		c.ring_offset = Vector2.ZERO
		c.blink_period = 0.0
		c.shape = ""
		c.scale = 1.0
		c.hole = 0.0
		c.shape_t = 0.0
		c.ring = 0.0
		c.wrong = 0.0
		c.shake = 0.0
		c.alpha = 1.0


## Bubbles grow in from nothing in a diagonal wave.
func intro(delay := 0.0) -> void:
	for i in cells.size():
		var c := cells[i]
		c.scale = 0.0
		c.alpha = 0.0
		var d := delay + (i % cols + i / cols) * 0.028
		c.tween = create_tween().set_parallel()
		c.tween.tween_property(c, "scale", 1.0, 0.42).set_delay(d) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		c.tween.tween_property(c, "alpha", 1.0, 0.18).set_delay(d)


func set_targets(indices: Array, delay := 0.0) -> void:
	for k in indices.size():
		var c := cells[indices[k]]
		c.target = true
		_ring_to(c, 1.0, 0.4, delay + k * 0.06)


## Makes a target's ring blink: visible for most of each period, hidden for the rest.
## The bubble stays a target while the ring is hidden. `phase` staggers the targets.
func set_blink(i: int, period: float, phase: float) -> void:
	cells[i].blink_period = period
	cells[i].blink_phase = phase


## Current ring opacity (0..1) including blinking. Hidden rings are still targets.
func ring_alpha(i: int) -> float:
	var c := cells[i]
	return c.ring * _blink_alpha(c)


func neighbors(i: int) -> Array:
	var out := []
	var c := i % cols
	var r := i / cols
	if c > 0:
		out.append(i - 1)
	if c < cols - 1:
		out.append(i + 1)
	if r > 0:
		out.append(i - cols)
	if r < rows - 1:
		out.append(i + cols)
	return out


## Moves a target to a neighbouring cell. The target flag moves immediately, so a tap on
## the new cell counts; the ring glides over from the old one.
func move_target(from: int, to: int, dur := 0.24) -> void:
	var a := cells[from]
	var b := cells[to]
	if not a.target or b.target or b.popped:
		return
	for t in [a.ring_tween, b.ring_tween, a.offset_tween, b.offset_tween]:
		if t:
			t.kill()
	a.target = false
	b.target = true
	b.blink_period = a.blink_period
	b.blink_phase = a.blink_phase
	a.blink_period = 0.0
	b.ring = a.ring
	b.ring_offset = center(from) + a.ring_offset - center(to)
	a.ring = 0.0
	a.ring_offset = Vector2.ZERO
	b.offset_tween = create_tween()
	b.offset_tween.tween_property(b, "ring_offset", Vector2.ZERO, dur) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func pop(i: int) -> void:
	var c := cells[i]
	if c.popped:
		return
	c.popped = true
	_kill(c)
	c.tween = create_tween().set_parallel()
	c.tween.tween_property(c, "hole", 1.0, 0.07)
	c.tween.tween_property(c, "scale", popped_scale - 0.09, 0.08) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	c.tween.chain().tween_property(c, "scale", popped_scale, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if c.shape != "":
		c.tween.tween_property(c, "shape_t", 1.0, 0.36) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if c.target:
		c.target = false
		c.ring *= _blink_alpha(c)
		c.blink_period = 0.0
		_ring_to(c, 0.0, 0.12)
	if fx:
		var pos := fx.to_local(global_center(i))
		var r := radius()
		fx.burst(pos, c.color, 9, 250.0, r * 0.11)
		fx.ring(pos, r * 0.95, Color(c.color.lightened(0.3), 0.9), r * 0.45, 0.32, 3.0)


func unpop(i: int, delay := 0.0, sound := false) -> void:
	var c := cells[i]
	if not c.popped:
		return
	c.popped = false
	_kill(c)
	c.tween = create_tween().set_parallel()
	if sound:
		c.tween.tween_callback(Audio.unpop).set_delay(delay)
	c.tween.tween_property(c, "hole", 0.0, 0.1).set_delay(delay)
	c.tween.tween_property(c, "shape_t", 0.0, 0.1).set_delay(delay)
	c.tween.tween_property(c, "scale", 1.08, 0.14).set_delay(delay) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	c.tween.chain().tween_property(c, "scale", 1.0, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Red ring flash plus a short shake. The bubble does not pop.
func wrong(i: int) -> void:
	var c := cells[i]
	_kill(c)
	c.wrong = 1.0
	c.tween = create_tween()
	for x in [7.0, -6.0, 4.5, -3.0, 1.5, 0.0]:
		c.tween.tween_property(c, "shake", x, 0.045)
	c.tween.parallel().tween_property(c, "wrong", 0.0, 0.4).set_delay(0.3)
	if fx:
		fx.ring(fx.to_local(global_center(i)), radius() + 4.5, P.PENALTY, 10.0, 0.4, 3.0)


## Card-flip the whole board; `apply` runs at the edge-on midpoint to swap content.
func flip(apply: Callable) -> void:
	var t := create_tween()
	t.tween_property(self, "scale:x", 0.0, 0.13).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(apply)
	t.tween_property(self, "scale:x", 1.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await t.finished


## Smoothly recolor bubbles in a wave (theme switch).
func recolor(colors: Array, shape_colors: Array) -> void:
	for i in cells.size():
		var c := cells[i]
		var d := (i % cols + i / cols) * 0.025
		var t := create_tween().set_parallel()
		t.tween_property(c, "color", colors[i], 0.3).set_delay(d)
		t.tween_property(c, "shape_color", shape_colors[i], 0.3).set_delay(d)


## 1 for steady rings. For blinking ones: fade in, hold for ~60% of the period, fade out, hide.
func _blink_alpha(c: Cell) -> float:
	if c.blink_period <= 0.0:
		return 1.0
	var u := fposmod((_time + c.blink_phase) / c.blink_period, 1.0)
	return smoothstep(0.0, 0.08, u) * (1.0 - smoothstep(0.58, 0.68, u))


func _ring_to(c: Cell, value: float, dur: float, delay := 0.0) -> void:
	if c.ring_tween:
		c.ring_tween.kill()
	c.ring_tween = create_tween()
	c.ring_tween.tween_property(c, "ring", value, dur).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK if value > 0.0 else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _kill(c: Cell) -> void:
	if c.tween:
		c.tween.kill()
		c.tween = null
	c.shake = 0.0
	c.wrong = 0.0
	c.alpha = 1.0


# --- Input -----------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not input_enabled or not is_visible_in_tree() or Router.busy:
		return
	var pos: Vector2
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed or (not multi_touch and touch.index != 0):
			return
		pos = touch.position
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT \
				or mb.device == InputEvent.DEVICE_ID_EMULATION:
			return
		pos = mb.position
	else:
		return
	var i := cell_at(get_global_transform_with_canvas().affine_inverse() * pos)
	if i >= 0:
		get_viewport().set_input_as_handled()
		cell_pressed.emit(i)


# --- Drawing ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	_hole_layer.queue_redraw()
	_gloss_layer.queue_redraw()
	_deco_layer.queue_redraw()


func _pos(i: int) -> Vector2:
	return center(i) + Vector2(cells[i].shake, 0.0)


func _draw() -> void:
	var r := radius()
	var pulse := 0.5 - 0.5 * cos(_time * PI / RING_PULSE_S)
	for i in cells.size():
		var c := cells[i]
		var ring_a := ring_alpha(i)
		if ring_a > 0.01:
			var off := 2.0 + 3.0 * pulse + (1.0 - c.ring) * 14.0
			draw_arc(_pos(i) + c.ring_offset, r * c.scale + off + 1.5, 0.0, TAU, 64,
				Color(1, 1, 1, clampf(ring_a, 0.0, 1.0) * c.alpha), 3.0, true)
		if c.wrong > 0.01:
			draw_arc(_pos(i), r + 4.5, 0.0, TAU, 64, Color(P.PENALTY, c.wrong), 3.0, true)


func _draw_holes() -> void:
	var r := radius()
	for i in cells.size():
		var c := cells[i]
		if c.hole > 0.001:
			var rr := r * c.scale
			_hole_layer.draw_texture_rect(_white, Rect2(_pos(i) - Vector2(rr, rr), Vector2(rr, rr) * 2.0),
				false, Color(P.SURFACE, c.alpha))


func _draw_gloss() -> void:
	var r := radius()
	for i in cells.size():
		var c := cells[i]
		var a := (1.0 - c.hole) * c.alpha
		if a > 0.001 and c.scale > 0.001:
			var rr := r * c.scale
			_gloss_layer.draw_texture_rect(_white, Rect2(_pos(i) - Vector2(rr, rr), Vector2(rr, rr) * 2.0),
				false, Color(c.color, a))


func _draw_deco() -> void:
	var k := cell_size / 57.0
	for i in cells.size():
		var c := cells[i]
		if c.shape != "" and c.shape_t > 0.01:
			Icons.draw(_deco_layer, c.shape, _pos(i), 26.0 * k * c.shape_t, Color(c.shape_color, c.alpha))
