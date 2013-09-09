/*
Created 2013 by Pat Wallace, based on sample code provided by Apple Inc.
Released under the GNU General Public License, version 3
*/

#import "BasicOpenGLView.h"
#import "PWGL.h"
#import "win.h"
#import "ini.h"
#import "Render.h"
#import "Model.h"
#import "World.h"
#import "texture.h"

#pragma mark - Utilities

// return float elpased time in seconds since app start
static CFAbsoluteTime getElapsedTime(void)
{
    static CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
	return CFAbsoluteTimeGetCurrent () - startTime;
}


// Error reporting is via a debugger string (printed to the console by the screensaver module).
// Multiple errors from the same location are suppressed. Only the first is shown.
void glReportError(const char* strLocation)
{
    static NSString *lastError = nil;

	for(GLenum err = glGetError(); err != GL_NO_ERROR; err = glGetError()) {
        NSString *error = [NSString stringWithFormat:@"Error [%s] in [%s]", gluErrorString(err), strLocation];
        if((lastError == nil) || ! [lastError isEqualToString:error]) {
            lastError = error;
            NSLog (@"%@, at time: %0.1f secs).", error, getElapsedTime());
        }
    }
}




@implementation BasicOpenGLView
@synthesize animating, world, setupCallback;

#pragma mark - OpenGL Support

// pixel format definition
+ (NSOpenGLPixelFormat*) basicPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow                                       // Windowed
      , NSOpenGLPFADoubleBuffer                                 // double buffered
      , NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)16  // 16 bit depth buffer
      , (NSOpenGLPixelFormatAttribute)nil
    };
    return [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
}



    // set initial OpenGL state (current context is set). called after context is created
    // This is called automatically by NSOpenGLView when the OpenGL context has been created.
- (void) prepareOpenGL
{
    GLint swapInt = 1;
    [self.openGLContext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; // set to vbl sync
    
    [self.openGLContext makeCurrentContext];

        // init GL stuff here
    self.world = [[World alloc] initWithViewSize:self.bounds.size];
    [self.openGLContext flushBuffer];
    [self.world.renderer resize:self.bounds.size];
    glReportError("prepareOpenGL");    
    
	_time = CFAbsoluteTimeGetCurrent();  // set animation time start time
    
    if(self.setupCallback) {
        self.setupCallback();
    }
}


- (void) resizeGL
{
    [self.openGLContext makeCurrentContext];
	NSRect rectView = [self bounds];
    [world.renderer resize:rectView.size];
	glReportError("resizeGL");
}

// Called for each tick of the timer. Redraw the scene here with the updates
- (void)animationTick
{
	BOOL shouldDraw = self.animating;
    
	_time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
    
	if (YES == shouldDraw) {
        self.needsDisplay = YES;
		[self drawRect:self.bounds]; // redraw now instead dirty to enable updates during live resize
    }
}


#pragma mark - Method Overrides




- (void) drawRect:(NSRect)rect
{
    [self.openGLContext makeCurrentContext];
    
        // Move the world along by one tick, and then draw it into the GL context.
    [self.world update:self.bounds.size];
    [self.world draw];

	if (self.inLiveResize && ! self.animating)
		glFlush();
	else
		[[self openGLContext] flushBuffer];

	glReportError("drawRect");
}


// ---------------------------------

-(id) initWithFrame: (NSRect) frameRect
{
	self = [super initWithFrame:frameRect pixelFormat:[BasicOpenGLView basicPixelFormat]];
    return self;
}

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder  { return YES; }
- (BOOL)resignFirstResponder  { return YES; }

// ---------------------------------

-(void) awakeFromNib
{
    [super awakeFromNib];
}

-(void)dealloc
{
    [world term];
}

@end







