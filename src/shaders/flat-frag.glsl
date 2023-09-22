#version 300 es
precision highp float;

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform int u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

float noise2D(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) *
                 43758.5453);
}

float interpNoise2D(vec2 p) {
    int intX = int(floor(p.x)), intY = int(floor(p.y));
    float fractX = fract(p.x), fractY = fract(p.y);

    float v1 = noise2D(vec2(intX, intY));
    float v2 = noise2D(vec2(intX + 1, intY));
    float v3 = noise2D(vec2(intX, intY + 1));
    float v4 = noise2D(vec2(intX + 1, intY + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

    float j1 = mix(i1, i2, fractY);

    return j1;
}

float fbm(vec2 p) {
    float total = 0.0;
    float persistence = 1.f / 2.f;
    int octaves = 8;
    float freq = 16.f;
    float amp = 1.0f;
    for(int i = 1; i <= octaves; i++) {
        total += interpNoise2D(p * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

float star_noise(vec2 coord) {
    float starThreshold = 0.95;
    float n = fract(415.92653 * (0.7 * cos(37.3 * coord.x) + 1.2 * cos(56.1 * coord.y)));
    return n >= starThreshold ? pow((n - starThreshold) / (1.0 - starThreshold), 10.0) : 0.0;
}

vec3 getStarColor(vec2 uv) {
    // use int for noise to stablize star field
    vec2 coordFloor = floor(uv * 973.0);
    float starVal = star_noise(coordFloor);

    return vec3(starVal);
}

const vec3 darkblue = vec3(0.1, 0.0, 0.35);
const vec3 darkviolet = vec3(0.5, 0.1, 0.9);

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_Dimensions.xy) / u_Dimensions.y;
  out_Col += vec4(getStarColor(uv), 0.0);
  uv *= 2.34;

  float time = float(u_Time) * 0.1;
  vec2 q = vec2(fbm(uv - 0.001 * cos(time)), 
                fbm(uv + vec2(0.05, -0.03)));

  vec2 r = vec2(fbm(uv + q + vec2(0.3, 0.2) + 0.15 * sin(time)), 
                fbm(uv + q + vec2(-2.3, 8.2) + 0.126 * sin(time)));

  float fbm_noise = fbm(uv + r);

  float offset = 0.1 * fbm_noise;

  uv -= offset * normalize(uv);

  vec3 light_color = vec3(1.0, 0.9, 0.5) * 0.8;
  float light = 0.1 / distance(normalize(uv), uv);

  out_Col += vec4(light * light_color + mix(darkviolet, darkblue, smoothstep(0.0, 1.0, gl_FragCoord.y / u_Dimensions.y)), 1.0);
}
