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
uniform int particleCount;
uniform vec4 fluidColor;

const float radius = 5.0;

float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}

float smin( float a, float b, float k )
{
    k *= 1.0/(1.0-sqrt(0.5));
    float h = max( k-abs(a-b), 0.0 )/k;
    return min(a,b) - k*0.5*(1.0+h-sqrt(1.0-h*(h-2.0)));
}

void main()
{
    // Texel color fetching from texture sampler
    vec4 texelColor = texture(texture0, fragTexCoord);

    vec2 worldCoord = vec2(fragTexCoord.x * width, fragTexCoord.y * height);

    // NOTE: Implement here your fragment shader code
    float minDist = sdCircle(worldCoord - particlePositions[0], radius);
    for (int i = 0; i < particleCount; i++) {
        minDist = smin(minDist, sdCircle(worldCoord - particlePositions[i], radius), 7.0);
    }

    finalColor = mix(fluidColor, vec4(0.0), step(0.0, minDist));
    // finalColor = mix(vec4(0.0, 0.0, 1.0, 1.0), vec4(0.0), step(0.0, minDist));
    // final color is the color from the texture 
    //    times the tint color (colDiffuse)
    //    times the fragment color (interpolated vertex color)
    // finalColor = texelColor*colDiffuse*fragColor;
}
