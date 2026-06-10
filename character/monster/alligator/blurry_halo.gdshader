shader_type canvas_item;

// Tunables
uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float blur_amount : hint_range(0.0, 0.05) = 0.012;
uniform float halo_extent : hint_range(1.0, 2.5) = 1.35;
uniform float intensity : hint_range(0.0, 2.0) = 1.0;

void fragment() {
	// Compress UVs so the slime occupies a smaller area, leaving margin for the halo to bloom into.
	vec2 centered = (UV - 0.5) * halo_extent + 0.5;

	float total_alpha = 0.0;
	float weight_sum = 0.0;

	// 9x9 Gaussian-ish kernel sampling the texture's alpha channel.
	for (int x = -4; x <= 4; x++) {
		for (int y = -4; y <= 4; y++) {
			vec2 offset = vec2(float(x), float(y)) * blur_amount;
			vec2 uv = centered + offset;

			float r2 = float(x * x + y * y);
			float weight = exp(-r2 / 8.0);

			if (uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0) {
				total_alpha += texture(TEXTURE, uv).a * weight;
			}
			weight_sum += weight;
		}
	}

	float halo_alpha = clamp(total_alpha / weight_sum * intensity, 0.0, 1.0);
	COLOR = vec4(tint_color.rgb, halo_alpha * tint_color.a);
}
