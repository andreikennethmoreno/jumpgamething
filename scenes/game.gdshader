shader_type canvas_item;

uniform float line_thickness : hint_range(0, 10) = 0.5;
uniform vec4 border_color : source_color = vec4(0, 0, 0, 1); // black

const int DILATION_RADIUS = 1;
const int EXTRA_VERTICAL = 1;

void fragment() {
	vec2 base_size = TEXTURE_PIXEL_SIZE * line_thickness;
	vec2 size = base_size * 1.5;

	vec4 color = texture(TEXTURE, UV);
	bool is_transparent = (color.a == 0.0);

	bool near_transparent = false;

	// Detect if this pixel is on the edge
	if (!is_transparent) {
		for (int y = -2; y <= 2; y++) {
			for (int x = -2; x <= 2; x++) {
				if (x == 0 && y == 0) continue;
				vec2 offset = vec2(float(x), float(y));
				vec2 sample_uv = clamp(UV + size * offset, vec2(0.0), vec2(1.0));
				if (texture(TEXTURE, sample_uv).a == 0.0) {
					near_transparent = true;
				}
			}
		}
	}

	bool is_edge = !is_transparent && near_transparent;
	bool expanded_edge = is_edge;

	// Strong vertical expansion first
	if (!is_edge) {
		for (int y = -DILATION_RADIUS - EXTRA_VERTICAL; y <= DILATION_RADIUS + EXTRA_VERTICAL; y++) {
			if (y == 0) continue;
			vec2 offset = vec2(0.0, float(y));
			vec2 sample_uv = clamp(UV + size * offset, vec2(0.0), vec2(1.0));
			vec4 sample_color = texture(TEXTURE, sample_uv);

			if (sample_color.a > 0.0) {
				// Check if it's a border pixel
				bool sample_near_transparent = false;
				for (int ny = -2; ny <= 2; ny++) {
					for (int nx = -2; nx <= 2; nx++) {
						if (nx == 0 && ny == 0) continue;
						vec2 n_offset = vec2(float(nx), float(ny));
						vec2 neighbor_uv = clamp(sample_uv + size * n_offset, vec2(0.0), vec2(1.0));
						if (texture(TEXTURE, neighbor_uv).a == 0.0) {
							sample_near_transparent = true;
						}
					}
				}
				if (sample_near_transparent) {
					expanded_edge = true;
					break;
				}
			}
		}
	}

	// Normal radial expansion to support connectivity
	if (!expanded_edge) {
		for (int y = -DILATION_RADIUS; y <= DILATION_RADIUS; y++) {
			for (int x = -DILATION_RADIUS; x <= DILATION_RADIUS; x++) {
				vec2 offset = vec2(float(x), float(y));
				vec2 sample_uv = clamp(UV + size * offset, vec2(0.0), vec2(1.0));
				vec4 sample_color = texture(TEXTURE, sample_uv);

				if (sample_color.a > 0.0) {
					bool sample_near_transparent = false;
					for (int ny = -1; ny <= 1; ny++) {
						for (int nx = -1; nx <= 1; nx++) {
							if (nx == 0 && ny == 0) continue;
							vec2 n_offset = vec2(float(nx), float(ny));
							vec2 neighbor_uv = clamp(sample_uv + size * n_offset, vec2(0.0), vec2(1.0));
							if (texture(TEXTURE, neighbor_uv).a == 0.0) {
								sample_near_transparent = true;
							}
						}
					}
					if (sample_near_transparent) {
						expanded_edge = true;
						break;
					}
				}
			}
			if (expanded_edge) break;
		}
	}

	if (is_transparent) {
		COLOR = color;
	} else if (expanded_edge) {
		COLOR = border_color;
	} else {
		COLOR = color;
	}
}
