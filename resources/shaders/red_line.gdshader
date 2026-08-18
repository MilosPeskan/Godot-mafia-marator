shader_type canvas_item;

uniform vec4 ink_color : source_color = vec4(0.55, 0.05, 0.08, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    vec3 final_color = mix(tex.rgb, ink_color.rgb, opacity);

    COLOR = vec4(final_color, tex.a);
}