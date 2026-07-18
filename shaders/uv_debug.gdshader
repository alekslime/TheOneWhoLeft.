shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

// --- Eye state, driven from eye_controller.gd ---
uniform float open_amount : hint_range(0.0, 1.0) = 1.0; // 0 = sealed eyelid, 1 = fully open
uniform vec2 pupil_offset = vec2(0.0, 0.0);              // where the pupil looks, in UV space (-0.5..0.5)
uniform float stress : hint_range(0.0, 1.0) = 0.0;       // 0 = calm veins, 1 = bloodshot/bulging

// --- Look/appearance ---
uniform vec3 sclera_color : source_color = vec3(0.85, 0.82, 0.75);
uniform vec3 iris_color : source_color = vec3(0.25, 0.18, 0.08);
uniform vec3 vein_color : source_color = vec3(0.55, 0.05, 0.05);
uniform vec3 eyelid_color : source_color = vec3(0.35, 0.22, 0.18);
uniform float roughness_val : hint_range(0.0, 1.0) = 0.25;
uniform sampler2D noise_tex;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float veins(vec2 uv, float t) {
	float n = 0.0;
	float amp = 0.5;
	vec2 p = uv * 8.0;
	for (int i = 0; i < 4; i++) {
		float ridge = 1.0 - abs(noise(p + float(i) * 4.7) * 2.0 - 1.0);
		n += pow(ridge, 6.0) * amp;
		p *= 1.9;
		amp *= 0.55;
	}
	return clamp(n * t, 0.0, 1.0);
}

varying vec2 world_uv;

void vertex() {
	world_uv = UV;
}

void fragment() {
	vec2 uv = world_uv;
	vec2 centered = uv - vec2(0.5);

	float lid_gap = open_amount * 0.42;
	float lid_top = 0.5 + lid_gap;
	float top_mask = smoothstep(lid_top - 0.03, lid_top, uv.y);
	float bottom_mask = smoothstep(lid_top - 0.03, lid_top, 1.0 - uv.y);
	float eyelid_mask = clamp(top_mask + bottom_mask, 0.0, 1.0);

	vec2 eye_center = vec2(0.0, 0.0) + pupil_offset * 0.25;
	float dist_from_center = length(centered - eye_center);

	float pupil_radius = mix(0.06, 0.10, stress);
	float iris_radius = 0.18;

	float pupil_mask = smoothstep(pupil_radius, pupil_radius - 0.01, dist_from_center);
	float iris_mask = smoothstep(iris_radius, iris_radius - 0.02, dist_from_center);

	vec3 eye_color = mix(sclera_color, iris_color, iris_mask);
	eye_color = mix(eye_color, vec3(0.02), pupil_mask);

	float v = veins(uv, stress);
	eye_color = mix(eye_color, vein_color, v * (1.0 - iris_mask) * 0.7);

	float rim = pow(1.0 - clamp(dist_from_center / iris_radius, 0.0, 1.0), 3.0);
	eye_color += rim * 0.05 * (1.0 - pupil_mask);

	vec3 final_color = mix(eye_color, eyelid_color, eyelid_mask);

	ALBEDO = final_color;
	ROUGHNESS = mix(0.6, roughness_val, 1.0 - eyelid_mask);
	SPECULAR = mix(0.2, 0.6, 1.0 - eyelid_mask);
}