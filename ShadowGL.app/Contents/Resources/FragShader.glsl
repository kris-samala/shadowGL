//
// FragShader.glsl
//
#version 410

in VSoutFSIn {
    vec2 texCoord;
} fsIn;

out vec4 fragColor;
uniform sampler2D tex;

void main() {
//    fragColor = vec4(fsIn.texCoord, 1.0, 1.0);

    fragColor = texture(tex, fsIn.texCoord);
}
