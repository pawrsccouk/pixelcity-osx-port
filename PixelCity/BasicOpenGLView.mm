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
#import "RenderAPI.h"
#import "Model.h"
#import "World.h"
#import "texture.h"

#pragma mark ---- OpenGL Capabilities ----

// GL configuration info globals. See GLCheck.h for more info
GLCaps * gDisplayCaps = NULL; // array of GLCaps
CGDisplayCount gNumDisplays = 0;

static void getCurrentCaps (void)
{
    auto getNumDisplays = ^{ CGDisplayCount numDisplays = 0; CheckOpenGLCaps(0, NULL, &numDisplays); return numDisplays; };

 	// Check for existing opengl caps here
	// This can be called again with same display caps array when display configurations are changed and
	//   your info needs to be updated.  Note, if you are doing dynmaic allocation, the number of displays
	//   may change and thus you should always reallocate your display caps array.
    
	if (gDisplayCaps && HaveOpenGLCapsChanged(gDisplayCaps, gNumDisplays)) { // see if caps have changed
		free (gDisplayCaps);
		gDisplayCaps = NULL;
	}
    
	if (!gDisplayCaps) { // if we do not have caps
		gNumDisplays = getNumDisplays();
		gDisplayCaps = (GLCaps*)malloc(sizeof(GLCaps) * gNumDisplays);
		CheckOpenGLCaps(gNumDisplays, gDisplayCaps, &gNumDisplays);
//		initCapsTexture (gDisplayCaps, gNumDisplays); // (re)init the texture for printing caps
	}
}

#pragma mark - Utilities

static CFAbsoluteTime gStartTime = 0.0f;

// set app start time
static void setStartTime (void)
{	
	gStartTime = CFAbsoluteTimeGetCurrent ();
}



// return float elpased time in seconds since app start
static CFAbsoluteTime getElapsedTime (void)
{	
	return CFAbsoluteTimeGetCurrent () - gStartTime;
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
//    NSLog(@"OpenGL context is %@, attached to view %@", self.openGLContext, self.openGLContext.view);
    
            // init GL stuff here
    NSRect r = [self bounds];
    self.world = AppInit(r.size.width, r.size.height);
    [self.openGLContext flushBuffer];
    AppResize(r.size.width, r.size.height);
    glReportError("prepareOpenGL");    
    
	setStartTime (); // get app start time
	getCurrentCaps (); // get current GL capabilites for all displays
	
	_time = CFAbsoluteTimeGetCurrent();  // set animation time start time
}


- (void) resizeGL
{
	NSRect rectView = [self bounds];
	AppResize(rectView.size.width, rectView.size.height);
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

static const int MAX_CACHED_GL_STRINGS = 100;

-(void)drawOverlayText:(NSString*)overlayText
{
    [[self openGLContext] makeCurrentContext];
    NSRect bounds = self.bounds;
        // Cache the glString objects by the text, so they don't need to be regenerated each time.
        // The text is mostly boilerplate and there isn't that much of it.
        // May need to revisit this if we start displaying a lot of arbitrary text.
    static NSMutableDictionary *cachedStrings;
    static CGSize lastSize = { 0, 0 }, boundsSize = { bounds.size.width, bounds.size.height };
    if(!cachedStrings) cachedStrings = [NSMutableDictionary dictionary];
    if(lastSize.width <= 0 || lastSize.height <= 0) lastSize = boundsSize;
    
        // Clear the cache if the image size has changed or if the cache has gotten too large.
    if( (! CGSizeEqualToSize(lastSize, boundsSize)) || (cachedStrings.count > MAX_CACHED_GL_STRINGS) ) {
        [cachedStrings removeAllObjects];
        lastSize = { bounds.size.width, bounds.size.height };
    }
    
    GLString *glString = [cachedStrings objectForKey:overlayText];
    if(! glString) {
        glString = [[GLString alloc] initWithString:overlayText attributes:@{
                    NSForegroundColorAttributeName : [NSColor whiteColor],
                    NSFontAttributeName            : [NSFont fontWithName: @"Helvetica-Bold" size: 14.0f] }
                                          textColor:[NSColor whiteColor]
                                           boxColor:[NSColor clearColor]
                                        borderColor:[NSColor clearColor]];
        
        [glString useDynamicFrame];
        [cachedStrings setObject:glString forKey:overlayText];
    }
    
    pwMatrixMode (GL_PROJECTION);
    pwPushMatrix();
    @try {
        pwLoadIdentity();
        glOrtho(0, bounds.size.width, bounds.size.height, 0, 0.1f, 2048);	glReportError("glOrtho");
        
        pwMatrixMode (GL_MODELVIEW);
        pwPushMatrix ();
        @try {
            pwLoadIdentity();
            pwTranslatef(0, 0, -1.0f);
            pwDisable(GL_BLEND);
            pwDisable(GL_FOG);
            pwDisable(GL_TEXTURE_2D);
            pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

            [glString drawAtPoint:bounds.origin];
        }
        @finally {
            pwPopMatrix();
            glMatrixMode(GL_PROJECTION);
        }
    }
    @finally {
        pwPopMatrix();
        glMatrixMode(GL_MODELVIEW);
    }
}



#pragma mark - Method Overrides




- (void) drawRect:(NSRect)rect
{
    [[self openGLContext] makeCurrentContext];
    
	// setup viewport and prespective
	NSRect r = [self bounds];
	AppUpdate(self.world, r.size.width, r.size.height);

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
		getCurrentCaps(); // this call checks to see if the current config changed in a reasonably lightweight way to prevent expensive re-allocations

	glReportError("update");
}

// ---------------------------------

-(id) initWithFrame: (NSRect) frameRect
{
	self = [super initWithFrame:frameRect pixelFormat:[BasicOpenGLView basicPixelFormat]];
    if(self) {
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

@end



void RenderPrintOverlayText(int line, const char *fmt, ...)
{
        // Find the BasicOpenGLView object we should be drawing into, and pass the message on to that.
        // This is needed to link the objectless C call here to the openGL window.
        // (Note the screensaver creates multiple opengl views, so I can't just use a global to hold one).

    NSView *view = [NSOpenGLContext currentContext].view;
    if(view && [view isKindOfClass:[BasicOpenGLView class]]) {
    
        NSString *text, *fmtText = [NSString stringWithUTF8String:fmt];
        va_list args;
        va_start(args, fmt);
        @try { text = [[NSString alloc] initWithFormat:fmtText arguments:args]; }
        @finally {  va_end(args); }
    
        [(BasicOpenGLView*)view drawOverlayText:text];
    }
    else NSLog(@"RenderPrintOverlayText: View %@ was not a BasicOpenGLView. Not drawing.", view);
}




