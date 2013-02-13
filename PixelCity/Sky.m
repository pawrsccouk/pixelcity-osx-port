/*-----------------------------------------------------------------------------

  Sky.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  Did this need to be written as a class? It did not. There will never be 
  more than one sky in play, so the whole class structure here is superflous,
  but harmless.
  
-----------------------------------------------------------------------------*/

static const int SKYPOINTS = 24;

#import "PWGL.h"
#import "glTypesObjC.h"
#import "camera.h"
#import "sky.h"
#import "texture.h"
#import "mathx.h"

#pragma mark - Vertex



@implementation Vector
@synthesize x = _x, y = _y, z = _z;

+(id)vectorWithX:(float)x Y:(float)y Z:(float)z { return [[Vector alloc] initWithX:x Y:y Z:z]; }


-(id)initWithX:(float)x Y:(float)y Z:(float)z
{
    self = [super init];
    if(self) {
        self.x = x;
        self.y = y;
        self.z = z;
    }
    return self;
}

-(void)glVertex3
{
    float xyz[3] = { self.x, self.y, self.z };
    glVertex3fv(xyz);
}

-(id)copyWithZone:(NSZone *)zone
{
    return [[Vector allocWithZone:zone] initWithX:self.x Y:self.y Z:self.z];
}

@end



#pragma mark - Vertex


@implementation Vertex
@synthesize u = _u, v = _v, position = _position;

+(id)vertexWithPosition:(Vector*)position u:(float)u v:(float)v { return [[Vertex alloc] initWithPosition:position u:u v:v]; }

-(id)initWithPosition:(Vector*)position u:(float)u v:(float)v
{
    self = [super init];
    if(self) {
        self.position = position;
        self.u = u;
        self.v = v;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    return [[Vertex allocWithZone:zone] initWithPosition:[self.position copy] u:self.u v:self.v];
}

@end

#pragma mark - SkyPoint


@interface SkyPoint : NSObject
@property (nonatomic, copy) NSColor *color;
@property (nonatomic, copy) Vertex *vertex;

-(id)initWithVertex:(Vertex*)vertex color:(NSColor*)color;

@end

@implementation SkyPoint
@synthesize vertex = _vertex, color = _color;


-(id)initWithVertex:(Vertex*)vertex color:(NSColor*)color;
{
    self = [super init];
    if(self) {
        self.color = color;
        self.vertex = vertex;
    }
    return self;
}

@end

static const int SKY_GRID = 21;
static const int SKY_HALF = (SKY_GRID / 2);

#pragma mark - Sky

@interface Sky : NSObject
{
    int m_list;
    int m_stars_list;
    SkyPoint *m_grid[SKY_GRID][SKY_GRID];
}
   
-(id)init;
-(void)Render;
    
@end

static Sky *theSky;



/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void SkyInit()
{
    theSky = [[Sky alloc] init];
}

void SkyRender()
{
  [theSky Render];
}

void SkyClear ()
{
    theSky = NULL;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

@implementation Sky

-(void) Render
{
    if (!TextureReady ())
        return;
    
    pwDepthMask (GL_FALSE);
    pwPushAttrib (GL_POLYGON_BIT | GL_FOG_BIT);
    pwPolygonMode (GL_FRONT_AND_BACK, GL_FILL);
    pwDisable (GL_CULL_FACE);
    pwDisable (GL_FOG);
    {
        pwPushMatrix();
        @try {
            pwLoadIdentity();
            Vector *angle = CameraAngle (), *position = CameraPosition ();
            pwRotatef (angle.x, 1.0f, 0.0f, 0.0f);
            pwRotatef (angle.y, 0.0f, 1.0f, 0.0f);
            pwRotatef (angle.z, 0.0f, 0.0f, 1.0f);
            pwTranslatef (0.0f, -position.y / 100.0f, 0.0f);
            pwEnable (GL_TEXTURE_2D);
            pwBindTexture(GL_TEXTURE_2D, TextureId(TEXTURE_SKY));
            glCallList (m_list);
        }
        @finally { pwPopMatrix(); }
    }
    pwPopAttrib();
    pwDepthMask(GL_TRUE);
    pwEnable (GL_COLOR_MATERIAL);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(id)init
{
    self = [super init];
    if(self) {
        SkyPoint *circle[SKYPOINTS];
        float size = 10.0f;
        for (int i = 0; i < SKYPOINTS; i++) {
            float angle = ((float)i / (float)(SKYPOINTS - 1)) * 360.0f * DEGREES_TO_RADIANS;
            float rad   = ((float)i / (SKYPOINTS - 1)) * 180.0f * DEGREES_TO_RADIANS;
            float lum   = (float)pow(sinf(rad), 5);
            Vector *position = [Vector vectorWithX:(sinf(angle) * size)
                                                 Y:0.1f
                                                 Z:(cosf(angle) * size)];
            Vertex *vertex = [Vertex vertexWithPosition:position
                                                      u:((float)i / (float)(SKYPOINTS - 1)) * 5.0f v:0.5f];
            circle[i] = [[SkyPoint alloc] initWithVertex:vertex
                                                   color:[NSColor colorWithDeviceWhite:lum alpha:1.0f]];
        }
        m_list = glGenLists(1);
        pwNewList(m_list, GL_COMPILE);
        @try {
            glColor3f (1, 1, 1);
            pwBegin(GL_QUAD_STRIP);
            @try {
                for (int i = 0; i < SKYPOINTS; i++) {
                    glTexCoord2f (circle[i].vertex.u, 0.0f);
                    [circle[i].vertex.position glVertex3];
                    Vector *pos = [circle[i].vertex.position copy];
                    pos.y = size / 3.5f;
                    glTexCoord2f (circle[i].vertex.u, 1.0f);
                    [pos glVertex3];
                }
            }
            @finally { pwEnd(); }
        }
        @finally { pwEndList(); }
    }
    return self;
}
@end
