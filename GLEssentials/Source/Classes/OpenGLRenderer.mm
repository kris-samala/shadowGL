//
// OpenGLRenderer.m
//
#import "OpenGLRenderer.h"


@interface OpenGLRenderer ()
// Add private methods here that are only called from this file:

- (void) onInit;
- (void) setupGL;
- (void) setupVertexBuffers;

@end


@implementation OpenGLRenderer {
@private
// Add private member instance variables here:
    
    GLuint _viewWidth;
    GLuint _viewHeight;
    
    GLuint _vao;
    GLuint _vbo;
    
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
    [self setupVertexBuffers];
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
    
    // Draw our scene once without presenting the rendered image.
    // This is done in order to pre-warm OpenGL
    // We don't need to present the buffer since we don't actually want the
    // user to see this, we're only drawing as a pre-warm stage
    [self render];
    
    // Check for errors to make sure all of our setup went ok
    GetGLError();
    
}

//---------------------------------------------------------------------------------------
- (void) setupVertexBuffers
{
    
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
}


//---------------------------------------------------------------------------------------
- (void) dealloc
{
    // Do any cleanup here.
}

@end
