shader_type sky;

uniform vec3 top_color : source_color = vec3(0.3, 0.6, 1.0);
uniform vec3 horizon_color : source_color = vec3(0.8, 0.9, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 sun_color : source_color = vec3(1.0, 0.95, 0.8);
uniform float cloud_speed = 0.1;
uniform float cloud_scale = 3.0;
uniform float cloud_density = 0.5;
uniform float sun_size = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1,0)), f.x),
		mix(hash(i + vec2(0,1)), hash(i + vec2(1,1)), f.x),
		f.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void sky() {
	vec3 dir = EYEDIR;
	
	// sky gradient
	float horizon = pow(clamp(1.0 - dir.y, 0.0, 1.0), 2.0);
	vec3 sky = mix(top_color, horizon_color, horizon);

	// sun
	vec3 sun_dir = normalize(vec3(0.3, 0.4, -0.5));
	float sun = pow(max(dot(dir, sun_dir), 0.0), 512.0 / sun_size);
	float sun_glow = pow(max(dot(dir, sun_dir), 0.0), 8.0) * 0.3;
	sky += sun_color * sun;
	sky += sun_color * sun_glow * 0.5;
	
	// clouds — only above horizon
	if (dir.y > 0.0) {
		vec2 uv = dir.xz / (dir.y + 0.1);
		uv *= cloud_scale;
		uv.x += TIME * cloud_speed;
		
		// two layers for depth
		float cloud1 = fbm(uv);
		float cloud2 = fbm(uv * 1.5 + vec2(TIME * cloud_speed * 0.5, 0.0));
		float clouds = smoothstep(cloud_density, cloud_density + 0.3, cloud1 * cloud2 * 2.0);
		
		// fade clouds near horizon
		float fade = clamp(dir.y * 4.0, 0.0, 1.0);
		clouds *= fade;
		
		// sun highlight on clouds
		float sun_highlight = pow(max(dot(dir, sun_dir), 0.0), 4.0) * 0.3;
		vec3 cloud_lit = mix(cloud_color, cloud_color * sun_color * 1.2, sun_highlight);
		
		sky = mix(sky, cloud_lit, clouds * 0.9);
	}
	
	COLOR = sky;
}