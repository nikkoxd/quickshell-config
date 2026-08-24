#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D dest;

void main() {
    vec2 uv = qt_TexCoord0;
    float t = smoothstep(0.0, 1.0, progress);

    vec2 p = vec2(uv.x * aspect, 1.0 - uv.y);

    vec2 dir = normalize(vec2(1.0, 1.0));
    float dmax = dot(vec2(aspect, 1.0), dir);  // far corner's projection
    float d = 1.0 - dot(p, dir) / dmax;        // 0 at start corner, 1 at the opposite one

    float local = step(d, t);
    fragColor = mix(texture(source, uv), texture(dest, uv), local) * qt_Opacity;
}
