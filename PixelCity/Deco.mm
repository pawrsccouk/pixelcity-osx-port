/*-----------------------------------------------------------------------------

  Deco.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  This handles building and rendering decoration objects - infrastructure & 
  such around the city.

-----------------------------------------------------------------------------*/


#import "Model.h"
#import "light.h"
#import "deco.h"
#import "mesh.h"
#import "render.h"
#import "texture.h"
#import "world.h"
#import "visible.h"
#import "win.h"


static const float LOGO_OFFSET = 0.2f; //How far a logo sticks out from the given surface


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

@implementation Deco


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(id)init
{
    self = [super init];
    if(self) {
        _mesh = [[Mesh alloc] init];
        _use_alpha = false;
    }
    return self;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) Render
{
    float rgb[3] = {};
    _color.copyRGB(rgb);
    glColor3fv(rgb);
    [_mesh Render];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void)RenderFlat:(BOOL) colored { }
-(BOOL)alpha { return _use_alpha; }
-(unsigned long)polyCount  { return _mesh.polyCount; }
-(GLuint) texture  { return _texture; }

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static const short LIGHT_SIZE = 3;

-(void) CreateRadioTowerWithPosition:(GLvector) pos height:(float) height;
{
  float offset = height / 15.0f;
  _center = pos;
  _use_alpha = true;
  
        //Radio tower
  [_mesh addVertex:GLvertex(glVector(_center.x         , _center.y + height, _center.z         ), glVector(0, 1))];
  [_mesh addVertex:GLvertex(glVector(_center.x - offset, _center.y         , _center.z - offset), glVector(1, 0))];
  [_mesh addVertex:GLvertex(glVector(_center.x + offset, _center.y         , _center.z - offset), glVector(0, 0))];
  [_mesh addVertex:GLvertex(glVector(_center.x + offset, _center.y         , _center.z + offset), glVector(1, 0))];
  [_mesh addVertex:GLvertex(glVector(_center.x - offset, _center.y         , _center.z + offset), glVector(0, 0))];
  [_mesh addVertex:GLvertex(glVector(_center.x - offset, _center.y         , _center.z - offset), glVector(1, 0))];

  [_mesh addFan:fan(0, 1, 2, 3, 4, 5, LIST_TERM)];
  
  LightAdd(_center, GLrgba(1.0f, 192.0f/255.0f, 160.0f/255.0f, 1.0f), LIGHT_SIZE, true);
  
  _texture = TextureId (TEXTURE_LATTICE);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) CreateLogoWithStart:(const GLvector2 &)start end:(const GLvector2 &) end base:(float) bottom seed:(int) seed color:(const GLrgba &)color;
{
  _use_alpha = true;
  _color = color;
  GLvector2 center2d = (start + end) / 2;
  _center = glVector(center2d.x, bottom, center2d.y);
  
  GLvector to = glVectorNormalize(glVector(start.x, 0.0f, start.y) - glVector(end.x, 0.0f, end.y));
  GLvector out = glVectorCrossProduct(glVector(0.0f, 1.0f, 0.0f), to) * LOGO_OFFSET;
  
  float height = ((start - end) / 8.0f).Length() * 1.5f;
  float top = bottom + height, u1 = 0.0f, u2 = 1.0f, v1 = 1.0f, v2 = 0.0f;

  [_mesh addVertex:GLvertex(glVector(start.x, bottom, start.y) + out, glVector(u1, v1), _color) ];
  [_mesh addVertex:GLvertex(glVector(end.x  , bottom, end.y  ) + out, glVector(u2, v1), _color) ];
  [_mesh addVertex:GLvertex(glVector(end.x  , top   , end.y  ) + out, glVector(u2, v2), _color) ];
  [_mesh addVertex:GLvertex(glVector(start.x, top   , start.y) + out, glVector(u1, v2), _color) ];
  
  [_mesh addQuadStrip:quad_strip( 0, 1, 3, 2, LIST_TERM) ];
  
  _texture = TextureRandomLogo(); // TextureId (TEXTURE_LOGOS);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) CreateLightStripWithX:(float) x z:(float) z width:(float) width depth:(float) depth height:(float) height color:(GLrgba) color;
{
  _color = color;
  _use_alpha = true;
  _center = glVector (x + width / 2, height, z + depth / 2);
  _texture = TextureId (TEXTURE_LIGHT);
  
  float u = (width < depth) ? 1.0f : float(int(width / depth));
  float v = (width < depth) ? float(int(depth / width)) : 1.0f;
  [_mesh addVertex:GLvertex(glVector(x        , height, z        ), glVector(0.0f, 0.0f))];
  [_mesh addVertex:GLvertex(glVector(x        , height, z + depth), glVector(0.0f, v   ))];
  [_mesh addVertex:GLvertex(glVector(x + width, height, z + depth), glVector(u   , v   ))];
  [_mesh addVertex:GLvertex(glVector(x + width, height, z        ), glVector(u   , 0.0f))];
  
  [_mesh addQuadStrip:quad_strip(0, 1, 3, 2, LIST_TERM)];
  [_mesh Compile];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) CreateLightTrimWithChain:(GLvector*) chain count:(int) count height:(float) height seed:(unsigned long) seed color:(GLrgba) color;
{
    _color = color;
    _center = glVector (0.0f, 0.0f, 0.0f);

    quad_strip qs;
    qs.index_list.reserve(count * 2 + 2);
    for (int i = 0; i < count; i++)
        _center = _center + chain[i];
    
    _center = _center / float(count);
    float row = float(seed % TRIM_ROWS);
    float v1 = row * TRIM_SIZE, v2 = (row + 1.0f) * TRIM_SIZE, u = 0.0f;
    int index = 0;

    GLvertex p;
    for (int i = 0; i < count + 1; i++)
    {
        if (i)
            u += (chain[i % count] - p.position).Length() * 0.1f;
        
            //Add the bottom point
        int prev = i - 1;
        if (prev < 0)
            prev = count + prev;
        
        int next = (i + 1) % count;
        GLvector to = glVectorNormalize (chain[next] - chain[prev]);
        GLvector out = glVectorCrossProduct (glVector (0.0f, 1.0f, 0.0f), to) * LOGO_OFFSET;
        p.position = chain[i % count] + out; p.uv = glVector (u, v2);
        [_mesh addVertex:p];
        qs.index_list.push_back(index++);
        
            //Top point
        p.position.y += height; p.uv = glVector(u, v1);
        [_mesh addVertex:p];
        qs.index_list.push_back(index++);
    }
    
    [_mesh addQuadStrip:qs];
    _texture = TextureId (TEXTURE_TRIM);
    [_mesh Compile];
}

@end
