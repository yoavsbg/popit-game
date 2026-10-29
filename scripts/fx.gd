extends Node2D
## Lightweight effects layer: pop particles, shockwave rings and confetti, all drawn in one pass.

const P := preload("res://scripts/palette.gd")


class Particle:
	var pos: Vector2
	var vel: Vector2
	var color: Color
	var size: float
	var life: float
	var max_life: float
	var gravity: float
	var drag: float
	var rot := 0.0
	var spin := 0.0
	var confetti := false


class Wave:
	var pos: Vector2
	var r0: float
	var r1: float
	var t := 0.0
	var dur: float
	var color: Color
	var width: float


var _parts: Array = []
var _waves: Array = []
var _dirty := false


## Small droplets flying out of a popped bubble.
func burst(pos: Vector2, color: Color, count := 9, speed := 230.0, size := 5.0) -> void:
	for i in count:
		var p := Particle.new()
		var a := TAU * i / count + randf_range(-0.35, 0.35)
		p.pos = pos + Vector2(cos(a), sin(a)) * size
		p.vel = Vector2(cos(a), sin(a)) * speed * randf_range(0.5, 1.0)
		p.color = color.lightened(randf_range(0.0, 0.3))
		p.size = size * randf_range(0.55, 1.1)
		p.max_life = randf_range(0.35, 0.55)
		p.life = p.max_life
		p.gravity = 420.0
		p.drag = 4.0
		_parts.append(p)


## Expanding ring that fades out.
func ring(pos: Vector2, radius: float, color: Color, grow := 16.0, dur := 0.32, width := 3.0) -> void:
	var w := Wave.new()
	w.pos = pos
	w.r0 = radius
	w.r1 = radius + grow
	w.dur = dur
	w.color = color
	w.width = width
	_waves.append(w)


## Paper confetti fired upward from `origin`, drifting down with spin.
func confetti(origin: Vector2, count := 60, spread := 0.9, power := 820.0) -> void:
	for i in count:
		var p := Particle.new()
		var a := -PI / 2 + randf_range(-spread, spread)
		p.pos = origin + Vector2(randf_range(-30, 30), 0)
		p.vel = Vector2(cos(a), sin(a)) * power * randf_range(0.45, 1.0)
		p.color = P.hsl(randf() * 360.0, 0.85, 0.64)
		p.size = randf_range(7.0, 12.0)
		p.max_life = randf_range(1.6, 2.6)
		p.life = p.max_life
		p.gravity = 700.0
		p.drag = 2.2
		p.rot = randf() * TAU
		p.spin = randf_range(-9.0, 9.0)
		p.confetti = true
		_parts.append(p)


func busy() -> bool:
	return not _parts.is_empty() or not _waves.is_empty()


func _process(delta: float) -> void:
	if not busy():
		if _dirty:
			_dirty = false
			queue_redraw()
		return
	_dirty = true
	for p: Particle in _parts:
		p.life -= delta
		p.vel *= maxf(0.0, 1.0 - p.drag * delta)
		p.vel.y += p.gravity * delta
		if p.confetti:
			p.vel.y = minf(p.vel.y, 260.0)
			p.vel.x += sin(p.life * 5.0 + p.rot) * 30.0 * delta
		p.pos += p.vel * delta
		p.rot += p.spin * delta
	_parts = _parts.filter(func(p: Particle) -> bool: return p.life > 0.0)
	for w: Wave in _waves:
		w.t += delta
	_waves = _waves.filter(func(w: Wave) -> bool: return w.t < w.dur)
	queue_redraw()


func _draw() -> void:
	for w: Wave in _waves:
		var k := w.t / w.dur
		var e := 1.0 - pow(1.0 - k, 3.0)
		var c := Color(w.color, w.color.a * (1.0 - k))
		draw_arc(w.pos, lerpf(w.r0, w.r1, e), 0.0, TAU, 48, c, maxf(w.width * (1.0 - k), 0.6), true)
	for p: Particle in _parts:
		var k := p.life / p.max_life
		var c := Color(p.color, clampf(k * 2.0, 0.0, 1.0))
		if p.confetti:
			draw_set_transform(p.pos, p.rot, Vector2(1.0, absf(cos(p.rot * 1.3)) * 0.8 + 0.2))
			draw_rect(Rect2(-p.size / 2.0, -p.size * 0.3, p.size, p.size * 0.6), c)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_circle(p.pos, p.size * (0.35 + 0.65 * k), c, true, -1.0, true)
