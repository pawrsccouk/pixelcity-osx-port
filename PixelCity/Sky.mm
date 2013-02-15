/*-----------------------------------------------------------------------------

  Sky.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  Did this need to be written as a class? It did not. There will never be 
  more than one sky in play, so the whole class structure here is superflous,
  but harmless.
  
-----------------------------------------------------------------------------*/


#import "Model.h"
#import "camera.h"
#import "sky.h"
#import "texture.h"

static const int SKYPOINTS = 24;

struct CSkyPoint
{
    GLrgba _color;
    GLvertex _vertex;
    CSkyPoint() {}
    CSkyPoint(const GLvertex &vertex, const GLrgba &color) : _vertex(vertex), _color(color) {}
};

static const int SKY_GRID = 21;
static const int SKY_HALF = (SKY_GRID / 2);

#pragma mark - Sky

@interface Sky : NSObject
{
    int m_list;
    int m_stars_list;
    CSkyPoint m_grid[SKY_GRID][SKY_GRID];
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
            GLvector angle = CameraAngle (), position = CameraPosition ();
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
        CSkyPoint circle[SKYPOINTS];
        float size = 10.0f;
        for (int i = 0; i < SKYPOINTS; i++) {
            float angle = ((float)i / (float)(SKYPOINTS - 1)) * 360.0f * DEGREES_TO_RADIANS;
            float rad   = ((float)i / (SKYPOINTS - 1)) * 180.0f * DEGREES_TO_RADIANS;
            float lum   = (float)pow(sinf(rad), 5);
            GLvector position = GLvector(sinf(angle) * size, 0.1f, (cosf(angle) * size));
            GLvertex vertex(position, GLvector2(((float)i / (float)(SKYPOINTS - 1)) * 5.0f, 0.5f));
            circle[i] = CSkyPoint(vertex, GLrgba(lum));
        }
        m_list = glGenLists(1);
        pwNewList(m_list, GL_COMPILE);
        @try {
            glColor3f (1, 1, 1);
            pwBegin(GL_QUAD_STRIP);
            @try {
                for (int i = 0; i < SKYPOINTS; i++) {
                    glTexCoord2f (circle[i]._vertex.uv.x, 0.0f);
                    circle[i]._vertex.position.glVertex3();
                    GLvector &pos = circle[i]._vertex.position;
                    pos.y = size / 3.5f;
                    glTexCoord2f(circle[i]._vertex.uv.x, 1.0f);
                    pos.glVertex3();
                }
            }
            @finally { pwEnd(); }
        }
        @finally { pwEndList(); }
    }
    return self;
}
@end
