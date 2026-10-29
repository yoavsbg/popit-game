extends Control
## 12 px progress dot that pops when it fills.

const P := preload("res://scripts/palette.gd")

var filled := false


func _init() -> void:
	custom_minimum_size = Vector2(12, 12)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_filled(value: bool, animate := true) -> void:
	filled = value
	queue_redraw()
	if value and animate:
		pivot_offset = size / 2.0
		scale = Vector2(1.8, 1.8)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	draw_circle(size / 2.0, 6.0, P.ACCENT if filled else P.DOT_EMPTY, true, -1.0, true)
