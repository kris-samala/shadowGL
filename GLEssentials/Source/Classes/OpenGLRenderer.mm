//
// OpenGLRenderer.m
//
#import "OpenGLRenderer.h"

#import "ShaderProgram.hpp"
#import "GLCheckErrors.h"
#import "VertexAttributeDefines.h"


#import <vector>

struct Vertex {
    float position[2];
    float texCoord[2];
};

// Vertex indices.
typedef unsigned short Index;


@interface OpenGLRenderer ()
// Add private methods here that are only called from this file:

- (void) onInit;
- (void) setupGL;
- (void) setupVertexBuffer;
- (void) setupVAO;
- (void) setupShaderProgram;

@end


@implementation OpenGLRenderer {
@private
// Add private member instance variables here:
    
    GLuint _viewWidth;
    GLuint _viewHeight;
    
    GLuint _vao_screenQuad;
    GLuint _vbo_screenQuad;
    GLuint _ibo_screenQuad;
    GLuint _numIndices;
    
    ShaderProgram _shaderProgram;
}


//---------------------------------------------------------------------------------------
- (id) initWithDefaultFBO: (GLuint) defaultFBOName
{
    self = [super init];
	if(self) {
        [self onInit];
	}
	
	return self;
}

//---------------------------------------------------------------------------------------
- (void) onInit
{
    
    //	filePathName = [[NSBundle mainBundle] pathForResource:@"demon" ofType:@"model"];
    [self setupGL];
    [self setupVertexBuffer];
    [self setupVAO];
    [self setupShaderProgram];
}

//---------------------------------------------------------------------------------------
- (void) setupGL
{
    NSLog(@"%s %s", glGetString(GL_RENDERER), glGetString(GL_VERSION));
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    // Always use this clear color
    glClearColor(0.5f, 0.4f, 0.5f, 1.0f);
    
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) setupVertexBuffer
{
    std::vector<Vertex> screenQuadVertices = {
        //   Positions(2d),   texture-coordinates
        Vertex{-1.0f, 1.0f,    0.0f, 0.0f},     // Top Left
        Vertex{ 1.0f, 1.0f,    1.0f, 0.0f},     // Top Right
        Vertex{-1.0f,-1.0f,    0.0f, 1.0f},     // Bottom Left
        Vertex{ 1.0f,-1.0f,    1.0f, 1.0f},     // Bottom Right
    };
    
    //-- Upload Vertex data:
    {
        glGenBuffers(1, &_vbo_screenQuad);
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_screenQuad);
        size_t numBytes = screenQuadVertices.size() * sizeof(Vertex);
        glBufferData(GL_ARRAY_BUFFER, numBytes, screenQuadVertices.data(), GL_STATIC_DRAW);
        
        CHECK_GL_ERRORS;
    }
    
    std::vector<Index> indices = {
        0,2,1, 1,2,3
    };
    _numIndices = static_cast<GLuint>(indices.size());
    
    //-- Upload Index data:
    {
        glGenBuffers(1, &_ibo_screenQuad);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ibo_screenQuad);
        size_t numBytes = _numIndices * sizeof(Index);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, numBytes, indices.data(), GL_STATIC_DRAW);
    }
    
    // Unbind
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) setupVAO
{
    glGenVertexArrays(1, &_vao_screenQuad);
    
    glBindVertexArray(_vao_screenQuad);
    
    glEnableVertexAttribArray(ATTRIBUTE_POSITION);
    glEnableVertexAttribArray(ATTRIBUTE_TEXTCOORD);
    
    
    // Associate index buffer with this vao
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ibo_screenQuad);
    
    // Map Position vertex data to shader attribute slot:
    {
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_screenQuad);
        GLint numElements = 2;
        GLsizei stride = sizeof(Vertex);
        size_t offset = 0;
        glVertexAttribPointer(ATTRIBUTE_POSITION, numElements, GL_FLOAT, GL_FALSE, stride,
                              reinterpret_cast<const GLvoid *>(offset));
        CHECK_GL_ERRORS;
    }
    
    // Map Texture-coordinate vertex data to shader attribute slot:
    {
        glBindBuffer(GL_ARRAY_BUFFER, _vbo_screenQuad);
        GLint numElements = 2;
        GLsizei stride = sizeof(Vertex);
        size_t offset = sizeof(Vertex::position)*2;
        glVertexAttribPointer(ATTRIBUTE_TEXTCOORD, numElements, GL_FLOAT, GL_FALSE, stride,
                              reinterpret_cast<const GLvoid *>(offset));
        CHECK_GL_ERRORS;
    }
    
    
    // Unbind
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) setupShaderProgram
{
    
    NSString * fileString;
    fileString = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"VertexShader.glsl"];
    const std::string vertexShaderFile = [fileString UTF8String];
    fileString = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"FragShader.glsl"];
    const std::string fragmentShaderFile =[fileString UTF8String];
    
    _shaderProgram.generateProgramObject();
    _shaderProgram.attachVertexShader(vertexShaderFile);
    _shaderProgram.attachFragmentShader(fragmentShaderFile);
    _shaderProgram.link();
    
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height
{
    glViewport(0, 0, width, height);
    
    _viewWidth = width;
    _viewHeight = height;
}

//---------------------------------------------------------------------------------------
- (void) update
{
    
}

//---------------------------------------------------------------------------------------
- (void) render
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArray(_vao_screenQuad);
    
    _shaderProgram.enable();
        glDrawElements(GL_TRIANGLES, _numIndices, GL_UNSIGNED_SHORT, nullptr);
        CHECK_GL_ERRORS;
    _shaderProgram.disable();
    
    CHECK_GL_ERRORS;
}


//---------------------------------------------------------------------------------------
- (void) dealloc
{
    // Do any cleanup here.
}

@end
