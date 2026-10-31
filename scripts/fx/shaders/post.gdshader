shader_type canvas_item;
// Full-screen post: inversion flash, chromatic split (overflow), dimension cracks,
// beam darken, vignette, fade whiteout dissolve.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float invert = 0.0;
uniform float pulse = 0.0;
uniform float chroma = 0.0;
uniform float cracks = 0.0;
uniform float darken = 0.0;
uniform float fade = 0.0;
uniform float time_s = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float crack_field(vec2 uv) {
	vec2 g = uv * vec2(7.0, 4.0);
	vec2 i = floor(g);
	vec2 f = fract(g);
	float d = 1.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 o = vec2(float(x), float(y));
		vec2 p = o + vec2(hash(i + o), hash(i + o + 7.0));
		d = min(d, length(f - p));
	}
	float d2 = 1.0;
	for (int y = -1; y <= 1; y++) for (int x = -1; x <= 1; x++) {
		vec2 o = vec2(float(x), float(y));
		vec2 p = o + vec2(hash(i + o), hash(i + o + 7.0));
		float l = length(f - p);
		if (l > d + 0.001) d2 = min(d2, l);
	}
	return 1.0 - smoothstep(0.0, 0.03, d2 - d);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 off = (uv - 0.5) * chroma * 0.012 * (1.0 + 0.3 * sin(time_s * 9.0));
	vec3 c;
	c.r = texture(screen_tex, uv + off).r;
	c.g = texture(screen_tex, uv).g;
	c.b = texture(screen_tex, uv - off).b;
	c = mix(c, vec3(1.0) - c, invert);
	c += vec3(pulse * 0.6);
	c *= 1.0 - darken * 0.4;
	float cr = crack_field(uv + vec2(0.0, time_s * 0.002)) * cracks;
	c = mix(c, vec3(1.2, 0.5, 1.1), cr * 0.55);
	float v = smoothstep(1.15, 0.35, length(uv - 0.5));
	c *= mix(0.72, 1.0, v);
	float n = hash(floor(uv * vec2(320.0, 180.0)) + floor(time_s * 3.0));
	float dis = step(n, fade);
	c = mix(c, vec3(1.0), clamp(fade * 0.6 + dis * fade, 0.0, 1.0));
	COLOR = vec4(c, 1.0);
}
