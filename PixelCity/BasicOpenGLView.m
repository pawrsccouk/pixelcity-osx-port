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
#import "RenderAPI.h"

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

Vector gOrigin = {0.0, 0.0, 0.0};

// single set of interaction flags and states
GLint gDollyPanStartPoint[2] = {0, 0};
GLfloat gTrackBallRotation [4] = {0.0f, 0.0f, 0.0f, 0.0f};
GLboolean gDolly = GL_FALSE, gPan = GL_FALSE, gTrackball = GL_FALSE;
BasicOpenGLView * gTrackingViewInfo = NULL;

// time and message info
CFAbsoluteTime gMsgPresistance = 10.0f;

// error output
//GLString * gErrStringTex;
float gErrorTime;

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

void DebugLog(const char* str)
{
//	NSLog(@"%@\n", [NSString stringWithUTF8String:str]);
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
	GLdouble ratio, radians, wd2;
	GLdouble left, right, top, bottom, near, far;

    [[self openGLContext] makeCurrentContext];

	// set projection
	glMatrixMode (GL_PROJECTION);
	glLoadIdentity ();
	near = -camera.viewPos.z - shapeSize * 0.5;
	if (near < 0.00001)
		near = 0.00001;
	far = -camera.viewPos.z + shapeSize * 0.5;
	if (far < 1.0)
		far = 1.0;
	radians = 0.0174532925 * camera.aperture / 2; // half aperture degrees to radians 
	wd2 = near * tan(radians);
	ratio = camera.viewWidth / (float) camera.viewHeight;
	if (ratio >= 1.0) {
		left  = -ratio * wd2;
		right = ratio * wd2;
		top = wd2;
		bottom = -wd2;	
	} else {
		left  = -wd2;
		right = wd2;
		top = wd2 / ratio;
		bottom = -wd2 / ratio;	
	}
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
	else {
	}
	// accumlated world rotation via trackball
	glRotatef (worldRotation[0], worldRotation[1], worldRotation[2], worldRotation[3]);
	// object itself rotating applied after camera rotation
	glRotatef (objectRotation[0], objectRotation[1], objectRotation[2], objectRotation[3]);
	cubeSpin[0].rotation = 0.0f; // reset animation rotations (do in all cases to prevent rotating while moving with trackball)
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

#pragma mark ---- IB Actions ----

-(IBAction) animate: (id) sender
{
	fAnimate = 1 - fAnimate;
	if (fAnimate)
		[animateMenuItem setState: NSOnState];
	else 
		[animateMenuItem setState: NSOffState];
}

// ---------------------------------

    // Dump logs and debug info to the console.
-(IBAction) info: (id) sender
{
    EntityDump();
}

-(IBAction) toggleWireframe: (id) sender
{
	fWireframe = 1 - fWireframe;
	[wireframeToggleMenuItem setState:fWireframe ? NSOnState : NSOffState];
	RenderWireframeToggle();
}

-(IBAction) nextEffect:      (id) sender
{
	RenderEffectCycle();
}

-(IBAction) toggleLetterbox: (id) sender
{
	fLetterbox = 1 - fLetterbox;
	[letterboxToggleMenuItem setState:fWireframe ? NSOnState : NSOffState];
	RenderLetterboxToggle();
	NSRect bounds = [self bounds];
	AppResize(bounds.size.width, bounds.size.height);
}

-(IBAction) toggleFPS:       (id) sender
{
	// PAW disabled until I can get text working again.
}

-(IBAction) toggleFog:       (id) sender
{
	fFog = 1 - fFog;
	[fogToggleMenuItem setState:fFog ? NSOnState : NSOffState];
	RenderFogToggle();
}

-(IBAction) toggleFlat:      (id) sender
{
	fFlat = 1 - fFlat;
	[flatToggleMenuItem setState:fFlat ? NSOnState : NSOffState];
	RenderFlatToggle();
}

-(IBAction) toggleHelp:      (id) sender
{
	// PAW disabled until I can get text working again.
}

#pragma mark ---- Method Overrides ----

// ---------------------------------

- (void) drawRect:(NSRect)rect
{		
	glReportError("drawRect:Beginning");
	// setup viewport and prespective
//	[self resizeGL]; // forces projection matrix update (does test for size changes)
//	[self updateModelView];  // update model view matrix for object

	NSRect r = [self bounds];
	AppUpdate(r.size.width, r.size.height);
	glReportError("drawRect:After AppUpdate");

	if ([self inLiveResize] && !fAnimate)
		glFlush();
	else
		[[self openGLContext] flushBuffer];
	glReportError("drawRect:End");
}

// ---------------------------------

// set initial OpenGL state (current context is set)
// called after context is created
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
// ---------------------------------

// this can be a troublesome call to do anything heavyweight, as it is called on window moves, resizes, and display config changes.  So be
// careful of doing too much here.
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
	NSOpenGLPixelFormat * pf = [BasicOpenGLView basicPixelFormat];

	self = [super initWithFrame: frameRect pixelFormat: pf];
    return self;
}

// ---------------------------------

- (BOOL)acceptsFirstResponder
{
  return YES;
}

// ---------------------------------

- (BOOL)becomeFirstResponder
{
  return  YES;
}

// ---------------------------------

- (BOOL)resignFirstResponder
{
  return YES;
}

// ---------------------------------

- (void) awakeFromNib
{
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


@end
