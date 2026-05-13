shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, depth_prepass_alpha;

uniform vec4 sigil_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float pulse_speed : hint_range(0.5, 5.0) = 2.0;
uniform float pulse_min : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_max : hint_range(0.0, 5.0) = 2.5;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap;

void fragment() {
	vec4 tex = texture(texture_albedo, UV);
	float pulse = mix(pulse_min, pulse_max, (sin(TIME * pulse_speed) + 1.0) / 2.0);
	ALBEDO = sigil_color.rgb;
	EMISSION = sigil_color.rgb * pulse * tex.a;
	ALPHA = tex.a;
}