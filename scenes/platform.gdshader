shader_type canvas_item;

uniform float desaturation : hint_range(0.0, 1.0) = 0.0;  // Full color
uniform float fog_amount : hint_range(0.0, 1.0) = 0.00;  // Very subtle fog
uniform vec3 fog_color : source_color = vec3(1.0, 0.95, 0.5); // Warm bright fog (off-white, slight cream)

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    vec3 desaturated = mix(tex_color.rgb, vec3(gray), desaturation);

    vec3 foggy = mix(desaturated, fog_color, fog_amount);

    COLOR = vec4(foggy, tex_color.a);
}
