shader_type canvas_item;

uniform vec2 light_pos;
uniform float radius = 300.0;
uniform float softness = 200.0;

void fragment() {
    vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
    vec2 pixel_pos = SCREEN_UV * screen_size;

    float dist = distance(pixel_pos, light_pos);

    float alpha = smoothstep(radius, radius + softness, dist) * 0.8;

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}