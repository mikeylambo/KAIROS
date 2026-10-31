shader_type canvas_item;
// Light ribbon with frayed ends. UV.x: 0 at shoulder → 1 at tip.
uniform vec4 core_color : source_color = vec4(1.0);
uniform vec4 end_color : source_color = vec4(0.25, 0.96, 1.0, 1.0);
uniform float glow = 1.6;
uniform float time_s = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

void fragment() {
	float x = UV.x;
	float fray = smoothstep(0.55, 1.0, x);
	float strand = floor(UV.y * 7.0);
	float n = hash(vec2(strand, floor(x * 30.0 + time_s * 2.0)));
	float cut = step(n, 1.0 - fray * 1.15);
	float edge = 1.0 - pow(abs(UV.y * 2.0 - 1.0), 3.0);
	vec3 col = mix(core_color.rgb, end_color.rgb, smoothstep(0.15, 0.85, x)) * glow;
	COLOR = vec4(col, edge * cut * (1.0 - x * 0.35));
}
