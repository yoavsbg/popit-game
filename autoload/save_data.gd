extends Node
## Best times, unlocked levels and settings, stored in one ConfigFile.

const PATH := "user://save.cfg"
const TEST_PATH := "user://autotest.cfg"

var _cfg := ConfigFile.new()
var _path := PATH


func _init() -> void:
	if "--autotest" in OS.get_cmdline_user_args():
		_path = TEST_PATH
		if "--keep-save" not in OS.get_cmdline_user_args():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	_cfg.load(_path)


func get_best(level_id: int) -> int:
	return int(_cfg.get_value("best", str(level_id), -1))


func set_best(level_id: int, ms: int) -> void:
	_cfg.set_value("best", str(level_id), ms)
	_save()


## Highest level id the player may open.
func unlocked_up_to() -> int:
	return int(_cfg.get_value("progress", "unlocked", 0))


func unlock(level_id: int) -> void:
	if level_id > unlocked_up_to():
		_cfg.set_value("progress", "unlocked", level_id)
		_save()


func get_setting(key: String, default: Variant) -> Variant:
	return _cfg.get_value("settings", key, default)


func set_setting(key: String, value: Variant) -> void:
	_cfg.set_value("settings", key, value)
	_save()


func _save() -> void:
	var err := _cfg.save(_path)
	if err != OK:
		push_warning("Could not save %s (error %d)" % [_path, err])
