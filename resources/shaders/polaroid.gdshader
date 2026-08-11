shader_type canvas_item;

// Progression and Texture Inputs
uniform float development_progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;

// Chemical Customization
uniform vec3 unexposed_color : source_color = vec3(0.18, 0.15, 0.12); // Muddy chemical tint
uniform float chemical_edge_width : hint_range(0.01, 0.1) = 0.04;

void fragment() {
    // 1. Sample original UI texture (the solid polaroid film backing) and noise
    vec4 base_color = texture(TEXTURE, UV);
    float noise = texture(noise_tex, UV + vec2(TIME * 0.02)).r; // Slight noise drift

    // 2. Generate organic, uneven reveal mask based on development progress
    // Value maps from 0.0 (fully covered in chemical) to 1.0 (chemically dissolved/clear)
    float mask = smoothstep(noise - 0.1, noise + 0.1, development_progress * 1.2 - 0.1);

    // 3. Simulate the active chemical reaction line (dark burning edge)
    float edge_factor = smoothstep(0.0, chemical_edge_width, mask) * (1.0 - smoothstep(chemical_edge_width, chemical_edge_width * 2.0, mask));
    edge_factor *= (1.0 - development_progress); // Fade edge effect out when fully transparent
    
    // 4. Calculate Final Alpha: dissolve the base texture using the mask
    // When mask is 1.0, alpha becomes 0.0 (fully transparent)
    float final_alpha = base_color.a * (1.0 - mask);

    // 5. Mix states: Unexposed Chemical -> Dark Chemical Bleed
    // The underlying color darkens right before disappearing
    vec3 final_rgb = mix(unexposed_color, vec3(0.0), edge_factor * 0.8);

    COLOR = vec4(final_rgb, final_alpha);
}