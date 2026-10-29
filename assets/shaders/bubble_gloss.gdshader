// Glossy bubble: base color from COLOR, a broad white highlight at the top-left
// (radial-gradient at 34% 28% in the mock) and a soft dark shade along the bottom edge.
shader_type canvas_item;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float aa = max(fwidth(d) * 1.25, 0.002);
	float mask = 1.0 - smoothstep(1.0 - aa, 1.0, d);

	vec3 col = COLOR.rgb;
	float edge = smoothstep(0.55, 1.0, d);
	float bottom = smoothstep(-0.15, 0.9, p.y);
	col = mix(col, col * 0.62, edge * bottom * 0.55);
	col = mix(col, col * 0.88, smoothstep(0.86, 1.0, d) * 0.6);

	float h = clamp(1.0 - length(p - vec2(-0.32, -0.44)) / 1.02, 0.0, 1.0);
	col = mix(col, vec3(1.0), h * 0.65);

	COLOR = vec4(col, mask * COLOR.a);
}
