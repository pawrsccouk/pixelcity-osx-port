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

#import "glTypesObjC.h"
#import "light.h"
#import "glRGBA.h"
#import "glTypes.h"
#import <math.h>
#import "camera.h"
#import "entity.h"
#import "macro.h"
#import "mathx.h"
#import "random.h"
#import "render.h"
#import "texture.h"
#import "visible.h"
#import "win.h"
#import "PWGL.h"
#import "World.h"
#import <vector>
#import <algorithm>
#import <functional>

static void addLight(float x, float y, float z, float r, float g, float b, float a, int size, bool blinks);


class CLight
{
    GLvector        _position;
    GLrgba          _color;
    int             _size;
    float           _vert_size;
    float           _flat_size;
    bool            _blink;
    unsigned long   _blink_interval;
    int             _cell_x;
    int             _cell_z;
    
public:
    CLight(GLvector pos, GLrgba color, int size);
    void            Render ();
    void            Blink ();
    
};

static GLvector2      angles[5][360];
std::vector<CLight*>  all_lights;
static bool           angles_done;

// PAW: Don't know why this is necessary, but the light.h isn't always marking this as a "C" function.
//extern "C" void LightAdd(Vector*, NSColor *, int, BOOL);

void LightAdd(Vector *position,
              NSColor *color,
              int size, BOOL blink)
{
    CGFloat red = 1.0f, green = 1.0f, blue = 1.0f, alpha = 1.0f;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];

    CLight *newLight = new CLight(GLvector(position.x, position.y, position.z), GLrgba(red, green, blue, alpha), size);
    all_lights.push_back(newLight);
    if(blink)
        newLight->Blink();
}

static const short MAX_SIZE = 5;

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void DeleteLight(CLight *l) { delete l; }

void LightClear ()
{
    std::for_each(all_lights.begin(), all_lights.end(), DeleteLight);
    all_lights.resize(0);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

unsigned long LightCount () {  return all_lights.size();  }

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


void LightRender ()
{	
	if (!EntityReady ())
		return;

	if (!angles_done) {
		for (int size = 0; size < MAX_SIZE; size++) {
			for (int i = 0 ;i < 360; i++) {
				angles[size][i].x = cosf (float(i) * DEGREES_TO_RADIANS) * (float(size) + 0.5f);
				angles[size][i].y = sinf (float(i) * DEGREES_TO_RADIANS) * (float(size) + 0.5f);
			}
		}
	}

	pwDepthMask (GL_FALSE);
	pwEnable (GL_BLEND);
	pwDisable (GL_CULL_FACE);
	pwBlendFunc (GL_ONE, GL_ONE);
	pwBindTexture(GL_TEXTURE_2D, TextureId(TEXTURE_LIGHT));
	pwDisable (GL_CULL_FACE);
	
    std::for_each(all_lights.begin(), all_lights.end(), std::mem_fun(&CLight::Render));

	pwDepthMask (GL_TRUE);
}

/*---------------------------------------------------------------------------------------------------------------------------------*/

CLight::CLight (GLvector pos, GLrgba color, int size)
{
    _position = pos;
    _color = color;
    _size = CLAMP(size, 0, (MAX_SIZE - 1));
    _vert_size = (float)_size + 0.5f;
    _flat_size = _vert_size + 0.5f;
    _blink = false;
    _cell_x = WORLD_TO_GRID(pos.x);
    _cell_z = WORLD_TO_GRID(pos.z);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CLight::Blink ()
{
  _blink = true;
        //we don't want blinkers to be in sync, so have them blink at slightly different rates. (Milliseconds)
  _blink_interval = 1500 + RandomInt(500);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static GLvector VectorToGLvector(Vector *v) { return GLvector(v.x, v.y, v.z); }

void CLight::Render ()
{
	if (!Visible (_cell_x, _cell_z))
		return;
	GLvector camera = VectorToGLvector(CameraAngle());
	GLvector camera_position = VectorToGLvector(CameraPosition());
    
	if( (fabs (camera_position.x - _position.x) > RenderFogDistance ())
	||  (fabs (camera_position.z - _position.z) > RenderFogDistance ())
	|| (_blink && (GetTickCount () % _blink_interval) > 200) )
		return;

	int angle = (int)MathAngle1 (camera.y);
	GLvector2 offset = angles[_size][angle];
	GLvector pos = _position;
	
	{
        MakePrimitive mp(GL_QUADS);
		glColor4(_color);
		glTexCoord2f (0, 0);   
		glVertex3f (pos.x + offset.x, pos.y - _vert_size, pos.z + offset.y);
		glTexCoord2f (0, 1);   
		glVertex3f (pos.x - offset.x, pos.y - _vert_size, pos.z - offset.y);
		glTexCoord2f (1, 1);   
		glVertex3f (pos.x - offset.x, pos.y + _vert_size, pos.z - offset.y);
		glTexCoord2f (1, 0);   
		glVertex3f (pos.x + offset.x, pos.y + _vert_size, pos.z + offset.y);
	}
}