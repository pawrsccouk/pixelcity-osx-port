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
#import "sky.h"
#import "texture.h"
#import "world.h"
#import "Visible.h"
#import "Win.h"
#import "RenderAPI.h"

static const int   LOGO_RESOLUTION      = 512;
static const int   LOGO_ROWS            = 16;
static const float LOGO_PIXELS          = (LOGO_RESOLUTION / LOGO_ROWS);

static const int    RENDER_DISTANCE  =   1280;
static const int    MAX_TEXT         =   256;
static const int    COLOR_CYCLE_TIME =   10000;			//milliseconds
static const int    COLOR_CYCLE      =   (COLOR_CYCLE_TIME / 4);
static const int    FONT_SIZE        =   (LOGO_PIXELS - LOGO_PIXELS / 8);
static const float  BLOOM_SCALING    =     0.07f;

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

static const size_t HELP_SIZE = sizeof(g_help);

static float g_render_aspect, g_fog_distance;
static int   g_render_width, g_render_height, g_letterbox_offset;
static bool  g_letterbox;
static EffectType g_effect = EFFECT_NONE;
static bool g_terminating = false;

static unsigned g_current_fps, g_frames;
static bool g_show_wireframe, g_flat, g_show_fps, g_show_fog, g_show_help, g_show_normalized;

/*-----------------------------------------------------------------------------
 
 Draw a clock-ish progress.. widget... thing.  It's cute.
 
 -----------------------------------------------------------------------------*/

static void do_progress (float center_x, float center_y, float radius, float opacity, float progress)
{
	DebugRep dbr("do_progress");
	
	//Outer Ring
	float gap = radius * 0.05f;
	float outer = radius;
	float inner = radius - gap * 2;
	glColor4f (1,1,1, opacity);
	{	MakePrimitive mp(GL_QUAD_STRIP);
		for (int i = 0; i <= 360; i+= 15) {
			float angle = (float)i * DEGREES_TO_RADIANS;
			float s = sinf (angle);
			float c = -cosf (angle);
			glVertex2f (center_x + s * outer, center_y + c * outer);
			glVertex2f (center_x + s * inner, center_y + c * inner);
		}
	}
	
	//Progress indicator
	glColor4f (1,1,1, opacity);
	int end_angle = (int)(360 * progress);
	outer = radius - gap * 3;
	{	MakePrimitive mp(GL_TRIANGLE_FAN);
		glVertex2f (center_x, center_y);
		for (int i = 0; i <= end_angle; i+= 3) {
			float angle = (float)i * DEGREES_TO_RADIANS;
			float s = sinf (angle);
			float c = -cosf (angle);
			glVertex2f (center_x + s * outer, center_y + c * outer);
		}
	}
	
	//Tic lines
	pwLineWidth (2.0f);
	outer = radius - gap * 1;
	inner = radius - gap * 2;
	glColor4f (0,0,0, opacity);
	{	MakePrimitive mp(GL_LINES);
		for (int i = 0; i <= 360; i+= 15) {
			float angle = (float)i * DEGREES_TO_RADIANS;
			float s = sinf (angle);
			float c = -cosf (angle);
			glVertex2f (center_x + s * outer, center_y + c * outer);
			glVertex2f (center_x + s * inner, center_y + c * inner);
		}
	}
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark - effects

    // This is used to set a gradient fog that goes from camera to some portion of the normal fog distance.
    // This is used for making wireframe outlines and flat surfaces fade out after rebuild.  Looks cool.
static void drawFogFX(float scalar)
{
	if (scalar >= 1.0f) {
		pwDisable (GL_FOG);
		return;
	}
	pwFogf (GL_FOG_START, 0.0f);
	pwFogf (GL_FOG_END, g_fog_distance * 2.0f * scalar);
	pwEnable (GL_FOG);
}

static void drawFog()
{
    pwEnable (GL_FOG);
    pwFogf (GL_FOG_START, g_fog_distance - 100);
    pwFogf (GL_FOG_END  , g_fog_distance);
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


static void fadeDisplay(float fade)
{
    pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    pwEnable (GL_BLEND);
    pwDisable (GL_TEXTURE_2D);
    glColor4f (0, 0, 0, fade);
    MakePrimitive mp(GL_QUADS);
    glVertex2i (0, 0);
    glVertex2i (0, g_render_height);
    glVertex2i (g_render_width, g_render_height);
    glVertex2i (g_render_width, 0);
}

static void updateProgress(Entities *entities, float fade)
{
    int radius = g_render_width / 16;
    GLrgba color(0.5f);
    do_progress ((float)g_render_width / 2, (float)g_render_height / 2, (float)radius, fade, entities.progress);
    RenderPrintOverlayText (1, "%s v%d.%d.%03d\n%1.2f%%", APP_TITLE, VERSION_MAJOR, VERSION_MINOR, VERSION_REVISION, entities.progress * 100.0f);
}

static void drawDebugEffect()
{
    const size_t TICK_INTERVAL = 2 * 1000;  // seconds to millis.
    static size_t lastCheck = 0;
    static GLuint lastLogoTex = 0;
    
        // Change the logo every couple of seconds.
    if(GetTickCount() > lastCheck + TICK_INTERVAL) {
        lastCheck = GetTickCount();
        lastLogoTex = TextureRandomLogo();
    }
    float blockHeight = g_render_height / 4.0f, blockWidth = g_render_width / 2.0f;
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
static void drawBloomRadialEffect(const GLrgba &bloomColor)
{
    pwEnable (GL_BLEND);
    MakePrimitive mp(GL_QUADS);
    GLrgba color = bloomColor * BLOOM_SCALING * 2;
    color.glColor3();
    for (int i = 0; i <= 100; i+=10) {
        glTexCoord2f (0, 0);  glVertex2i (-i, i + g_render_height);
        glTexCoord2f (0, 1);  glVertex2i (-i, -i);
        glTexCoord2f (1, 1);  glVertex2i (i + g_render_width, -i);
        glTexCoord2f (1, 0);  glVertex2i (i + g_render_width, i + g_render_height);
    }
}

	//Oooh. Pretty colors.  Tint the scene according to screenspace.
static void drawColorCycleEffect()
{
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
    glTexCoord2f (0, 0);  glVertex2i (0, g_render_height);
    color = glRgbaFromHsl (hue2, 1.0f, 0.6f);
    color.glColor3();
    glTexCoord2f (0, 1);  glVertex2i (0, 0);
    color = glRgbaFromHsl (hue3, 1.0f, 0.6f);
    color.glColor3();
    glTexCoord2f (1, 1);  glVertex2i (g_render_width, 0);
    color = glRgbaFromHsl (hue4, 1.0f, 0.6f);
    color.glColor3();
    glTexCoord2f (1, 0);  glVertex2i (g_render_width, g_render_height);
}

	//Simple bloom effect
static void drawBloomEffect(const GLrgba &bloomColor)
{
    MakePrimitive mp(GL_QUADS);
    GLrgba color = bloomColor * BLOOM_SCALING;
    color.glColor3();
	int bloom_radius = 15, bloom_step  = bloom_radius / 3;
    for (int x = -bloom_radius; x <= bloom_radius; x += bloom_step) {
        for (int y = -bloom_radius; y <= bloom_radius; y += bloom_step) {
            if (abs (x) == abs(y) && x)
                continue;
            glTexCoord2f(0, 0);  glVertex2i(x, y + g_render_height);
            glTexCoord2f(0, 1);  glVertex2i(x, y);
            glTexCoord2f(1, 1);  glVertex2i(x + g_render_width, y);
            glTexCoord2f(1, 0);  glVertex2i(x + g_render_width, y + g_render_height);
        }
    }
}

	//This will punish that uppity GPU. Good for testing low frame rate behavior.
static void drawDebugOverbloomEffect(const GLrgba &bloomColor)
{
    MakePrimitive mp(GL_QUADS);
    GLrgba color = bloomColor * 0.01f;
    color.glColor3();
    for (int x = -50; x <= 50; x+=5) {
        for (int y = -50; y <= 50; y+=5) {
            glTexCoord2f(0, 0);  glVertex2i(x, y + g_render_height);
            glTexCoord2f(0, 1);  glVertex2i(x, y);
            glTexCoord2f(1, 1);  glVertex2i(x + g_render_width, y);
            glTexCoord2f(1, 0);  glVertex2i(x + g_render_width, y + g_render_height);
        }
    }
}

static void doEffects(EffectType type, World *world)
{
    if (!TextureReady ())
		return;
    
        //Now change projection modes so we can render full-screen effects
	pwMatrixMode (GL_PROJECTION);
	{
        PWMatrixStacker pushMatrix;
        pwLoadIdentity ();
        glOrtho (0, g_render_width, g_render_height, 0, 0.1f, 2048);
        
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
            pwBindTexture(GL_TEXTURE_2D, TextureId(TEXTURE_BLOOM));
            
            switch (type) {
                case EFFECT_DEBUG:            drawDebugEffect();            break;
                case EFFECT_BLOOM_RADIAL:     drawBloomRadialEffect(world.bloomColor);      break;
                case EFFECT_COLOR_CYCLE:      drawColorCycleEffect();       break;
                case EFFECT_BLOOM:            drawBloomEffect(world.bloomColor);            break;
                case EFFECT_DEBUG_OVERBLOOM:  drawDebugOverbloomEffect(world.bloomColor); 	break;
                default:
                    break;
            }
            
                //Do the fade to / from darkness used to hide scene transitions
            if(LOADING_SCREEN) {
                float fade = world.fadeCurrent;
                if (fade > 0.0f)
                    fadeDisplay(fade);
                
                if (TextureReady () && ! world.entities.ready && fade != 0.0f)
                    updateProgress(world.entities, fade);
            }
        }
        pwMatrixMode (GL_PROJECTION);
    }
    pwMatrixMode (GL_MODELVIEW);
    pwEnable(GL_DEPTH_TEST);
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark -


int RenderMaxTextureSize ()
{
	GLint mts;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &mts);	glReportError("glGetIntegerv");
	return std::min(mts, std::min(g_render_width, g_render_height));
}




/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void static do_help (void)
{
    RenderPrintOverlayText(1, g_help);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void do_fps ()
{
    GLulong interval = 1000;
    static GLulong next_update = 0;
    if (next_update > GetTickCount())
        return;
    next_update = GetTickCount() + interval;

	g_current_fps = g_frames;
	g_frames = 0;	
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


static bool isBloom()
{
	return g_effect == EFFECT_BLOOM           || g_effect == EFFECT_BLOOM_RADIAL
    || g_effect == EFFECT_DEBUG_OVERBLOOM || g_effect == EFFECT_COLOR_CYCLE;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark - Render External API

void RenderResize (int width, int height)
{
	DebugLog("RenderResize");
	g_render_width  = width;
	g_render_height = height;
	
	if (g_letterbox) {
		g_letterbox_offset = g_render_height / 6;
		g_render_height = g_render_height - g_letterbox_offset * 2;
	}
	else
		g_letterbox_offset = 0;
        //render_aspect = (float)render_height / (float)render_width;
	pwViewport (0, g_letterbox_offset, g_render_width, g_render_height);
	pwMatrixMode (GL_PROJECTION);
	pwLoadIdentity ();
	g_render_aspect = (float)g_render_width / (float)g_render_height;
	float fovy = 60.0f;
	if (g_render_aspect > 1.0f)
		fovy /= g_render_aspect;
	gluPerspective (fovy, g_render_aspect, 0.1f, RENDER_DISTANCE);			glReportError("gluPerspective");
	pwMatrixMode (GL_MODELVIEW);
}

void RenderInit (int width, int height)
{
	DebugLog("RenderInit");
    
    g_fog_distance   = WORLD_HALF;
    
        //clear the viewport so the user isn't looking at trash while the program starts
	pwViewport (0, 0, width, height);    
	pwClearColor (0.0f, 0.0f, 0.0f, 1.0f);
	pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}


void RenderSetFPS(bool showFPS)
{
	g_show_fps = showFPS;
}

bool RenderFog () {	return g_show_fog;	}

void RenderSetFog(bool fog)
{	
	g_show_fog = fog;
}

float RenderFogDistance () { return g_fog_distance; }

extern "C" void RenderSetNormalized(bool norm)
{
    g_show_normalized = norm;
}

extern "C" void RenderSetLetterbox(bool letterbox)
{
	g_letterbox = letterbox;
}

bool RenderWireframe () {  return g_show_wireframe;	}

void RenderSetWireframe(bool wireframe)
{	
	g_show_wireframe = wireframe;
}

bool RenderFlat () { return g_flat;	}

void RenderSetFlat(bool flat)
{
	g_flat = flat;
}

void RenderSetHelpMode(bool helpMode)
{
	g_show_help = helpMode;
        // This is transient and always defaults to Off.
}

void RenderSetEffect(EffectType type)
{
	g_effect = type;
}

EffectType RenderEffect()
{
    return g_effect;
}

void RenderTerminate()
{
    g_terminating = true;   // Stops all updating and wait for the window to close.
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark -

void RenderUpdate (World *world, int width, int height)
{
    if(g_terminating) return;   // Stop if we are in the process of shutting down.

	g_render_width  = width;
	g_render_height = height;
	g_frames++;
    
	TextureUpdate(world, g_flat, isBloom());
	glReportError("AppUpdate:After TextureUpdate");

	do_fps();
    
	pwViewport (0, 0, width, height);
	pwDepthMask (GL_TRUE);
	pwClearColor (0.0f, 0.0f, 0.0f, 1.0f);
	pwEnable(GL_DEPTH_TEST);
	pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	if (g_letterbox) 
		pwViewport (0, g_letterbox_offset, g_render_width, g_render_height);
    
	if (LOADING_SCREEN && TextureReady () && ! world.entities.ready) {
		doEffects (EFFECT_NONE, world);
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
	GLvector pos = CameraPosition(), angle = CameraAngle();
	pwRotatef (angle.x, 1.0f, 0.0f, 0.0f);
	pwRotatef (angle.y, 0.0f, 1.0f, 0.0f);
	pwRotatef (angle.z, 0.0f, 0.0f, 1.0f);
	pwTranslatef (-pos.x, -pos.y, -pos.z);
	pwEnable (GL_TEXTURE_2D);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    
        //Render all the stuff in the whole entire world.
	pwDisable (GL_FOG);
    
    if(! g_flat)
        SkyRender();
    
	if (g_show_fog)
        drawFog();

	[world render];
    
	if (g_effect == EFFECT_GLASS_CITY) {
        setupGlassCityEffect(pos);
	} else {
		pwEnable (GL_CULL_FACE);
		pwDisable (GL_BLEND);
	}
    
        // Enable or disable the normalization. This adds extra calculations but prevents errors where
        // adding scaling to the model matrix causes the lighting to be too dark.
    (g_show_normalized ? glEnable : glDisable)(GL_NORMALIZE);
    
	[world.entities render:g_flat];
    
	if (!LOADING_SCREEN) {
		GLlong elapsed = 3000 - world.sceneElapsed;
		if (elapsed >= 0 && elapsed <= 3000) {
			drawFogFX(float(elapsed) / 3000.0f);
			pwDisable(GL_TEXTURE_2D);
			pwEnable(GL_BLEND);
			pwBlendFunc(GL_ONE, GL_ONE);
			[world.entities render:g_flat];
		}
	} 
	if (world.entities.ready)
		[world.lights render];

	[world.cars render];

	if (RenderWireframe()) {
		pwDisable (GL_TEXTURE_2D);
		pwPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		[world.entities render:g_flat];
	}

	doEffects(g_effect, world);
    
	if (g_show_fps)     //Framerate tracker
		RenderPrintOverlayText(1, "FPS=%d : Entities=%d : polys=%d",
                               g_current_fps, world.entities.count + world.lights.count + world.cars.count,
                               world.entities.polyCount + world.lights.count + world.cars.count);
    
	if (g_show_help)    //Show the help overlay
		do_help ();
}
