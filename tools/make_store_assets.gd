extends SceneTree
## Composes the App Store and Google Play listing images from the raw 1290x2796 game frames in
## docs/store/raw (captured by the autotest on an Android emulator set to that size).
## Needs a real renderer, so it can't run headless.
## Run: godot --path . -s tools/make_store_assets.gd
## Output: docs/store/app-store/ and docs/store/google-play/

const P := preload("res://scripts/palette.gd")
const FONT_FILE := preload("res://assets/fonts/Fredoka-Variable.ttf")

const RAW := "res://docs/store/raw/"
const OUT := "res://docs/store/"

## Headline in two lines (the second one is yellow), a one-line benefit, and the glow color.
const SHOTS := [
	{"raw": "L03_run", "name": "pop-the-ringed-bubbles", "a": "POP THE", "b": "RINGED BUBBLES",
		"sub": "Tap fast. Pure fidget fun.", "glow": "#7C4DFF"},
	{"raw": "04_wrong_taps", "name": "beat-the-clock", "a": "BEAT THE", "b": "CLOCK",
		"sub": "Every wrong tap costs +1 second", "glow": "#FF5C8A"},
	{"raw": "21_levels_top", "name": "200-levels", "a": "200", "b": "LEVELS",
		"sub": "Each one trickier than the last", "glow": "#2EC4D6"},
	{"raw": "L05_run", "name": "flashing-and-moving-targets", "a": "FLASHING &", "b": "MOVING TARGETS",
		"sub": "Stay sharp. Stay fast.", "glow": "#FFB020"},
	{"raw": "31_freepop_candy", "name": "relax-in-free-pop", "a": "RELAX IN", "b": "FREE POP",
		"sub": "No timer. Just satisfying pops.", "glow": "#FF7AC8", "crop": 0.015},
	{"raw": "L03_result", "name": "chase-your-best-time", "a": "CHASE YOUR", "b": "BEST TIME",
		"sub": "The next level starts by itself", "glow": "#4D9DFF"},
	{"raw": "00_splash_pop", "name": "so-satisfying", "a": "SO", "b": "SATISFYING",
		"sub": "Great pops, haptics and music", "glow": "#9B5CFF"},
]

const RAINBOW := ["#FF5A5F", "#FF8A3D", "#FFC93C", "#7ED957", "#36D1C4", "#4D9DFF", "#8B6CFF", "#E056FD"]


## Soft round bubbles in the same style as the game and the icon.
var _fonts := {}


class Bubbles extends Control:
	var items: Array = []

	func _draw() -> void:
		for b in items:
			var c: Vector2 = b.pos
			var r: float = b.r
			var col: Color = b.col
			draw_circle(c + Vector2(0, r * 0.10), r * 1.03, Color(0, 0, 0, 0.22))
			draw_circle(c, r, col.darkened(0.2))
			draw_circle(c + Vector2(0, -r * 0.05), r * 0.93, col)
			draw_circle(c + Vector2(-r * 0.30, -r * 0.34), r * 0.32, Color(1, 1, 1, 0.26))
			draw_circle(c + Vector2(-r * 0.35, -r * 0.40), r * 0.15, Color(1, 1, 1, 0.55))
			if b.get("ring", false):
				draw_arc(c, r * 1.27, 0.0, TAU, 96, Color.WHITE, maxf(r * 0.09, 2.0), true)
			if b.get("hole", false):
				draw_circle(c, r * 1.02, Color("#120C2E"))
				draw_circle(c + Vector2(0, r * 0.08), r * 0.82, Color("#231A52"))


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for d in ["app-store/screenshots-6.9in-1290x2796", "app-store/screenshots-6.5in-1284x2778",
			"google-play/phone-screenshots-1080x1920"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + d))

	var n := 0
	for s in SHOTS:
		n += 1
		var tex := _load_tex(RAW + s.raw + ".png")
		var file := "%02d-%s.png" % [n, s.name]
		await _save(await _render(Vector2i(1290, 2796), _listing.bind(s, tex, n, 0.285, s.get("crop", 0.07))),
			"app-store/screenshots-6.9in-1290x2796/" + file)
		await _save(await _render(Vector2i(1284, 2778), _listing.bind(s, tex, n, 0.285, s.get("crop", 0.07))),
			"app-store/screenshots-6.5in-1284x2778/" + file)
		await _save(await _render(Vector2i(1080, 1920), _listing.bind(s, tex, n, 0.28, s.get("crop", 0.07))),
			"google-play/phone-screenshots-1080x1920/" + file)

	await _save(await _render(Vector2i(1024, 500), _feature.bind(_load_tex(RAW + "L03_run.png"))),
		"google-play/feature-graphic-1024x500.png")

	# Icons: the 1024 px icon the iOS export uses, and the 512 px Play Store icon (32-bit PNG).
	var icon := Image.load_from_file(ProjectSettings.globalize_path("res://assets/icon_1024.png"))
	icon.convert(Image.FORMAT_RGB8)
	icon.save_png(ProjectSettings.globalize_path(OUT + "app-store/app-icon-1024x1024.png"))
	var small := icon.duplicate() as Image
	small.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	small.convert(Image.FORMAT_RGBA8)
	small.save_png(ProjectSettings.globalize_path(OUT + "google-play/app-icon-512x512.png"))
	print("done")
	quit()


func _load_tex(path: String) -> Texture2D:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Renders a Control tree built by `builder(root)` into an opaque image of the given size.
func _render(size: Vector2i, builder: Callable) -> Image:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var stage := Control.new()
	stage.size = Vector2(size)
	vp.add_child(stage)
	builder.call(stage)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGB8)
	return img


func _save(img: Image, rel: String) -> void:
	var path := ProjectSettings.globalize_path(OUT + rel)
	img.save_png(path)
	print("wrote ", rel, " ", img.get_size())


# --- Layouts -------------------------------------------------------------------------------

## Store screenshot: benefit headline on top, the real game frame in a phone below it,
## cropped by the bottom edge so the phone can be big.
func _listing(stage: Control, s: Dictionary, tex: Texture2D, index: int, top_frac: float, crop_frac: float) -> void:
	var size := stage.size
	var w := size.x
	var h := size.y
	_gradient(stage, Color("#3A1F87").lerp(Color(s.glow), 0.25), Color("#1B1340"), Vector2(0.5, 0), Vector2(0.5, 0.75))

	# Soft glow behind the phone.
	var glow := TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.colors = PackedColorArray([Color(s.glow, 0.55), Color(s.glow, 0.0)])
	gt.gradient = g
	gt.width = 256
	gt.height = 256
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.size = Vector2(w * 1.5, w * 1.5)
	glow.position = Vector2(w * 0.5 - glow.size.x / 2.0, h * 0.62 - glow.size.y / 2.0)
	stage.add_child(glow)

	var phone_top := h * top_frac
	var visible_h := h - phone_top
	var outer_h := visible_h / (1.0 - crop_frac)
	var screen_aspect := float(tex.get_height()) / tex.get_width()
	var pw := outer_h / (0.956 * screen_aspect + 0.044)
	pw = minf(pw, w * 0.86)

	var bubbles := Bubbles.new()
	bubbles.size = size
	bubbles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubbles.items = _scatter(index, size, Rect2(w * 0.03, 0.0, w * 0.94, phone_top))
	stage.add_child(bubbles)

	# Headline: line one white, line two yellow, each fitted to the width.
	var y := h * 0.028
	var l1 := _fit(stage, s.a, 700, 0.115 * w, w * 0.9, Color.WHITE, y)
	var l2 := _fit(stage, s.b, 700, 0.150 * w, w * 0.92, P.ACCENT, y + l1 * 0.98)
	var sub := _fit(stage, s.sub, 500, 0.040 * w, w * 0.9, Color("#E2DEFA"), y + l1 * 0.98 + l2 * 1.0 + w * 0.012)
	assert(y + l1 + l2 + sub < phone_top + h * 0.02)

	var phone := _phone(tex, Vector2((w - pw) / 2.0, phone_top), pw)
	stage.add_child(phone)


## Google Play feature graphic, 1024x500: wordmark, tagline and a cluster of bubbles.
func _feature(stage: Control, tex: Texture2D) -> void:
	_gradient(stage, Color("#4B2AA8"), Color("#1B1340"), Vector2(0, 0), Vector2(1, 1))
	var bubbles := Bubbles.new()
	bubbles.size = stage.size
	bubbles.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 3x3 grid like the app icon: a ringed target, one popped hole.
	var items: Array = []
	var cx := 770.0
	var cy := 250.0
	var step := 150.0
	var r := 60.0
	var k := 0
	for row in 3:
		for col in 3:
			var item := {"pos": Vector2(cx + (col - 1) * step, cy + (row - 1) * step), "r": r,
				"col": Color(RAINBOW[(k * 3 + 1) % RAINBOW.size()])}
			if row == 1 and col == 1:
				item.ring = true
			if row == 2 and col == 2:
				item.hole = true
			items.append(item)
			k += 1
	bubbles.items = items
	stage.add_child(bubbles)

	var title := _label("Pop It", 700, 176, Color.WHITE, -4)
	title.position = Vector2(54, 62)
	stage.add_child(title)
	var tag := _label("Pop. Race. Beat your best.", 600, 38, P.ACCENT)
	tag.position = Vector2(60, 270)
	stage.add_child(tag)
	var chips := _label("200 levels  -  Free pop  -  Plays offline", 500, 27, Color("#D9D4F5"))
	chips.position = Vector2(60, 332)
	stage.add_child(chips)


# --- Building blocks ------------------------------------------------------------------------

func _gradient(stage: Control, from: Color, to: Color, f: Vector2, t: Vector2) -> void:
	var gt := GradientTexture2D.new()
	gt.fill_from = f
	gt.fill_to = t
	var g := Gradient.new()
	g.colors = PackedColorArray([from, to])
	gt.gradient = g
	gt.width = 512
	gt.height = 512
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = stage.size
	stage.add_child(tr)


## Fredoka at a weight, as the game does it (variable font axis), with optional letter spacing.
func _font(weight: int, spacing := 0) -> Font:
	var key := "%d-%d" % [weight, spacing]
	if not _fonts.has(key):
		var f := FontVariation.new()
		f.base_font = FONT_FILE
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		f.spacing_glyph = spacing
		_fonts[key] = f
	return _fonts[key]


func _label(text: String, weight: int, size: float, color: Color, spacing := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font(weight, spacing))
	l.add_theme_font_size_override("font_size", int(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(int(size * 0.035), 2))
	return l


## Adds a centered one-line label shrunk to fit max_w. Returns the line height used.
func _fit(stage: Control, text: String, weight: int, max_size: float, max_w: float, color: Color, y: float) -> float:
	var font := _font(weight)
	var size := max_size
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x
	if tw > max_w:
		size = floorf(size * max_w / tw)
	var l := _label(text, weight, size, color)
	var lw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x
	l.position = Vector2((stage.size.x - lw) / 2.0, y)
	stage.add_child(l)
	return font.get_height(int(size))


## A phone: dark rounded body, the frame clipped to the rounded screen, and a camera pill.
func _phone(tex: Texture2D, pos: Vector2, pw: float) -> Control:
	var bez := pw * 0.022
	var sw := pw - 2.0 * bez
	var sh := sw * tex.get_height() / tex.get_width()
	var radius := int(pw * 0.125)

	var body := Panel.new()
	body.position = pos
	body.size = Vector2(pw, sh + 2.0 * bez)
	var st := StyleBoxFlat.new()
	st.bg_color = Color("#0B0721")
	st.set_corner_radius_all(radius)
	st.set_border_width_all(maxi(int(pw * 0.004), 2))
	st.border_color = Color("#5A4BB0")
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_size = int(pw * 0.06)
	st.shadow_offset = Vector2(0, pw * 0.02)
	body.add_theme_stylebox_override("panel", st)

	var screen := Panel.new()
	screen.position = Vector2(bez, bez)
	screen.size = Vector2(sw, sh)
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color.BLACK
	ss.set_corner_radius_all(int(radius - bez))
	screen.add_theme_stylebox_override("panel", ss)
	screen.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	body.add_child(screen)

	var pic := TextureRect.new()
	pic.texture = tex
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_SCALE
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	pic.size = Vector2(sw, sh)
	screen.add_child(pic)

	var pill := Panel.new()
	pill.size = Vector2(sw * 0.27, sw * 0.075)
	pill.position = Vector2((pw - pill.size.x) / 2.0, bez + sw * 0.025)
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color("#05030F")
	ps.set_corner_radius_all(int(pill.size.y / 2.0))
	pill.add_theme_stylebox_override("panel", ps)
	body.add_child(pill)
	return body


## Deterministic bubbles scattered outside the headline area; the phone covers most of them, so they
## peek out from behind its sides.
func _scatter(seed_value: int, size: Vector2, keep_out: Rect2) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + seed_value * 7
	var out: Array = []
	var tries := 0
	while out.size() < 10 and tries < 600:
		tries += 1
		var r := rng.randf_range(size.x * 0.03, size.x * 0.07)
		var c := Vector2(rng.randf_range(-r * 0.3, size.x + r * 0.3), rng.randf_range(size.y * 0.1, size.y * 0.55))
		var box := Rect2(c - Vector2(r, r) * 1.3, Vector2(r, r) * 2.6)
		if box.intersects(keep_out):
			continue
		var clash := false
		for o in out:
			if c.distance_to(o.pos) < (r + o.r) * 1.25:
				clash = true
		if clash:
			continue
		out.append({"pos": c, "r": r, "col": Color(RAINBOW[rng.randi() % RAINBOW.size()])})
	return out
