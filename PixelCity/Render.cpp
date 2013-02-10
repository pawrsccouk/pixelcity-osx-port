/*-----------------------------------------------------------------------------
 
 Render.cpp
 
 2009 Shamus Young
 
 -------------------------------------------------------------------------------
 
 This is the core of the gl rendering functions.  This contains the main 
 rendering function RenderUpdate (), which initiates the various 
 other renders in the other modules. 
 
 -----------------------------------------------------------------------------*/


#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdarg.h>
#include <math.h>
#include <string.h> 
#include <iostream>

#include <OpenGL/gl.h>
#include <OpenGL/glu.h>

#include "gltypes.h"
#include "entity.h"
#include "car.h"
#include "camera.h"
#include "ini.h"
#include "light.h"
#include "macro.h"
#include "math.h"
#include "render.h"
#include "sky.h"
#include "texture.h"
#include "world.h"
#include "PWGL.h"
#include "win.h"
#include "RenderAPI.h"

static const int    RENDER_DISTANCE  =   1280;
static const int    MAX_TEXT         =   256;
static const int    COLOR_CYCLE_TIME =   10000;			//milliseconds
static const int    COLOR_CYCLE      =   (COLOR_CYCLE_TIME / 4);
static const int    FONT_SIZE        =   (LOGO_PIXELS - LOGO_PIXELS / 8);
static const float  BLOOM_SCALING    =     0.07f;


//#define YOUFAIL(message)    {WinPopup (message);return;}
/*
 static	PIXELFORMATDESCRIPTOR pfd =			
 {
 sizeof(PIXELFORMATDESCRIPTOR),			
 1,											  // Version Number
 PFD_DRAW_TO_WINDOW |			// Format Must Support Window
 PFD_SUPPORT_OPENGL |			// Format Must Support OpenGL
 PFD_DOUBLEBUFFER,					// Must Support Double Buffering
 PFD_TYPE_RGBA,						// Request An RGBA Format
 32,										    // Select Our glRgbaDepth
 0, 0, 0, 0, 0, 0,					// glRgbaBits Ignored
 0,											  // No Alpha Buffer
 0,											  // Shift Bit Ignored
 0,											  // Accumulation Buffers
 0, 0, 0, 0,								// Accumulation Bits Ignored
 16,											  // Z-Buffer (Depth Buffer)  bits
 0,											  // Stencil Buffers
 1,											  // Auxiliary Buffers
 PFD_MAIN_PLANE,						// Main Drawing Layer
 0,											  // Reserved
 0, 0, 0										// Layer Masks Ignored
 };
 */

static const char g_help[] = 
"ESC - Exit!\n" 
"F1  - Show this help screen\n" 
"R   - Rebuild city\n" 
"L   - Toggle 'letterbox' mode\n"
"F   - Show Framecounter\n"
"W   - Toggle Wireframe\n"
"E   - Change full-scene effects\n"
"T   - Toggle Textures\n"
"G   - Toggle Fog\n";

static const size_t HELP_SIZE = sizeof(g_help);

struct glFont
{
	const char* name;
	unsigned	  base_char;
};

glFont g_fonts[] = 
{
	"Courier New",      0,
	"Arial",            0,
	"Times New Roman",  0,
	"Arial Black",      0,
	"Impact",           0,
	"Agency FB",        0,
	"Book Antiqua",     0,
};

static const size_t FONT_COUNT = (sizeof(g_fonts) / sizeof(g_fonts[0]));


enum EffectType
{
	EFFECT_NONE,
	EFFECT_BLOOM,
	EFFECT_BLOOM_RADIAL,
	EFFECT_COLOR_CYCLE,
	EFFECT_GLASS_CITY,
	EFFECT_DEBUG,
	EFFECT_DEBUG_OVERBLOOM,
    
	EFFECT_COUNT,
};

static float g_render_aspect;
static float g_fog_distance;
static int   g_render_width;
static int   g_render_height;
static bool  g_letterbox;
static int   g_letterbox_offset;
static EffectType g_effect;

//static unsigned         g_next_fps;

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

/*-----------------------------------------------------------------------------
 
 -----------------------------------------------------------------------------*/

static void FadeDisplay(float fade)
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

static void UpdateProgress(float fade)
{
    int radius = g_render_width / 16;
    do_progress ((float)g_render_width / 2, (float)g_render_height / 2, (float)radius, fade, EntityProgress ());
    RenderPrint (g_render_width / 2 - LOGO_PIXELS, g_render_height / 2 + LOGO_PIXELS, 0, glRgba (0.5f), "%1.2f%%", EntityProgress () * 100.0f);
    RenderPrint (1, "%s v%d.%d.%03d", APP_TITLE, VERSION_MAJOR, VERSION_MINOR, VERSION_REVISION);
}

static void DrawDebugEffect()
{
    pwBindTexture(GL_TEXTURE_2D, TextureId(TEXTURE_LOGOS));
    pwDisable (GL_BLEND);
    MakePrimitive mp(GL_QUADS);
    glColor3f (1.0f, 1.0f, 1.0f);
    glTexCoord2f (0.0f, 0.0f);  glVertex2i (0, g_render_height / 4);
    glTexCoord2f (0.0f, 1.0f);  glVertex2i (0, 0);
    glTexCoord2f (1.0f, 1.0f);  glVertex2i (g_render_width / 4, 0);
    glTexCoord2f (1.0f, 0.0f);  glVertex2i (g_render_width / 4, g_render_height / 4);
    
    glTexCoord2f (0.0f, 0.0f);  glVertex2i (0, 512);
    glTexCoord2f (0.0f, 1.0f);  glVertex2i (0, 0);
    glTexCoord2f (1.0f, 1.0f);  glVertex2i (512, 0);
    glTexCoord2f (1.0f, 0.0f);  glVertex2i (512, 512);
}

	//Psychedelic bloom
static void DrawBloomRadialEffect()
{
    pwEnable (GL_BLEND);
    MakePrimitive mp(GL_QUADS);
    GLrgba color = WorldBloomColor () * BLOOM_SCALING * 2;
    glColor3(color);
    for (int i = 0; i <= 100; i+=10) {
        glTexCoord2f (0, 0);  glVertex2i (-i, i + g_render_height);
        glTexCoord2f (0, 1);  glVertex2i (-i, -i);
        glTexCoord2f (1, 1);  glVertex2i (i + g_render_width, -i);
        glTexCoord2f (1, 0);  glVertex2i (i + g_render_width, i + g_render_height);
    }
}

	//Oooh. Pretty colors.  Tint the scene according to screenspace.
static void DrawColorCycleEffect()
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
    glColor3(color);
    glTexCoord2f (0, 0);  glVertex2i (0, g_render_height);
    color = glRgbaFromHsl (hue2, 1.0f, 0.6f);
    glColor3(color);
    glTexCoord2f (0, 1);  glVertex2i (0, 0);
    color = glRgbaFromHsl (hue3, 1.0f, 0.6f);
    glColor3(color);
    glTexCoord2f (1, 1);  glVertex2i (g_render_width, 0);
    color = glRgbaFromHsl (hue4, 1.0f, 0.6f);
    glColor3(color);
    glTexCoord2f (1, 0);  glVertex2i (g_render_width, g_render_height);
}

	//Simple bloom effect
static void DrawBloomEffect()
{
    MakePrimitive mp(GL_QUADS);
    GLrgba color = WorldBloomColor () * BLOOM_SCALING;
    glColor3(color);
	int bloom_radius = 15, bloom_step  = bloom_radius / 3;
    for (int x = -bloom_radius; x <= bloom_radius; x += bloom_step) {
        for (int y = -bloom_radius; y <= bloom_radius; y += bloom_step) {
            if (abs (x) == abs(y) && x)
                continue;
            glTexCoord2f (0, 0);  glVertex2i (x, y + g_render_height);
            glTexCoord2f (0, 1);  glVertex2i (x, y);
            glTexCoord2f (1, 1);  glVertex2i (x + g_render_width, y);
            glTexCoord2f (1, 0);  glVertex2i (x + g_render_width, y + g_render_height);
        }
    }
}

	//This will punish that uppity GPU. Good for testing low frame rate behavior.
static void DrawDebugOverbloomEffect()
{
    MakePrimitive mp(GL_QUADS);
    GLrgba color = WorldBloomColor () * 0.01f;
    glColor3(color);
    for (int x = -50; x <= 50; x+=5) {
        for (int y = -50; y <= 50; y+=5) {
            glTexCoord2f (0, 0);  glVertex2i (x, y + g_render_height);
            glTexCoord2f (0, 1);  glVertex2i (x, y);
            glTexCoord2f (1, 1);  glVertex2i (x + g_render_width, y);
            glTexCoord2f (1, 0);  glVertex2i (x + g_render_width, y + g_render_height);
        }
    }
}

static void do_effects(EffectType type)
{
	DebugRep dbr("do_effects");
	DebugLog("type=%d", type);
	
	GLrgba          color;
	
	if (!TextureReady ())
		return;

        //Now change projection modes so we can render full-screen effects
	pwMatrixMode (GL_PROJECTION);
	pwPushMatrix ();
	pwLoadIdentity ();
	glOrtho (0, g_render_width, g_render_height, 0, 0.1f, 2048);
    
	pwMatrixMode (GL_MODELVIEW);
	pwPushMatrix ();
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
		case EFFECT_DEBUG:            DrawDebugEffect();            break;
		case EFFECT_BLOOM_RADIAL:     DrawBloomRadialEffect();      break;
		case EFFECT_COLOR_CYCLE:      DrawColorCycleEffect();       break;
		case EFFECT_BLOOM:            DrawBloomEffect();            break;
		case EFFECT_DEBUG_OVERBLOOM:  DrawDebugOverbloomEffect(); 	break;
        default:
            break;
	}
    
	//Do the fade to / from darkness used to hide scene transitions
	if (LOADING_SCREEN) {
        float fade = WorldFade ();
		if (fade > 0.0f)
            FadeDisplay(fade);

		if (TextureReady () && !EntityReady () && fade != 0.0f)
            UpdateProgress(fade);
	}
	pwPopMatrix ();
	pwMatrixMode (GL_PROJECTION);
	pwPopMatrix ();
	pwMatrixMode (GL_MODELVIEW);
	pwEnable(GL_DEPTH_TEST);
}


/*------------------------------------------------------------------------------------------------------------------------------------------------------*/

int RenderMaxTextureSize ()
{
	GLint mts;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &mts);	glReportError("glGetIntegerv");
	return std::min(mts, std::min(g_render_width, g_render_height));
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderPrint (int x, int y, int font, GLrgba color, const char *fmt, ...)				
{
//	return;	// PAW - these are causing stack overflow errors. Enable later, or use the better ones in the Cocoa sample code.
	if (fmt == NULL)
		return;						
	DebugRep dbr("RenderPrint");
	
	char text[MAX_TEXT] = {'\0'};	
	{
		va_list ap;
		va_start (ap, fmt);		
		vsprintf (text, fmt, ap);				
		va_end (ap);
	}
	pwPushAttrib(GL_LIST_BIT);
	glListBase(g_fonts[font % FONT_COUNT].base_char - 32);				
	glColor3(color);
	glRasterPos2i (x, y);
	glCallLists(GLsizei(strlen(text)), GL_UNSIGNED_BYTE, text);
    pwPopAttrib();
}

/*------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderPrint (int line, const char *fmt, ...)				
{
//	return;	// PAW - these cause stack overflow errors, re-enable later or use the better ones in the Cocoa sample code.
	if (fmt == NULL)
		return;						

	DebugRep dbr("RenderPrint");

	char text[MAX_TEXT] = {'\0'};	
	{
		va_list ap;
		va_start (ap, fmt);		
		vsprintf (text, fmt, ap);				
		va_end (ap);
	}
	
	pwMatrixMode (GL_PROJECTION);
	pwPushMatrix ();
	pwLoadIdentity ();
	glOrtho (0, g_render_width, g_render_height, 0, 0.1f, 2048);	glReportError("glOrtho");
	pwDisable(GL_DEPTH_TEST);
	pwDepthMask (GL_FALSE);	
	pwMatrixMode (GL_MODELVIEW);
	pwPushMatrix ();
	pwLoadIdentity();
	pwTranslatef(0, 0, -1.0f);
	pwDisable(GL_BLEND);
	pwDisable(GL_FOG);
	pwDisable(GL_TEXTURE_2D);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	RenderPrint (0, line * FONT_SIZE - 2, 0, glRgba (0.0f), text);
	RenderPrint (4, line * FONT_SIZE + 2, 0, glRgba (0.0f), text);
	RenderPrint (2, line * FONT_SIZE, 0, glRgba (1.0f), text);
	glPopAttrib();							glReportError("glPopAttrib");
	pwPopMatrix ();
	pwMatrixMode (GL_PROJECTION);
	pwPopMatrix ();
	pwMatrixMode (GL_MODELVIEW);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void static do_help (void)
{
	char parse[HELP_SIZE] = {'\0'}; 
	strcpy (parse, g_help);
	char *text = strtok (parse, "\n");
	int line = 0;
	while (text) {
		RenderPrint (line + 2, text);
		text = strtok (NULL, "\n");
		line++;
	}
	
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void do_fps ()
{
    unsigned long interval = 1000;
    static unsigned long next_update = 0;
    if (next_update > GetTickCount())
        return;
    next_update = GetTickCount() + interval;

	g_current_fps = g_frames;
	g_frames = 0;	
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

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

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderTerm (void)
{
	/*  Let NSOpenGLView handle this.
	 if (!hRC)
	 return;
	 wglDeleteContext (hRC);
	 hRC = NULL;
	 */
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderInit (int width, int height)
{
	DebugLog("RenderInit");
	/*
	 unsigned		  PixelFormat;
	 hWnd = WinHwnd ();
	 if (!(hDC = GetDC (hWnd))) 
	 YOUFAIL ("Can't Create A GL Device Context.") ;
	 if (!(PixelFormat = ChoosePixelFormat(hDC,&pfd)))
	 YOUFAIL ("Can't Find A Suitable PixelFormat.") ;
	 if(!SetPixelFormat(hDC,PixelFormat,&pfd))
	 YOUFAIL ("Can't Set The PixelFormat.");
	 if (!(hRC = wglCreateContext (hDC)))	
	 YOUFAIL ("Can't Create A GL Rendering Context.");
	 if(!wglMakeCurrent(hDC,hRC))	
	 YOUFAIL ("Can't Activate The GL Rendering Context.");
	 */
	
	//Load the fonts for printing debug info to the window.
	/*
	 HFONT	          font, oldfont;
	 for (int i = 0; i < FONT_COUNT; i++) {
	 fonts[i].base_char = glGenLists(96); 
	 font = CreateFont (FONT_SIZE,	0, 0,	0,	
	 FW_BOLD, false,	false, false,	DEFAULT_CHARSET,	OUT_TT_PRECIS,		
	 CLIP_DEFAULT_PRECIS,	ANTIALIASED_QUALITY, FF_DONTCARE|DEFAULT_PITCH,
	 fonts[i].name);
	 oldfont = (HFONT)SelectObject(hDC, font);	
	 wglUseFontBitmaps(hDC, 32, 96, fonts[i].base_char);
	 SelectObject(hDC, oldfont);
	 DeleteObject(font);		
	 }
	 */
     
    g_effect         = EffectType(IniInt("Effect"));
    g_fog_distance   = WORLD_HALF;

        //clear the viewport so the user isn't looking at trash while the program starts
	pwViewport (0, 0, width, height);
	pwClearColor (0.0f, 0.0f, 0.0f, 1.0f);
	pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderSetFPS(bool showFPS)
{
	g_show_fps = showFPS;
	IniIntSet ("ShowFPS", g_show_fps ? 1 : 0);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

bool RenderFog () {	return g_show_fog;	}

void RenderSetFog(bool fog)
{	
	g_show_fog = fog;
	IniIntSet ("ShowFog", g_show_fog ? 1 : 0);
}

float RenderFogDistance () { return g_fog_distance; }

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

extern "C" void RenderSetNormalized(bool norm)
{
    g_show_normalized = norm;
    IniIntSet("ShowNormalized", g_show_normalized ? 1 : 0);
}
/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

extern "C" void RenderSetLetterbox(bool letterbox)
{
	g_letterbox = letterbox;
	IniIntSet ("Letterbox", g_letterbox ? 1 : 0);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


bool RenderWireframe () {  return g_show_wireframe;	}

void RenderSetWireframe(bool wireframe)
{	
	g_show_wireframe = wireframe;
	IniIntSet ("Wireframe", g_show_wireframe ? 1 : 0);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

bool RenderFlat () { return g_flat;	}

void RenderSetFlat(bool flat)
{
	g_flat = flat;
	IniIntSet ("Flat", g_flat ? 1 : 0);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderSetHelpMode(bool helpMode)
{
	g_show_help = helpMode;
        // This is transient and always defaults to Off.
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderEffectCycle ()
{
	g_effect = EffectType((g_effect + 1) % EFFECT_COUNT);
	IniIntSet ("Effect", g_effect);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

bool RenderBloom ()
{
	return g_effect == EFFECT_BLOOM || g_effect == EFFECT_BLOOM_RADIAL 
    || g_effect == EFFECT_DEBUG_OVERBLOOM || g_effect == EFFECT_COLOR_CYCLE;
}


/*-----------------------------------------------------------------------------
 This is used to set a gradient fog that goes from camera to some portion of the normal fog distance.  This is used for making wireframe outlines and
 flat surfaces fade out after rebuild.  Looks cool.
 -----------------------------------------------------------------------------*/

void RenderFogFX (float scalar)
{
	if (scalar >= 1.0f) {
		pwDisable (GL_FOG);
		return;
	}
	pwFogf (GL_FOG_START, 0.0f);
	pwFogf (GL_FOG_END, g_fog_distance * 2.0f * scalar);
	pwEnable (GL_FOG);
}

static void FogRender()
{
    pwEnable (GL_FOG);
    pwFogf (GL_FOG_START, g_fog_distance - 100);
    pwFogf (GL_FOG_END  , g_fog_distance);
    float red = glRgba(0.0f).red();
    pwFogfv(GL_FOG_COLOR, &red);
}

static void SetupGlassCityEffect(const GLvector &pos)
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

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void RenderUpdate (int width, int height)		
{
	g_render_width  = width;
	g_render_height = height;
	g_frames++;
	do_fps();
    
	pwViewport (0, 0, width, height);
	pwDepthMask (GL_TRUE);
	pwClearColor (0.0f, 0.0f, 0.0f, 1.0f);
	pwEnable(GL_DEPTH_TEST);
	pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
	if (g_letterbox) 
		pwViewport (0, g_letterbox_offset, g_render_width, g_render_height);
    
	if (LOADING_SCREEN && TextureReady () && !EntityReady ()) {
		do_effects (EFFECT_NONE);
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
	GLvector pos   = CameraPosition();
	GLvector angle = CameraAngle();
	pwRotatef (angle.x, 1.0f, 0.0f, 0.0f);
	pwRotatef (angle.y, 0.0f, 1.0f, 0.0f);
	pwRotatef (angle.z, 0.0f, 0.0f, 1.0f);
	pwTranslatef (-pos.x, -pos.y, -pos.z);
	pwEnable (GL_TEXTURE_2D);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    
        //Render all the stuff in the whole entire world.
	pwDisable (GL_FOG);
	SkyRender ();
	if (g_show_fog)
        FogRender();

	WorldRender ();
	if (g_effect == EFFECT_GLASS_CITY) {
        SetupGlassCityEffect(pos);
	} else {
		pwEnable (GL_CULL_FACE);
		pwDisable (GL_BLEND);
	}
    
        // Enable or disable the normalization. This adds extra calculations but prevents errors where
        // adding scaling to the model matrix causes the lighting to be too dark.
    (g_show_normalized ? glEnable : glDisable)(GL_NORMALIZE);
    
	EntityRender ();
	if (!LOADING_SCREEN) {
		long elapsed = 3000 - WorldSceneElapsed();
		if (elapsed >= 0 && elapsed <= 3000) {
			RenderFogFX(float(elapsed) / 3000.0f);
			pwDisable(GL_TEXTURE_2D);
			pwEnable(GL_BLEND);
			pwBlendFunc(GL_ONE, GL_ONE);
			EntityRender();
		}
	} 
	if (EntityReady ())
		LightRender ();

	CarRender ();

	if (RenderWireframe()) {
		pwDisable (GL_TEXTURE_2D);
		pwPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		EntityRender ();
	}

	do_effects(g_effect);
    
	if (g_show_fps)     //Framerate tracker
		RenderPrint (1, "FPS=%d : Entities=%d : polys=%d",
                     g_current_fps, EntityCount () + LightCount () + CarCount (),
                     EntityPolyCount () + LightCount () + CarCount ());
    
	if (g_show_help)    //Show the help overlay
		do_help ();
}
