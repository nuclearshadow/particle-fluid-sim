#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
out vec4 finalColor;

// NOTE: Add your custom variables here
uniform float width;
uniform float height;
uniform vec2[1000] particlePositions;
uniform float[1000] particleSpeeds;
uniform int particleCount;
uniform vec4 fluidColor;

const float radius = 5.0;

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

// cubic polynomial
vec2 smin( float a, float b, float k )
{
    float h = 1.0 - min( abs(a-b)/(6.0*k), 1.0 );
    float w = h*h*h;
    float m = w*0.5;
    float s = w*k; 
    return (a<b) ? vec2(a-s,m) : vec2(b-s,1.0-m);
}

void main()
{
    // Texel color fetching from texture sampler
    vec4 texelColor = texture(texture0, fragTexCoord);

    vec2 worldCoord = vec2(fragTexCoord.x * width, fragTexCoord.y * height);

    // NOTE: Implement here your fragment shader code
    float minDist = sdCircle(worldCoord - particlePositions[0], radius);
    float speed = particleSpeeds[0];
    for (int i = 0; i < particleCount; i++) {
        vec2 res = smin(minDist, sdCircle(worldCoord - particlePositions[i], radius), 7.0);
        minDist = res.x;
        speed = mix(speed, particleSpeeds[i], res.y);
    }

    const float speedScale = 0.003;
    const float edgeBlurRadius = 3.0;
    finalColor = mix(mix(fluidColor, vec4(1.0), speed * speedScale), vec4(0.0), smoothstep(-edgeBlurRadius, edgeBlurRadius, minDist));
    // finalColor = mix(vec4(vec3(speed * 0.01), 1.0), vec4(0.0), step(0.0, minDist));
    // finalColor = mix(vec4(0.0, 0.0, 1.0, 1.0), vec4(0.0), step(0.0, minDist));
    // final color is the color from the texture 
    //    times the tint color (colDiffuse)
    //    times the fragment color (interpolated vertex color)
    // finalColor = texelColor*colDiffuse*fragColor;
}
