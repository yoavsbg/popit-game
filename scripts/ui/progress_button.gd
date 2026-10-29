extends Button
## Pill button that fills with yellow like a progress bar and emits `finished` when full.
## It is still a normal button: the owner connects `pressed` to the same action to skip the wait.

signal finished

const P := preload("res://scripts/palette.gd")
const UI := preload("res://scripts/ui_kit.gd")

var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		_sync_clip()
		queue_redraw()

var _fs := 22
var _track: StyleBoxFlat
var _fill: StyleBoxFlat
## Clips a dark copy of the label to the filled part, so the text flips color as the bar passes it.
var _clip := Control.new()
var _tween: Tween


func _init(label := "Next level", height := 60, font_size := 22) -> void:
	text = label
	_fs = font_size
	custom_minimum_size.y = height
	_track = UI.box(P.SURFACE, height / 2)
	_fill = UI.box(P.ACCENT, height / 2)
	UI.style_button(self, StyleBoxEmpty.new(), StyleBoxEmpty.new(), Color.TRANSPARENT)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip.draw.connect(_draw_label.bind(_clip, P.BG))
	add_child(_clip)
	UI.add_press_feedback(self)


func start(duration: float, delay := 0.0) -> void:
	stop()
	progress = 0.0
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_property(self, "progress", 1.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(finished.emit)


func stop() -> void:
	if _tween:
		_tween.kill()
		_tween = null


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync_clip()


func _sync_clip() -> void:
	_clip.position = Vector2.ZERO
	_clip.size = Vector2(size.x * progress, size.y)
	_clip.queue_redraw()


func _draw() -> void:
	draw_style_box(_track, Rect2(Vector2.ZERO, size))
	if progress > 0.0:
		draw_style_box(_fill, Rect2(0.0, 0.0, maxf(size.x * progress, 1.0), size.y))
	_draw_label(self, P.TEXT)


func _draw_label(ci: CanvasItem, color: Color) -> void:
	var font := UI.font(600)
	var y := size.y / 2.0 + (font.get_ascent(_fs) - font.get_descent(_fs)) / 2.0
	ci.draw_string(font, Vector2(0.0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, _fs, color)
