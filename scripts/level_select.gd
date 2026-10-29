extends "res://scripts/screen.gd"
## Level select: 2-column cards in a scrolling list. Clearing a level unlocks the next one,
## whatever the time was.

const Badge := preload("res://scripts/ui/badge.gd")
const BADGE_HUES := [12.0, 48.0, 150.0, 210.0, 270.0, 320.0, 90.0, 180.0, 30.0, 240.0, 340.0, 120.0]
## A press that moves further than this is a scroll, not a tap.
const TAP_SLOP := 12.0

var scroll: ScrollContainer

var _grid: GridContainer
var _pressed_card: Control
var _press_pos := Vector2.ZERO


## No bottom padding: the list scrolls to the screen edge and pads itself.
func padding() -> Array:
	return [56, 24, 0]


func build() -> void:
	body.add_child(top_bar(go_back))

	var head := UI.vbox(4)
	head.add_child(UI.label("Levels", 44, 700))
	var sub := UI.label("Clear a level to unlock the next one.", 17, 400, P.MUTED)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.add_child(sub)
	body.add_child(head)
	appear(head, 0.05)

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	body.add_child(scroll)

	var inner := MarginContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("margin_top", 2)
	inner.add_theme_constant_override("margin_bottom", 32)
	scroll.add_child(inner)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_grid)
	for l in Game.levels:
		var card := _card(l)
		_grid.add_child(card)
		# Only the first screenful animates in; the rest of a long list just appears.
		if l.id < 8:
			appear(card, 0.1 + l.id * 0.05)
	_reveal_progress()


func go_back() -> void:
	Router.go(Router.HOME)


## Scrolls down to the newest unlocked level when it is below the fold.
func _reveal_progress() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var newest := mini(SaveData.unlocked_up_to(), Game.levels.size() - 1)
	var card := _grid.get_node_or_null("Card%d" % newest) as Control
	if card == null:
		return
	var want := int(card.position.y + card.size.y + 2.0 - scroll.size.y + 24.0)
	if want > 0:
		create_tween().tween_property(scroll, "scroll_vertical", want, 0.5) \
			.set_delay(0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _card(l: Dictionary) -> Control:
	var id: int = l.id
	var unlocked := Game.is_unlocked(id)
	var card := PanelContainer.new()
	card.name = "Card%d" % id
	card.custom_minimum_size = Vector2(0, 178)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# PASS lets drags reach the ScrollContainer while taps still open the card.
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.add_theme_stylebox_override("panel",
		UI.box(P.SURFACE if unlocked else P.LOCKED, 22, 0, Color.TRANSPARENT, 16, 16))
	card.gui_input.connect(_on_card_input.bind(card, id))

	var v := UI.vbox(6)
	card.add_child(v)
	var badge := Badge.new()
	badge.locked = not unlocked
	badge.color = P.hsl(BADGE_HUES[id % BADGE_HUES.size()], 0.82, 0.62) if unlocked else P.DOT_EMPTY
	badge.text = str(id)
	v.add_child(badge)
	v.add_child(UI.label(l.name, 20, 600, P.TEXT if unlocked else P.LOCKED_NAME))
	var detail := UI.label(l.detail, 15, 400, P.MUTED)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(detail)
	v.add_child(UI.spacer())

	if unlocked:
		var best := SaveData.get_best(id)
		if best >= 0:
			v.add_child(UI.label("Best %ss" % Game.format_ms(best), 15, 500, P.ACCENT))
		else:
			v.add_child(UI.label("Not played yet", 15, 500, P.MUTED))
	elif not Game.is_implemented(id) and id <= SaveData.unlocked_up_to():
		v.add_child(UI.label("Coming soon", 15, 500, P.MUTED))
	return card


func _on_card_input(event: InputEvent, card: Control, id: int) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _pressed_card == card and motion.global_position.distance_to(_press_pos) > TAP_SLOP:
			UI.press_out(card)
			_pressed_card = null
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_pressed_card = card
		_press_pos = mb.global_position
		UI.press_in(card, false)
	elif _pressed_card == card:
		_pressed_card = null
		UI.press_out(card)
		if Rect2(Vector2.ZERO, card.size).has_point(mb.position):
			_open(card, id)


func _open(card: Control, id: int) -> void:
	if Game.is_unlocked(id):
		Audio.click()
		Haptics.tap()
		Game.current_level_id = id
		Router.go(Router.LEVEL)
		return
	Haptics.wrong()
	Audio.wrong()
	card.pivot_offset = card.size / 2.0
	var t := card.create_tween()
	for a in [0.05, -0.04, 0.025, -0.012, 0.0]:
		t.tween_property(card, "rotation", a, 0.05)
