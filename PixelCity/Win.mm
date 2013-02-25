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

static bool quit = false;

void AppQuit ()
{
  quit = true;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void AppUpdate (World *world, int width, int height)
{    
	CameraUpdate (world);
	EntityUpdate ();    
	[world update];
        //cleanup and restore the viewport after TextureUpdate()
	RenderResize (width, height);     
	VisibleUpdate();    
	[world.cars update];
	RenderUpdate (world, width, height);
	glReportError("AppUpdate");
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

World *AppInit(int width, int height)
{
	DebugLog("AppInit");
    World *world = [[World alloc] init];
    RandomInit (time (NULL));
    CameraInit ();
    RenderInit (width, height);
    TextureInit(world);
    return world;
}



void AppTerm (World *world)
{
	DebugLog("AppTerm");
    TextureTerm ();
    [world term];
    RenderTerminate();
}

void AppResize(int width, int height)
{
	RenderResize(width, height);
}




// PAW: Replacement for Windows function that returns time since computer was started in milliseconds.
// gettimeofday returns it in microseconds, so we need to convert the result.
GLulong GetTickCount()
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return (((tv.tv_sec * 1000 * 1000) + tv.tv_usec) / 1000);
}
