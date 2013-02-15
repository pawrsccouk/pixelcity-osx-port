//
// File:		BasicOpenGLView.m
//
// Abstract:	Basic OpenGL View with Renderer information
//
// Version:		1.1 - minor fixes.
//				1.0 - Original release.

#import "BasicOpenGLView.h"
#import "GLCheck.h"
#import "trackball.h"
#import "drawinfo.h"
#import "win.h"
#import "ini.h"
#import "RenderAPI.h"
#import "PWGL.h"
#import "Random.h"

// ==================================

// simple cube data
GLint cube_num_vertices = 8;

GLfloat cube_vertices [8][3] = {
    {1.0, 1.0, 1.0} ,   {1.0, -1.0, 1.0} ,   {-1.0, -1.0, 1.0} ,   {-1.0, 1.0, 1.0},
    {1.0, 1.0, -1.0},   {1.0, -1.0, -1.0},   {-1.0, -1.0, -1.0},   {-1.0, 1.0, -1.0}
};

GLfloat cube_vertex_colors [8][3] = {
    {1.0, 1.0, 1.0}, {1.0, 1.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 1.0, 1.0},
    {1.0, 0.0, 1.0}, {1.0, 0.0, 0.0}, {0.0, 0.0, 0.0}, {0.0, 0.0, 1.0}
};

GLint num_faces = 6;

short cube_faces [6][4] = {
	{3, 2, 1, 0},    {2, 3, 7, 6},    {0, 1, 5, 4},    {3, 0, 4, 7},    {1, 2, 6, 5},    {4, 5, 6, 7} 
};

Vector3 gOrigin = {0.0, 0.0, 0.0};

// single set of interaction flags and states
GLint gDollyPanStartPoint[2] = {0, 0};
GLfloat gTrackBallRotation [4] = {0.0f, 0.0f, 0.0f, 0.0f};
GLboolean gDolly = GL_FALSE, gPan = GL_FALSE, gTrackball = GL_FALSE;
__weak BasicOpenGLView * gTrackingViewInfo = nil;

// time and message info
CFAbsoluteTime gMsgPresistance = 10.0f;

// error output
float gErrorTime;

// Hack - assumes there will be only one OpenGL view. Needed to convert between the OpenGL Objective-C object
// and the C runtime API.

__weak BasicOpenGLView *theOpenGLView = nil;

// ==================================

#pragma mark ---- OpenGL Capabilities ----

// GL configuration info globals
// see GLCheck.h for more info
GLCaps * gDisplayCaps = NULL; // array of GLCaps
CGDisplayCount gNumDisplays = 0;

static void getCurrentCaps (void)
{
 	// Check for existing opengl caps here
	// This can be called again with same display caps array when display configurations are changed and
	//   your info needs to be updated.  Note, if you are doing dynmaic allocation, the number of displays
	//   may change and thus you should always reallocate your display caps array.
	if (gDisplayCaps && HaveOpenGLCapsChanged (gDisplayCaps, gNumDisplays)) { // see if caps have changed
		free (gDisplayCaps);
		gDisplayCaps = NULL;
	}
	if (!gDisplayCaps) { // if we do not have caps
		CheckOpenGLCaps (0, NULL, &gNumDisplays); // will just update number of displays
		gDisplayCaps = (GLCaps*) malloc (sizeof (GLCaps) * gNumDisplays);
		CheckOpenGLCaps (gNumDisplays, gDisplayCaps, &gNumDisplays);
//		initCapsTexture (gDisplayCaps, gNumDisplays); // (re)init the texture for printing caps
	}
}

#pragma mark ---- Utilities ----

static CFAbsoluteTime gStartTime = 0.0f;

// set app start time
static void setStartTime (void)
{	
	gStartTime = CFAbsoluteTimeGetCurrent ();
}

// ---------------------------------

// return float elpased time in seconds since app start
static CFAbsoluteTime getElapsedTime (void)
{	
	return CFAbsoluteTimeGetCurrent () - gStartTime;
}

#pragma mark ---- Error Reporting ----

// error reporting as a debugger string
static void reportError (const char * strError, const char *strLocation)
{
	gErrorTime = getElapsedTime ();
	NSString * errString = [NSString stringWithFormat:@"Error: %s (in %s, at time: %0.1f secs).", strError, strLocation, gErrorTime];
	NSLog (@"%@\n", errString);
}

static bool fDebugLog = false;

void DebugLog(const char* str, ...)
{
    if(fDebugLog) {
        va_list args;
        va_start(args, str);
        
        char buffer[512];
        memset(buffer, 0, 512);
        
        @try {        vsprintf(buffer, str, args);    }
        @finally {    va_end(args);                   }
        
        NSLog(@"%@\n", [NSString stringWithUTF8String:buffer]);
    }
}

// if error dump gl errors to debugger string, return error
void glReportError (const char* strLocation)
{
	GLenum err = glGetError();
	while(GL_NO_ERROR != err) {
		reportError( (char *)gluErrorString(err), strLocation );
		err = glGetError();
	}
}

#pragma mark ---- OpenGL Utils ----


// ===================================

@implementation BasicOpenGLView

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

// ---------------------------------

// update the projection matrix based on camera and view info
- (void) updateProjection
{
    [[self openGLContext] makeCurrentContext];

        // set projection
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
    
	GLdouble near = -camera.viewPos.z - shapeSize * 0.5;
	if (near < 0.00001)
		near = 0.00001;
    
	GLdouble far = -camera.viewPos.z + shapeSize * 0.5;
	if (far < 1.0)
		far = 1.0;
	GLdouble radians = 0.0174532925 * camera.aperture / 2; // half aperture degrees to radians
	GLdouble wd2 = near * tan(radians);
	
    GLdouble ratio = camera.viewWidth / (float)camera.viewHeight;
	GLdouble left = (ratio >= 1.0) ? -ratio * wd2 : -wd2,
            right = (ratio >= 1.0) ?  ratio * wd2 :  wd2,
              top = (ratio >= 1.0) ?  wd2 :  wd2 / ratio,
           bottom = (ratio >= 1.0) ? -wd2 : -wd2 / ratio;
	glFrustum (left, right, bottom, top, near, far);
	
	glReportError("updateProjection");
}

// ---------------------------------

// updates the contexts model view matrix for object and camera moves
- (void) updateModelView
{
    [[self openGLContext] makeCurrentContext];
	
        // move view
	glMatrixMode (GL_MODELVIEW);
	glLoadIdentity ();
	gluLookAt (camera.viewPos.x, camera.viewPos.y, camera.viewPos.z,
			   camera.viewPos.x + camera.viewDir.x,
			   camera.viewPos.y + camera.viewDir.y,
			   camera.viewPos.z + camera.viewDir.z,
			   camera.viewUp.x, camera.viewUp.y ,camera.viewUp.z);
			
        // if we have trackball rotation to map (this IS the test I want as it can be explicitly 0.0f)
	if ((gTrackingViewInfo == self) && gTrackBallRotation[0] != 0.0f) 
		glRotatef (gTrackBallRotation[0], gTrackBallRotation[1], gTrackBallRotation[2], gTrackBallRotation[3]);

        // accumlated world rotation via trackball
	glRotatef (worldRotation[0], worldRotation[1], worldRotation[2], worldRotation[3]);
    
        // object itself rotating applied after camera rotation
	glRotatef (objectRotation[0], objectRotation[1], objectRotation[2], objectRotation[3]);
    
        // reset animation rotations (do in all cases to prevent rotating while moving with trackball)
	cubeSpin[0].rotation = 0.0f;
	cubeSpin[1].rotation = 0.0f;
	cubeSpin[2].rotation = 0.0f;
	glReportError("GLModelView");
}

// ---------------------------------

// handles resizing of GL need context update and if the window dimensions change, a
// a window dimension update, reseting of viewport and an update of the projection matrix
- (void) resizeGL
{
	NSRect rectView = [self bounds];
	AppResize(rectView.size.width, rectView.size.height);
	/*
	// ensure camera knows size changed
	if ((camera.viewHeight != rectView.size.height) ||
	    (camera.viewWidth != rectView.size.width)) {
		camera.viewHeight = rectView.size.height;
		camera.viewWidth = rectView.size.width;
		
		glViewport (0, 0, camera.viewWidth, camera.viewHeight);
		[self updateProjection];  // update projection matrix
	}
	 */
	glReportError("resizeGL");
}

// ---------------------------------

// sets the camera data to initial conditions
- (void) resetCamera
{
   camera.aperture = 40;
   camera.rotPoint = gOrigin;

   camera.viewPos.x = 0.0;
   camera.viewPos.y = 0.0;
   camera.viewPos.z = -10.0;
   camera.viewDir.x = -camera.viewPos.x; 
   camera.viewDir.y = -camera.viewPos.y; 
   camera.viewDir.z = -camera.viewPos.z;

   camera.viewUp.x = 0;  
   camera.viewUp.y = 1; 
   camera.viewUp.z = 0;
}

// ---------------------------------

// given a delta time in seconds and current rotation accel, velocity and position, update overall object rotation
- (void) updateObjectRotationForTimeDelta:(CFAbsoluteTime)deltaTime
{
	// update rotation based on vel and accel
	float rotation[4] = {0.0f, 0.0f, 0.0f, 0.0f};
	GLfloat fVMax = 2.0;
	short i;
	// do velocities
	for (i = 0; i < 3; i++) {	// Axes X, Y and Z.
		Spin *pSpin = &cubeSpin[i];
		pSpin->velocity += pSpin->acceleration * deltaTime * 30.0;
		
		if (pSpin->velocity > fVMax) {
			pSpin->acceleration *= -1.0;
			pSpin->velocity = fVMax;
		} else if (pSpin->velocity < -fVMax) {
			pSpin->acceleration *= -1.0;
			pSpin->velocity = -fVMax;
		}
		
		pSpin->rotation += pSpin->velocity * deltaTime * 30.0;
		
		while (pSpin->rotation > 360.0)
			pSpin->rotation -= 360.0;
		while (pSpin->rotation < -360.0)
			pSpin->rotation += 360.0;
	}
	rotation[0] = cubeSpin[0].rotation;
	rotation[1] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
	rotation[0] = cubeSpin[1].rotation;
	rotation[1] = 0.0f; rotation[2] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
	rotation[0] = cubeSpin[2].rotation;
	rotation[2] = 0.0f; rotation[3] = 1.0f;
	addToRotationTrackball (rotation, objectRotation);
	
	glReportError("updateObjectRotationForTimeDelta");
}

// ---------------------------------

// per-window timer function, basic time based animation preformed here
- (void)animationTimer:(NSTimer *)timer
{
	BOOL shouldDraw = fAnimate;
	time = CFAbsoluteTimeGetCurrent (); //reset time in all cases
	// if we have current messages
	if (((getElapsedTime () - msgTime) < gMsgPresistance) || ((getElapsedTime () - gErrorTime) < gMsgPresistance))
		shouldDraw = YES; // force redraw
	if (YES == shouldDraw) 
		[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
}

static const int MAX_CACHED_GL_STRINGS = 100;

-(void)drawOverlayText:(NSString*)overlayText
{
    CGRect bounds = self.bounds;
        // TODO: If this is slow, try cacheing the glString objects by the text, so they don't need to be regenerated each time.
        // The text is mostly boilerplate and there isn't that much of it.
    static NSMutableDictionary *cachedStrings;
    static CGSize lastSize = { 0, 0 };
    if(!cachedStrings) cachedStrings = [NSMutableDictionary dictionary];
    if(lastSize.width <= 0 || lastSize.height <= 0) lastSize = bounds.size;
    
        // Clear the cache if the image size has changed or if the cache has gotten too large.
    if( (! CGSizeEqualToSize(lastSize, bounds.size)) || (cachedStrings.count > MAX_CACHED_GL_STRINGS) ) {
        [cachedStrings removeAllObjects];
        lastSize = bounds.size;
    }
    
    GLString *glString = cachedStrings[overlayText];
    if(! glString) {
        glString = [[GLString alloc] initWithString:overlayText attributes:@{
                    NSForegroundColorAttributeName : [NSColor whiteColor],
                    NSFontAttributeName            : [NSFont fontWithName: @"Helvetica-Bold" size: 12.0f] }
                                          textColor:[NSColor whiteColor]
                                           boxColor:[NSColor clearColor]
                                        borderColor:[NSColor clearColor]];
        
        [glString useDynamicFrame];
        cachedStrings[overlayText] = glString;
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



#pragma mark ---- IB Actions ----

    // Dump logs and debug info to the console.
-(IBAction) info: (id) sender
{
    EntityDump();
}


static void toggleFlag(NSMenuItem *menuItem, void(^pbl)(bool), bool *pFlag)
{
	*pFlag = ! *pFlag;
	[menuItem setState:(*pFlag) ? NSOnState : NSOffState];
	if(pbl)
        pbl(*pFlag);
}

-(IBAction) animate: (id) sender
{
    toggleFlag(animateMenuItem, nil, &fAnimate);
}

-(IBAction)toggleWireframe:(id)sender
{
    toggleFlag(wireframeToggleMenuItem, ^(bool b) { RenderSetWireframe(b); }, &fWireframe);
}

-(IBAction)nextEffect:(id)sender
{
	RenderEffectCycle();
}

-(IBAction) toggleLetterbox: (id) sender
{
    toggleFlag(letterboxToggleMenuItem, ^(bool b) { RenderSetLetterbox(b); }, &fLetterbox);
        // PAW TODO: I think I'm supposed to change the window size to match the letterbox size here.
	CGSize size = [self bounds].size;
	AppResize(size.width, size.height);
}

-(IBAction) toggleFPS:       (id) sender
{
    toggleFlag(FPSToggleMenuItem, ^(bool b) {  RenderSetFPS(b); }, &fFPS);
}

-(IBAction) toggleFog:       (id) sender
{
    toggleFlag(fogToggleMenuItem, ^(bool b) { RenderSetFog(b); }, &fFog);
}

-(IBAction) toggleFlat:      (id) sender
{
    toggleFlag(flatToggleMenuItem, ^(bool b) { RenderSetFlat(b); }, &fFlat);
}

-(IBAction)toggleDebugLog:(id)sender
{
    toggleFlag(debugLogToggleMenuItem, nil, &fDebugLog);
}

-(IBAction) toggleHelp:      (id) sender
{
    toggleFlag(helpToggleMenuItem, ^(bool b) { RenderSetHelpMode(b); }, &fHelp);
}

-(IBAction)toggleNormalized:(id)sender
{
    toggleFlag(normalizeToggleMenuItem, ^(bool b) { RenderSetNormalized(b); }, &fNormalize);
}




#pragma mark ---- Method Overrides ----




- (void) drawRect:(NSRect)rect
{		
	glReportError("drawRect:Beginning");
	// setup viewport and prespective

	NSRect r = [self bounds];
	AppUpdate(r.size.width, r.size.height);
	glReportError("drawRect:After AppUpdate");

	if ([self inLiveResize] && !fAnimate)
		glFlush();
	else
		[[self openGLContext] flushBuffer];
	glReportError("drawRect:End");
}




// set initial OpenGL state (current context is set). called after context is created
- (void) prepareOpenGL
{
    GLint swapInt = 1;

    [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; // set to vbl sync

	// init GL stuff here
	NSRect r = [self bounds];
	AppInit(r.size.width, r.size.height);
	[[self openGLContext] flushBuffer];
	AppResize(r.size.width, r.size.height);	
	glReportError("prepareOpenGL");
}



// this can be a troublesome call to do anything heavyweight, as it is called on window moves, resizes, and display config changes.
// So be careful of doing too much here.
- (void) update // window resizes, moves and display changes (resize, depth and display config change)
{
	[super update];
	if (![self inLiveResize])  {// if not doing live resize
		getCurrentCaps (); // this call checks to see if the current config changed in a reasonably lightweight way to prevent expensive re-allocations
	}
	glReportError("update");
}

// ---------------------------------

-(id) initWithFrame: (NSRect) frameRect
{
	self = [super initWithFrame:frameRect pixelFormat:[BasicOpenGLView basicPixelFormat]];
    if(self) {
            //load in our settings
        fLetterbox = IniInt("Letterbox") != 0;
        fWireframe = IniInt("Wireframe") != 0;
        fFog       = IniInt("ShowFog")   != 0;
        fFlat      = IniInt("Flat")      != 0;
        fFPS       = IniInt("ShowFPS")   != 0;
        fDebugLog  = false;
        
        NSAssert(theOpenGLView == nil, @"theOpenGLView already had a value. Is there more than one opengl view?");
        theOpenGLView = self;
    }
    return self;
}

- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder  { return YES; }
- (BOOL)resignFirstResponder  { return YES; }

// ---------------------------------

- (void) awakeFromNib
{
        // Set the current values for the flags in Render, so the output matches the settings we show on the menus
    RenderSetFlat(fFlat);
    RenderSetFog(fFog);
    RenderSetFPS(fFPS);
    RenderSetHelpMode(fHelp);
    RenderSetLetterbox(fLetterbox);
    RenderSetNormalized(fNormalize);
    RenderSetWireframe(fWireframe);

	setStartTime (); // get app start time
	getCurrentCaps (); // get current GL capabilites for all displays
	
	// set start values...
	cubeSpin[0].velocity     = 0.3;   cubeSpin[1].velocity     = 0.1;    cubeSpin[2].velocity     = 0.2; 
	cubeSpin[0].acceleration = 0.003; cubeSpin[1].acceleration = -0.005; cubeSpin[2].acceleration = 0.004;
	fAnimate = fDrawHelp = 1;
	time = CFAbsoluteTimeGetCurrent ();  // set animation time start time
	
	// start animation timer
	timer = [NSTimer timerWithTimeInterval:(1.0f / 60.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize (otherwise the cube will freeze when resizing).
}

#pragma mark - NSWindow delegate

-(void)windowWillClose:(NSNotification *)notification
{
    NSAssert(notification.object == self.window, @"The object %@ is not our window.", notification.object);
    RenderTerminate();  // Stop any OpenGL renders and wait for the window to be closed.
}

@end



void RenderPrintOverlayText(int line, const char *fmt, ...)
{
    NSString *text, *fmtText = [NSString stringWithUTF8String:fmt];
    va_list args;
    va_start(args, fmt);
    @try { text = [[NSString alloc] initWithFormat:fmtText arguments:args]; }
    @finally {  va_end(args); }
    
    assert(theOpenGLView);
    [theOpenGLView drawOverlayText:text];
}




static NSArray *getFontAttributes()
{
    static NSMutableArray *fontAttribs;
    if(!fontAttribs) {
        NSString *fontNames[] = { @"Helvetica-Bold", @"Courier-Bold", @"Times-Bold", @"Impact", @"Chalkboard-Bold", @"Baskerville-Bold" };
        int arraySize = sizeof(fontNames) / sizeof(fontNames[0]);
        fontAttribs = [NSMutableArray arrayWithCapacity:6];
        
        for(NSUInteger i = 0; i < arraySize; i++) {
            NSFont *font = [NSFont fontWithName:fontNames[i] size:32];
            if(font)
                [fontAttribs addObject:@{
                  NSFontAttributeName            : font,
                  NSForegroundColorAttributeName : [NSColor whiteColor]}];
            else  NSLog(@"Font %@ could not be created.", fontNames[i]);
        }
    }
    return fontAttribs;
}

int RenderGetNumFonts()
{
    return (int)getFontAttributes().count;
}

void RenderPrintIntoTexture(GLuint textureId, int x, int y, int texWidth, int texHeight,
                            int font, NSColor *textColor,
                            const char *fmt, ...)
{
    NSString *text, *fmtText = [NSString stringWithUTF8String:fmt];
    va_list args;
    va_start(args, fmt);
    @try { text = [[NSString alloc] initWithFormat:fmtText arguments:args]; }
    @finally {  va_end(args); }
    
    NSMutableDictionary *stringAttrs = [NSMutableDictionary dictionaryWithDictionary:getFontAttributes()[font]];
    stringAttrs[NSForegroundColorAttributeName] = textColor;
    assert(stringAttrs[NSFontAttributeName]);
    GLString *glString = [[GLString alloc] initWithString:text
                                               attributes:stringAttrs
                                                textColor:textColor
                                                 boxColor:[NSColor redColor]
                                              borderColor:[NSColor greenColor]];
    [glString drawIntoTexture:textureId x:x y:y width:texWidth height:texHeight];
}

static NSArray *makeLogos()
{
    NSArray* prefix =
    @[
	@"i"     ,
	@"Green ",
	@"Mega"  ,
	@"Super ",
	@"Omni"  ,
	@"e"     ,
	@"Hyper" ,
	@"Global ",
	@"Vital" ,
	@"Next " ,
	@"Pacific ",
	@"Metro" ,
	@"Unity ",
	@"G-"    ,
	@"Trans" ,
	@"Infinity ",
	@"Superior ",
	@"Monolith ",
	@"Best " ,
	@"Atlantic ",
	@"First ",
	@"Union ",
	@"National ",
    ];

    NSArray* name =
    @[
	@"Biotic",
	@"Info",
	@"Data",
	@"Solar",
	@"Aerospace",
	@"Motors",
	@"Nano",
	@"Online",
	@"Circuits",
	@"Energy",
	@"Med",
	@"Robotic",
	@"Exports",
	@"Security",
	@"Systems",
	@"Financial",
	@"Industrial",
	@"Media",
	@"Materials",
	@"Foods",
	@"Networks",
	@"Shipping",
	@"Tools",
	@"Medical",
	@"Publishing",
	@"Enterprises",
	@"Audio",
	@"Health",
	@"Bank",
	@"Imports",
	@"Apparel",
	@"Petroleum",
	@"Studios",
    ];

    NSArray* suffix =
    @[
	@"Corp",
	@" Inc.",
	@"Co",
	@"World",
	@".Com",
	@" USA",
	@" Ltd.",
	@"Net",
	@" Tech",
	@" Labs",
	@" Mfg.",
	@" UK",
	@" Unlimited",
	@" One",
	@" LLC"
    ];

    pwDepthMask(GL_FALSE);
    pwDisable(GL_BLEND);
    
    static const int NUM_LOGOS = 20;
    int name_num = RandomIntR((int)name.count), prefix_num = RandomIntR((int)prefix.count), suffix_num = RandomIntR((int)suffix.count);
    int font = RandomIntR(RenderGetNumFonts());
    
    NSMutableArray *textures = [NSMutableArray array];
    
    for(int i = 0; i < NUM_LOGOS; i++) {
        
        NSMutableDictionary *logoAttributes = [NSMutableDictionary dictionaryWithDictionary:getFontAttributes()[font]];
        logoAttributes[NSForegroundColorAttributeName] = [NSColor whiteColor];
        assert(logoAttributes[NSFontAttributeName]);

        NSString *logoText = COIN_FLIP() ? [NSString stringWithFormat:@"%@%@", prefix[prefix_num], name[name_num]    ]
                                         : [NSString stringWithFormat:@"%@%@", name[name_num]    , suffix[suffix_num]];

        GLString *s = [[GLString alloc] initWithString:logoText
                                            attributes:logoAttributes
                                             textColor:[NSColor whiteColor]
                                              boxColor:[NSColor clearColor]
                                           borderColor:[NSColor clearColor]];
        
        GLuint textureId = [s makeTexture];
        assert(textureId);
        if(textureId)
            [textures addObject:[NSNumber numberWithInt:textureId]];
        
        name_num   = (name_num   + 1) % name.count  ;
        prefix_num = (prefix_num + 1) % prefix.count;
        suffix_num = (suffix_num + 1) % suffix.count;
    }
    return textures;
}


GLuint TextureRandomLogo()
{
    static NSArray *textures = nil;
    if(!textures)
        textures = makeLogos();
    
    return [textures[RandomIntR(textures.count)] intValue];
}

