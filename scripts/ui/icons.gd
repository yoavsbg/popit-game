extends RefCounted
## Stroke icons ported from the mock's 24x24 SVGs, drawn with antialiased lines.

const STAR := [
	Vector2(12, 3), Vector2(14.7, 8.6), Vector2(20.8, 9.5), Vector2(16.4, 13.8), Vector2(17.4, 19.9),
	Vector2(12, 17), Vector2(6.6, 19.9), Vector2(7.6, 13.8), Vector2(3.2, 9.5), Vector2(9.3, 8.6),
]
const DIAMOND := [Vector2(12, 2), Vector2(21, 12), Vector2(12, 22), Vector2(3, 12)]
const SPEAKER := [
	Vector2(11, 5), Vector2(6, 9), Vector2(3, 9), Vector2(3, 15), Vector2(6, 15), Vector2(11, 19),
	Vector2(11, 5),
]

static var _heart := PackedVector2Array()


## Draws `kind` into a box of `size` px centered at `center`.
static func draw(ci: CanvasItem, kind: String, center: Vector2, size: float, color: Color,
		width := 2.0) -> void:
	var s := size / 24.0
	var o := center - Vector2(12, 12) * s
	var w := width * s
	match kind:
		"back":
			ci.draw_polyline(_pts([Vector2(15, 18), Vector2(9, 12), Vector2(15, 6)], o, s), color, w, true)
		"sound", "muted":
			ci.draw_polyline(_pts(SPEAKER, o, s), color, w, true)
			if kind == "sound":
				ci.draw_arc(o + Vector2(11.93, 12) * s, 5.0 * s, -0.775, 0.775, 16, color, w, true)
				ci.draw_arc(o + Vector2(12.28, 12) * s, 9.0 * s, -0.806, 0.806, 24, color, w, true)
			else:
				ci.draw_line(o + Vector2(16, 9) * s, o + Vector2(22, 15) * s, color, w, true)
				ci.draw_line(o + Vector2(22, 9) * s, o + Vector2(16, 15) * s, color, w, true)
		"lock":
			var r := Rect2(o + Vector2(5, 11) * s, Vector2(14, 9) * s)
			_round_rect(ci, r, 2.0 * s, color, w)
			ci.draw_line(o + Vector2(8, 11) * s, o + Vector2(8, 8) * s, color, w, true)
			ci.draw_arc(o + Vector2(12, 8) * s, 4.0 * s, PI, TAU, 20, color, w, true)
			ci.draw_line(o + Vector2(16, 8) * s, o + Vector2(16, 11) * s, color, w, true)
		"star":
			fill(ci, _pts(STAR, o, s), color)
		"heart":
			fill(ci, _pts(heart(), o, s), color)
		"diamond":
			fill(ci, _pts(DIAMOND, o, s), color)


## Filled polygon with an antialiased outline to smooth the edges.
static func fill(ci: CanvasItem, pts: PackedVector2Array, color: Color) -> void:
	ci.draw_colored_polygon(pts, color)
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, color, 1.0, true)


## Heart outline in 24x24 space, close to the mock's SVG heart.
static func heart() -> PackedVector2Array:
	if _heart.is_empty():
		for i in 48:
			var t := TAU * i / 48.0
			var x := 16.0 * pow(sin(t), 3)
			var y := -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))
			_heart.append(Vector2(12.0 + x * 0.62, 10.5 + y * 0.62))
	return _heart


static func _pts(src: Array, o: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in src:
		out.append(o + p * s)
	return out


static func _round_rect(ci: CanvasItem, r: Rect2, rad: float, color: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var corners := [
		[r.position + Vector2(r.size.x - rad, rad), -PI / 2],
		[r.end - Vector2(rad, rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI / 2],
		[r.position + Vector2(rad, rad), PI],
	]
	for c in corners:
		for k in 5:
			var a: float = c[1] + (PI / 2) * k / 4.0
			pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	pts.append(pts[0])
	ci.draw_polyline(pts, color, w, true)
