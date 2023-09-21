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
in float fs_Density;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


// ref: https://www.shadertoy.com/view/3lcfWN

const vec3 darkRed = vec3(0.3, 0.0, 0.2);
const vec3 red = vec3(0.8, 0.0, 0.1);
const vec3 darkOrange = vec3(0.95, 0.4, 0.2);
const vec3 orange = vec3(1.0, 0.6, 0.2);
const vec3 darkYellow = vec3(1.0, 0.9, 0.3);
const vec3 yellow = vec3(1.0, 1.0, 0.5);

vec3 getCoronaColor(float density) {
    float interpolateVal = smoothstep(0.8, 1.3, fs_Density);

    if (interpolateVal < 0.4f) {
        return yellow;
    } else if (interpolateVal < 0.5f) {
        return mix(yellow, darkYellow, smoothstep(0.4f, 0.5f, interpolateVal));
    } else if (interpolateVal < 0.6f) {
        return mix(darkYellow, orange, smoothstep(0.5f, 0.6f, interpolateVal));
    } else if (interpolateVal < 0.7f) {
        return mix(orange, darkOrange, smoothstep(0.6f, 0.7f, interpolateVal));
    } else if (interpolateVal < 0.8f) {
        return mix(darkOrange, red, smoothstep(0.7f, 0.8f, interpolateVal));
    } else if (interpolateVal < 0.9f) {
        return mix(red, darkRed, smoothstep(0.8f, 0.9f, interpolateVal));
    }
    return darkRed;
}

float noise3D(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 721.5))) *
                 43758.5453);
}



// float interpNoise3D(vec3 p) {
//     int intX = int(floor(p.x)), intY = int(floor(p.y)), intZ = int(floor(p.z));
//     float fractX = fract(p.x), fractY = fract(p.y), fractZ = fract(p.z);

//     float v1 = noise3D(vec3(intX, intY, intZ));
//     float v2 = noise3D(vec3(intX + 1, intY, intZ));
//     float v3 = noise3D(vec3(intX, intY + 1, intZ));
//     float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
//     float v5 = noise3D(vec3(intX, intY, intZ + 1));
//     float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
//     float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
//     float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

//     float i1 = mix(v1, v2, fractX);
//     float i2 = mix(v3, v4, fractX);
//     float i3 = mix(v5, v6, fractX);
//     float i4 = mix(v7, v8, fractX);

//     float j1 = mix(i1, i2, fractY);
//     float j2 = mix(i3, i4, fractY);

//     return mix(j1, j2, fractZ);
// }

// float fbm(vec3 p) {
//     float total = 0.0;
//     float persistence = 1.f / 2.f;
//     int octaves = 8;
//     float freq = 16.f;
//     float amp = 1.0f;
//     for(int i = 1; i <= octaves; i++) {
//         total += interpNoise3D(p * freq) * amp;

//         freq *= 2.f;
//         amp *= persistence;
//     }
//     return total;
// }

// vec4 interpCoronaColor(float density) {
//     vec4 brighterColor = vec4(0.8, 0.8, 0.1, 0.25);
//     vec4 darkerColor = vec4(1.0, 0.0, 0.15, 0.625);
//     vec4 middleColor = mix(brighterColor, darkerColor, 0.5);

//     float noiseTexel = fbm(vec3(fs_Pos));
//     float interpVal = smoothstep(1.02, 1.18, density);

//     float firstStep = smoothstep(0.0, noiseTexel, interpVal);
//     float darkerColorStep = smoothstep(0.0, noiseTexel, interpVal - 0.2f);
//     float darkerColorPath = firstStep - darkerColorStep;
//     vec4 color = mix(brighterColor, darkerColor, darkerColorPath);

//     float middleColorStep = smoothstep(0.0, noiseTexel, interpVal - 0.2 * 2.0);
    
//     color = mix(color, middleColor, darkerColorStep - middleColorStep);
//     color = mix(vec4(0.0), color, firstStep);

//     return middleColor;
// }

void main(){
    float time = fs_Time;

    vec3 base = getCoronaColor(fs_Density);

    // bloom filter for emission core
    vec3 grayScale = vec3(0.2126, 0.7152, 0.0722);
    float result = 1.0 + (dot(base, grayScale) > 0.9 ? 1.2 : 0.0);

    out_Col = vec4(base * result, 1.0);
}