//
// OpenGLRenderer.h
//
#include "glUtil.h"
#import <Foundation/Foundation.h>

@interface OpenGLRenderer : NSObject 

@property (nonatomic) GLuint defaultFBOName;

- (instancetype) initWithDefaultFBO: (GLuint) defaultFBOName;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;

// Called once per frame before render.
- (void) update;

// Called once per frame after update.
- (void) render;

- (void) dealloc;

@end
