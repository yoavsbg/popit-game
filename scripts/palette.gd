extends RefCounted
## Design tokens from the build brief and color helpers.

const BG := Color("#1B1340")
const SURFACE := Color("#2A1F5E")
const SURFACE_PRESSED := Color("#3A2E7A")
const LOCKED := Color("#231A52")
const MUTED := Color("#B9B1E6")
const ACCENT := Color("#FFD23F")
const OUTLINE := Color("#8B7FD8")
const PENALTY := Color("#FF6B6B")
const TEXT := Color("#FFFFFF")
const DOT_EMPTY := Color("#3A2E7A")
const LOCKED_NAME := Color("#D9D4F5")
const CHIP_TEXT := Color("#FF9A9A")
const CHIP_BG := Color("#4A2345")


## CSS-style hsl(): hue in degrees, saturation and lightness in 0..1.
static func hsl(hue: float, s: float, l: float, a := 1.0) -> Color:
	var h := fposmod(hue, 360.0) / 60.0
	var c := (1.0 - absf(2.0 * l - 1.0)) * s
	var x := c * (1.0 - absf(fmod(h, 2.0) - 1.0))
	var m := l - c / 2.0
	var rgb: Vector3
	if h < 1.0:
		rgb = Vector3(c, x, 0)
	elif h < 2.0:
		rgb = Vector3(x, c, 0)
	elif h < 3.0:
		rgb = Vector3(0, c, x)
	elif h < 4.0:
		rgb = Vector3(0, x, c)
	elif h < 5.0:
		rgb = Vector3(x, 0, c)
	else:
		rgb = Vector3(c, 0, x)
	return Color(rgb.x + m, rgb.y + m, rgb.z + m, a)


## Bubble color for cell `i` of `n` in the default rainbow board.
static func bubble(i: int, n: int, hue_offset := 0.0) -> Color:
	return hsl(round(i * 360.0 / n) + hue_offset, 0.82, 0.62)
