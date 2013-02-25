static const int   SEGMENTS_PER_TEXTURE = 64;
static const int   TRIM_RESOLUTION      = 256;
static const int   TRIM_ROWS            = 4;
static const float TRIM_SIZE            = (1.0f / TRIM_ROWS);
static const int   TRIM_PIXELS          = (TRIM_RESOLUTION / TRIM_ROWS);


typedef enum TextureType
{
  TEXTURE_LIGHT,
  TEXTURE_SOFT_CIRCLE,
  TEXTURE_SKY,
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

@class World;

@interface Textures : NSObject

@property (nonatomic, readonly) BOOL ready;

-(id)   initWithWorld:(World *) world;

//-(GLuint) textureFromName:(NSString*) name;
-(GLuint) textureId:(TextureType) texType;
-(void)   term;
-(GLuint) randomBuilding:(GLulong) index;
-(void)   reset;
-(void)   update:(World *)world showFlat:(BOOL) showFlat showBloom:(BOOL) showBloom;

    // PAW: Return the texture ID of one of a set of pre-defined logos.
    // Shamus' code worked by creating one large logo texture, and then getting each logo to map a different sub-rect of it.
    // I'm going to try creating an array of smaller textures instead.
-(GLuint) randomLogo;

@end

