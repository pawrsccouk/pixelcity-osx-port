/*-----------------------------------------------------------------------------

  Light.cpp

  2006 Shamus Young

-------------------------------------------------------------------------------

  This tracks and renders the light sources. (Note that they do not really 
  CAST light in the OpenGL sense of the world, these are just simple panels.) 
  These are NOT subclassed to entities because these are dynamic.  Some lights 
  blink, and thus they can't go into the fixed render lists managed by 
  Entity.cpp.  

-----------------------------------------------------------------------------*/

#import "Model.h"
#import "light.h"
#import "camera.h"
#import "entity.h"
#import "render.h"
#import "texture.h"
#import "visible.h"
#import "win.h"
#import "World.h"

static void addLight(float x, float y, float z, float r, float g, float b, float a, int size, bool blinks);

@interface Light : NSObject
{
    GLvector        _position;
    GLrgba          _color;
    int             _size;
    float           _vert_size, _flat_size;
    GLulong   _blink_interval;
    int             _cell_x, _cell_z;
}
@property (nonatomic) BOOL blink;

-(id) initWithPosition:(const GLvector&) pos color:(const GLrgba&) color size:(int) size blink:(BOOL)blink;
-(void) render;
@end

static GLvector2      angles[5][360];
static NSMutableArray *allLights = [NSMutableArray array];
static bool           angles_done;

void LightAdd(const GLvector &position, const GLrgba &color, int size, bool blink)
{
    [allLights addObject:[[Light alloc] initWithPosition:position color:color size:size blink:blink]];
}

static const short MAX_SIZE = 5;

void LightClear ()
{
    [allLights removeAllObjects];
}


GLulong LightCount () {  return allLights.count;  }



void LightRender ()
{	
	if (!EntityReady ())
		return;

	if (!angles_done)
		for (int size = 0; size < MAX_SIZE; size++)
			for (int i = 0 ;i < 360; i++) {
				angles[size][i].x = cosf (float(i) * DEGREES_TO_RADIANS) * (float(size) + 0.5f);
				angles[size][i].y = sinf (float(i) * DEGREES_TO_RADIANS) * (float(size) + 0.5f);
			}

    pwDisable(GL_FOG);      // Allow the lights to peek out of the fog.
	pwDepthMask (GL_FALSE);
	pwEnable (GL_BLEND);
	pwDisable (GL_CULL_FACE);
	pwBlendFunc (GL_ONE, GL_ONE);
	pwBindTexture(GL_TEXTURE_2D, TextureId(TEXTURE_LIGHT));
	pwDisable (GL_CULL_FACE);
	
    for(Light *light in allLights)
        [light render];

	pwDepthMask (GL_TRUE);
}

/*---------------------------------------------------------------------------------------------------------------------------------*/

@implementation Light
@synthesize blink = _blink;

-(id)initWithPosition:(const GLvector &)pos color:(const GLrgba &)color size:(int)size blink:(BOOL)blink
{
    self = [super init];
    if(self) {
        self.blink = blink;
        _position = pos;
        _color = color;
        _size = CLAMP(size, 0, (MAX_SIZE - 1));
        _vert_size = _size + 0.5f;
        _flat_size = _vert_size + 0.5f;
        _cell_x = WORLD_TO_GRID(pos.x);
        _cell_z = WORLD_TO_GRID(pos.z);
    }
    return self;
}

-(void)setBlink:(BOOL) blink
{
  _blink = blink;
        //we don't want blinkers to be in sync, so have them blink at slightly different rates. (Milliseconds)
  _blink_interval = 1500 + RandomIntR(500);
}

-(void)render
{
	if (!Visible (_cell_x, _cell_z))
		return;
	GLvector camera = CameraAngle(), camera_position = CameraPosition();
    
	if( (fabs (camera_position.x - _position.x) > RenderFogDistance ())
	||  (fabs (camera_position.z - _position.z) > RenderFogDistance ())
	|| (_blink && (GetTickCount () % _blink_interval) > 200) )
		return;

	int angle = (int)MathAngle1 (camera.y);
	GLvector2 offset = angles[_size][angle];
	GLvector pos = _position;
	
	pwBegin(GL_QUADS);
    @try {
        GLvertex(GLvector(pos.x + offset.x, pos.y - _vert_size, pos.z + offset.y), GLvector2(0, 0), _color).apply();
        GLvertex(GLvector(pos.x - offset.x, pos.y - _vert_size, pos.z - offset.y), GLvector2(0, 1), _color).apply();
        GLvertex(GLvector(pos.x - offset.x, pos.y + _vert_size, pos.z - offset.y), GLvector2(1, 1), _color).apply();
        GLvertex(GLvector(pos.x + offset.x, pos.y + _vert_size, pos.z + offset.y), GLvector2(1, 0), _color).apply();
	}
    @finally { pwEnd(); }
}
@end



