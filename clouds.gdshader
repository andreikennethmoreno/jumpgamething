shader_type canvas_item;

// Optional: uncomment if you don’t want lighting applied
// render_mode unshaded;

uniform sampler2D noise_texture : repeat_enable, filter_nearest;
uniform float density : hint_range(0.0, 1.0) = 0.25;
uniform vec2 speed = vec2(0.00, 0.01); // Only moves vertically (adjust if needed)
uniform float cloud_scale : hint_range(0.01, 10.0) = 5.0;

void fragment() {
	// Animate the UV to move the clouds
	vec2 uv = UV * cloud_scale + speed * TIME;

	// Sample the noise texture
	float noise = texture(noise_texture, uv).r;

	// Transform and clamp
	float fog = clamp(noise * 2.0 - 1.0, 0.0, 1.0);

	// Multiply effect: darken based on fog
	COLOR.rgb *= mix(vec3(1.0), vec3(fog), density);

	// Optional: modify transparency as well
	COLOR.a *= fog * density;
}
