shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable, filter_linear;

uniform float density : hint_range(0.0, 1.0) = 1;
uniform vec2 speed = vec2(0.0002, 0.0001);
uniform float cloud_scale : hint_range(0.01, 5.0) = 0.1;

void fragment() {
    vec2 offset = vec2(sin(TIME * 0.1), cos(TIME * 0.1)) * 0.03;

    vec2 uv1 = UV * cloud_scale + speed * TIME + offset;
    vec2 uv2 = UV * cloud_scale * 2.7 + speed * TIME * 1.5 + offset + vec2(10.0, 20.0);

    float noise1 = texture(noise_texture, uv1).r;
    float noise2 = texture(noise_texture, uv2).r;

    // Smooth blend factor based on UV.x
	float blend_factor = 0.10 + 0.10 * sin(TIME * 0.10);

    float noise = mix(noise1, noise2, blend_factor);

    float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);

       // Fade alpha at edges to hide seam
    float edge_fade = smoothstep(0.0, 0.05, UV.x) * smoothstep(1.0, 0.95, UV.x);

    COLOR.a *= fog * density * edge_fade;
}
