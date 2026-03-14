shader_type canvas_item;

// 0..1: distance from center where fade starts
uniform float fade_start : hint_range(0.0,1.0) = 0.7;

// 0..1: distance from center to edge where mask is fully black
uniform float fade_end : hint_range(0.0,1.0) = 1;

void fragment() {
	vec2 center = vec2(0.5, 0.5);

	// distance from center
	float dist = distance(UV, center) / 0.5;

	// compute fade
	float alpha = 1.0 - smoothstep(fade_start, fade_end, dist);

	COLOR = vec4(vec3(alpha), 1.0);
}