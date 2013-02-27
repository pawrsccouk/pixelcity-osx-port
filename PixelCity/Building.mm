/*-----------------------------------------------------------------------------

  Building.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  This module contains the class to construct the buildings.  

-----------------------------------------------------------------------------*/

static const int MAX_VBUFFER = 256;

#import "Model.h"
#import "light.h"
#import "building.h"
#import "deco.h"
#import "mesh.h"
#import "texture.h"
#import "world.h"
#import "win.h"

//This is used by the recursive roof builder to decide what items may be added.
enum AddonType
{
  ADDON_NONE,
  ADDON_LOGO,
  ADDON_TRIM,
  ADDON_LIGHTS,
  ADDON_COUNT
};

static const short LIGHT_SIZE  = 1;
static const float ONE_SEGMENT = (1.0f / SEGMENTS_PER_TEXTURE);

struct Cube
{
    float _front, _back, _left, _right, _top, _bottom;
    Cube(float front, float back, float left, float right, float top, float bottom)
    : _front(front), _back(back), _left(left), _right(right), _top(top), _bottom(bottom) {}
};

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

@interface Building ()
{
    int     _x, _y, _width, _depth, _height;
    GLulong _texture_type, _seed, _roof_tiers;
    GLrgba  _color, _trim_color;
    Mesh   *_mesh, *_mesh_flat;
    BOOL    _have_lights, _have_trim, _have_logo;
}

-(void)CreateSimple;
-(void)CreateBlocky;
-(void)CreateModern;
-(void)CreateTower;

@end

@implementation Building

+(id)buildingWithType:(BuildingType) type
                    x:(int) x
                    y:(int) y
               height:(int) height
                width:(int) width
                depth:(int) depth
                 seed:(int) seed
                color:(GLrgba) color
                world:(World*) world
{
    return [[Building alloc] initWithType:type x:x y:y height:height width:width depth:depth seed:seed color:color world:world];
}

-(id)initWithType:(BuildingType) type
                x:(int) x
                y:(int) y
           height:(int) height
            width:(int) width
            depth:(int) depth
             seed:(int) seed
            color:(GLrgba) color
            world:(World*) world
{
    self = [super initWithWorld:world];
    if(self) {
        _color = color.colorWithAlpha(0.1f);
        _trim_color = [world lightColorAtIndex:seed];
        _x = x;
        _y = y;
        _width = width;
        _depth = depth;
        _height = height;
        _center = glVector (float(_x + width / 2), 0.0f, float(_y + depth / 2));
        _seed = seed;
        _texture_type = RandomInt();
        _have_lights =  _have_logo = _have_trim = false;
        _roof_tiers = 0;
            //Pick a color for logos & roof lights
        _mesh       = [[Mesh alloc] init]; //The main textured mesh for the building
        _mesh_flat  = [[Mesh alloc] init]; //Flat-color mesh for untextured detail items.
        switch (type) {
            case BUILDING_SIMPLE:  [self CreateSimple];   break;
            case BUILDING_MODERN:  [self CreateModern];   break;
            case BUILDING_TOWER:   [self CreateTower ];   break;
            case BUILDING_BLOCKY:  [self CreateBlocky];   break;
        }
    }
    return self;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(GLuint) texture
{
  return [self.world.textures randomBuilding:_texture_type];
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(GLulong) polyCount
{
  return _mesh.polyCount + _mesh_flat.polyCount;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) Render
{
    _color.glColor3();
    [_mesh Render];
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) RenderFlat: (BOOL) colored
{ 
    if (colored) {
        _color.glColor3();
    }
    [_mesh_flat Render];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static GLvertex GLvertexMake(float x, float y, float z, float u, float v)
{
    return GLvertex(glVector(x, y, z), glVector(u, v), GLrgba(1.0f, 1.0f, 1.0f, 1.0f), 0);
}

-(void)ConstructCubeWithLeft:(int) left
                       right:(int) right
                       front:(int) front
                        back:(int) back
                      bottom:(int) bottom
                         top:(int) top
{
    float x1 = left, x2 = right, y1 = bottom, y2 = top, z1 = front, z2 = back;
    float mapping = float(SEGMENTS_PER_TEXTURE);
    float u  = float(RandomInt () % SEGMENTS_PER_TEXTURE) / float(SEGMENTS_PER_TEXTURE);
    float v1 = float(bottom) / float(mapping), v2 = float(top) / float(mapping);
    
    GLvertex p[10];
    p[0] = GLvertexMake(x1, y1, z1, u, v1);
    p[1] = GLvertexMake(x1, y2, z1, u, v2);
    u += float(_width) / mapping;
    
    p[2] = GLvertexMake(x2, y1, z1, u, v1);
    p[3] = GLvertexMake(x2, y2, z1, u, v2);
    u += float(_depth) / mapping;
    
    p[4] = GLvertexMake(x2, y1, z2, u, v1);
    p[5] = GLvertexMake(x2, y2, z2, u, v2);
    u += float(_width) / mapping;
    
    p[6] = GLvertexMake(x1, y1, z2, u, v1);
    p[7] = GLvertexMake(x1, y2, z2, u, v2);
    u += float(_width) / mapping;
    
    p[8] = GLvertexMake(x1, y1, z1, u, v1);
    p[9] = GLvertexMake(x1, y2, z1, u, v2);
    
    GLulong base_index = _mesh.vertexCount;
    cube c;
    for (int i = 0; i < 10; i++) {
        p[i].uv.x = (p[i].position.x + p[i].position.z) / (float)SEGMENTS_PER_TEXTURE;
        [_mesh addVertex:p[i]];
        c.index_list.push_back(base_index + i);
    }
    [_mesh addCube:c];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void)ConstructCubeWithFloatLeft:(float)  left right:(float) right front:(float) front back:(float) back bottom:(float) bottom top:(float) top
{
    float x1 = left  , x2 = right;
    float y1 = bottom, y2 = top;
    float z1 = front , z2 = back;
    
    GLvertex p[10];
    p[0] = GLvertexMake(x1, y1, z1, 0.0f, 0.0f);
    p[1] = GLvertexMake(x1, y2, z1, 0.0f, 0.0f);
    p[2] = GLvertexMake(x2, y1, z1, 0.0f, 0.0f);
    p[3] = GLvertexMake(x2, y2, z1, 0.0f, 0.0f);
    p[4] = GLvertexMake(x2, y1, z2, 0.0f, 0.0f);
    p[5] = GLvertexMake(x2, y2, z2, 0.0f, 0.0f);
    p[6] = GLvertexMake(x1, y1, z2, 0.0f, 0.0f);
    p[7] = GLvertexMake(x1, y2, z2, 0.0f, 0.0f);
    p[8] = GLvertexMake(x1, y1, z1, 0.0f, 0.0f);
    p[9] = GLvertexMake(x1, y2, z1, 0.0f, 0.0f);
    
    cube  c;
    GLulong base_index = _mesh_flat.vertexCount;
    for (int i = 0; i < 10; i++) {
        p[i].uv.x = (p[i].position.x + p[i].position.z) / (float)SEGMENTS_PER_TEXTURE;
        [_mesh_flat addVertex:p[i]];
        c.index_list.push_back(base_index + i);
    }
    [_mesh_flat addCube:c];
}

/*-----------------------------------------------------------------------------
  This will take the given area and populate it with rooftop stuff like
  air conditioners or light towers.
-----------------------------------------------------------------------------*/

-(void)ConstructRoofWithLeft:(float)  left right:(float) right front:(float) front back:(float) back bottom:(float) bottom
{
    int       air_conditioners = 0, i = 0;
    int       face = 0;
    GLulong addon = 0;
    float     ac_base = 0.0f;
    
    _roof_tiers++;
    int max_tiers = _height / 10;
    int width = int(right - left );
    int depth = int(back  - front);
    GLulong height = 5 - _roof_tiers;
    float logo_offset = 0.2f;
    
        //See if this building is special and worthy of fancy roof decorations.
    if (bottom > 35.0f)
        addon = RandomIntR(ADDON_COUNT);

        //Build the roof slab
    [self ConstructCubeWithLeft:left right:right front:front back:back bottom:bottom top:bottom + height];
    
        //Consider putting a logo on the roof, if it's tall enough
    if (addon == ADDON_LOGO && !_have_logo) {
        Deco *d = [[Deco alloc] initWithWorld:self.world];
        
        face = (width > depth) ? (COIN_FLIP() ? NORTH : SOUTH)
                               : (COIN_FLIP() ? EAST  : WEST);
        GLvector2 start, end;
        switch (face) {
            case NORTH:
                start = glVector (left , back + logo_offset);
                end   = glVector (right, back + logo_offset);
                break;
            case SOUTH:
                start = glVector (right, front - logo_offset);
                end   = glVector (left , front - logo_offset);
                break;
            case EAST:
                start = glVector (right + logo_offset, back );
                end   = glVector (right + logo_offset, front);
                break;
            case WEST:
            default:
                start = glVector (left - logo_offset, front);
                end   = glVector (left - logo_offset, back );
                break;
        }
        [d CreateLogoWithStart:start end:end base:bottom seed:self.world.logoIndex color:_trim_color];
        _have_logo = true;
    } else if (addon == ADDON_TRIM) {
        Deco *d =  [[Deco alloc] initWithWorld:self.world];
        GLvector vector_buffer[4];
        vector_buffer[0] = glVector (left  - logo_offset, bottom, back  + logo_offset);
        vector_buffer[1] = glVector (left  - logo_offset, bottom, front - logo_offset);
        vector_buffer[2] = glVector (right + logo_offset, bottom, front - logo_offset);
        vector_buffer[3] = glVector (right + logo_offset, bottom, back  + logo_offset);
        [d CreateLightTrimWithChain:vector_buffer count:4 height:(float)RandomIntR(2) + 1.0f seed:_seed color:_trim_color];
    } else if (addon == ADDON_LIGHTS && !_have_lights) {
        Lights *lights = self.world.lights;
        [lights newLightWithPosition:glVector(left , (float)(bottom + 2), front) color:_trim_color size:LIGHT_SIZE blink:NO];
        [lights newLightWithPosition:glVector(right, (float)(bottom + 2), front) color:_trim_color size:LIGHT_SIZE blink:NO];
        [lights newLightWithPosition:glVector(right, (float)(bottom + 2), back ) color:_trim_color size:LIGHT_SIZE blink:NO];
        [lights newLightWithPosition:glVector(left , (float)(bottom + 2), back ) color:_trim_color size:LIGHT_SIZE blink:NO];
        _have_lights = true;
    }
    bottom += (float)height;
        //If the roof is big enough, consider making another layer
    if (width > 7 && depth > 7 && _roof_tiers < max_tiers) {
        [self ConstructRoofWithLeft:left + 1 right:right - 1 front:front + 1 back:back - 1 bottom:bottom];
        return;
    }
        //1 air conditioner block for every 15 floors sounds reasonble
    air_conditioners = _height / 15;
    for (i = 0; i < air_conditioners; i++) {
        float ac_size = (float)(10 + RandomIntR(30)) / 10;
        float ac_height = (float)RandomIntR(20) / 10 + 1.0f;
        float ac_x = left + (float)RandomIntR(width);
        float ac_y = front + (float)RandomIntR(depth);
            //make sure the unit doesn't hang off the right edge of the building
        if (ac_x + ac_size > (float)right) {
            ac_x = (float)right - ac_size;
        }
            //make sure the unit doesn't hang off the back edge of the building
        if (ac_y + ac_size > (float)back) {
            ac_y = (float)back - ac_size;
        }
        ac_base = (float)bottom;
            //make sure it doesn't hang off the edge
        [self ConstructCubeWithFloatLeft:ac_x right:ac_x + ac_size front:ac_y back:ac_y + ac_size bottom:ac_base top:ac_base + ac_height];
    }
    
    if (_height > 45) {
        Deco *d = [[Deco alloc] initWithWorld:self.world];
        [d CreateRadioTowerWithPosition:glVector ((float)(left + right) / 2.0f, (float)bottom, (float)(front + back) / 2.0f) height:15.0f];
    }
}



-(void)ConstructSpikeWithLeft:(int) left right:(int) right front:(int) front back:(int) back bottom:(int) bottom top:(int) top
{
    fan f;
    for (int i = 0; i < 5; i++) {
        f.index_list.push_back(_mesh_flat.vertexCount + i);
    }
    f.index_list.push_back(f.index_list[1]);
    
    [_mesh_flat addVertex:GLvertexMake(float(left + right) / 2.0f, top, float(front + back) / 2.0f, 0.0f, 0.0f)];
    [_mesh_flat addVertex:GLvertexMake(left , bottom, back , 0.0f, 0.0f)];
    [_mesh_flat addVertex:GLvertexMake(right, bottom, back , 0.0f, 0.0f)];
    [_mesh_flat addVertex:GLvertexMake(right, bottom, front, 0.0f, 0.0f)];
    [_mesh_flat addVertex:GLvertexMake(left , bottom, front, 0.0f, 0.0f)];
    
    [_mesh_flat addFan:f];
}

/*-----------------------------------------------------------------------------
  This builds an outer wall of a building, with blank (windowless) areas deliberately left.  
  It creates a chain of segments that alternate between windowed and windowless, and it always makes sure the wall is symetrical.  
  window_groups tells it how many windows to place in a row.
-----------------------------------------------------------------------------*/

-(float)constructWallWithPosition:(const GLvector3 &) pos
                 direction:(RoadDirection) direction
                    length:(int) length
                    height:(int) height
              windowGroups:(GLulong) windowGroups
                   UVStart:(float)   uvStart
              blankCorners:(BOOL)    blankCorners
{
    int step_x, step_z;
    switch (direction) {
        case NORTH:   step_z =  1; step_x =  0; break;
        case WEST:    step_z =  0; step_x = -1; break;
        case SOUTH:   step_z = -1; step_x =  0; break;
        case EAST:    step_z =  0; step_x =  1; break;
    }
    
    int x = pos.x, z = pos.z, mid = (length / 2) - 1, odd = 1 - (length % 2);
    if (length % 2)
        mid++;
        //mid = (length / 2);
    
    GLvertex    v;
    quad_strip  qs;
    qs.index_list.reserve(2 * length);
    v.uv.x = (float)(x + z) / SEGMENTS_PER_TEXTURE;
    v.uv.x = uvStart;
    bool blank = false;
    for (int i = 0; i <= length; i++)
    {
            //column counts up to the mid point, then back down, to make it symetrical
        int column = (i <= mid) ? i - odd : (mid) - (i - (mid));
        
        bool last_blank = blank;
        blank = (column % windowGroups) > windowGroups / 2;
        if( (blankCorners && i == 0) || (blankCorners && i == (length - 1)) ) {
            blank = true;
        }
        if (last_blank != blank || i == 0 || i == length)
        {
            v.position = GLvector3(x, pos.y, z);
            v.uv.y = float(pos.y) / SEGMENTS_PER_TEXTURE;
            [_mesh addVertex:v];
            qs.index_list.push_back(_mesh.vertexCount - 1);
            
            v.position.y = float(pos.y + height);
            v.uv.y = float(pos.y + height) / SEGMENTS_PER_TEXTURE;;
            [_mesh addVertex:v];
            qs.index_list.push_back(_mesh.vertexCount - 1);
        }
            //if (!blank && i != 0 && i != (length - 1))
        if (!blank && i != length) {
            v.uv.x += 1.0f / SEGMENTS_PER_TEXTURE;
        }
        x += step_x;
        z += step_z;
    }
    [_mesh addQuadStrip:qs];
    return v.uv.x;
}

/*-----------------------------------------------------------------------------

  This makes a big chunky building of intersecting cubes.  

-----------------------------------------------------------------------------*/

-(void)CreateBlocky
{
    bool blank_corners = COIN_FLIP();    //Choose if the corners of the building are to be windowless.
    float uv_start = (float)RandomIntR(SEGMENTS_PER_TEXTURE) / SEGMENTS_PER_TEXTURE;    //Choose a random column on our texture;
    GLulong grouping = 2 + RandomIntR(4);    //Choose how the windows are grouped
    float lid_height = RandomIntR(3) + 1;    //Choose how tall the lid should be on top of each section
    
        //find the center of the building.
    GLint mid_x = _x + _width / 2;
    GLint mid_z = _y + _depth / 2;
    GLint max_left = 1, max_right = 1, max_front = 1, max_back = 1;
    GLint height = _height;
        //  min_height = _height / 2;
    GLint min_height = 3;
    GLint half_depth = _depth / 2, half_width = _width / 2;
    
    GLint tiers = 0, max_tiers = 1;
    if      (_height > 40) { max_tiers = 15; }
    else if (_height > 30) { max_tiers = 10; }
    else if (_height > 20) { max_tiers = 5;  }
    else if (_height > 10) { max_tiers = 2;  }
    
        //We begin at the top of the building, and work our way down.
        //Viewed from above, the sections of the building are randomly sized rectangles that ALWAYS include the center of the building somewhere within their area.
    while (true) {
        if( (height < min_height) || (tiers >= max_tiers) )
            break;
        
            //pick new locationsfor our four outer walls
        GLint left  = (RandomInt () % half_width) + 1, right = (RandomInt () % half_width) + 1;
        GLint front = (RandomInt () % half_depth) + 1, back  = (RandomInt () % half_depth) + 1;
        
            //At least ONE of the walls must reach out beyond a previous maximum. Otherwise, this tier would be completely hidden within a previous one.
            //Or if any of the four walls is in the same position as the previous max, then skip this tier, or else the two walls will end up z-fightng.
        bool skip = (left <= max_left && right <= max_right && front <= max_front && back <= max_back)
        || (left == max_left || right == max_right || front == max_front || back == max_back);
        
        if (! skip) {
                //if this is the top, then put some lights up here
            max_left  = std::max(left , max_left );
            max_right = std::max(right, max_right);
            max_front = std::max(front, max_front);
            max_back  = std::max(back , max_back );
            
                //Now build the four walls of this part
            auto makeWall = ^(Building *building, const GLvector &posn, RoadDirection d, GLint l, GLint h) {
                return [building constructWallWithPosition:posn direction:d length:l height:h windowGroups:grouping UVStart:uv_start blankCorners:blank_corners] - ONE_SEGMENT;
            };
            uv_start = makeWall(self, GLvector(mid_x - left , 0, mid_z + back ), SOUTH, front + back, height);
            uv_start = makeWall(self, GLvector(mid_x - left , 0, mid_z - front), EAST , right + left, height);
            uv_start = makeWall(self, GLvector(mid_x + right, 0, mid_z - front), NORTH, front + back, height);
            uv_start = makeWall(self, GLvector(mid_x + right, 0, mid_z + back ), WEST , right + left, height);
            if (!tiers)
                [self ConstructRoofWithLeft:mid_x - left right:mid_x + right front:mid_z - front back:mid_z + back bottom:height];
            else {
                    //add a flat-color lid onto this section
                [self ConstructCubeWithFloatLeft:mid_x - left right:mid_x + right front:mid_z - front back:mid_z + back bottom:height top:height + lid_height];
            }
            height -= (RandomInt () % 10) + 1;
            tiers++;
        }
        height--;
    }
    
    [self ConstructCubeWithLeft:mid_x - half_width right:mid_x + half_width front:mid_z - half_depth back:mid_z + half_depth bottom:0 top:2];
    [_mesh Compile];
    [_mesh_flat Compile];
}

/*-----------------------------------------------------------------------------

  A single-cube building.  Good for low-rise buildings and stuff that will be 
  far from the camera;

-----------------------------------------------------------------------------*/

static void addToMesh(float x, float y, float z, float u, float v, Mesh *mesh)
{
    GLvertex p;
    p.bone     = 0;
    p.color    = GLrgba();
    p.position = glVector (x, y, z);
    p.uv       = glVector (u, v);
    [mesh addVertex:p];
}

-(void)CreateSimple
{
    float x1 = _x  , x2 = _x + _width, y1 = 0.0f, y2 = _height, z2 = _y  , z1 = _y + _depth;
    
    float u  = float(RandomIntR(SEGMENTS_PER_TEXTURE)) / SEGMENTS_PER_TEXTURE;
    float v1 = float(RandomIntR(SEGMENTS_PER_TEXTURE)) / SEGMENTS_PER_TEXTURE;
    float v2 = v1 + float(_height) * ONE_SEGMENT;
    
    addToMesh(x1, y1, z1, u, v1, _mesh);
    addToMesh(x1, y2, z1, u, v2, _mesh);
    u += (float)_depth / SEGMENTS_PER_TEXTURE;
    
    addToMesh(x1, y1, z2, u, v1, _mesh);
    addToMesh(x1, y2, z2, u, v2, _mesh);
    u += (float)_width / SEGMENTS_PER_TEXTURE;
    
    addToMesh(x2, y1, z2, u, v1, _mesh);
    addToMesh(x2, y2, z2, u, v2, _mesh);
    u += (float)_depth / SEGMENTS_PER_TEXTURE;
    
    addToMesh(x2, y1, z1, u, v1, _mesh);
    addToMesh(x2, y2, z1, u, v2, _mesh);
    u += (float)_depth / SEGMENTS_PER_TEXTURE;
    
    addToMesh(x1, y1, z1, u, v1, _mesh);
    addToMesh(x1, y2, z1, u, v2, _mesh);
    
    quad_strip  qs;
    for(int i=0; i<=10; i++) {
        qs.index_list.push_back(i);
    }
    [_mesh addQuadStrip:qs];
    
    float cap_height = float(1 + RandomIntR(4));  //How tall the flat-color roof is
    float ledge = float(RandomIntR(10)) / 30.0f;  //how much the ledge sticks out
    [self ConstructCubeWithFloatLeft:x1 - ledge right:x2 + ledge front:z2 - ledge back:z1 + ledge bottom:_height top:_height + cap_height];
    
    [_mesh Compile];
}


//  This makes a deformed cylinder building.  
-(void)CreateModern
{
    std::vector<GLvector3> vector_buffer;
    vector_buffer.resize(MAX_VBUFFER);
        
    GLvector pos;
    GLulong cap_height    = 1 + RandomIntR(5);        // How tall the windowless section on top will be.
    GLulong skip_interval = 1 + RandomIntR(8);        // How many 10-degree segments to build before the next skip.
    GLulong skip_delta    = (1 + RandomIntR(2)) * 30; // When a skip happens, how many degrees should be skipped: 30 60 or 90
    
        //Get the center and radius of the circle
    GLint half_depth = _depth / 2, half_width = _width / 2;
    GLvector  center(_x + half_width, 0.0f, _y + half_depth);
    GLvector2 radius(half_width, half_depth);
    GLvertex    p;
    p.uv.x = 0.0f;
    GLint points = 0, skip_counter = 0;
    bool logo_done = false;
    
    GLint windows = 0;
    for (GLint angle = 0; angle <= 360; angle += 10) {
        if (skip_counter >= skip_interval && (angle + skip_delta < 360)) {
            angle += skip_delta;
            skip_counter = 0;
        }
        pos.x = center.x - sinf ((float)angle * DEGREES_TO_RADIANS) * radius.x;
        pos.z = center.z + cosf ((float)angle * DEGREES_TO_RADIANS) * radius.y;
        if (angle > 0 && skip_counter == 0) {
            float length = MathDistance (p.position.x, p.position.z, pos.x, pos.z);
            windows += (int)length;
            if (length > 10 && ! logo_done) {
                logo_done = true;
                GLvector2 start(pos.x, pos.z), end(p.position.x, p.position.z);
                Deco *d = [[Deco alloc] initWithWorld:self.world];
                [d CreateLogoWithStart:start end:end base:_height seed:self.world.logoIndex color:RANDOM_COLOR()];
            }
        } else if (skip_counter != 1)
            windows++;
        
        p.position = pos;
        p.uv.x = (float)windows / (float)SEGMENTS_PER_TEXTURE;
        p.uv.y = 0.0f;
        p.position.y = 0.0f;
        [_mesh addVertex:p];
        
        p.position.y = (float)_height;
        p.uv.y = (float)_height / (float)SEGMENTS_PER_TEXTURE;
        [_mesh addVertex:p];
        [_mesh_flat addVertex:p];
        
        p.position.y += (float)cap_height;
        [_mesh_flat addVertex:p];
        
        vector_buffer[points / 2] = p.position;
        vector_buffer[points / 2].y = (float)_height + cap_height / 4;
        points += 2;
        skip_counter++;
    }
        //if this is a big building and it didn't get a logo, consider giving it a light strip
    bool do_trim = (_height > 48 && RandomIntR(3) == 0);
    if (!logo_done && do_trim) {
        Deco *d = [[Deco alloc] initWithWorld:self.world];
        [d CreateLightTrimWithChain:&vector_buffer[0] count:(points / 2) - 2 height:(float)cap_height / 2 seed:_seed color:RANDOM_COLOR()];
    }
    
        //Add the outer walls
    quad_strip qs;
    qs.index_list.reserve(points);
    for (GLint i = 0; i < points; i++)
        qs.index_list.push_back(i);
        
        [_mesh addQuadStrip:qs];
    [_mesh_flat addQuadStrip:qs];
    
        //add the fan to cap the top of the buildings
    fan f;
    f.index_list.push_back(points);
    for (GLint i = 0; i < points / 2; i++)
        f.index_list.push_back(points - (1 + i * 2));
        
        p.position.x = _center.x;
        p.position.z = _center.z;
        [_mesh_flat addVertex:p];
    [_mesh_flat addFan:f];
    radius = radius / 2.0f;
    
        //ConstructRoof ((int)(_center.x - radius), (int)(_center.x + radius), (int)(_center.z - radius), (int)(_center.z + radius), _height + cap_height);
    [_mesh Compile];
    [_mesh_flat Compile];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void)CreateTower
{
    const float   ledge        = float(RandomIntR(3)) * 0.25f;    // How much ledges protrude from the building
    const GLulong ledge_height = RandomIntR(4) + 1;               // How tall the ledges are, in stories
    const GLulong grouping     = RandomIntR(3) + 2;               // How the windows are grouped
    const bool    blank_corners = RandomIntR(4) > 0;              // If the corners of the building have no windows
    const GLuint  tier_fraction      = 2 + RandomIntR(4);         // What fraction of the remaining height should be given to each tier
    const GLulong narrowing_interval = 1 + RandomIntR(10);        // How often (in tiers) does the building get narrower?
    const GLulong foundation         = 2 + RandomIntR(3);         // The height of the windowsless slab at the bottom
    GLint   left  = _x, right = _x + _width, front = _y, back  = _y + _depth, bottom = 0, tiers = 0;
    
        //build the foundations.
    [self ConstructCubeWithFloatLeft:(float)left - ledge right:(float)right + ledge front:(float)front - ledge back:(float)back + ledge bottom:(float)bottom top:(float)foundation];
    bottom += foundation;
    
        //now add tiers until we reach the top
    while (true) {
        int remaining_height = _height - bottom, section_depth = back - front;
        int section_width = right - left, section_height = (remaining_height < 10) ? remaining_height : std::max(remaining_height / tier_fraction, 2u);
    
            //Build the four walls
        float uv_start = (float)RandomIntR(SEGMENTS_PER_TEXTURE) / SEGMENTS_PER_TEXTURE;
        uv_start = [self constructWallWithPosition:GLvector(left , bottom, back ) direction:SOUTH length:section_depth height:section_height windowGroups:grouping UVStart:uv_start blankCorners:blank_corners] - ONE_SEGMENT;
        uv_start = [self constructWallWithPosition:GLvector(left , bottom, front) direction:EAST  length:section_width height:section_height windowGroups:grouping UVStart:uv_start blankCorners:blank_corners] - ONE_SEGMENT;
        uv_start = [self constructWallWithPosition:GLvector(right, bottom, front) direction:NORTH length:section_depth height:section_height windowGroups:grouping UVStart:uv_start blankCorners:blank_corners] - ONE_SEGMENT;
        uv_start = [self constructWallWithPosition:GLvector(right, bottom, back ) direction:WEST  length:section_width height:section_height windowGroups:grouping UVStart:uv_start blankCorners:blank_corners] - ONE_SEGMENT;
        bottom += section_height;
        
            //Build the slab / ledges to cap this section.
        if (bottom + ledge_height > _height)
            break;
        [self ConstructCubeWithFloatLeft:(float)left - ledge right:(float)right + ledge front:(float)front - ledge back:(float)back + ledge bottom:(float)bottom top:(float)(bottom + ledge_height)];
        bottom += ledge_height;
        if (bottom > _height)
            break;
        
        tiers++;
        if ((tiers % narrowing_interval) == 0) {
            if (section_width > 7) {
                left  += 1;
                right -= 1;
            }
            if (section_depth > 7) {
                front += 1;
                back  -= 1;
            }
        }
    }

    [self ConstructRoofWithLeft:float(left) right:float(right) front:float(front) back:float(back) bottom:float(bottom)];
    
    
    [_mesh Compile];
    [_mesh_flat Compile];
}



@end
