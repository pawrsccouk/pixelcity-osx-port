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
    GLvector _position;
    GLrgba   _color;
    int      _size;
    float   _vert_size, _flat_size;
    GLulong _blink_interval;
    int     _cell_x, _cell_z;
}
@property (nonatomic) BOOL blink;
@property (nonatomic, readonly) __weak World *world;

-(id) initWithPosition:(const GLvector&) pos color:(const GLrgba&) color size:(int) size blink:(BOOL)blink world:(World*) world;
-(void) render;
@end

@interface Lights ()
{
    NSMutableArray *_allLights;
    GLvector2 _angles[5][360];
    BOOL _anglesDone;
}

-(GLvector2) angleAtX:(GLint)x y:(GLint) y;

@end


@implementation Lights

-(id)initWithWorld:(World *)world
{
    self = [super init];
    if(self) {
        _world      = world;
        _anglesDone = NO;
        _allLights  = [NSMutableArray array];
    }
    return self;
}

-(Light*)newLightWithPosition:(const GLvector &)position color:(const GLrgba &)color size:(int)size blink:(BOOL)blink
{
    Light *light = [[Light alloc] initWithPosition:position color:color size:size blink:blink world:self.world];
    [_allLights addObject:light];
    return light;
}


static const short MAX_SIZE = 5;

-(void)clear
{
    [_allLights removeAllObjects];
}

-(void)addLight:(Light *)light
{
    [_allLights addObject:light];
}

-(GLulong)count {  return _allLights.count;  }


-(void)render
{
	if (! self.world.entities.ready)
		return;

	if (!_anglesDone)
		for (int size = 0; size < MAX_SIZE; size++)
			for (int i = 0 ;i < 360; i++) {
				_angles[size][i].x = cosf (float(i) * DEGREES_TO_RADIANS) * (float(size) + 0.5f);
				_angles[size][i].y = sinf (float(i) * DEGREES_TO_RADIANS) * (float(size) + 0.5f);
			}

    pwDisable(GL_FOG);      // Allow the lights to peek out of the fog.
	pwDepthMask (GL_FALSE);
	pwEnable (GL_BLEND);
	pwDisable (GL_CULL_FACE);
	pwBlendFunc (GL_ONE, GL_ONE);
	pwBindTexture(GL_TEXTURE_2D, [self.world.textures textureId:TEXTURE_LIGHT]);
	pwDisable (GL_CULL_FACE);
	
    for(Light *light in _allLights)
        [light render];

	pwDepthMask (GL_TRUE);
}

-(GLvector2)angleAtX:(GLint)x y:(GLint)y
{
    return _angles[x][y];
}

@end


/*---------------------------------------------------------------------------------------------------------------------------------*/

@implementation Light
@synthesize blink = _blink, world = _world;

-(id)initWithPosition:(const GLvector &)pos color:(const GLrgba &)color size:(int)size blink:(BOOL)blink world:(World*) world
{
    self = [super init];
    if(self) {
        _world = world;
        [_world.lights addLight:self];
        
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
	if (![self.world.visibilityGrid visibleAtX:_cell_x Z:_cell_z])
		return;

    Camera *camera = self.world.camera;
	GLvector camera_angle = camera.angle, camera_position = camera.position;
    
    float fogDistance = self.world.renderer.fogDistance;
	if( (fabs (camera_position.x - _position.x) > fogDistance)
	||  (fabs (camera_position.z - _position.z) > fogDistance)
	|| (_blink && (GetTickCount () % _blink_interval) > 200) )
		return;

	int angle = (int)MathAngle1(camera_angle.y);
	GLvector2 offset = [self.world.lights angleAtX:_size y:angle];
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



