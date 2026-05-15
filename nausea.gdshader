shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float time_offset = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// chromatic aberration
	float aberration = intensity * 0.008;
	float r = texture(TEXTURE, uv + vec2(aberration, 0.0)).r;
	float g = texture(TEXTURE, uv).g;
	float b = texture(TEXTURE, uv - vec2(aberration, 0.0)).b;
	vec4 color = vec4(r, g, b, 1.0);
	
	// desaturation
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(color.rgb, vec3(gray), intensity * 0.6);
	
	// vignette pulse
	vec2 center = uv - 0.5;
	float vignette = 1.0 - dot(center, center) * (2.0 + intensity * 3.0);
	vignette += sin(time_offset * 2.0) * intensity * 0.05;
	color.rgb *= clamp(vignette, 0.0, 1.0);
	
	COLOR = color;
}