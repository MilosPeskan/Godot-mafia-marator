shader_type canvas_item;

uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform bool reveal_from_left = true;
uniform bool invert_reveal = false;

uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float noise_influence : hint_range(0.0, 0.5) = 0.15;

// Ovaj parametar kontroliše pomeranje šuma spolja
uniform vec2 noise_offset = vec2(0.0);

void fragment()
{
	float current_x = UV.x;
	if (!reveal_from_left) {
		current_x = 1.0 - UV.x;
	}

	// Koristimo noise_offset umesto TIME
	float noise = texture(noise_tex, UV + noise_offset).r;
	
	float distorted_x = current_x + (noise - 0.5) * noise_influence;

	if (!invert_reveal) {
		if (distorted_x > reveal) {
			discard;
		}
	} else {
		if (distorted_x < reveal) {
			discard;
		}
	}

	COLOR = texture(TEXTURE, UV);
}
