#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import "GLString.h"

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

- (void) drawRect:(NSRect)rect;

- (void) update;		// moved or resized

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (id) initWithFrame: (NSRect) frameRect;
- (void) awakeFromNib;

@end
