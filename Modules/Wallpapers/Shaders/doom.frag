#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float sectionWidth;
    float maxOffset;
    float seed;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D dest;

float hash(float x) {
    return fract(sin(x * 12.9898) * 43758.5453123);
}

void main() {
    vec2 uv = qt_TexCoord0;

    float s = floor(uv.x / sectionWidth);
    float o = hash(s * 1.37 + seed) * maxOffset;
    float d = clamp(progress * progress * (1.0 + maxOffset) - o, 0.0, 1.0);

    float srcY = uv.y - d;

    vec4 c = srcY <= 0.0 ? texture(dest, uv)
                         : texture(source, vec2(uv.x, srcY));
    fragColor = c * qt_Opacity;
}
