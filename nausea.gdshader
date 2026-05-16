shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// screen wobble
	float wobble = intensity * 0.006;
	uv.x += sin(uv.y * 40.0 + time_offset * 5.0) * wobble;
	uv.x += sin(uv.y * 15.0 + time_offset * 3.0) * wobble * 0.5;
	uv.y += cos(uv.x * 40.0 + time_offset * 4.0) * wobble;
	uv.y += cos(uv.x * 10.0 + time_offset * 6.0) * wobble * 0.5;
	
	// chromatic aberration
	float aberration = intensity * 0.01;
	float r = texture(SCREEN_TEXTURE, uv + vec2(aberration, 0.0)).r;
	float g = texture(SCREEN_TEXTURE, uv).g;
	float b = texture(SCREEN_TEXTURE, uv - vec2(aberration, 0.0)).b;
	vec4 color = vec4(r, g, b, 1.0);
	
	// noise grain
	float noise = fract(sin(dot(uv + time_offset, vec2(127.1, 311.7))) * 43758.5453);
	color.rgb += (noise - 0.5) * intensity * 0.15;
	
	// desaturation
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(color.rgb, vec3(gray), intensity * 0.5);
	
	// vignette — starts at 0, builds fast
	vec2 center = uv - 0.5;
	float vignette = 1.0 - dot(center, center) * intensity * 5.0;
	color.rgb *= clamp(vignette, 0.0, 1.0);
	
	COLOR = color;
}