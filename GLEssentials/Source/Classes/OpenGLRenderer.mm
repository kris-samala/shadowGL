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
- (void) setupTexture;

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
    
    GLuint _texture;
    
    GLubyte * _pixels;
    int _imageWidth;
    int _imageHeight;
    
    SRWebSocket * _webSocket;
    NSMutableArray * _frame;
    
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
    
    [self setupGL];
    [self setupVertexBuffer];
    [self setupVAO];
    [self setupShaderProgram];
    [self setupTexture];
    
    _imageWidth = 640;
    _imageHeight = 480;
    _pixels = new unsigned char[_imageHeight * _imageWidth * 3];
    [self connectWebSocket];
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
        Vertex{-1.0f, 1.0f,    0.0f, 1.0f},     // Top Left
        Vertex{ 1.0f, 1.0f,    1.0f, 1.0f},     // Top Right
        Vertex{-1.0f,-1.0f,    0.0f, 0.0f},     // Bottom Left
        Vertex{ 1.0f,-1.0f,    1.0f, 0.0f},     // Bottom Right
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
        size_t offset = sizeof(float)*2;
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
    
    _shaderProgram.enable();
        // Set sampler2d to use texture unit offset 0.
        GLint uniformLocation = _shaderProgram.getUniformLocation("tex");
        glUniform1i(uniformLocation, 0);
    _shaderProgram.disable();
    
    
    CHECK_GL_ERRORS;
}

//---------------------------------------------------------------------------------------

- (void) setupTexture
{
    glGenTextures(1, &_texture);
    
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    //wrap
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
    
    //filtering
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _imageWidth, _imageHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, nullptr);
 
    glBindTexture(GL_TEXTURE_2D, 0);
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
    int w = _imageWidth;
    int h = _imageHeight;
    int r = h-1;
    
    for(int i=0; i<h; ++i) {
        NSArray * row = [_frame objectAtIndex:r];
        --r;
        
        for(int j=0; j<w; ++j) {
            unsigned char c = [[row objectAtIndex:j] unsignedCharValue];
            c = [self adjustColor:c];
            
            for(int k=0; k < 3; ++k) {
                //random pixel value
//                float r = static_cast<float> (rand()) / RAND_MAX;
//                _pixels[i*3*w + j*3 + k] = floor(r * 255);
                _pixels[i*3*w + j*3 + k] = c;
            }
        }
    }
    
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, _imageWidth, _imageHeight, 0, GL_RGB, GL_UNSIGNED_BYTE, _pixels);
//    glDeleteTextures(1, &_texture);
//    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _imageWidth, _imageHeight, GL_BGRA, GL_UNSIGNED_BYTE, _pixels);
  
    glBindTexture(GL_TEXTURE_2D, 0);
    CHECK_GL_ERRORS;
}

- (unsigned char) adjustColor: (unsigned char) color {
    if (color > 238) {
        color = 255;
    } else {
        unsigned char newColor = color - 102;
        if (newColor < 0) {
            newColor = 0;
        }
        color = newColor;
    }
    return color;
}

//---------------------------------------------------------------------------------------
- (void) render
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
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
    delete _pixels;
    _webSocket = nil;
}


//WEBSOCKET

#pragma mark - Connection

- (void)connectWebSocket {
    _webSocket.delegate = nil;
    _webSocket = nil;
    printf("Connecting web socket...");
    
    NSString *urlString = @"ws://localhost:8090";
    _webSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
    _webSocket.delegate = self;
    
    [_webSocket open];
}

#pragma mark - SRWebSocket delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"Websocket Connected");
    
    [webSocket send:@"@"];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@":( Websocket Failed With Error %@", error);
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"WebSocket closed");
    _webSocket = nil;
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message {
    
    NSError *error;
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    _frame = [NSMutableArray arrayWithArray:[dictionary valueForKey:@"frame"]];
    
    [webSocket send:@"@"];
    error = nil;
    data = nil;
    dictionary = nil;
}

@end
