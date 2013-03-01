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

#import "Model.h"
#import "texture.h"
#import "world.h"
#import "render.h"
#import "win.h"
#import "car.h"
#import "light.h"
#import "Entity.h"
#import "GLString.h"
#import "Fog.h"

#pragma mark - Texture interface

@interface Texture : NSObject
{
	int  _desired_size, _half, _segment_size;
	bool _masked, _mipmap, _clamp;
}

@property (nonatomic) TextureType type;
@property (nonatomic) GLuint glid;
@property (nonatomic) GLint  size;
@property (nonatomic) BOOL ready;
@property (nonatomic, readonly) __weak World *world;

+(id)textureWithType:(TextureType) type size:(int) size mipmap:(BOOL) mipmap clamp:(BOOL) clamp masked:(BOOL) masked world:(World*)world;

-(id)initWithType:(TextureType) type size:(int) size mipmap:(BOOL) mipmap clamp:(BOOL) clamp masked:(BOOL) masked world:(World*) world;
-(void) Clear;
-(void) term;
-(void) Rebuild;
-(void) DrawWindows;
-(void) DrawSky;
-(void) DrawHeadlight;

@end


@interface Textures ()
{
    int  _buildTime;
    NSArray *_allTextures, *_logoTextures;
}

-(void) addBuildTime:(GLulong) timeElapsed;

@end


//---------------------------------------------------------------------------------------------------------------------------------------------

#pragma mark - Texture implementation

@implementation Texture

@synthesize type = _type, size = _size, glid = _glid, world = _world;

+(id)textureWithType:(TextureType)type size:(int)size mipmap:(BOOL)mipmap clamp:(BOOL)clamp masked:(BOOL)masked world:(World *)world
{
    return [[Texture alloc] initWithType:type size:size mipmap:mipmap clamp:clamp masked:masked world:world];
}

-(id)initWithType:(TextureType)type size:(int)size mipmap:(BOOL)mipmap clamp:(BOOL)clamp masked:(BOOL)masked world:(World *)world
{
    self = [super init];
    if(self) {
        auto allocTexture = ^{ GLuint texId = 0; pwGenTextures(1, &texId); return texId; };
        self.glid = allocTexture();
        self.type = type;
        _world  = world;
        _mipmap = mipmap;
        _clamp = clamp;
        _masked = masked;
        _desired_size = size;
        self.size = size;
        _half = size / 2;
        _segment_size = size / SEGMENTS_PER_TEXTURE;
        self.ready = NO;
    }
    return self;
}

-(void)Clear
{
    self.ready = NO;
}

-(void)term
{
    if(_glid > 0) {
        glDeleteTextures(1, &_glid);
        _glid = 0;
    }
}

/*-----------------------------------------------------------------------------
 
 This draws all of the windows on a building texture. lit_density controls 
 how many lights are on. (1 in n chance that the light is on. Higher values 
 mean less lit windows. run_length controls how often it will consider 
 changing the lit / unlit status. 1 produces a complete scatter, higher
 numbers make GLlong strings of lights.
 
 -----------------------------------------------------------------------------*/
 

-(void)DrawWindows
{
	int     run, run_length, lit_density;
	GLrgba  color;
	bool    lit = true;
    auto    randomColorShift = ^{ return RandomLongR(10) / 50.0f; };
    auto    randomLitColor   = ^{ return (GLrgba(0.5f + float(RandomLong() % 128) / 256.0f)
                                        + GLrgba(randomColorShift(), randomColorShift(), randomColorShift())); };
    auto    randomDarkColor  = ^{ return GLrgba(float(RandomLong () % 40) / 256.0f); };
   
	for (int y = 0; y < SEGMENTS_PER_TEXTURE; y++)  {
		
            //Every few floors we change the behavior
		if (!(y % 8)) {
			run = 0;
			run_length = RandomIntR(9) + 2;
			lit_density = 2 + RandomIntR(2) + RandomIntR(2);
			lit = false;
		}
        
		for (int x = 0; x < SEGMENTS_PER_TEXTURE; x++) {
                //if this run is over reroll lit and start a new one
			if (run < 1) {
				run = RandomIntR(run_length);
				lit = RandomLongR(lit_density) == 0;
 			}
            GLrgba color = lit ? randomLitColor() : randomDarkColor();
            window (x * _segment_size, y * _segment_size, _segment_size, self.type, color);
            run--;
		}
	}
}


-(void)DrawSky
{
	GLrgba color = _world.bloomColor;
	float grey = (color.red() + color.green() + color.blue()) / 3.0f;
	color = (color + GLrgba(grey) * 2.0f) / 15.0f;    //desaturate, slightly dim
	pwDisable (GL_BLEND);
	
    GLint skySize = self.size;
	pwBegin(GL_QUAD_STRIP);
    @try {
		glColor3f(0,0,0);
		glVertex2i(0, _half);
		glVertex2i(skySize, _half);
		color.glColor3();
		glVertex2i(0, skySize - 2);  
		glVertex2i(skySize, skySize - 2);  
	}
    @finally { pwEnd(); }
	
	//Draw a bunch of little faux-buildings on the horizon.
	for (int i = 0; i < skySize; i += 5)
		drawrect (i, skySize - RandomIntR(8) - RandomIntR(8) - RandomIntR(8), i + RandomIntR(9), skySize, GLrgba(0.0f));
	
	//Draw the clouds
	for (int i = skySize - 30; i > 5; i -= 2) {
		float x   = RandomIntR(skySize), y = i;
		int scale = 1.0f - (y / skySize);
		int width = RandomIntR(_half / 2) + int(float(_half) * scale) / 2;
		int hght  = std::max(int(float(width) * scale), 4);
		
		pwEnable (GL_BLEND);
		pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		pwDisable (GL_CULL_FACE);
		pwEnable (GL_TEXTURE_2D);
		pwBindTexture (GL_TEXTURE_2D, [self.world.textures textureId:TEXTURE_SOFT_CIRCLE]);
		pwDepthMask (GL_FALSE);
		
        pwBegin(GL_QUADS);
        @try {
            for (int offset = -skySize; offset <= skySize; offset += skySize)
                for (int scale = 1.0f; scale > 0.0f; scale -= 0.25f)
                    drawOneCloud(_world.bloomColor, x, y, width, hght, scale, offset);
        }
        @finally { pwEnd(); }
	}
}


-(void)DrawHeadlight
{
	//Make a simple circle of light, bright in the center and fading out	
	float           radius = float(_half) - 20;
	int             i, x = _half - 20, y = _half;
	GLvector2       pos;

	pwEnable (GL_BLEND);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	
    pwBegin(GL_TRIANGLE_FAN);
    @try {
		glColor4f (0.8f, 0.8f, 0.8f, 0.6f);
		glVertex2i (_half - 5, y);
		glColor4f (0, 0, 0, 0);
		for (i = 0; i <= 360; i += 36) {
			pos.x = sinf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			pos.y = cosf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			glVertex2i (x + (int)pos.x, _half + (int)pos.y);
		}
	}
    @finally { pwEnd(); }
    
	x = _half + 20;
	
    pwBegin(GL_TRIANGLE_FAN);
    @try {
		glColor4f (0.8f, 0.8f, 0.8f, 0.6f);
		glVertex2i (_half + 5, y);
		glColor4f (0, 0, 0, 0);
		for (i = 0; i <= 360; i += 36) {
			pos.x = sinf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			pos.y = cosf ((float)(i % 360) * DEGREES_TO_RADIANS) * radius;
			glVertex2i (x + (int)pos.x, _half + (int)pos.y);
		}
	}
    @finally { pwEnd(); }
    
	x = _half - 6;
	drawrect_simple (x - 3, y - 2, x + 2, y + 2, GLrgba (1.0f));
	x = _half + 6;
	drawrect_simple (x - 2, y - 2, x + 3, y + 2, GLrgba (1.0f));
}

/*-----------------------------------------------------------------------------
 Here is where ALL of the procedural textures are created.  It's filled with obscure logic, magic numbers, and messy code. Part of this is because 
 there is a lot of "art" being done here, and lots of numbers that could be endlessly tweaked.  Also because I'm lazy.
 -----------------------------------------------------------------------------*/

-(void)Rebuild
{
	glReportError("CTexture::Rebuild BEGIN");
	
	GLulong start = GetTickCount ();
	// Since we make textures by drawing into the viewport, we can't make them bigger than the current view.
	_size = _desired_size;
	int max_size = self.world.renderer.maxTextureSize;
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
    GLint size = self.size;
	pwViewport(0, 0, _size , _size);
	pwMatrixMode (GL_PROJECTION);
	pwLoadIdentity ();
	glOrtho (0, size, size, 0, 0.1f, 2048);
    
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
        switch (self.type) {
            case TEXTURE_LATTICE    : makeLattice(_size)     ; break;
            case TEXTURE_SOFT_CIRCLE: makeSoftCircle(_half)  ; break;
            case TEXTURE_LIGHT      : makeLight(_half)       ; break;
            case TEXTURE_TRIM       : makeTrim(size)         ; break;
            case TEXTURE_HEADLIGHT  : [self DrawHeadlight]   ; break;
            case TEXTURE_SKY        : [self DrawSky]         ; break;
            default                 : [self DrawWindows]     ; break; //building textures
        }
    }
    @finally { pwPopMatrix(); }

	//Now blit the finished image into our texture  
    bool use_framebuffer = true;
	if (use_framebuffer) {
		pwBindTexture(GL_TEXTURE_2D, self.glid);
		pwCopyTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, size, size, 0);
	}
	if (_mipmap) {
        NSMutableData *bits = [NSMutableData dataWithCapacity:size * size * 4];
		pwGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, bits.mutableBytes);
		pwuBuild2DMipmaps(GL_TEXTURE_2D, GL_RGBA, size, size, GL_RGBA, GL_UNSIGNED_BYTE, bits.mutableBytes);
		pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR_MIPMAP_LINEAR);
		pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	} 
	else
		pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
	_ready = true;
	GLulong lapsed = GetTickCount() - start;
    [self.world.textures addBuildTime:lapsed];
}

static void drawOneCloud(const GLrgba &bloomColor, int x, int y, int width, int height, GLfloat scale, int offset)
{
    float inv_scale = 1.0f - (scale);
    GLrgba color = (scale < 0.4f) ? bloomColor * 0.1f : GLrgba(0.0f);
    color = color.colorWithAlpha(0.2f);
    color.glColor4();
    int width_adjust = int(float(width) / 2.0f + int(inv_scale * (float(width) / 2.0f)));
    int height_adjust = height + int(scale * float(height) * 0.99f);
    glTexCoord2f(0, 0);   glVertex2i(offset + x - width_adjust, y + height - height_adjust);
    glTexCoord2f(0, 1);   glVertex2i(offset + x - width_adjust, y + height);
    glTexCoord2f(1, 1);   glVertex2i(offset + x + width_adjust, y + height);
    glTexCoord2f(1, 0);   glVertex2i(offset + x + width_adjust, y + height - height_adjust);
}

static void makeLattice(GLint size)
{
    pwLineWidth (2.0f);
    glColor3f (0,0,0);
    
    glBegin(GL_LINES);
    @try {
        glVertex2i (0, 0);  glVertex2i(size, size);	//diagonal
        glVertex2i (0, 0);  glVertex2i(0    , size);	//vertical
        glVertex2i (0, 0);  glVertex2i(size, 0    );	//vertical
    }
    @finally { pwEnd(); }
    
    glBegin(GL_LINE_STRIP);
    @try {
        glVertex2i(0, 0);
        for (int i = 0; i < size; i += 9) {
            glVertex2i( (i % 2) ? 0 : i, i);
        }
        for (int i = 0; i < size; i += 9) {
            glVertex2i( i, (i % 2) ? 0 : i);
        }
    }
    @finally { pwEnd(); }
}

static void makeSoftCircle(GLint halfSize)
{
        //Make a simple circle of light, bright in the center and fading out
    pwEnable (GL_BLEND);
    pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    float radius = float(halfSize) - 3;
    
    pwBegin(GL_TRIANGLE_FAN);
    @try {
        glColor4f (1, 1, 1, 1);
        glVertex2i (halfSize, halfSize);
        glColor4f (0, 0, 0, 0);
        for (int i = 0; i <= 360; i++) {
            GLvector2 pos;
            pos.x = sinf ((float)i * DEGREES_TO_RADIANS) * radius;
            pos.y = cosf ((float)i * DEGREES_TO_RADIANS) * radius;
            glVertex2i (halfSize + (int)pos.x, halfSize + (int)pos.y);
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
            float radius = j ? 8 : (float(halfSize) / 2);
            glColor4f (1, 1, 1, 0);
            
            for (int i = 0; i <= 360; i++) {
                GLvector2 pos;
                pos.x = sinf (float(i) * DEGREES_TO_RADIANS) * radius;
                pos.y = cosf (float(i) * DEGREES_TO_RADIANS) * radius;
                glVertex2i (halfSize + int(pos.x), halfSize + int(pos.y));
            }
        }
        @finally { pwEnd(); }
    }
}

static void drawrect_simple (int left, int top, int right, int bottom, const GLrgba &color)
{
    pwBegin(GL_QUADS);
	@try {
        color.glColor3();
		glVertex2i (left, top);
		glVertex2i (right, top);
		glVertex2i (right, bottom);
		glVertex2i (left, bottom);
	}
    @finally { pwEnd(); }
}


static void drawrect_simple (int left, int top, int right, int bottom, const GLrgba &color1, const GLrgba &color2)
{
    pwBegin(GL_TRIANGLE_FAN);
	@try {
        color1.glColor3();
		glVertex2i ((left + right) / 2, (top + bottom) / 2);
		color2.glColor3();
		glVertex2i(left, top);
		glVertex2i(right, top);
		glVertex2i(right, bottom);
		glVertex2i(left, bottom);
		glVertex2i(left, top);
	}
    @finally { pwEnd(); }
}



static void drawrect (int left, int top, int right, int bottom, GLrgba color)
{
    auto randomColorVal = ^{ return float(RandomLongR(256)) / 256.0f; };
    
	pwDisable(GL_CULL_FACE);
	pwBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	pwEnable(GL_BLEND);
	pwLineWidth(1.0f);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	color.glColor3();
    
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
		
		float average   = (color.red() + color.blue() + color.green()) / 3.0f;
		int   potential = (int)(average * 255.0f);
		
		if (average > 0.5f) {
			pwBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
			
            pwBegin(GL_POINTS);
            @try {
				for(int i = left + 1; i < right - 1; i++) {
					for(int j = top + 1; j < bottom - 1; j++) {
						glColor4i(255, 0, RandomIntR(potential), 255);
						float hue = 0.2f + (float)RandomLongR(100) / 300.0f + (float)RandomLongR(100) / 300.0f + (float)RandomLongR(100) / 300.0f;
						GLrgba color_noise = glRgbaFromHsl(hue, 0.3f, 0.5f).colorWithAlpha(float(RandomLongR(potential)) / 144.0f);
						glColor4f(randomColorVal(), randomColorVal(), randomColorVal(), float(RandomLongR(potential)) / 144.0f);
						color_noise.glColor4();
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
                @finally { glEnd(); }
			}
		}
	}
}



static void makeTrim(GLint size)
{
    int y = 0, margin = std::max(TRIM_PIXELS / 4, 1);
    for (int x = 0; x < size; x += TRIM_PIXELS)
        drawrect_simple(x + margin, y + margin    , x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, GLrgba (1.0f), GLrgba (0.5f));
    y += TRIM_PIXELS;
    for (int x = 0; x < size; x += TRIM_PIXELS * 2)
        drawrect_simple(x + margin, y + margin    , x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, GLrgba (1.0f), GLrgba (0.5f));
    y += TRIM_PIXELS;
    for (int x = 0; x < size; x += TRIM_PIXELS * 3)
        drawrect_simple(x + margin, y + margin    , x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, GLrgba (1.0f), GLrgba (0.5f));
    y += TRIM_PIXELS;
    for (int x = 0; x < size; x += TRIM_PIXELS)
        drawrect_simple(x + margin, y + margin * 2, x + TRIM_PIXELS - margin, y + TRIM_PIXELS - margin, GLrgba (1.0f), GLrgba (0.5f));
}

static void window (int x, int y, int size, TextureType tt, GLrgba color)
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
			drawrect (x + 1, y + 1, x + size - 1, y + i + 1, color * 0.3f);
			break;
		case TEXTURE_BUILDING5: //vert stripes
			drawrect (x + 1, y + 1, x + size - 1, y + size - 1, color);
			drawrect (x + margin, y + 1, x + margin, y + size - 1, color * 0.7f);
			drawrect (x + size - margin - 1, y + 1, x + size - margin - 1, y + size - 1, color * 0.3f);
			break;
		case TEXTURE_BUILDING6: //wide horz line
			drawrect (x + 1, y + 1, x + size - 1, y + size - margin, color);
			break;
		case TEXTURE_BUILDING7: //4-pane
			drawrect (x + 2, y + 1, x + size - 1, y + size - 1, color);
			drawrect (x + 2, y + half, x + size - 1, y + half, color * 0.2f);
			drawrect (x + half, y + 1, x + half, y + size - 1, color * 0.2f);
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

@end


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark - Global interface


@implementation Textures
@synthesize ready = _ready;

static void doBloom(World *world, Texture *t, bool showFlat)
{
    float fogDistance = world.renderer.fog.start;
	pwBindTexture(GL_TEXTURE_2D, 0);
	pwViewport(0, 0, t.size , t.size);
	pwCullFace (GL_BACK);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	pwDepthMask (GL_TRUE);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	pwEnable(GL_DEPTH_TEST);
	pwEnable (GL_CULL_FACE);
	pwCullFace (GL_BACK);
	pwBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	pwEnable (GL_FOG);
	pwFogf (GL_FOG_START, fogDistance / 2);
	pwFogf (GL_FOG_END  , fogDistance);
	pwPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	pwClearColor (0.0f, 0.0f, 0.0f, 0.0f);
	pwClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	pwEnable (GL_TEXTURE_2D);
	[world.entities render:showFlat];
	[world.cars render];
	[world.lights render];
	pwBindTexture(GL_TEXTURE_2D, t.glid);
	pwTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	pwCopyTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, t.size, t.size, 0);
}



-(GLuint) textureId:(TextureType) texType
{
	for (Texture* t in _allTextures)
		if (t.type == texType)
			return t.glid;
	return 0;
}

-(GLuint)randomBuilding:(GLulong)index
{
	index = labs(index) % BUILDING_COUNT;
	return [self textureId:(TextureType(TEXTURE_BUILDING1 + index))];
}

-(void)reset
{	
	_ready = false;
	_buildTime = 0;
	for (Texture *t in _allTextures)
		[t Clear];
}

-(void)addBuildTime:(GLulong)timeElapsed
{
    _buildTime += timeElapsed;
}

-(void)update:(World *)world showFlat:(BOOL)showFlat showBloom:(BOOL)showBloom
{
	glReportError("TextureUpdate:Beginning.");
	
	if (self.ready) {
		if (! showBloom)
			return;
		
		for(Texture *t in _allTextures) {
			if(t.type == TEXTURE_BLOOM) {
				doBloom(world, t, showFlat);
				return;
			}
		}
	}

	for (Texture *t in _allTextures) {
		if(! t.ready) {
			[t Rebuild];
			return;
		}
	}
    glReportError("TextureUpdate:After CTexture::Rebuild()");
	_ready = true;
}

-(void)term
{
    for(Texture *tex in _allTextures) {
        [tex term];
    }
    
    for(NSNumber *texId in _logoTextures) {
        GLuint texIdi = texId.unsignedIntValue;
        glDeleteTextures(1, &texIdi);
    }
    _allTextures = _logoTextures = nil;
}

-(id)initWithWorld:(World *)world
{
    self = [super init];
    if(self) {
        _ready = false;
        _buildTime = 0;
        _logoTextures = makeLogos();
        
        NSMutableArray *textures = [NSMutableArray array];
        
        [textures addObject:[Texture textureWithType:TEXTURE_SKY         size:512 mipmap:YES clamp:NO  masked:NO  world:world]];
        [textures addObject:[Texture textureWithType:TEXTURE_LATTICE     size:128 mipmap:YES clamp:YES masked:YES world:world]];
        [textures addObject:[Texture textureWithType:TEXTURE_LIGHT       size:128 mipmap:NO  clamp:NO  masked:YES world:world]];
        [textures addObject:[Texture textureWithType:TEXTURE_SOFT_CIRCLE size:128 mipmap:NO  clamp:NO  masked:YES world:world]];
        [textures addObject:[Texture textureWithType:TEXTURE_HEADLIGHT   size:128 mipmap:NO  clamp:NO  masked:YES world:world]];
        [textures addObject:[Texture textureWithType:TEXTURE_BLOOM       size:512 mipmap:YES clamp:NO  masked:NO  world:world]];
        [textures addObject:[Texture textureWithType:TEXTURE_TRIM        size:TRIM_RESOLUTION mipmap:YES clamp:NO masked:NO world:world]];
        
        for (int i = TEXTURE_BUILDING1; i <= TEXTURE_BUILDING9; i++)
            [textures addObject:[Texture textureWithType:TextureType(i) size:512 mipmap:YES clamp:NO masked:NO world:world]];

        _allTextures = textures;
    }
    return self;
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
            if(font) {
                [fontAttribs addObject:@{
                     NSFontAttributeName            : font,
                     NSForegroundColorAttributeName : [NSColor whiteColor]
                 }];
            }
            else  NSLog(@"Font %@ could not be created.", fontNames[i]);
        }
    }
    return fontAttribs;
}

static NSArray *makeLogos()
{
    NSArray* prefix =
    @[
	@"i"        ,	@"Green "   ,	@"Mega"     ,	@"Super "   ,
	@"Omni"     ,	@"e"        ,	@"Hyper"    ,	@"Global "  ,
	@"Vital"    ,	@"Next "    ,	@"Pacific " ,	@"Metro"    ,
	@"Unity "   ,	@"G-"       ,	@"Trans"    ,	@"Infinity ",
	@"Superior ",	@"Monolith ",	@"Best "    ,	@"Atlantic ",
	@"First "   ,	@"Union "   ,	@"National ",
    ];
    
    NSArray* name =
    @[
	@"Biotic"    ,	@"Info"       ,	@"Data"      ,	@"Solar"    ,
	@"Aerospace" ,	@"Motors"     ,	@"Nano"      ,	@"Online"   ,
	@"Circuits"  ,	@"Energy"     ,	@"Med"       ,	@"Robotic"  ,
	@"Exports"   ,	@"Security"   ,	@"Systems"   ,	@"Financial",
	@"Industrial",	@"Media"      ,	@"Materials" ,	@"Foods"    ,
	@"Networks"  ,	@"Shipping"   ,	@"Tools"     ,	@"Medical"  ,
	@"Publishing",	@"Enterprises",	@"Audio"     ,	@"Health"   ,
	@"Bank"      ,	@"Imports"    ,	@"Apparel"   ,	@"Petroleum",
	@"Studios"   ,
    ];
    
    NSArray* suffix =
    @[
	@"Corp"      ,	@" Inc.",	@"Co"        ,	@"World",
	@".Com"      ,	@" USA" ,	@" Ltd."     ,	@"Net",
	@" Tech"     ,	@" Labs",	@" Mfg."     ,	@" UK",
	@" Unlimited",	@" One" ,	@" LLC"
    ];
    
    pwDepthMask(GL_FALSE);
    pwDisable(GL_BLEND);
    
    static const int NUM_LOGOS = 20;
    int __block name_num = RandomIntR(int(name.count)), __block prefix_num = RandomIntR(int(prefix.count)), __block suffix_num = RandomIntR(int(suffix.count));
    int font = RandomIntR(GLint(getFontAttributes().count));
    
    NSMutableArray *textures = [NSMutableArray array];
    
    auto getPrefixName = ^{ return [NSString stringWithFormat:@"%@%@", [prefix objectAtIndex:prefix_num], [name objectAtIndex:name_num]]; };
    auto getsuffixName = ^{ return [NSString stringWithFormat:@"%@%@", [name objectAtIndex:name_num]    , [suffix objectAtIndex:suffix_num]]; };
    
    for(int i = 0; i < NUM_LOGOS; i++) {
        
        NSMutableDictionary *logoAttributes = [NSMutableDictionary dictionaryWithDictionary:[getFontAttributes() objectAtIndex:font]];
        [logoAttributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        assert([logoAttributes objectForKey:NSFontAttributeName] != nil);
        
        GLString *s = [[GLString alloc] initWithString:COIN_FLIP() ? getPrefixName() : getsuffixName()
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


-(GLuint) randomLogo
{
    return [[_logoTextures objectAtIndex:RandomIntR(GLint(_logoTextures.count))] intValue];
}

@end

