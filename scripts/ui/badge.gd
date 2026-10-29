extends Control
## Filled circle with a centered number, or a lock icon when locked.

const P := preload("res://scripts/palette.gd")
const UI := preload("res://scripts/ui_kit.gd")
const Icons := preload("res://scripts/ui/icons.gd")

var color := P.ACCENT
var text := ""
var locked := false


func _init(diameter := 44.0) -> void:
	custom_minimum_size = Vector2(diameter, diameter)
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	draw_circle(c, r, color, true, -1.0, true)
	if locked:
		Icons.draw(self, "lock", c, 22.0, P.TEXT)
		return
	var font := UI.font(700)
	var fs := 24
	var baseline := c.y + (font.get_ascent(fs) - font.get_descent(fs)) / 2.0
	draw_string(font, Vector2(0, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, P.BG)
