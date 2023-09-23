#version 300 es

#define TURBULENCE_STEP 10

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform int u_Time;

uniform float u_ShapeAmp;
uniform float u_ShapeFreq;
uniform float u_FBMAmp;
uniform float u_FBMFreq;
uniform int u_FBMOneOverPersistence;
uniform int u_FBMOctaves;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.

out vec4 fs_Pos;
out float fs_Time;
out float fs_Density;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

vec3 random3(vec3 p) {
    return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 489.1)),
                          dot(p, vec3(269.5, 183.3, 892.5)),
                          dot(p, vec3(420.6, 631.2, 458.8))
                    )) * 43758.5453);
}

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


// a higher-frequency, lower-amplitude layer of fractal Brownian motion to apply a finer level of distortion.
// ref: https://www.shadertoy.com/view/3lcfWN
float fbm_displacement(vec3 p) {
    float total = 0.0;
    float persistence = 1.f / float(u_FBMOneOverPersistence);
    int octaves = u_FBMOctaves;
    float freq = u_FBMFreq;
    float amp = u_FBMAmp;
    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(p * freq) * amp;

        freq *= 2.f;
        amp *= persistence;
    }
    return total;
}

float surflet(vec3 p, vec3 gridPoint) {
    // Compute the distance between p and the grid point along each axis, and warp it with a
    // quintic function so we can smooth our cells
    vec3 t2 = abs(p - gridPoint);
    vec3 t = vec3(1.f) - 6.f * pow(t2, vec3(5.f)) + 15.f * pow(t2, vec3(4.f)) - 10.f * pow(t2, vec3(3.f));
    // Get the random vector for the grid point (assume we wrote a function random2
    // that returns a vec2 in the range [0, 1])
    vec3 gradient = random3(gridPoint) * 2. - vec3(1., 1., 1.);
    // Get the vector from the grid point to P
    vec3 diff = p - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * t.x * t.y * t.z;
}


float perlinNoise(vec3 p) {
	float surfletSum = 0.f;
	// Iterate over the four integer corners surrounding uv
	for(int dx = 0; dx <= 1; ++dx) {
		for(int dy = 0; dy <= 1; ++dy) {
			for (int dz = 0; dz <= 1; ++dz) {
                surfletSum += surflet(p, floor(p) + vec3(dx, dy, dz));
            }
		}
	}
	return surfletSum;
}

// a low-frequency, high-amplitude displacement of your sphere so as to make it less uniformly sphere-like
// turbulence from formula sum(abs(1 / 2^i * noise(2^i * x))
// ref: https://www.clicktorelease.com/blog/vertex-displacement-noise-3d-webgl-glsl-three-js/
// ref: https://www.shadertoy.com/view/MtXSzS
float turbulence(vec3 p) {
  float value = 0.0;
  float step = u_ShapeFreq;
  float amplitude = u_ShapeAmp;

  for (int f = 1 ; f <= TURBULENCE_STEP; f++ ){
    value += abs(perlinNoise(vec3(step * p)) / step);
    step *= 2.0;
  }

  return value * amplitude;
}

void main()
{
    fs_Col = vs_Col;                         // Pass the vertex colors to the fragment shader for interpolation

    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    float time = float(u_Time) * 0.01;
    fs_Time = time;
    fs_Pos = vs_Pos;

    // combining fbm noise and turblence perlin noise (distortion) to form shape
    vec4 modelposition = u_Model * vs_Pos;   // Temporarily store the transformed vertex positions for use below

    // basic turbulence shape, determine color
    vec4 normal_noise = vec4(0.0f);

    float normal_offset = 0.0;
    float turbulence_noise = turbulence(vec3(vs_Pos) + vec3(0.2f * time));

    normal_offset += turbulence_noise;

    // Use fbm to produce smoke/fire surrounding
    // Domain Warping FBM, ref: https://thebookofshaders.com/13/

    vec3 q = vec3(fbm_displacement(vec3(vs_Pos) - 0.001 * time), 
                  fbm_displacement(vec3(vs_Pos) + vec3 (0.05, -0.03, 0.02)),
                  fbm_displacement(vec3(vs_Pos) + 0.05 * cos(0.005 * time)));

    vec3 r = vec3(fbm_displacement(vec3(vs_Pos) + q + vec3(0.3, 0.2, -0.4) + 0.15 * time), 
                  fbm_displacement(vec3(vs_Pos) + q + vec3(-2.3, 8.2, -5.4) + 0.126 * time), 
                  fbm_displacement(vec3(vs_Pos) + q + vec3(-3.3, -4.6, 6.7) - 0.24 * time));

    float fbm_noise = fbm_displacement(vec3(vs_Nor) + r);
    normal_offset += fbm_noise;

    vec3 flame_dir = vec3(0., 1., 0.);
    float prod = dot(flame_dir, vec3(fs_Nor));
    if (prod > 0.0) {
        //modelposition += vec4(flame_dir * prod, 0.0) * fbm_noise * 6.0;
    }


    modelposition += normal_offset * fs_Nor;

    fs_Density = turbulence(vec3(vs_Pos) + vec3(0.2f * time)) + length(vec3(vs_Pos)); // offset + length

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
