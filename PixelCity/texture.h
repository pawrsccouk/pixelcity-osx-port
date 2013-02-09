static const int SEGMENTS_PER_TEXTURE = 64;
static const int ONE_SEGMENT          = (1.0f / SEGMENTS_PER_TEXTURE);
static const int LANES_PER_TEXTURE    = 8;
static const int LANE_SIZE            = (1.0f / LANES_PER_TEXTURE);
static const int TRIM_RESOLUTION      = 256;
static const int TRIM_ROWS            = 4;
static const int TRIM_SIZE            = (1.0f / TRIM_ROWS);
static const int TRIM_PIXELS          = (TRIM_RESOLUTION / TRIM_ROWS);
static const int LOGO_RESOLUTION      = 512;
static const int LOGO_ROWS            = 16;
static const int LOGO_SIZE            = (1.0f / LOGO_ROWS);
static const int LOGO_PIXELS          = (LOGO_RESOLUTION / LOGO_ROWS);

#define LANE_PIXELS  (_size / LANES_PER_TEXTURE)

enum TextureType
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
};

static const int BUILDING_COUNT  =  ((TEXTURE_BUILDING9 - TEXTURE_BUILDING1) + 1);

unsigned  TextureFromName (char* name);
unsigned  TextureId (unsigned long texId);
void      TextureInit (void);
void      TextureTerm (void);
GLuint    TextureRandomBuilding (unsigned long index);
bool      TextureReady ();
void      TextureReset (void);
void      TextureUpdate (void);

