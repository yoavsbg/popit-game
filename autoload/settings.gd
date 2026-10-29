extends Node
## Global player settings. The mute flag silences every sound and survives restarts.

signal muted_changed(muted: bool)

var muted := false:
	set(value):
		if value == muted:
			return
		muted = value
		AudioServer.set_bus_mute(0, muted)
		SaveData.set_setting("muted", muted)
		muted_changed.emit(muted)

var theme_id := "rainbow":
	set(value):
		theme_id = value
		SaveData.set_setting("theme", value)


func _ready() -> void:
	muted = bool(SaveData.get_setting("muted", false))
	AudioServer.set_bus_mute(0, muted)
	theme_id = str(SaveData.get_setting("theme", "rainbow"))


func toggle_mute() -> void:
	muted = not muted
