#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>

#import "GLString.h"

typedef struct {
   GLdouble x,y,z;
} Vector3;

typedef struct {
	Vector3 viewPos;    // View position
	Vector3 viewDir;    // View direction vector
	Vector3 viewUp;     // View up direction
	Vector3 rotPoint;   // Point to rotate about
	GLdouble aperture; // pContextInfo->camera aperture
	GLint viewWidth, viewHeight; // current window/screen height and width
} Camera;

typedef struct {
	GLfloat rotation, velocity, acceleration;
} Spin;	// Spin variables for one object along one axis.

@interface BasicOpenGLView : NSOpenGLView <NSWindowDelegate>
{
	CFAbsoluteTime msgTime; // message posting time for expiration

	NSTimer* timer;
 
    bool fAnimate, fDrawCaps, fDrawHelp;
	bool fWireframe, fLetterbox, fFPS, fFog, fFlat, fHelp, fNormalize;
	
	__weak IBOutlet NSMenuItem * animateMenuItem;
	__weak IBOutlet NSMenuItem * infoMenuItem;
	__weak IBOutlet NSMenuItem * resetMenuItem; 
	__weak IBOutlet NSMenuItem * wireframeToggleMenuItem;
	__weak IBOutlet NSMenuItem * effectCycleMenuItem;
	__weak IBOutlet NSMenuItem * letterboxToggleMenuItem;
	__weak IBOutlet NSMenuItem * FPSToggleMenuItem;
	__weak IBOutlet NSMenuItem * fogToggleMenuItem;
	__weak IBOutlet NSMenuItem * flatToggleMenuItem;
	__weak IBOutlet NSMenuItem * helpToggleMenuItem;
    __weak IBOutlet NSMenuItem * normalizeToggleMenuItem;
    __weak IBOutlet NSMenuItem * debugLogToggleMenuItem;
	
	CFAbsoluteTime time;

	Spin cubeSpin[3];	// spin data, for X, Y, Z axes respectively.
        // camera handling
	Camera camera;
	GLfloat worldRotation[4], objectRotation[4], shapeSize;
}

+ (NSOpenGLPixelFormat*) basicPixelFormat;

- (void) updateProjection;
- (void) updateModelView;
- (void) resizeGL;
- (void) resetCamera;

- (void) updateObjectRotationForTimeDelta:(CFAbsoluteTime)deltaTime;
- (void)animationTimer:(NSTimer *)timer;

// Menu action events.
-(IBAction) animate:         (id) sender;
-(IBAction) info:            (id) sender;
-(IBAction) toggleWireframe: (id) sender;
-(IBAction) nextEffect:      (id) sender;
-(IBAction) toggleLetterbox: (id) sender;
-(IBAction) toggleFPS:       (id) sender;
-(IBAction) toggleFog:       (id) sender;
-(IBAction) toggleFlat:      (id) sender;
-(IBAction) toggleHelp:      (id) sender;
-(IBAction) toggleNormalized:(id) sender;
-(IBAction) toggleDebugLog:  (id) sender;

- (void) drawRect:(NSRect)rect;

- (void) prepareOpenGL;
- (void) update;		// moved or resized

- (BOOL) acceptsFirstResponder;
- (BOOL) becomeFirstResponder;
- (BOOL) resignFirstResponder;

- (id) initWithFrame: (NSRect) frameRect;
- (void) awakeFromNib;

@end
