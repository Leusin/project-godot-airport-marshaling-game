shader_type spatial;

render_mode unshaded, cull_disabled;

uniform float radius = 10.0;
uniform float half_angle = 35.0;
uniform vec4 vision_color : source_color = vec4(1,0,0,0.5);


void fragment() {
    vec2 p = (UV - vec2(0.5)) * radius * 2.0;
	
	float dist = length(p);
    float angle = degrees(atan(p.x, p.y));
	
    if (length(p) > radius)
        discard;
	
	if (abs(angle) > half_angle)
        discard;
		
    ALBEDO = vision_color.rgb;
    ALPHA = vision_color.a;
}