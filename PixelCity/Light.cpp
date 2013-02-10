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

#define MAX_SIZE            5

#include <math.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#include "glTypes.h"

#include "camera.h"
#include "entity.h"
#include "light.h"
#include "macro.h"
#include "mathx.h"
#include "random.h"
#include "render.h"
#include "texture.h"
#include "visible.h"
#include "win.h"
#include "PWGL.h"
#include <vector>
#include <algorithm>
#include <functional>
#include "World.h"

static GLvector2      angles[5][360];
std::vector<CLight*>  all_lights;
static bool           angles_done;

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
	pwBindTexture(GL_TEXTURE_2D, TextureId (TEXTURE_LIGHT));
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
    all_lights.push_back(this);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CLight::Blink ()
{
  _blink = true;
        //we don't want blinkers to be in sync, so have them blink at slightly different rates. (Milliseconds)
  _blink_interval = 1500 + RandomInt(500);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CLight::Render ()
{
	if (!Visible (_cell_x, _cell_z))
		return;
	GLvector camera = CameraAngle ();
	GLvector camera_position = CameraPosition ();
    
	if( (fabs (camera_position.x - _position.x) > RenderFogDistance ())
	||  (fabs (camera_position.z - _position.z) > RenderFogDistance ())
	|| (_blink && (GetTickCount () % _blink_interval) > 200) )
		return;

	int angle = (int)MathAngle (camera.y);
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