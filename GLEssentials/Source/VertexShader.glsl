//
// VertexShader.glsl
//
#version 410

#define ATTRIBUTE_POSITION    0
#define ATTRIBUTE_TEXTCOORD   1

layout(location = ATTRIBUTE_POSITION) in vec2 position;
layout(location = ATTRIBUTE_TEXTCOORD) in vec2 texCoord;

struct VSoutFSIn {
    vec2 texCoord;
} vsOut;


void main() {
    vsOut.texCoord = texCoord;
    
    gl_Position = vec4(position, 0.0, 1.0);
}