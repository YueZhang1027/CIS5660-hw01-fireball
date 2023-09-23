#version 300 es

precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Radius;

uniform float u_ColorOffset;
uniform float u_BloomThres;
uniform float u_BloomIntensity;

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
// reg: https://www.schemecolor.com/sun-colors.php
const vec3[6] colorPallete = vec3[] (
    vec3(1.0, 1.0, 0.8),
    vec3(1.0, 0.9, 0.5),
    vec3(1.0, 0.8, 0.2),
    vec3(1.0, 0.6, 0.0),
    vec3(0.8, 0.25, 0.0),
    vec3(0.5, 0.0, 0.0)
);

const float[7] thresholds = float[] (
    0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8
);

vec3 getCoronaColor(float density) {
    density += 0.05 * u_ColorOffset;
    float interpolateVal = smoothstep(0.92, 1.26, density);

    if (interpolateVal < thresholds[0]) {
        return colorPallete[0];
    }

    for (int i = 1; i <= 5; ++i) {
        if (interpolateVal < thresholds[i]) {
            return mix(colorPallete[i - 1], colorPallete[i], smoothstep(thresholds[i - 1], thresholds[i], interpolateVal));
        }
    }

    return colorPallete[5];
}


void main(){
    float time = fs_Time;

    vec3 base = getCoronaColor(fs_Density);

    // bloom filter for emission core
    vec3 grayScale = vec3(0.2126, 0.7152, 0.0722);
    float result = 1.0 + (dot(base, grayScale) > u_BloomThres ? u_BloomIntensity : 0.0);

    out_Col = vec4(base * result, 1.0);
}