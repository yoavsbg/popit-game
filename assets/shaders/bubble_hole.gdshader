// Popped bubble: the surface color pressed in, with an inner shadow at the top
// (inset 0 4px 8px rgba(0,0,0,0.45) in the mock).
shader_type canvas_item;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float d = length(p);
	float aa = max(fwidth(d) * 1.25, 0.002);
	float mask = 1.0 - smoothstep(1.0 - aa, 1.0, d);

	float shadow = smoothstep(0.5, 1.08, length(p - vec2(0.0, 0.2)));
	vec3 col = mix(COLOR.rgb, vec3(0.0), shadow * 0.5);
	col = mix(col, COLOR.rgb * 1.15, smoothstep(0.6, 1.0, d) * smoothstep(0.3, 1.0, p.y) * 0.5);

	COLOR = vec4(col, mask * COLOR.a);
}
