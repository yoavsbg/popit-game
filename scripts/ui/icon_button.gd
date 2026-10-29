extends Button
## 48x48 rounded square button with a drawn stroke icon (back, sound, muted).

const P := preload("res://scripts/palette.gd")
const UI := preload("res://scripts/ui_kit.gd")
const Icons := preload("res://scripts/ui/icons.gd")

var icon_kind := "back":
	set(value):
		icon_kind = value
		queue_redraw()


func _init(kind := "back") -> void:
	icon_kind = kind
	custom_minimum_size = Vector2(48, 48)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	UI.style_button(self, UI.box(P.SURFACE, 16), UI.box(P.SURFACE_PRESSED, 16), P.TEXT)
	UI.add_press_feedback(self)


func _draw() -> void:
	Icons.draw(self, icon_kind, size / 2.0, 24.0, P.TEXT)
