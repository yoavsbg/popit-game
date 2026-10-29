extends Control
## Base for every screen: background, safe-area padding, a main column, an effects
## layer, staggered entrance animations and screen shake. Subclasses implement build().

const P := preload("res://scripts/palette.gd")
const UI := preload("res://scripts/ui_kit.gd")
const Fx := preload("res://scripts/fx.gd")
const Board := preload("res://scripts/board.gd")
const IconButton := preload("res://scripts/ui/icon_button.gd")
const MuteButton := preload("res://scripts/ui/mute_button.gd")

## Shakes as a whole; holds the content.
var stage := Control.new()
var content := MarginContainer.new()
## The main vertical column subclasses fill.
var body: VBoxContainer
var fx: Fx

var _appear: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = P.BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(stage)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(content)
	body = UI.vbox(gap())
	content.add_child(body)
	fx = Fx.new()
	add_child(fx)
	_apply_margins()
	get_viewport().size_changed.connect(_apply_margins)
	build()
	_run_appear()


## Top, sides, bottom padding in design pixels.
func padding() -> Array:
	return [56, 24, 40]


func gap() -> int:
	return 16


func build() -> void:
	pass


func go_back() -> void:
	pass


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()


## Registers a control for the staggered fade-and-grow entrance.
func appear(c: Control, delay := -1.0) -> void:
	c.modulate.a = 0.0
	_appear.append([c, delay if delay >= 0.0 else _appear.size() * 0.05])


func _run_appear() -> void:
	await get_tree().process_frame
	for e in _appear:
		var c: Control = e[0]
		if not is_instance_valid(c):
			continue
		c.pivot_offset = c.size / 2.0
		c.scale = Vector2(0.94, 0.94)
		var t := c.create_tween().set_parallel()
		t.tween_property(c, "modulate:a", 1.0, 0.25).set_delay(e[1])
		t.tween_property(c, "scale", Vector2.ONE, 0.5).set_delay(e[1]) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func shake(strength := 6.0) -> void:
	var t := create_tween()
	for k in 5:
		var f := strength * (1.0 - k / 5.0)
		t.tween_property(stage, "position", Vector2(randf_range(-f, f), randf_range(-f, f) * 0.5), 0.035)
	t.tween_property(stage, "position", Vector2.ZERO, 0.05)


## Back button, centered title block, mute button.
func top_bar(on_back: Callable, center: Control = null) -> HBoxContainer:
	var bar := UI.hbox(8)
	if on_back.is_valid():
		var back := IconButton.new("back")
		back.tooltip_text = "Back"
		back.pressed.connect(on_back)
		bar.add_child(back)
	else:
		var hole := Control.new()
		hole.custom_minimum_size = Vector2(48, 48)
		bar.add_child(hole)
	var mid := CenterContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center:
		mid.add_child(center)
	bar.add_child(mid)
	bar.add_child(MuteButton.new())
	return bar


## Number followed by a small unit ("sec"), sharing a baseline.
func value_with_unit(value: Label, unit: Label) -> HBoxContainer:
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(value)
	var font := value.get_theme_font("font")
	var big := value.get_theme_font_size("font_size")
	var small := unit.get_theme_font_size("font_size")
	var lift := font.get_descent(big) - font.get_descent(small)
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("margin_bottom", int(lift))
	unit.size_flags_vertical = Control.SIZE_SHRINK_END
	holder.size_flags_vertical = Control.SIZE_FILL
	holder.add_child(unit)
	row.add_child(holder)
	return row


func _apply_margins() -> void:
	var p := padding()
	var insets := _safe_insets()
	content.add_theme_constant_override("margin_top", int(maxf(p[0], insets.x + 10.0)))
	content.add_theme_constant_override("margin_bottom", int(maxf(p[2], insets.y + 8.0)))
	content.add_theme_constant_override("margin_left", p[1])
	content.add_theme_constant_override("margin_right", p[1])


## Top and bottom unsafe areas (notch, home indicator) in design pixels.
func _safe_insets() -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.x <= 0 or safe.size.y <= 0:
		return Vector2.ZERO
	var k := get_viewport_rect().size.x / float(screen.x)
	var top := clampf(safe.position.y * k, 0.0, 120.0)
	var bottom := clampf((screen.y - safe.end.y) * k, 0.0, 80.0)
	return Vector2(top, bottom)
