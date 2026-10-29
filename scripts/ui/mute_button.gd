extends "res://scripts/ui/icon_button.gd"
## The always-visible mute toggle. Reflects and flips Settings.muted.


func _init() -> void:
	super("sound")
	tooltip_text = "Mute sound"


func _ready() -> void:
	_sync(Settings.muted)
	Settings.muted_changed.connect(_sync)
	pressed.connect(_on_pressed)


func _sync(muted: bool) -> void:
	icon_kind = "muted" if muted else "sound"


func _on_pressed() -> void:
	Settings.toggle_mute()
	pivot_offset = size / 2.0
	var t := create_tween()
	t.tween_property(self, "rotation", 0.18, 0.06)
	t.tween_property(self, "rotation", -0.14, 0.08)
	t.tween_property(self, "rotation", 0.0, 0.1)
