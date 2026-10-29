extends SceneTree
## Renders icon.svg to the opaque 1024 px PNG the iOS export uses.
## Run: godot --headless --path . -s tools/make_icon.gd


func _init() -> void:
	var img := Image.new()
	var err := img.load_svg_from_string(FileAccess.get_file_as_string("res://icon.svg"), 1.0)
	if err != OK:
		push_error("SVG load failed: %d" % err)
		quit(1)
		return
	img.convert(Image.FORMAT_RGB8)
	img.save_png("res://assets/icon_1024.png")
	print("wrote assets/icon_1024.png ", img.get_size())
	quit()
