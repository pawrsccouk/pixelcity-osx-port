/*-----------------------------------------------------------------------------

  Win.cpp

  2006 Shamus Young

-------------------------------------------------------------------------------

  Create the main window and make it go.

-----------------------------------------------------------------------------*/

static const float MOUSE_MOVEMENT = 0.5f;

#import "Model.h"

#import "camera.h"
#import "car.h"
#import "entity.h"
#import "ini.h"
#import "render.h"
#import "texture.h"
#import "win.h"
#import "world.h"
#import "visible.h"
#import "RenderAPI.h"
#import <sys/time.h>


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void AppUpdate (World *world, const CGSize &size)
{    
	[world.camera update];
	[world.entities update];
	[world update];
        //cleanup and restore the viewport after TextureUpdate()
    Renderer *renderer = world.renderer;
	[renderer resize:size];
	[world.visibilityGrid update];
	[world.cars update];
	[renderer update:size];
	glReportError("AppUpdate");
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


// PAW: Replacement for Windows function that returns time since computer was started in milliseconds.
// gettimeofday returns it in microseconds, so we need to convert the result.
GLulong GetTickCount()
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return (((tv.tv_sec * 1000 * 1000) + tv.tv_usec) / 1000);
}
