#version 440
layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 cursorPosition;
    float strength;
    float radius;
};
void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    vec2 delta = cursorPosition - qt_Vertex.xy;
    // Local attraction: a soft droplet tip, with the distant contour left in place.
    float influence = exp(-dot(delta, delta) / (2.0 * radius * radius));
    vec2 displacement = delta * (0.36 * influence * strength);
    gl_Position = qt_Matrix * vec4(qt_Vertex.xy + displacement, qt_Vertex.zw);
}
