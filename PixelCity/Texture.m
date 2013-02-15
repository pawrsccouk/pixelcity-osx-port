/*-----------------------------------------------------------------------------
 
 Texture.cpp
 
 2009 Shamus Young
 
 -------------------------------------------------------------------------------
 
 This procedurally builds all of the textures.  
 
 I apologize in advance for the apalling state of this module. It's the victim 
 of iterative and experimental development.  It has cruft, poorly named
 functions, obscure code, poorly named variables, and is badly organized. Even
 the formatting sucks in places. Its only saving grace is that it works.
 
 -----------------------------------------------------------------------------*/

#import <stdlib.h>
#import <stdio.h>
#import <math.h>
#import <memory.h>

#import "texture.h"
//#import "building.h"
#import "camera.h"
#import "car.h"
#import "light.h"
//#import "macro.h"
#import "random.h"
#import "render.h"
#import "sky.h"
#import "world.h"
#import "Entity.h"
#import "win.h"
#import "PWGL.h"
#import "RenderAPI.h"
#import "Mathx.h"
#import "NSColor_OpenGL.h"

static const float LOGO_SIZE            = (1.0f / LOGO_ROWS);
static const int   LANES_PER_TEXTURE    = 8;
static const float LANE_SIZE            = (1.0f / LANES_PER_TEXTURE);
static const int   TRIM_RESOLUTION      = 256;
static const int   TRIM_PIXELS          = (TRIM_RESOLUTION / TRIM_ROWS);
    //#define LANE_PIXELS  (_size / LANES_PER_TEXTURE)

float RANDOM_COLOR_SHIFT(void)  { return (float)(RandomLongR(10)) / 50.0f; }
float RANDOM_COLOR_VAL(void)    { return (float)(RandomLongR(256)) / 256.0f; }
float RANDOM_COLOR_LIGHT(void)  { return (float)(200 + RandomLongR(56)) / 256.0f; }

static const char* prefix[] = 
{
	"i", 
	"Green ",
	"Mega",
	"Super ",
	"Omni",
	"e",
	"Hyper",
	"Global ",
	"Vital", 
	"Next ",
	"Pacific ",
	"Metro",
	"Unity ",
	"G-",
	"Trans",
	"Infinity ", 
	"Superior ",
	"Monolith ",
	"Best ",
	"Atlantic ",
	"First ",
	"Union ",
	"National ",
};

static const char* name[] = 
{
	"Biotic",
	"Info",
	"Data",
	"Solar",
	"Aerospace",
	"Motors",
	"Nano",
	"Online",
	"Circuits",
	"Energy",
	"Med",
	"Robotic",
	"Exports",
	"Security",
	"Systems",
	"Financial",
	"Industrial",
	"Media",
	"Materials",
	"Foods",
	"Networks",
	"Shipping",
	"Tools",
	"Medical",
	"Publishing",
	"Enterprises",
	"Audio",
	"Health",
	"Bank",
	"Imports",
	"Apparel",
	"Petroleum", 
	"Studios",
};

static const char* suffix[] = 
{
	"Corp",
	" Inc.",
	"Co",
	"World",
	".Com",
	" USA",
	" Ltd.",
	"Net",
	" Tech",
	" Labs",
	" Mfg.",
	" UK",
	" Unlimited",
	" One",
	" LLC"
};

//static const size_t  SKY_BANDS     =  sizeof(sky_pos) / sizeof(int)  ;
static const size_t  PREFIX_COUNT  =  sizeof(prefix)  / sizeof(char*);
static const size_t  SUFFIX_COUNT  =  sizeof(suffix)  / sizeof(char*);
static const size_t  NAME_COUNT    =  sizeof(name)    / sizeof(char*);

//@class Texture;

//static Texture*     head = NULL;
static NSMutableArray *allTextures;

static bool         textures_done = false;
static bool         prefix_used[PREFIX_COUNT];
static bool         name_used  [NAME_COUNT];
static bool         suffix_used[SUFFIX_COUNT];
static int          build_time = 0;

@interface Texture : NSObject
{
	TextureType       _texType;
	int               _desired_size;
	int               _half;
	int               _segment_size;

//	Texture*         _next;
}
@property (nonatomic, readonly) unsigned glid;
@property (nonatomic, readonly) int      size;
@property (nonatomic, readonly) TextureType type;
@property (nonatomic, readonly) BOOL ready, masked, mipmap, clamp;

+(id)textureWithType:(TextureType) texType size:(int) size mipmap:(BOOL) mipmap clamp:(BOOL) clamp masked:(BOOL) masked;

-(id)initWithType:(TextureType) texType size:(int) size mipmap:(BOOL) mipmap clamp:(BOOL) clamp masked:(BOOL) masked;
-(void) Clear; // { _ready = false; }
-(void) Rebuild;
-(void) DrawWindows;
-(void) DrawSky;
-(void) DrawHeadlight;
@end

static void glColor3(NSColor *color)
{
    CGFloat r, g, b;
    [color getRed:&r green:&g blue:&b alpha:NULL];
    glColor3f(r, g, b);
}

static void glColor4(NSColor *color)
{
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    glColor4f(r, g, b, a);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void drawrect_simple1 (int left, int top, int right, int bottom, NSColor *color)
{
	glColor3(color);
    pwBegin(GL_QUADS);
    @try {
		glVertex2i (left , top);
		glVertex2i (right, top);
		glVertex2i (right, bottom);
		glVertex2i (left , bottom);
	}
    @finally { pwEnd(); }
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void drawrect_simple2 (int left, int top, int right, int bottom, NSColor *color1, NSColor *color2)
{
	glColor3(color1);
	pwBegin(GL_TRIANGLE_FAN);
    @try {
		glVertex2i( (left + right) / 2, (top + bottom) / 2 );
		glColor3(color2);
		glVertex2i(left, top);
		glVertex2i(right, top);
		glVertex2i(right, bottom);
		glVertex2i(left, bottom);
		glVertex2i(left, top);
	}
    @finally { pwEnd(); }
}


static float averageFromColor(NSColor *color)
{
    CGFloat r, g, b;
    [color getRed:&r green:&g blue:&b alpha:NULL];
    return (r + g + b) / 3.0f;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void drawrect (int left, int top, int right, int bottom, NSColor *color)
{	
	pwDisable(GL_CULL_FACE);
	pwBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	pwEnable(GL_BLEND);
	pwLineWidth(1.0f);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	glColor3(color);
	
	glReportError("drawrect setup done.");

//	// Try and clear any existing errors out of the system before loading the textures.
//	glBegin(GL_POINTS);
//	glEnd();
//	while(glGetError() != GL_NO_ERROR)
//	{
//	}
	
	if (left == right) { //in low resolution, a "rect" might be 1 pixel wide
		pwBegin(GL_LINES);
        @try {
			glVertex2i(left, top);
			glVertex2i(left, bottom);
		}
        @finally { pwEnd(); }
	} 
	if (top == bottom) { //in low resolution, a "rect" might be 1 pixel wide
		pwBegin(GL_LINES);
        @try {
			glVertex2i(left, top);
			glVertex2i(right, top);
		}
        @finally { pwEnd(); }
	} 
	else { // draw one of those fancy 2-dimensional rectangles
		pwBegin(GL_QUADS);
        @try {
			glVertex2i(left, top);
			glVertex2i(right, top);
			glVertex2i(right, bottom);
			glVertex2i(left, bottom);
		}
        @finally { pwEnd(); }
		
		float average   = averageFromColor(color);
		int   potential = (int)(average * 255.0f);
		
		if (average > 0.5f) {
			pwBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            pwBegin(GL_POINTS);
			@try {
				for(int i = left + 1; i < right - 1; i++) {
					for(int j = top + 1; j < bottom - 1; j++) {
						glColor4i(255, 0, RandomIntR(potential), 255);
						float hue = 0.2f + (float)RandomLongR(100) / 300.0f + (float)RandomLongR(100) / 300.0f + (float)RandomLongR(100) / 300.0f;
                        float alpha = (float)RandomLongR(potential) / 144.0f;
						
                        NSColor *colorNoise = [NSColor colorWithDeviceHue:hue saturation:0.3f brightness:0.5f alpha:alpha];
                        CGFloat red, green, blue;
                        [colorNoise getRed:&red green:&green blue:&blue alpha:NULL];
//                        GLrgba color_noise = glRgbaFromHsl(hue, 0.3f, 0.5f).colorWithAlpha();
						
                        glColor4f(RANDOM_COLOR_VAL(), RANDOM_COLOR_VAL(), RANDOM_COLOR_VAL(), alpha);
                        glColor4f(red, green, blue, alpha);
//						glColor4(color_noise);
						glVertex2i(i, j);
					}
				}
			}
            @finally { pwEnd(); }
		}
		int hght = (bottom - top) + (RandomIntR(3) - 1) + (RandomIntR(3) - 1);
		for (int i = left; i < right; i++) {
			if (RandomLongR(6) == 0) {
				hght = bottom - top;
				hght = RandomIntR(hght);
				hght = RandomIntR(hght);
				hght = RandomIntR(hght);
				hght = ((bottom - top) + hght) / 2;
			}
			for (int j = 0; j < 1; j++) {
                pwBegin(GL_LINES);
                @try {
                    glColor4f(0, 0, 0, (float)RandomLongR(256) / 256.0f);
                    glVertex2i(i, bottom - hght);
                    glColor4f(0, 0, 0, (float)RandomLongR(256) / 256.0f);
                    glVertex2i(i, bottom);
                }
                @finally { pwEnd(); }
			}
		}
	}
}

static NSColor *colorMult(NSColor *baseCol, CGFloat offset)
{
    CGFloat r, g, b;
    [baseCol getRed:&r green:&g blue:&b alpha:NULL];
    return [NSColor colorWithDeviceRed:r + offset green:g + offset blue:b + offset alpha:1.0f];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void window (int x, int y, int size, TextureType tt, NSColor *color)
{
	int margin = size / 3, half = size / 2, i = 0;
	switch (tt) {
		case TEXTURE_BUILDING1: //filled, 1-pixel frame
			drawrect (x + 1, y + 1, x + size - 1, y + size - 1, color);
			break;
		case TEXTURE_BUILDING2: //vertical
			drawrect (x + margin, y + 1, x + size - margin, y + size - 1, color);
			break;
		case TEXTURE_BUILDING3: //side-by-side pair
			drawrect (x + 1, y + 1, x + half - 1, y + size - margin, color);
			drawrect (x + half + 1, y + 1, x + size - 1, y + size - margin,  color);
			break;
		case TEXTURE_BUILDING4: //windows with blinds
			drawrect (x + 1, y + 1, x + size - 1, y + size - 1, color);
			i = RandomIntR(size - 2);
			drawrect (x + 1, y + 1, x + size - 1, y + i + 1, colorMult(color, 0.3f));
			break;
		case TEXTURE_BUILDING5: //vert stripes
			drawrect (x + 1, y + 1, x + size - 1, y + size - 1, color);
			drawrect (x + margin, y + 1, x + margin, y + size - 1, colorMult(color, 0.7f));
			drawrect (x + size - margin - 1, y + 1, x + size - margin - 1, y + size - 1, colorMult(color, 0.3f));
			break;
		case TEXTURE_BUILDING6: //wide horz line
			drawrect (x + 1, y + 1, x + size - 1, y + size - margin, color);
			break;
		case TEXTURE_BUILDING7: //4-pane
			drawrect (x + 2, y + 1, x + size - 1, y + size - 1, color);
			drawrect (x + 2, y + half, x + size - 1, y + half,colorMult( color, 0.2f));
			drawrect (x + half, y + 1, x + half, y + size - 1, colorMult(color, 0.2f));
			break;
		case TEXTURE_BUILDING8: // Single narrow window
			drawrect (x + half - 1, y + 1, x + half + 1, y + size - margin, color);
			break;
		case TEXTURE_BUILDING9: //horizontal
			drawrect (x + 1, y + margin, x + size - 1, y + size - margin - 1, color);
			break;
        default:
            break;
	}
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void do_bloom(Texture* t, bool showFlat)
{
	pwBindTexture(GL_TEXTURE_2D, 0);		
	pwViewport(0, 0, t.size, t.size);
	pwCullFace (GL_BACK);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	pwDepthMask (GL_TRUE);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	pwEnable(GL_DEPTH_TEST);
	pwEnable (GL_CULL_FACE);
	pwCullFace (GL_BACK);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	pwEnable (GL_FOG);
	pwFogf (GL_FOG_START, RenderFogDistance () / 2);
	pwFogf (GL_FOG_END, RenderFogDistance ());
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	pwClearColor (0.0f, 0.0f, 0.0f, 0.0f);
	pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	pwEnable (GL_TEXTURE_2D);
	EntityRender(showFlat);
	CarRender ();
	LightRender ();
	pwBindTexture(GL_TEXTURE_2D, t.glid);
	pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	pwCopyTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, t.size, t.size, 0);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


@implementation Texture
@synthesize size = _size, glid = _glid, ready = _ready, mipmap = _mipmap, masked = _masked, clamp = _clamp;

+(id)textureWithType:(TextureType) texType size:(int) size mipmap:(BOOL) mipmap clamp:(BOOL) clamp masked:(BOOL) masked
{
    return [[Texture alloc] initWithType:texType size:size mipmap:mipmap clamp:clamp masked:masked];
}


-(id) initWithType:(TextureType) texType size:(int) size mipmap:(BOOL) mipmap clamp:(BOOL) clamp masked:(BOOL) masked
{
    self = [super init];
    if(self) {
        glGenTextures (1, &_glid);
        _size    = size;
        _texType = texType;
        _mipmap  = mipmap;
        _clamp   = clamp;
        _masked  = masked;
        _desired_size = size;
        _half    = size / 2;
        _segment_size = size / SEGMENTS_PER_TEXTURE;
        _ready   = false;
    }
    return self;
}



-(void) Clear
{
    _ready = NO;
}


/*-----------------------------------------------------------------------------
 
 This draws all of the windows on a building texture. lit_density controls 
 how many lights are on. (1 in n chance that the light is on. Higher values 
 mean less lit windows. run_length controls how often it will consider 
 changing the lit / unlit status. 1 produces a complete scatter, higher
 numbers make long strings of lights.
 
 -----------------------------------------------------------------------------*/

    // Return a randomly-generated color in the appropriate range for a lit window texture.
static NSColor *randomLitColor()
{
    CGFloat r = (0.5f + (float)(RandomLong() % 128) / 256.0f),
            g = (0.5f + (float)(RandomLong() % 128) / 256.0f),
            b = (0.5f + (float)(RandomLong() % 128) / 256.0f),
    redShift = RANDOM_COLOR_SHIFT(), greenShift = RANDOM_COLOR_SHIFT(), blueShift = RANDOM_COLOR_SHIFT();
    return [NSColor colorWithDeviceRed:(r + redShift) green:(g + greenShift) blue:(b + blueShift) alpha:1.0f];
}

    // Ditto for an unlit window texture.
static NSColor *randomUnlitColor() { return [NSColor colorWithDeviceWhite:(float)(RandomLong () % 40) / 256.0f alpha:1.0f]; }

-(void) DrawWindows
{
	glReportError("CTexture::DrawWindows BEGIN");
	
	for (int y = 0; y < SEGMENTS_PER_TEXTURE; y++)  {
        int run, run_length, lit_density;
        NSColor *color;
        BOOL lit;
            //Every few floors we change the behavior
		if (!(y % 8)) {
			run = 0;
			run_length = RandomIntR(9) + 2;
			lit_density = 2 + RandomIntR(2) + RandomIntR(2);
			lit = NO;
		}
        
		for (int x = 0; x < SEGMENTS_PER_TEXTURE; x++) {
                //if this run is over reroll lit and start a new one
			if (run < 1) {
				run = RandomIntR(run_length);
				lit = RandomLongR(lit_density) == 0;
			}
            
			color = lit ? randomLitColor() : randomUnlitColor();
            window (x * _segment_size, y * _segment_size, _segment_size, _texType, color);
            run--;
		}
	}
	glReportError("CTexture::DrawWindows END");
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void drawOneCloud(int x, int y, int width, int height, GLfloat scale, int offset)
{
    float inv_scale = 1.0f - (scale);
    NSColor *color = (scale < 0.4f) ? [WorldBloomColor() multiplyBy:0.1f] : [NSColor blackColor];
    color = [color colorWithAlphaComponent:0.2f];
    glColor4(color);
    int width_adjust = (int)((float)width / 2.0f + (int)(inv_scale * ((float)width / 2.0f)));
    int height_adjust = height + (int)(scale * (float)height * 0.99f);
    glTexCoord2f(0, 0);   glVertex2i(offset + x - width_adjust, y + height - height_adjust);
    glTexCoord2f(0, 1);   glVertex2i(offset + x - width_adjust, y + height);
    glTexCoord2f(1, 1);   glVertex2i(offset + x + width_adjust, y + height);
    glTexCoord2f(1, 0);   glVertex2i(offset + x + width_adjust, y + height - height_adjust);
}

static NSColor *desaturateColor(NSColor *baseCol)
{
    float grey = averageFromColor(baseCol);
    CGFloat r, g, b;
    [baseCol getRed:&r green:&g blue:&b alpha:NULL];
    return [NSColor colorWithDeviceRed:(r + grey * 2.0f) / 15.0f
                                 green:(g + grey * 2.0f) / 15.0f
                                  blue:(b + grey * 2.0f) / 15.0f
                                 alpha:1.0f];
}



-(void) DrawSky
{
//	float grey = averageFromColor(color);
	NSColor *color = desaturateColor(WorldBloomColor());
	pwDisable (GL_BLEND);
	
	pwBegin(GL_QUAD_STRIP);
    @try {
		glColor3f(0,0,0);
		glVertex2i(0, _half);
		glVertex2i(_size, _half);
		glColor3(color);
		glVertex2i(0, _size - 2);  
		glVertex2i(_size, _size - 2);  
	}
    @finally { pwEnd(); }
	
        //Draw a bunch of little faux-buildings on the horizon.
	for (int i = 0; i < _size; i += 5)
		drawrect (i, _size - RandomIntR(8) - RandomIntR(8) - RandomIntR(8), i + RandomIntR(9), _size, [NSColor blackColor]);
	
            //Draw the clouds
	for (int i = _size - 30; i > 5; i -= 2) {
		int x     = RandomIntR(_size), y = i;
		int scale = 1.0f - ((float)y / (float)_size);
		int width = RandomIntR(_half / 2) + (int)((float)_half * scale) / 2;
		int hght  = MAX((int)((float)width * scale), 4);
		
		pwEnable (GL_BLEND);
		pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		pwDisable (GL_CULL_FACE);
		pwEnable (GL_TEXTURE_2D);
		pwBindTexture (GL_TEXTURE_2D, TextureId (TEXTURE_SOFT_CIRCLE));
		pwDepthMask (GL_FALSE);
		
        pwBegin(GL_QUADS);
        @try {
        for (int offset = -_size; offset <= _size; offset += _size)
            for (int scale = 1.0f; scale > 0.0f; scale -= 0.25f)
                drawOneCloud(x, y, width, hght, scale, offset);
        }
        @finally { pwEnd(); }
	}
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) DrawHeadlight
{
	//Make a simple circle of light, bright in the center and fading out	
	float radius = (float)_half - 20.0f;
	int x = _half - 20, y = _half;

	pwEnable (GL_BLEND);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
    pwBegin(GL_TRIANGLE_FAN);
    @try {
		glColor4f (0.8f, 0.8f, 0.8f, 0.6f);
		glVertex2i (_half - 5, y);
		glColor4f (0, 0, 0, 0);
		for (int i = 0; i <= 360; i += 36)
        {
			float vx = sinf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			float vy = cosf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			glVertex2i (x + (int)vx, _half + (int)vy);
		}
    }
    @finally { pwEnd(); }
    
	x = _half + 20;
	
    pwBegin(GL_TRIANGLE_FAN);
    @try {
		glColor4f (0.8f, 0.8f, 0.8f, 0.6f);
		glVertex2i (_half + 5, y);
		glColor4f (0, 0, 0, 0);
		for (int i = 0; i <= 360; i += 36) {
			float vx = sinf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			float vy = cosf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			glVertex2i (x + (int)vx, _half + (int)vy);
		}
	}
    @finally { pwEnd(); }
    
	x = _half - 6;
	drawrect_simple1 (x - 3, y - 2, x + 2, y + 2, [NSColor whiteColor]);
	x = _half + 6;
	drawrect_simple1 (x - 2, y - 2, x + 3, y + 2, [NSColor whiteColor]);
}

/*-----------------------------------------------------------------------------
 Here is where ALL of the procedural textures are created.  It's filled with obscure logic, magic numbers, and messy code. Part of this is because 
 there is a lot of "art" being done here, and lots of numbers that could be endlessly tweaked.  Also because I'm lazy.
 -----------------------------------------------------------------------------*/

static void makeLattice(GLint size)
{
    pwLineWidth (2.0f);
    glColor3f (0,0,0);
    pwBegin(GL_LINES);
    @try {
        glVertex2i (0, 0);  glVertex2i(size, size);	//diagonal
        glVertex2i (0, 0);  glVertex2i(0    , size);	//vertical
        glVertex2i (0, 0);  glVertex2i(size, 0    );	//vertical
    }
    @finally { pwEnd(); }
    
    pwBegin(GL_LINE_STRIP);
    @try {
    glVertex2i(0, 0);
    for (int i = 0; i < size; i += 9)
        glVertex2i((i % 2) ? 0 : i, i);

    for (int i = 0; i < size; i += 9)
        glVertex2i(i, (i % 2) ? 0 : i);
    }
    @finally { pwEnd(); }
}

static void makeSoftCircle(GLint halfSize)
{
	//Make a simple circle of light, bright in the center and fading out
    pwEnable (GL_BLEND);
    pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    float radius = (float)halfSize - 3.0f;

    pwBegin(GL_TRIANGLE_FAN);
    @try {
        glColor4f (1, 1, 1, 1);
        glVertex2i (halfSize, halfSize);
        glColor4f (0, 0, 0, 0);
        for (int i = 0; i <= 360; i++) {
            float x = sinf ((float)i * DEGREES_TO_RADIANS) * radius;
            float y = cosf ((float)i * DEGREES_TO_RADIANS) * radius;
            glVertex2i(halfSize + (int)x, halfSize + (int)y);
        }
    }
    @finally { pwEnd(); }
}

static void makeLight(GLint halfSize)
{
    pwEnable (GL_BLEND);
    pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    for (int j = 0; j < 2; j++) {
        pwBegin(GL_TRIANGLE_FAN);
        @try {
            glColor4f (1.0f, 1.0f, 1.0f, 1.0f);
            glVertex2i (halfSize, halfSize);
            float radius = j ? 8 : ((float)halfSize / 2);
            glColor4f (1, 1, 1, 0);
            
            for (int i = 0; i <= 360; i++) {
                float x = sinf ((float)i * DEGREES_TO_RADIANS) * radius;
                float y = cosf ((float)i * DEGREES_TO_RADIANS) * radius;
                glVertex2i(halfSize + (int)x, halfSize + (int)y);
            }
        }
        @finally { glEnd(); }
    }
}

static void makeLogos(GLuint textureId, GLint size)
{
    pwDepthMask(GL_FALSE);
    pwDisable(GL_BLEND);
    int name_num = RandomIntR(NAME_COUNT), prefix_num = RandomIntR(PREFIX_COUNT), suffix_num = RandomIntR(SUFFIX_COUNT);
    glColor3f(1,1,1);
    for (int i = 0; i < size; i += LOGO_PIXELS) {
        GLint x = 2, y = size - i - LOGO_PIXELS / 4, numFonts = RenderGetNumFonts();
            //randomly use a prefix OR suffix, but not both.  Too verbose.
        if (COIN_FLIP())
            RenderPrintIntoTexture(textureId, x, y, size, size,
                                   RandomIntR(numFonts),
                                   [NSColor whiteColor],
                                   "%s%s", prefix[prefix_num], name[name_num]);
        else
            RenderPrintIntoTexture(textureId, x, y, size, size,
                                   RandomIntR(numFonts),
                                   [NSColor whiteColor],
                                   "%s%s", name[name_num]    , suffix[suffix_num]);
        name_num   = (name_num   + 1) % NAME_COUNT  ;
        prefix_num = (prefix_num + 1) % PREFIX_COUNT;
        suffix_num = (suffix_num + 1) % SUFFIX_COUNT;
    }
}

static void makeTrim(GLint size)
{
    NSColor *white = [NSColor whiteColor], *grey = [NSColor colorWithDeviceWhite:0.5f alpha:1.0f];
    int y = 0, margin = MAX(TRIM_PIXELS / 4, 1);
    for (int x = 0; x < size; x += TRIM_PIXELS)
        drawrect_simple2(x + margin, y + margin    , x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, white, grey);
    y += TRIM_PIXELS;
    for (int x = 0; x < size; x += TRIM_PIXELS * 2)
        drawrect_simple2(x + margin, y + margin    , x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, white, grey);
    y += TRIM_PIXELS;
    for (int x = 0; x < size; x += TRIM_PIXELS * 3)
        drawrect_simple2(x + margin, y + margin    , x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, white, grey);
    y += TRIM_PIXELS;
    for (int x = 0; x < size; x += TRIM_PIXELS)
        drawrect_simple2(x + margin, y + margin * 2, x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, white, grey);
}


-(void) Rebuild
{
	glReportError("CTexture::Rebuild BEGIN");
	
	unsigned long start = GetTickCount ();
	// Since we make textures by drawing into the viewport, we can't make them bigger than the current view.
	_size = _desired_size;
	int max_size = RenderMaxTextureSize ();
	while (_size > max_size)
		_size /= 2;
	pwBindTexture(GL_TEXTURE_2D, _glid);
    
	//Set up the texture
	pwTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, _size, _size, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	if (_clamp) {
		pwTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		pwTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	}
    
	//Set up our viewport so that drawing into our texture will be as easy as possible.
    //We make the viewport and projection simply match the given texture size. 
	pwViewport(0, 0, _size , _size);
	pwMatrixMode (GL_PROJECTION);
	pwLoadIdentity ();
	glOrtho (0, _size, _size, 0, 0.1f, 2048);
    
	pwMatrixMode (GL_MODELVIEW);
    pwPushMatrix();
    @try {
        pwLoadIdentity();
        
        pwDisable (GL_CULL_FACE);
        pwDisable (GL_FOG);
        pwBindTexture(GL_TEXTURE_2D, 0);
        pwTranslatef(0, 0, -10.0f);
        pwClearColor (0, 0, 0, _masked ? 0.0f : 1.0f);
        pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        switch (_texType) {
            case TEXTURE_LATTICE    : makeLattice(_size)     ; break;
            case TEXTURE_SOFT_CIRCLE: makeSoftCircle(_half)  ; break;
            case TEXTURE_LIGHT      : makeLight(_half)       ; break;
            case TEXTURE_HEADLIGHT  : [self DrawHeadlight]   ; break;
            case TEXTURE_LOGOS      : makeLogos(_glid, _size); break;
            case TEXTURE_TRIM       : makeTrim(_size)        ; break;
            case TEXTURE_SKY        : [self DrawSky]         ; break;
            default                 : [self DrawWindows]     ; break; //building textures
        }
    }
    @finally { pwPopMatrix(); }
    
	//Now blit the finished image into our texture
    bool use_framebuffer = true;
	if (use_framebuffer) {
		pwBindTexture(GL_TEXTURE_2D, _glid);
		pwCopyTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, _size, _size, 0);
	}
	if (_mipmap) {
        NSMutableData *bits = [NSMutableData dataWithCapacity:_size * _size * 4];
		pwGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, bits.mutableBytes);
		pwuBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, _size, _size, GL_RGBA, GL_UNSIGNED_BYTE, bits.mutableBytes);
		pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
		pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	} 
	else
		pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	_ready = true;
	unsigned long lapsed = GetTickCount() - start;
	build_time += lapsed;
}
@end

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

unsigned TextureId (TextureType texType)
{
	for (Texture* t in allTextures)
		if (t.type == texType)
			return t.glid;
	return 0;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

unsigned TextureRandomBuilding (unsigned long index)
{
	index = labs(index) % BUILDING_COUNT;
	return TextureId((TextureType)(TEXTURE_BUILDING1 + index));
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void TextureReset (void)
{	
	textures_done = false;
	build_time = 0;
	for (Texture* t in allTextures)
		[t Clear];
	memset(prefix_used, 0, sizeof(prefix_used));
	memset(name_used  , 0, sizeof(name_used  ));
	memset(suffix_used, 0, sizeof(suffix_used));	
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

bool TextureReady()
{	
	return textures_done;	
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void TextureUpdate(bool showFlat, bool showBloom)
{
	glReportError("TextureUpdate:Beginning.");
	
	if (textures_done) {
		if (! showBloom)
			return;
		
		for(Texture *t in allTextures) {
			if(t.type == TEXTURE_BLOOM) {
				do_bloom(t, showFlat);
				return;
			}
		}
	}

	for (Texture* t in allTextures) {
		if(! t.ready) {
			[t Rebuild];
			glReportError("TextureUpdate:After CTexture::Rebuild()");
			return;
		}
	}

	textures_done = true;
}


void TextureTerm (void)
{
    [allTextures removeAllObjects];
}


void TextureInit (void)
{
    [allTextures addObject:[Texture textureWithType:TEXTURE_SKY         size:512 mipmap:YES clamp:NO  masked:NO ]];
    [allTextures addObject:[Texture textureWithType:TEXTURE_LATTICE     size:128 mipmap:YES clamp:YES masked:YES]];
    [allTextures addObject:[Texture textureWithType:TEXTURE_LIGHT       size:128 mipmap:NO  clamp:NO  masked:YES]];
    [allTextures addObject:[Texture textureWithType:TEXTURE_SOFT_CIRCLE size:128 mipmap:NO  clamp:NO  masked:YES]];
    [allTextures addObject:[Texture textureWithType:TEXTURE_HEADLIGHT   size:128 mipmap:NO  clamp:NO  masked:YES]];
 	[allTextures addObject:[Texture textureWithType:TEXTURE_BLOOM       size:512 mipmap:YES clamp:NO  masked:NO]];
    [allTextures addObject:[Texture textureWithType:TEXTURE_TRIM size:TRIM_RESOLUTION   mipmap:YES clamp:NO masked:NO]];
    [allTextures addObject:[Texture textureWithType:TEXTURE_LOGOS size:LOGO_RESOLUTION mipmap:YES clamp:NO masked:YES]];
	for (int i = TEXTURE_BUILDING1; i <= TEXTURE_BUILDING9; i++)
        [allTextures addObject:[Texture textureWithType:(TextureType)i size:512 mipmap:YES clamp:NO masked:NO]];
}
