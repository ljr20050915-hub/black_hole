shader_type canvas_item;
render_mode unshaded;
uniform vec2 render_size = vec2(1280.0,720.0);
uniform float bloom_strength = 0.28;
uniform sampler2D rendered_frame : filter_linear;
vec3 bright(vec2 uv) {
    vec3 col=texture(rendered_frame,uv).rgb;
    float amount=smoothstep(0.62,0.98,max(col.r,max(col.g,col.b)));
    return col*amount;
}
void fragment() {
    vec3 color=texture(TEXTURE,UV).rgb;
    vec3 glow=vec3(0.0);
    vec2 pixel=1.0/render_size;
    for(int i=1;i<=4;i++) {
        float distance=float(i*i)*1.5;
        float weight=1.0/(float(i)*2.0);
        glow+=bright(UV+vec2(distance,0.0)*pixel)*weight;
        glow+=bright(UV-vec2(distance,0.0)*pixel)*weight;
        glow+=bright(UV+vec2(0.0,distance)*pixel)*weight;
        glow+=bright(UV-vec2(0.0,distance)*pixel)*weight;
    }
    float vignette=1.0-0.14*pow(length((UV-0.5)*vec2(1.0,0.8)),2.0);
    COLOR=vec4((color+glow*bloom_strength*0.24)*vignette,1.0);
}