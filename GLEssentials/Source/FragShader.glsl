//
// FragShader.glsl
//
#version 410

struct VSoutFSIn {
    vec2 texCoord;
} fsIn;

out vec4 fragColor;

void main() {
    fragColor = vec4(fsIn.texCoord, 1.0, 1.0);
}
