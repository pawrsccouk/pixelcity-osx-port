//
// File:		BasicOpenGLView.m
//
// Abstract:	Basic OpenGL View with Renderer information
//
// Version:		1.1 - minor fixes.
//				1.0 - Original release.

#import "BasicOpenGLView.h"
#import "GLCheck.h"
#import "win.h"
#import "ini.h"
#import "Render.h"
#import "Model.h"
#import "World.h"
#import "texture.h"

#pragma mark ---- OpenGL Capabilities ----

// GL configuration info globals. See GLCheck.h for more info

@interface BasicOpenGLView ()
{
    GLCaps * _displayCaps;          // array of GLCaps
    CGDisplayCount _displayCount;
}
@end


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
@synthesize animating, world;

#pragma mark - OpenGL Support

-(void) getCurrentCaps
{
    auto getNumDisplays = ^{ CGDisplayCount numDisplays = 0; CheckOpenGLCaps(0, NULL, &numDisplays); return numDisplays; };
    
        // Check for existing opengl caps here
        // This can be called again with same display caps array when display configurations are changed and
        //   your info needs to be updated.  Note, if you are doing dynmaic allocation, the number of displays
        //   may change and thus you should always reallocate your display caps array.
    
	if (_displayCaps && HaveOpenGLCapsChanged(_displayCaps, _displayCount)) { // see if caps have changed
		free (_displayCaps);
		_displayCaps = NULL;
	}
    
	if (!_displayCaps) { // if we do not have caps
		_displayCount = getNumDisplays();
		_displayCaps = (GLCaps*)malloc(sizeof(GLCaps) * _displayCount);
		CheckOpenGLCaps(_displayCount, _displayCaps, &_displayCount);
	}
}


// pixel format definition
+ (NSOpenGLPixelFormat*) basicPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,	// double buffered
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)16, // 16 bit depth buffer
        (NSOpenGLPixelFormatAttribute)nil
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
    NSRect r = [self bounds];
    self.world = [[World alloc] initWithViewSize:r.size];
    [self.openGLContext flushBuffer];
    [self.world.renderer resize:r.size];
    glReportError("prepareOpenGL");    
    
	[self getCurrentCaps];               // get current GL capabilites for all displays
	_time = CFAbsoluteTimeGetCurrent();  // set animation time start time
}


- (void) resizeGL
{
	NSRect rectView = [self bounds];
    [world.renderer resize:rectView.size];
	glReportError("resizeGL");
}

// Called for each tick of the timer. Redraw the scene here with the updates
- (void)animationTick
{
	BOOL shouldDraw = self.animating;
    
        // Screensaver sometimes tries to draw into an empty view.
        // If so, we get invalid framebuffer errors. So prevent drawing in that case.
    if(! self.openGLContext.view)
        shouldDraw = NO;
    
	_time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
    
	if (YES == shouldDraw) {
        self.needsDisplay = YES;
		[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
    }
}


#pragma mark - Method Overrides




- (void) drawRect:(NSRect)rect
{
    [[self openGLContext] makeCurrentContext];
    
	// setup viewport and prespective
	NSRect r = [self bounds];
	AppUpdate(self.world, r.size);

	if (self.inLiveResize && ! self.animating)
		glFlush();
	else
		[[self openGLContext] flushBuffer];

	glReportError("drawRect");
}



// this can be a troublesome call to do anything heavyweight, as it is called on window moves, resizes, and display config changes.
// So be careful of doing too much here.
- (void) update // window resizes, moves and display changes (resize, depth and display config change)
{
	[super update];
    
	if (! self.inLiveResize)
		[self getCurrentCaps]; // this call checks to see if the current config changed in a reasonably lightweight way to prevent expensive re-allocations

	glReportError("update");
}

// ---------------------------------

-(id) initWithFrame: (NSRect) frameRect
{
	self = [super initWithFrame:frameRect pixelFormat:[BasicOpenGLView basicPixelFormat]];
    if(self) {
        _displayCaps = NULL;
        _displayCount = 0;
    }
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
    if(_displayCaps)
        free(_displayCaps);
    _displayCaps = NULL;
    
    [world term];
}

@end







