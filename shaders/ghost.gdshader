shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec3 tint = vec3(0.35, 0.85, 1.0);

void fragment() {
	ALBEDO = tint;
	float slow = sin(TIME * 4.0);
	float flicker = sin(TIME * 11.0 + FRAGCOORD.y * 0.05);
	ALPHA = 0.30 + 0.12 * slow + 0.06 * flicker;
}
