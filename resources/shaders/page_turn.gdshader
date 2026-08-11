shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D back_texture : source_color;   // back strana lista = NOVI sadržaj strane na koju list sleže
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform int direction : hint_range(-1, 1) = 1;   // 1 = napred (desni list ide ulevo), -1 = nazad (levi list ide udesno)

uniform vec4 shadow_color : source_color = vec4(0.176, 0.129, 0.09, 0.55);   // blizu Ink #2B2117, malo transparentnije
uniform vec4 highlight_color : source_color = vec4(0.639, 0.514, 0.294, 0.35); // Gold Accent #A3834B, umesto bele
uniform float spine_shadow_width : hint_range(0.0, 0.3) = 0.12;

void fragment() {
    float hinge = 0.5;
    float signed_offset = UV.x - hinge;
    float abs_offset = abs(signed_offset);

    // near_side = strana SA KOJE list kreće (front strana vidljiva tu na početku)
    bool near_side = (direction == 1) ? (signed_offset > 0.0) : (signed_offset < 0.0);

    float angle = progress * PI;
    float scale = abs(cos(angle));           // 1 -> 0 -> 1 tokom celog okretanja
    bool second_half = progress >= 0.5;

    float visible_extent = scale * 0.5;
    bool covered = abs_offset <= visible_extent + 0.0001;

    if (!second_half) {
        // FAZA 1: front strana, skuplja se ka hrbatu na svojoj polaznoj strani.
        if (near_side && covered) {
            float s = abs_offset / max(visible_extent, 0.0001);
            float front_u = (direction == 1) ? s : 1.0 - s;
            vec4 col = texture(TEXTURE, vec2(front_u, UV.y));

            float spine_dark = (1.0 - smoothstep(0.0, spine_shadow_width, abs_offset)) * 0.25;
            col.rgb = mix(col.rgb, vec3(0.235, 0.180, 0.129), spine_dark);
            col.rgb = mix(col.rgb, shadow_color.rgb, (1.0 - scale) * shadow_color.a * 0.6);

            COLOR = col;
        } else {
            discard; // otkriva ono što je VEĆ ispod: stara suprotna strana, ili novi sadržaj na strani sa koje list odlazi
        }
    } else {
        // FAZA 2: back strana, širi se od hrbata na SUPROTNOJ (sletnoj) strani.
        bool landing_side = !near_side;
        if (landing_side && covered) {
            float s = abs_offset / max(visible_extent, 0.0001);
            float back_u = (direction == 1) ? (1.0 - s) : s;
            vec4 col = texture(back_texture, vec2(back_u, UV.y));

            float spine_dark = (1.0 - smoothstep(0.0, spine_shadow_width, abs_offset)) * 0.25;
            col.rgb = mix(col.rgb, vec3(0.235, 0.180, 0.129), spine_dark);
            col.rgb = mix(col.rgb, shadow_color.rgb, (1.0 - scale) * shadow_color.a * 0.6);

            float highlight = smoothstep(0.5, 0.65, progress) * (1.0 - smoothstep(0.65, 0.9, progress)) * highlight_color.a;
            col.rgb = mix(col.rgb, highlight_color.rgb, highlight);

            COLOR = col;
        } else {
            discard; // van pokrivenog dela: ili polazna strana (već otkrivena kao nova), ili sletna strana koja JOŠ nije prekrivena (stari sadržaj)
        }
    }
}