/*
Created 2013 by Pat Wallace
Released under the GNU General Public License, version 3
*/

#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import "../GLString.h"

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

    // setupCallback will be invoked when the OpenGL context is created the objects have been created.
    // You can then use it to set individual settings for the view.
@property (nonatomic, copy) setupCallback_t setupCallback;

- (void) drawRect:(NSRect)rect;

// - (void) update;		// moved or resized

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (id) initWithFrame:(NSRect)frameRect;

@end
