shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0); // White

void fragment() {
    vec4 col = texture(TEXTURE, UV);
    vec4 result = vec4(0.0);

    vec2 px = TEXTURE_PIXEL_SIZE;
    float alpha = 0.0;

    // Only apply outline if current pixel is fully transparent
    if (col.a == 0.0) {
        // Check all 8 surrounding pixels
        for (int x = -1; x <= 1; x++) {
            for (int y = -1; y <= 1; y++) {
                if (x == 0 && y == 0) continue;
                vec2 offset = vec2(float(x), float(y)) * px;
                alpha += texture(TEXTURE, UV + offset).a;
            }
        }

        if (alpha > 0.0) {
            result = outline_color;
        } else {
            discard;
        }
    } else {
        result = col;
    }

    COLOR = result;
}
