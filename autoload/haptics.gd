extends Node
## Thin wrapper over Input.vibrate_handheld() so a Core Haptics plugin can replace it later.


func tap() -> void:
	_vibrate(10, 0.35)


func wrong() -> void:
	_vibrate(70, 0.9)


func success() -> void:
	_vibrate(35, 0.6)


func _vibrate(ms: int, amplitude: float) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms, amplitude)
