// Created in 2013 by Patrick A Wallace
// Released under the GNU GPL v3. See the file COPYING for details.

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import "GLString.h"

typedef void (^setupCallback_t)(void);

@class World;


@interface BasicOpenGLView : NSOpenGLView <NSWindowDelegate>
{ 	
	CFAbsoluteTime _time;
}

+ (NSOpenGLPixelFormat*) basicPixelFormat;

- (void) resizeGL;
- (void) animationTick;

@property (nonatomic) BOOL animating;
@property (nonatomic, retain) World *world;

    // setupCallback will be invoked when the OpenGL context is created but before the objects have been created.
    // You can then use it to set individual settings for the view.
@property (nonatomic, copy) setupCallback_t setupCallback;

- (void) drawRect:(NSRect)rect;

- (id) initWithFrame:(NSRect)frameRect;

@end
