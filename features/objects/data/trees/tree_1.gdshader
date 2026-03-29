shader_type canvas_item;

uniform sampler2D mask_tex; // The viewport texture
uniform float alpha_amount = 0.5; // How transparent the foliage becomes

void fragment() {
	
	vec4 foliage_color = texture(TEXTURE, UV);

	// Get the position of this pixel in screen coordinates
	vec2 screen_pos = SCREEN_UV;

	// Sample the mask texture at this screen position
	float mask = texture(mask_tex, screen_pos).r;

	// Reduce alpha based on mask (white = 1 = fully transparent, black = 0 = no effect)
	foliage_color.a *= mix(1.0, alpha_amount, mask);

	COLOR = foliage_color;
}
