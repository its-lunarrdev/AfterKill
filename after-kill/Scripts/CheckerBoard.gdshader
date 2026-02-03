shader_type spatial;

uniform vec3 color_a : source_color = vec3(0.1);
uniform vec3 color_b : source_color = vec3(0.9);
uniform float scale = 4.0;

void fragment() {
    vec2 uv = UV * scale;
    float checker = mod(floor(uv.x) + floor(uv.y), 2.0);
    ALBEDO = mix(color_a, color_b, checker);
}
