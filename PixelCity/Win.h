//Versioning info
static const char * const APP_TITLE = "PixelCity";
static const char * const APP       = "pixelcity";
static const int VERSION_MAJOR    =    1;
static const int VERSION_MINOR    =    0;
static const int VERSION_REVISION =   10;

static const bool SCREENSAVER    = false;  //Best to disable screensaver mode when working on the program. // PAW - was true
static const bool LOADING_SCREEN = false;  //Do we hide scene building behing a loading screen or show it? // PAW - was true
static const int CARS            = 500;    //Controls the density of cars.
static const int WORLD_EDGE      = 200;    //The "dead zone" along the edge of the world, with super-low detail.

static const long RESET_INTERVAL  =    (SCREENSAVER ? 120000 : 999999); //milliseconds    //How often to rebuild the city
static const int FADE_TIME        =   (SCREENSAVER ? 1500 : 1);  //milliseconds    //How long the screen fade takes when transitioning to a new city
static const bool SHOW_DEBUG_GROUND  =  false;    //Debug ground texture that shows traffic lanes

//Controls the ammount of space available for buildings.  Other code is wrtten assuming this will be a power of two.
static const int WORLD_SIZE = 1024;
static const int WORLD_HALF = (WORLD_SIZE / 2);

//Bitflags used to track how world space is being used.
enum ClaimFlags {
    CLAIM_ROAD       =   1 ,
    CLAIM_WALK       =   2 ,
    CLAIM_BUILDING   =   4 ,
    MAP_ROAD_NORTH   =   8 ,
    MAP_ROAD_SOUTH   =   16,
    MAP_ROAD_EAST    =   32,
    MAP_ROAD_WEST    =   64
};

//Used in orienting roads and cars
enum
{
  NORTH,
  EAST,
  SOUTH,
  WEST
};

#ifdef __cplusplus
extern "C" {
#endif
	
	// If OpenGL had errors, report them. Where indicates where the first error was found.
	void glReportError(const char* where);
	// Write diagnostic information to the console.
	void DebugLog(const char* str);

// Milliseconds since computer started.
	unsigned long GetTickCount();

	void AppUpdate(int width, int height);
	void AppInit(int width, int height);
	void AppResize(int width, int height);
	void AppTerm();

/*
HWND  WinHwnd (void);
void  WinPopup (char* message, ...);
void  WinTerm (void);
bool  WinInit (void);
int   WinWidth (void);
int   WinHeight (void);
void  WinMousePosition (int* x, int* y);
*/

#ifdef __cplusplus
}
#endif
