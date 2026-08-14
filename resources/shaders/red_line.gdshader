shader_type canvas_item;

uniform vec4 ink_color : source_color = vec4(0.55, 0.05, 0.08, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(ink_color.rgb, tex.a);
}