shader_type canvas_item;

uniform sampler2D occlusion_mask;
uniform float fade_strength = 1.0;

void fragment() 
{
	// Get pixel position in screen coordinates
	vec2 screen_uv = FRAGCOORD.xy / vec2(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);

	// Sample mask texture
	vec4 mask_sample = texture(occlusion_mask, screen_uv);

	// Sample sprite texture
	vec4 tex = texture(TEXTURE, UV);

	// Multiply alpha by mask
	tex.a *= 1.0 - mask_sample.r * fade_strength;

	COLOR = tex;
}