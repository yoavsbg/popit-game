extends "res://scripts/screen.gd"
## Home: wordmark, a poppable decorative bubble cluster, Play levels and Free pop.

const HERO_RINGED := [3, 11]

var hero: Board


func build() -> void:
	body.add_child(top_bar(Callable()))

	var middle := UI.vbox(36)
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(middle)

	hero = Board.new(5, 3)
	hero.fx = fx
	hero.multi_touch = true
	var colors := []
	for i in hero.count():
		colors.append(P.hsl(i * 24.0, 0.82, 0.62))
	hero.set_colors(colors)
	hero.cell_pressed.connect(_on_hero_pressed)
	middle.add_child(hero)
	hero.intro(0.1)
	hero.set_targets(HERO_RINGED, 0.6)

	var title_block := UI.vbox(12)
	var title := UI.label("Pop It", 76, 700)
	title.add_theme_font_override("font", UI.font(700, false, -1))
	title_block.add_child(title)
	var tagline := UI.label("Pop only the ringed bubbles. Beat your best time.", 19, 400, P.MUTED)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_block.add_child(tagline)
	middle.add_child(title_block)
	appear(title, 0.25)
	appear(tagline, 0.32)

	var bottom := UI.vbox(14)
	var play := UI.pill_button("Play levels", true)
	play.pressed.connect(Router.go.bind(Router.LEVEL_SELECT))
	bottom.add_child(play)
	var free := UI.pill_button("Free pop", false)
	free.pressed.connect(Router.go.bind(Router.FREE_POP))
	bottom.add_child(free)
	var best := UI.label(_best_line(), 15, 400, P.MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	var best_box := MarginContainer.new()
	best_box.add_theme_constant_override("margin_top", 6)
	best_box.add_child(best)
	bottom.add_child(best_box)
	body.add_child(bottom)
	appear(play, 0.4)
	appear(free, 0.46)
	appear(best_box, 0.52)


func _best_line() -> String:
	for id in range(Game.levels.size() - 1, -1, -1):
		var ms := SaveData.get_best(id)
		if ms >= 0:
			return "Best on Level %d: %ss" % [id, Game.format_ms(ms)]
	return "Start with the warm up. Every millisecond counts."


## The hero bubbles are a toy: they pop and spring back a moment later.
func _on_hero_pressed(i: int) -> void:
	if hero.cells[i].popped:
		return
	var was_ringed := i in HERO_RINGED
	hero.pop(i)
	Audio.pop()
	Haptics.tap()
	await get_tree().create_timer(1.3).timeout
	if not is_instance_valid(hero):
		return
	hero.unpop(i, 0.0, true)
	if was_ringed:
		hero.set_targets([i], 0.15)
