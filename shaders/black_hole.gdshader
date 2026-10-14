shader_type canvas_item;
render_mode unshaded;
uniform sampler2D galaxy : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 eye = vec3(0.0, 2.5, 18.0);
uniform mat3 camera_basis;
uniform vec2 resolution = vec2(1280.0, 720.0);
uniform float tan_half_fov = 0.4452;
uniform float simulation_time = 0.0;
uniform float exposure = 1.15;
uniform float lens_strength = 0.8;
uniform int step_limit = 200;
const float RS = 1.0;
const float DISK_IN = 3.0;
const float DISK_OUT = 9.0;

vec3 acceleration(vec3 p, float angular_momentum_sq) {
    float rr = max(dot(p,p), 0.6);
    return -1.5 * RS * angular_momentum_sq * p / (rr * rr * sqrt(rr)) * lens_strength;
}
float turbulence(vec2 p) {
    return sin(p.x * 4.0 + sin(p.y * 2.0)) * 0.30
         + sin(p.x * 11.0 - p.y * 9.0) * 0.16
         + sin(p.x * 27.0 + p.y * 21.0) * 0.08;
}
vec3 disk_emission(vec3 hit, vec3 velocity) {
    float radius = length(hit.xz);
    float azimuth = atan(hit.z, hit.x);
    float orbital_rate = 0.45 * pow(3.0 / radius, 1.5);
    float flow = azimuth - simulation_time * orbital_rate;
    float bands = 0.80 + turbulence(vec2(radius * 1.5, flow * 4.0));
    float edge = smoothstep(DISK_IN, DISK_IN + 0.18, radius) * (1.0 - smoothstep(7.4, DISK_OUT, radius));
    float flux = pow(DISK_IN / radius, 3.0) * (1.0 - sqrt(DISK_IN / radius));
    vec3 tangent = normalize(vec3(-hit.z, 0.0, hit.x));
    float beta = sqrt(0.5 / max(radius - 1.0, 1.0));
    float doppler = sqrt(1.0 - beta * beta) / max(1.0 - beta * dot(tangent, -normalize(velocity)), 0.35);
    float shift = doppler * sqrt(1.0 - RS / radius);
    float warmth = clamp((radius - 3.0) / 6.0, 0.0, 1.0);
    vec3 temperature = mix(vec3(1.0, 0.89, 0.65), vec3(1.0, 0.22, 0.045), warmth);
    temperature = mix(temperature, vec3(0.72, 0.86, 1.0), clamp((shift-1.0)*0.65,0.0,0.32));
    return temperature * flux * 52.0 * bands * edge * pow(shift, 3.0);
}
vec3 sky_color(vec3 direction) {
    // Tilt the equirectangular Milky Way for a clear diagonal galactic band.
    float c = cos(0.43); float s = sin(0.43);
    direction.xy = mat2(vec2(c,s),vec2(-s,c)) * direction.xy;
    vec2 uv = vec2(atan(direction.z,direction.x) / TAU + 0.5, acos(clamp(direction.y,-1.0,1.0)) / PI);
    uv.x += 0.18;
    return pow(textureLod(galaxy, uv, 1.8).rgb, vec3(2.2)) * 1.6;
}
void fragment() {
    vec2 ndc = UV * 2.0 - 1.0;
    vec3 velocity = normalize(camera_basis * vec3(ndc.x * resolution.x / resolution.y * tan_half_fov, -ndc.y * tan_half_fov, -1.0));
    vec3 p = eye;
    vec3 angular_momentum = cross(p, velocity);
    float h2 = dot(angular_momentum, angular_momentum);
    vec3 radiance = vec3(0.0);
    bool terminated = false;
    float escape_distance = max(length(eye) * 1.5, 32.0);
    // Central-force null-orbit approximation; Verlet integration conserves
    // the orbital plane. Every pixel follows its own curved ray.
    for (int i=0; i<260; i++) {
        if (i >= step_limit) break;
        float r = length(p);
        if (r < RS * 1.002) { terminated = true; break; }
        float dt = clamp(r * 0.065, 0.028, 1.8);
        vec3 previous = p;
        vec3 half_velocity = velocity + acceleration(p,h2) * (0.5 * dt);
        p += half_velocity * dt;
        velocity = half_velocity + acceleration(p,h2) * (0.5 * dt);
        if (previous.y * p.y <= 0.0 && abs(previous.y-p.y) > 0.00001) {
            float crossing = previous.y / (previous.y-p.y);
            vec3 hit = mix(previous, p, crossing);
            float disk_radius = length(hit.xz);
            if (disk_radius >= DISK_IN && disk_radius <= DISK_OUT) {
                radiance = disk_emission(hit, velocity);
                terminated = true;
                break;
            }
        }
        if (length(p) > escape_distance && dot(p,velocity) > 0.0) {
            radiance = sky_color(normalize(velocity));
            terminated = true;
            break;
        }
    }
    if (!terminated && length(p) > 3.0) radiance = sky_color(normalize(velocity));
    vec3 mapped = vec3(1.0) - exp(-radiance * exposure);
    COLOR = vec4(pow(max(mapped,vec3(0.0)),vec3(1.0/2.2)),1.0);
}