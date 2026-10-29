extends RefCounted
## Builders for the shared UI pieces: Fredoka weights, labels, buttons and styleboxes.

const P := preload("res://scripts/palette.gd")
const FONT_FILE := preload("res://assets/fonts/Fredoka-Variable.ttf")

static var _fonts := {}


## Fredoka at a given weight (400 regular, 500 medium, 600 semibold, 700 bold).
static func font(weight: int, tabular := false, spacing := 0) -> Font:
	var key := "%d-%s-%d" % [weight, tabular, spacing]
	if not _fonts.has(key):
		var f := FontVariation.new()
		f.base_font = FONT_FILE
		var ts := TextServerManager.get_primary_interface()
		f.variation_opentype = {ts.name_to_tag("wght"): weight}
		if tabular:
			f.opentype_features = {ts.name_to_tag("tnum"): 1}
		f.spacing_glyph = spacing
		_fonts[key] = f
	return _fonts[key]


static func label(text: String, size: int, weight := 400, color := P.TEXT,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(weight))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func box(bg: Color, radius: int, border := 0, border_color := Color.TRANSPARENT,
		pad_x := 0, pad_y := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.set_border_width_all(border)
	s.border_color = border_color
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	s.anti_aliasing = true
	return s


static func style_button(b: Button, normal: StyleBox, pressed: StyleBox, text_color: Color) -> void:
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color",
			"font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(c, text_color)
	b.focus_mode = Control.FOCUS_NONE


## Fully rounded button: yellow primary or outlined secondary.
static func pill_button(text: String, primary: bool, height := 60, font_size := 22,
		pad_x := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = height
	b.add_theme_font_override("font", font(600))
	b.add_theme_font_size_override("font_size", font_size)
	var r := height / 2
	if primary:
		style_button(b, box(P.ACCENT, r, 0, Color.TRANSPARENT, pad_x),
			box(P.ACCENT.darkened(0.12), r, 0, Color.TRANSPARENT, pad_x), P.BG)
	else:
		style_button(b, box(Color(P.BG, 0.0), r, 2, P.OUTLINE, pad_x),
			box(P.SURFACE, r, 2, P.OUTLINE, pad_x), P.TEXT)
	add_press_feedback(b)
	return b


## Squash on press, springy release, soft click.
static func add_press_feedback(b: BaseButton, click := true) -> void:
	b.button_down.connect(func() -> void: press_in(b, click))
	b.button_up.connect(func() -> void: press_out(b))


static func press_in(c: Control, click := true) -> void:
	c.pivot_offset = c.size / 2.0
	c.create_tween().tween_property(c, "scale", Vector2(0.95, 0.95), 0.07) \
		.set_trans(Tween.TRANS_QUAD)
	if click:
		Audio.click()
		Haptics.tap()


static func press_out(c: Control) -> void:
	c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


static func spacer(vertical := true) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if vertical:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func vbox(gap: int) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", gap)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


static func hbox(gap: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", gap)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h
