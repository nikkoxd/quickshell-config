#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float progress;
    float aspect;
    float waveAmplitude;
    float waveCount;
};

layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D dest;

void main() {
    vec2 uv = qt_TexCoord0;
    float t = smoothstep(0.0, 1.0, progress);

    vec2 p = vec2(uv.x * aspect, 1.0 - uv.y);

    vec2 dir = normalize(vec2(1.0, 1.0));
    vec2 perp = vec2(-dir.y, dir.x);

    vec2 e = dir * vec2(aspect, 1.0);
    float hi = max(e.x, 0.0) + max(e.y, 0.0);
    float lo = min(e.x, 0.0) + min(e.y, 0.0);
    float d = (dot(p, dir) - lo) / (hi - lo);

    float freq = 6.28318 * waveCount;
    d += waveAmplitude * sin(freq * dot(p, perp));

    // Remap so the rippled edge still clears both ends of the screen.
    float tt = mix(-waveAmplitude, 1.0 + waveAmplitude, t);
    float local = step(1.0 - d, tt);

    fragColor = mix(texture(source, uv), texture(dest, uv), local) * qt_Opacity;
}
