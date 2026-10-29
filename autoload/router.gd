extends CanvasLayer
## Scene navigation with a short fade through the background color.

const SPLASH := "res://scenes/splash.tscn"
const HOME := "res://scenes/home.tscn"
const LEVEL_SELECT := "res://scenes/level_select.tscn"
const LEVEL := "res://scenes/level.tscn"
const RESULT := "res://scenes/result.tscn"
const FREE_POP := "res://scenes/free_pop.tscn"

var busy := false
var _veil := ColorRect.new()


func _ready() -> void:
	layer = 100
	_veil.color = Color("#1B1340")
	_veil.modulate.a = 0.0
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_veil)


func go(path: String) -> void:
	if busy:
		return
	busy = true
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	var out := create_tween()
	out.tween_property(_veil, "modulate:a", 1.0, 0.14)
	await out.finished
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var back := create_tween()
	back.tween_property(_veil, "modulate:a", 0.0, 0.2)
	await back.finished
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	busy = false
