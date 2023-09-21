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
const vec3 red = vec3(0.8, 0.0, 0.1);
const vec3 yellow = vec3(0.8, 0.8, 0.1);
const vec3 darkRed = vec3(0.3, 0.0, 0.2);
const vec3 dark = vec3(0.1, 0.1, 0.2);

vec3 getCoronaColor(float density) {
    if (density < 0.5f) return dark;
    else if (density < 0.4f) return mix(dark, darkRed, (density - 0.2f) * 5.f);
    else if (density < 0.6f) return darkRed;
    else if (density < 0.8f) return mix(darkRed, red, (density - 0.6f) * 5.f);
    else if (density < 1.f) return red;
    else if (density < 1.2f) return mix(red, yellow, (density - 1.f) * 5.f);
    return yellow;
}                  

void main(){
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.2;
    vec2 uv = fs_Nor.xy;
    float time = fs_Time;

    

    out_Col = vec4(getCoronaColor(fs_Density), 1.0);
    
    //float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    // Compute final shaded color
    //out_Col = vec4((diffuseColor.rgb) * lightIntensity, diffuseColor.a);
}