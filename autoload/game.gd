extends Node
## Level and theme data, plus the hand-off state between screens.

## Level modes this build can play. Others show as locked "coming soon" cards.
const IMPLEMENTED_MODES := ["static", "flash", "move", "flash_move"]

var levels: Array[Dictionary] = []
var themes: Array[Dictionary] = []

var current_level_id := 0
## Filled by the level screen when a level is cleared; read by the result screen.
var last_result := {}


func _init() -> void:
	for l in _load_json("res://data/levels.json"):
		var d: Dictionary = l
		d.id = int(d.id)
		d.targets = int(d.targets)
		d.boards = int(d.boards)
		levels.append(d)
	for t in _load_json("res://data/themes.json"):
		themes.append(t)


func level(id: int) -> Dictionary:
	for l in levels:
		if l.id == id:
			return l
	return {}


func is_implemented(id: int) -> bool:
	var l := level(id)
	return not l.is_empty() and l.mode in IMPLEMENTED_MODES


func is_unlocked(id: int) -> bool:
	return is_implemented(id) and id <= SaveData.unlocked_up_to()


func theme(id: String) -> Dictionary:
	for t in themes:
		if t.id == id:
			return t
	return themes[0]


static func format_ms(ms: int) -> String:
	return "%d.%03d" % [ms / 1000, ms % 1000]


func _load_json(path: String) -> Array:
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if data is Array:
		return data
	push_error("Could not parse %s" % path)
	return []
