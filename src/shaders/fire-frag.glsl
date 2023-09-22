#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Radius;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in float fs_Time;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float noise3D(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 721.5))) *
                 43758.5453);
}

float interpNoise3D(vec3 p) {
    int intX = int(floor(p.x)), intY = int(floor(p.y)), intZ = int(floor(p.z));
    float fractX = fract(p.x), fractY = fract(p.y), fractZ = fract(p.z);

    float v1 = noise3D(vec3(intX, intY, intZ));
    float v2 = noise3D(vec3(intX + 1, intY, intZ));
    float v3 = noise3D(vec3(intX, intY + 1, intZ));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
    float v5 = noise3D(vec3(intX, intY, intZ + 1));
    float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float j1 = mix(i1, i2, fractY);
    float j2 = mix(i3, i4, fractY);

    return mix(j1, j2, fractZ);
}

float fbm(vec3 p) {
    float total = 0.0;
    float persistence = 1.f / 2.f;
    int octaves = 8;
    float freq = 16.f;
    float amp = 1.0f;
    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(p * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

void main(){
    float time = fs_Time;

    out_Col = vec4(0., 0., 0., 1.0);
}