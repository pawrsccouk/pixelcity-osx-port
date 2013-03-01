//Versioning info
static const char * const APP_TITLE = "PixelCity";
static const char * const APP       = "pixelcity";
static const int VERSION_MAJOR    =    1;
static const int VERSION_MINOR    =    0;
static const int VERSION_REVISION =   10;

static const bool SCREENSAVER    = true;  //Best to disable screensaver mode when working on the program. // PAW - was true
static const bool LOADING_SCREEN = true;  //Do we hide scene building behing a loading screen or show it? // PAW - was true
static const int WORLD_EDGE      = 200;    //The "dead zone" along the edge of the world, with super-low detail.

static const GLlong RESET_INTERVAL  =  (SCREENSAVER ? 120000 : 999999); //milliseconds    //How often to rebuild the city
static const int FADE_TIME        =  (SCREENSAVER ? 1500 : 1);  //milliseconds    //How GLlong the screen fade takes when transitioning to a new city
static const bool SHOW_DEBUG_GROUND  =  false;    //Debug ground texture that shows traffic lanes

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
enum RoadDirection
{
  NORTH,
  EAST,
  SOUTH,
  WEST
};

@class World;
    // Milliseconds since computer started.
GLulong GetTickCount();



    // Write diagnostic information to the console.

#ifdef __cplusplus
extern "C"
#endif
void DebugLog(const char* str, ...)
    __attribute__((format(printf, 1, 2)));





