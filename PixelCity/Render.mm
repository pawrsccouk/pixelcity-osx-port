/*-----------------------------------------------------------------------------
 
 Render.cpp
 
 2009 Shamus Young
 
 -------------------------------------------------------------------------------
 
 This is the core of the gl rendering functions.  This contains the main 
 rendering function RenderUpdate (), which initiates the various 
 other renders in the other modules. 
 
 -----------------------------------------------------------------------------*/

#import "Model.h"
#import "entity.h"
#import "car.h"
#import "camera.h"
#import "light.h"
#import "render.h"
#import "texture.h"
#import "world.h"
#import "Visible.h"
#import "Win.h"
#import "GLString.h"


@interface Renderer ()
{
    float _renderAspect, _fogDistance;
    GLint _letterboxOffset;
    BOOL _terminating;
    
    GLuint _currentFPS, _frames;
    NSMutableDictionary *_cachedStrings;
    CGSize _viewSize, _lastSize;
    GLulong _nextUpdate;
}
@end

@implementation Renderer
@synthesize fog, flat, fps, effect, normalized, letterbox, wireframe, helpMode, world = _world;


-(void) updateFps
{
    GLulong interval = 1000;
    if (_nextUpdate > GetTickCount())
        return;
    _nextUpdate = GetTickCount() + interval;

	_currentFPS = _frames;
	_frames = 0;	
}

-(int) maxTextureSize
{
	GLint mts;
	pwGetIntegerv(GL_MAX_TEXTURE_SIZE, &mts);
	return std::min(mts, std::min<GLint>(_viewSize.width, _viewSize.height));
}

-(void) resize:(CGSize) size
{
    static const int RENDER_DISTANCE = 1280;
	_viewSize  = size;
	
	if (self.letterbox) {
		_letterboxOffset = _viewSize.height / 6;
		_viewSize.height = _viewSize.height - _letterboxOffset * 2;
	}
	else
		_letterboxOffset = 0;
	_renderAspect = _viewSize.width / _viewSize.height;
	float fovy = 60.0f;
	if (_renderAspect > 1.0f)
		fovy /= _renderAspect;

	pwViewport (0, _letterboxOffset, _viewSize.width, _viewSize.height);
	pwMatrixMode (GL_PROJECTION);
	pwLoadIdentity ();
	gluPerspective (fovy, _renderAspect, 0.1f, RENDER_DISTANCE);
    glReportError("gluPerspective");
	pwMatrixMode (GL_MODELVIEW);
}

-(id)initWithWorld:(World *)world viewSize:(CGSize)viewSize
{
    self = [super init];
    if(self) {
        _world = world;
        _fogDistance = WORLD_HALF;
        _terminating  = NO;
        self.effect    = EFFECT_NONE;
        _cachedStrings = [NSMutableDictionary dictionary];
        _lastSize      = CGSizeMake(0, 0);
        _nextUpdate    = 0;
        _viewSize      = viewSize;
        
            //clear the viewport so the user isn't looking at trash while the program starts
        pwViewport (0, 0, _viewSize.width, _viewSize.height);
        pwClearColor (0.0f, 0.0f, 0.0f, 1.0f);
        pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    }
    return self;
}



-(float) fogDistance { return _fogDistance; }


-(void) dump
{
    // Not implemented yet.
}


-(void) terminate
{
    _terminating = true;   // Stops all updating and wait for the window to close.
}


#pragma mark -

-(void) update:(CGSize) viewSize
{
    if(_terminating) return;   // Stop if we are in the process of shutting down.

	_viewSize  = viewSize;
	_frames++;
    
    World *world = self.world;
	[world.textures update:world showFlat:self.flat showBloom:isBloom(self.effect)];
	glReportError("AppUpdate:After TextureUpdate");

    [self updateFps];
    
	pwViewport (0, 0, viewSize.width, viewSize.height);
	pwDepthMask (GL_TRUE);
	pwClearColor (0.0f, 0.0f, 0.0f, 1.0f);
	pwEnable(GL_DEPTH_TEST);
	pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	if (self.letterbox)
		pwViewport (0, _letterboxOffset, _viewSize.width, _viewSize.height);
    
	if (LOADING_SCREEN && world.textures.ready && ! world.entities.ready) {
		drawEffects(_viewSize, EFFECT_NONE, world);
		return;
	}
	pwHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	pwShadeModel(GL_SMOOTH);	
	pwFogi (GL_FOG_MODE, GL_LINEAR);
	pwDepthFunc(GL_LEQUAL);
    
	pwEnable (GL_CULL_FACE);
	pwCullFace (GL_BACK);
    
	pwEnable (GL_BLEND);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
	pwMatrixMode (GL_TEXTURE);
	pwLoadIdentity();
    
	pwMatrixMode (GL_MODELVIEW);
	pwHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	pwLoadIdentity();
    
	pwLineWidth (1.0f);
	GLvector pos = world.camera.position, angle = world.camera.angle;
	pwRotatef (angle.x, 1.0f, 0.0f, 0.0f);
	pwRotatef (angle.y, 0.0f, 1.0f, 0.0f);
	pwRotatef (angle.z, 0.0f, 0.0f, 1.0f);
	pwTranslatef (-pos.x, -pos.y, -pos.z);
	pwEnable (GL_TEXTURE_2D);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    
        //Render all the stuff in the whole entire world.
	pwDisable (GL_FOG);
    
    if(! self.flat)
        [world.sky render];
    
	if (self.fog)
        drawFog(_fogDistance);

	[world render];
    
	if (self.effect == EFFECT_GLASS_CITY) {
        setupGlassCityEffect(pos);
	} else {
		pwEnable (GL_CULL_FACE);
		pwDisable (GL_BLEND);
	}
    
        // Enable or disable the normalization. This adds extra calculations but prevents errors where
        // adding scaling to the model matrix causes the lighting to be too dark.
    (self.normalized ? glEnable : glDisable)(GL_NORMALIZE);
    
	[world.entities render:self.flat];
    
	if (!LOADING_SCREEN) {
		GLlong elapsed = 3000 - world.sceneElapsed;
		if (elapsed >= 0 && elapsed <= 3000) {
			drawFogFX(float(elapsed) / 3000.0f, _fogDistance);
			pwDisable(GL_TEXTURE_2D);
			pwEnable(GL_BLEND);
			pwBlendFunc(GL_ONE, GL_ONE);
			[world.entities render:self.flat];
		}
	} 
	if (world.entities.ready)
		[world.lights render];

	[world.cars render];

	if (self.wireframe) {
		pwDisable (GL_TEXTURE_2D);
		pwPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		[world.entities render:self.flat];
	}

	drawEffects(_viewSize, self.effect, world);
    
	if (self.fps)     //Framerate tracker
		[world.renderer printOverlayTextAtLine:1 format:"FPS=%d : Entities=%d : polys=%d",
                               _currentFPS, world.entities.count + world.lights.count + world.cars.count,
                               world.entities.polyCount + world.lights.count + world.cars.count];
    
	if (self.helpMode)    //Show the help overlay
		drawHelp(world.renderer);
}

static const int MAX_CACHED_GL_STRINGS = 100;

-(void)drawOverlayText:(NSString*)overlayText
{
    CGRect bounds = CGRectMake(0, 0, _viewSize.width, _viewSize.height);
    
        // Cache the glString objects by the text, so they don't need to be regenerated each time.
        // The text is mostly boilerplate and there isn't that much of it.
        // May need to revisit this if we start displaying a lot of arbitrary text.
    
    if(_lastSize.width <= 0 || _lastSize.height <= 0)
        _lastSize = bounds.size;
        
            // Clear the cache if the image size has changed or if the cache has gotten too large.
        if( (! CGSizeEqualToSize(_lastSize, bounds.size)) || (_cachedStrings.count > MAX_CACHED_GL_STRINGS) ) {
            [_cachedStrings removeAllObjects];
            _lastSize = { bounds.size.width, bounds.size.height };
        }
    
    GLString *glString = [_cachedStrings objectForKey:overlayText];
    if(! glString) {
        glString = [[GLString alloc] initWithString:overlayText attributes:@{
                    NSForegroundColorAttributeName : [NSColor whiteColor],
                    NSFontAttributeName            : [NSFont fontWithName: @"Helvetica-Bold" size: 14.0f] }
                                          textColor:[NSColor whiteColor]
                                           boxColor:[NSColor clearColor]
                                        borderColor:[NSColor clearColor]];
        
        [glString useDynamicFrame];
        [_cachedStrings setObject:glString forKey:overlayText];
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

-(void) printOverlayTextAtLine:(int)line format:(const char *)fmt, ...
{
        // Find the BasicOpenGLView object we should be drawing into, and pass the message on to that.
        // This is needed to link the objectless C call here to the openGL window.
        // (Note the screensaver creates multiple opengl views, so I can't just use a global to hold one).
    
    NSString *text, *fmtText = [NSString stringWithUTF8String:fmt];
    va_list args;
    va_start(args, fmt);
    @try { text = [[NSString alloc] initWithFormat:fmtText arguments:args]; }
    @finally {  va_end(args); }
    
    [self drawOverlayText:text];
 }

static void drawHelp(Renderer *renderer)
{
    static const char g_help[] =
    "\n"        // Leave space for the FPS display on the top line.
    "H   - Show this help screen\n"
    "R   - Rebuild city\n"
    "L   - Toggle 'letterbox' mode\n"
    "F   - Show Framecounter\n"
    "W   - Toggle Wireframe\n"
    "E   - Change full-scene effects\n"
    "T   - Toggle Textures\n"
    "G   - Toggle Fog";
    
    [renderer printOverlayTextAtLine:1 format:g_help];
}

static BOOL isBloom(EffectType effect)
{
	return effect == EFFECT_BLOOM           || effect == EFFECT_BLOOM_RADIAL
    || effect == EFFECT_DEBUG_OVERBLOOM || effect == EFFECT_COLOR_CYCLE;
}

/*-----------------------------------------------------------------------------
 
 Draw a clock-ish progress.. widget... thing.  It's cute.
 
 -----------------------------------------------------------------------------*/

static void drawProgressWheel(const CGPoint &center, float radius, float opacity, float progress)
{
        //Outer Ring
	float gap = radius * 0.05f;
	float outer = radius;
	float inner = radius - gap * 2;
	glColor4f (1,1,1, opacity);
	{
        MakePrimitive mp(GL_QUAD_STRIP);
		for (int i = 0; i <= 360; i+= 15) {
			float angle = (float)i * DEGREES_TO_RADIANS;
			float s = sinf (angle);
			float c = -cosf (angle);
			glVertex2f (center.x + s * outer, center.y + c * outer);
			glVertex2f (center.x + s * inner, center.y + c * inner);
		}
	}
	
        //Progress indicator
	glColor4f (1,1,1, opacity);
	int end_angle = (int)(360 * progress);
	outer = radius - gap * 3;
	{
        MakePrimitive mp(GL_TRIANGLE_FAN);
		glVertex2f (center.x, center.y);
		for (int i = 0; i <= end_angle; i+= 3) {
			float angle = (float)i * DEGREES_TO_RADIANS;
			float s = sinf (angle);
			float c = -cosf (angle);
			glVertex2f (center.x + s * outer, center.y + c * outer);
		}
	}
	
        //Tic lines
	pwLineWidth (2.0f);
	outer = radius - gap * 1;
	inner = radius - gap * 2;
	glColor4f (0,0,0, opacity);
	{
        MakePrimitive mp(GL_LINES);
		for (int i = 0; i <= 360; i+= 15) {
			float angle = (float)i * DEGREES_TO_RADIANS;
			float s = sinf (angle);
			float c = -cosf (angle);
			glVertex2f (center.x + s * outer, center.y + c * outer);
			glVertex2f (center.x + s * inner, center.y + c * inner);
		}
	}
}


#pragma mark - effects

    // This is used to set a gradient fog that goes from camera to some portion of the normal fog distance.
    // This is used for making wireframe outlines and flat surfaces fade out after rebuild.  Looks cool.
static void drawFogFX(float scalar, float fogDistance)
{
	if (scalar >= 1.0f) {
		pwDisable (GL_FOG);
		return;
	}
	pwFogf (GL_FOG_START, 0.0f);
	pwFogf (GL_FOG_END, fogDistance * 2.0f * scalar);
	pwEnable (GL_FOG);
}

static void drawFog(float fogDistance)
{
    pwEnable (GL_FOG);
    pwFogf (GL_FOG_START, fogDistance - 100);
    pwFogf (GL_FOG_END  , fogDistance);
    float color[4] = { 0.15f, 0.15f, 0.15f, 0.15f };
    pwFogfv(GL_FOG_COLOR, color);
}

static void setupGlassCityEffect(const GLvector &pos)
{
    pwDisable (GL_CULL_FACE);
    pwEnable (GL_BLEND);
    pwBlendFunc (GL_ONE, GL_ONE);
    pwDepthFunc (GL_NEVER);
    pwDisable(GL_DEPTH_TEST);
    pwMatrixMode (GL_TEXTURE);
    pwTranslatef ((pos.x + pos.z) / SEGMENTS_PER_TEXTURE, 0, 0);
    pwMatrixMode (GL_MODELVIEW);
}


static void fadeDisplay(float fade, const CGSize &viewSize)
{
    pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    pwEnable (GL_BLEND);
    pwDisable (GL_TEXTURE_2D);
    glColor4f (0, 0, 0, fade);
    MakePrimitive mp(GL_QUADS);
    glVertex2i (0, 0);
    glVertex2i (0, viewSize.height);
    glVertex2i (viewSize.width, viewSize.height);
    glVertex2i (viewSize.width, 0);
}

static void updateProgress(Entities *entities, float fade, Renderer *renderer, const CGSize &viewSize)
{
    int radius = viewSize.width / 16;
    GLrgba color(0.5f);
    CGPoint viewCenter = CGPointMake(viewSize.width / 2.0f, viewSize.height / 2.0f);
    drawProgressWheel(viewCenter, radius, fade, entities.progress);
    [renderer printOverlayTextAtLine:1 format:"%s v%d.%d.%03d\n%1.2f%%", APP_TITLE, VERSION_MAJOR, VERSION_MINOR, VERSION_REVISION, entities.progress * 100.0f];
}

static void drawDebugEffect(const CGSize &viewSize, World *world)
{
    const size_t TICK_INTERVAL = 2 * 1000;  // seconds to millis.
    static size_t lastCheck = 0;
    static GLuint lastLogoTex = 0;
    
        // Change the logo every couple of seconds.
    if(GetTickCount() > lastCheck + TICK_INTERVAL) {
        lastCheck = GetTickCount();
        lastLogoTex = [world.textures randomLogo];
    }
    float blockHeight = viewSize.height / 4.0f, blockWidth = viewSize.width / 2.0f;
    pwBindTexture(GL_TEXTURE_2D, lastLogoTex);
    pwDisable (GL_BLEND);
    pwBegin(GL_QUADS);
    @try {
        glColor3f (1.0f, 1.0f, 1.0f);
        glTexCoord2f (0.0f, 0.0f);  glVertex2i (0, 0);
        glTexCoord2f (0.0f, 1.0f);  glVertex2i (0, blockHeight);
        glTexCoord2f (1.0f, 1.0f);  glVertex2i (blockWidth, blockHeight);
        glTexCoord2f (1.0f, 0.0f);  glVertex2i (blockWidth, 0);
    }
    @finally { pwEnd(); }
}

	//Psychedelic bloom
static void drawBloomRadialEffect(const CGSize &viewSize, const GLrgba &bloomColor, float bloomScaling )
{
    pwEnable (GL_BLEND);
    MakePrimitive mp(GL_QUADS);
    GLrgba color = bloomColor * bloomScaling * 2;
    color.glColor3();
    for (int i = 0; i <= 100; i+=10) {
        glTexCoord2f (0, 0);  glVertex2i (-i, i + viewSize.height);
        glTexCoord2f (0, 1);  glVertex2i (-i, -i);
        glTexCoord2f (1, 1);  glVertex2i (i + viewSize.width, -i);
        glTexCoord2f (1, 0);  glVertex2i (i + viewSize.width, i + viewSize.height);
    }
}


	//Oooh. Pretty colors.  Tint the scene according to screenspace.
static void drawColorCycleEffect(const CGSize &viewSize)
{
    static const int COLOR_CYCLE_TIME = 10000, COLOR_CYCLE = (COLOR_CYCLE_TIME / 4);    // Milliseconds
    
    float hue1 = (float) (GetTickCount () % COLOR_CYCLE_TIME) / COLOR_CYCLE_TIME;
    float hue2 = (float)((GetTickCount () + COLOR_CYCLE) % COLOR_CYCLE_TIME) / COLOR_CYCLE_TIME;
    float hue3 = (float)((GetTickCount () + COLOR_CYCLE * 2) % COLOR_CYCLE_TIME) / COLOR_CYCLE_TIME;
    float hue4 = (float)((GetTickCount () + COLOR_CYCLE * 3) % COLOR_CYCLE_TIME) / COLOR_CYCLE_TIME;
    pwBindTexture(GL_TEXTURE_2D, 0);
    pwEnable (GL_BLEND);
    pwBlendFunc (GL_ONE, GL_ONE);
    pwBlendFunc (GL_DST_COLOR, GL_SRC_COLOR);
    MakePrimitive mp(GL_QUADS);
    GLrgba color = glRgbaFromHsl (hue1, 1.0f, 0.6f);
    color.glColor3();
    glTexCoord2f (0, 0);  glVertex2i (0, viewSize.height);
    color = glRgbaFromHsl (hue2, 1.0f, 0.6f);
    color.glColor3();
    glTexCoord2f (0, 1);  glVertex2i (0, 0);
    color = glRgbaFromHsl (hue3, 1.0f, 0.6f);
    color.glColor3();
    glTexCoord2f (1, 1);  glVertex2i (viewSize.width, 0);
    color = glRgbaFromHsl (hue4, 1.0f, 0.6f);
    color.glColor3();
    glTexCoord2f (1, 0);  glVertex2i (viewSize.width, viewSize.height);
}

	//Simple bloom effect
static void drawBloomEffect(const CGSize &viewSize, const GLrgba &bloomColor, const float bloomScaling)
{
    MakePrimitive mp(GL_QUADS);
    GLrgba color = bloomColor * bloomScaling;
    color.glColor3();
	int bloom_radius = 15, bloom_step  = bloom_radius / 3;
    for (int x = -bloom_radius; x <= bloom_radius; x += bloom_step) {
        for (int y = -bloom_radius; y <= bloom_radius; y += bloom_step) {
            if (abs (x) == abs(y) && x)
                continue;
            glTexCoord2f(0, 0);  glVertex2i(x, y + viewSize.height);
            glTexCoord2f(0, 1);  glVertex2i(x, y);
            glTexCoord2f(1, 1);  glVertex2i(x + viewSize.width, y);
            glTexCoord2f(1, 0);  glVertex2i(x + viewSize.width, y + viewSize.height);
        }
    }
}

	//This will punish that uppity GPU. Good for testing low frame rate behavior.
static void drawDebugOverbloomEffect(const CGSize &viewSize, const GLrgba &bloomColor)
{
    MakePrimitive mp(GL_QUADS);
    GLrgba color = bloomColor * 0.01f;
    color.glColor3();
    for (int x = -50; x <= 50; x+=5) {
        for (int y = -50; y <= 50; y+=5) {
            glTexCoord2f(0, 0);  glVertex2i(x, y + viewSize.height);
            glTexCoord2f(0, 1);  glVertex2i(x, y);
            glTexCoord2f(1, 1);  glVertex2i(x + viewSize.width, y);
            glTexCoord2f(1, 0);  glVertex2i(x + viewSize.width, y + viewSize.height);
        }
    }
}

static void drawEffects(const CGSize &viewSize, EffectType type, World *world)
{
    if (! world.textures.ready)
		return;
    
        //Now change projection modes so we can render full-screen effects
    static const float  BLOOM_SCALING = 0.07f;
	pwMatrixMode (GL_PROJECTION);
	{
        PWMatrixStacker pushMatrix;
        pwLoadIdentity ();
        glOrtho(0, viewSize.width, viewSize.height, 0, 0.1f, 2048);
        
        pwMatrixMode (GL_MODELVIEW);
        {
            PWMatrixStacker pushMatrix;
            pwLoadIdentity();
            pwTranslatef(0, 0, -1.0f);
            
            pwDisable (GL_CULL_FACE);
            pwDisable (GL_FOG);
            pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
                //Render full-screen effects
            pwBlendFunc (GL_ONE, GL_ONE);
            pwEnable (GL_TEXTURE_2D);
            pwDisable(GL_DEPTH_TEST);
            pwDepthMask (GL_FALSE);
            pwBindTexture(GL_TEXTURE_2D, [world.textures textureId:TEXTURE_BLOOM]);
            
            switch (type) {
                case EFFECT_DEBUG:            drawDebugEffect(viewSize, world);                                  break;
                case EFFECT_BLOOM_RADIAL:     drawBloomRadialEffect(viewSize, world.bloomColor, BLOOM_SCALING);  break;
                case EFFECT_COLOR_CYCLE:      drawColorCycleEffect(viewSize);                                    break;
                case EFFECT_BLOOM:            drawBloomEffect(viewSize, world.bloomColor, BLOOM_SCALING);        break;
                case EFFECT_DEBUG_OVERBLOOM:  drawDebugOverbloomEffect(viewSize, world.bloomColor);              break;
                default:
                    break;
            }
            
                //Do the fade to / from darkness used to hide scene transitions
            if(LOADING_SCREEN) {
                float fade = world.fadeCurrent;
                if (fade > 0.0f)
                    fadeDisplay(fade, viewSize);
                
                if (world.textures.ready && ! world.entities.ready && fade != 0.0f)
                    updateProgress(world.entities, fade, world.renderer, viewSize);
            }
        }
        pwMatrixMode (GL_PROJECTION);
    }
    pwMatrixMode (GL_MODELVIEW);
    pwEnable(GL_DEPTH_TEST);
}


@end

