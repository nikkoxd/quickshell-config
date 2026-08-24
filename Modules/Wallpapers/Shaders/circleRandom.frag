#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    float seed;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D dest;

vec2 hash2(float n) {
    return fract(sin(vec2(n, n + 1.0) * vec2(127.1, 311.7)) * 43758.5453);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float t = smoothstep(0.0, 1.0, progress);

    // Work in aspect-corrected units so the wipe stays circular.
    vec2 scale = vec2(aspect, 1.0);
    vec2 p = uv * scale;
    vec2 c = (0.15 + 0.7 * hash2(seed)) * scale;        // centre
    float maxD = length(max(c, scale - c));             // distance to furthest corner
    float d = length(p - c) / maxD;

    float local = step(d, t);
    fragColor = mix(texture(source, uv), texture(dest, uv), local) * qt_Opacity;
}
