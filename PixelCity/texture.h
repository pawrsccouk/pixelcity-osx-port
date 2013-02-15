static const int   SEGMENTS_PER_TEXTURE = 64;
static const float ONE_SEGMENT          = (1.0f / SEGMENTS_PER_TEXTURE);
static const int   LANES_PER_TEXTURE    = 8;
static const float LANE_SIZE            = (1.0f / LANES_PER_TEXTURE);
static const int   TRIM_RESOLUTION      = 256;
static const int   TRIM_ROWS            = 4;
static const float TRIM_SIZE            = (1.0f / TRIM_ROWS);
static const int   TRIM_PIXELS          = (TRIM_RESOLUTION / TRIM_ROWS);
static const int   LOGO_RESOLUTION      = 512;
static const int   LOGO_ROWS            = 16;
static const float LOGO_SIZE            = (1.0f / LOGO_ROWS);
static const float LOGO_PIXELS          = (LOGO_RESOLUTION / LOGO_ROWS);

#define LANE_PIXELS  (_size / LANES_PER_TEXTURE)

typedef enum TextureType
{
  TEXTURE_LIGHT,
  TEXTURE_SOFT_CIRCLE,
  TEXTURE_SKY,
  TEXTURE_LOGOS,
  TEXTURE_TRIM,
  TEXTURE_BLOOM,
  TEXTURE_HEADLIGHT,
  TEXTURE_LATTICE,
  TEXTURE_BUILDING1,
  TEXTURE_BUILDING2,
  TEXTURE_BUILDING3,
  TEXTURE_BUILDING4,
  TEXTURE_BUILDING5,
  TEXTURE_BUILDING6,
  TEXTURE_BUILDING7,
  TEXTURE_BUILDING8,
  TEXTURE_BUILDING9,
  TEXTURE_COUNT,
} TextureType;

static const int BUILDING_COUNT  =  ((TEXTURE_BUILDING9 - TEXTURE_BUILDING1) + 1);

#ifdef __cplusplus
extern "C" {
#endif

unsigned  TextureFromName (char* name);
unsigned  TextureId (TextureType texType);
void      TextureInit (void);
void      TextureTerm (void);
GLuint    TextureRandomBuilding (unsigned long index);
bool      TextureReady ();
void      TextureReset (void);
void      TextureUpdate (bool showFlat, bool showBloom);

    // PAW: Return the texture ID of one of a set of pre-defined logos.
    // Shamus' code worked by creating one large logo texture, and then getting each logo to map a different sub-rect of it.
    // I'm going to try creating an array of smaller textures instead.
GLuint    TextureRandomLogo();

#ifdef __cplusplus
}
#endif
