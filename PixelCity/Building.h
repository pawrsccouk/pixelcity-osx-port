#import "entity.h"
#import "GLrgba.h"

enum BuildingType
{
  BUILDING_SIMPLE,
  BUILDING_BLOCKY,
  BUILDING_MODERN,
  BUILDING_TOWER
};

@class Mesh, World;

@interface Building : Entity
{
  int           _x, _y, _width, _depth, _height;
  GLulong _texture_type, _seed, _roof_tiers;
  GLrgba        _color, _trim_color;
  Mesh         *_mesh, *_mesh_flat;
  BOOL          _have_lights, _have_trim, _have_logo;
  __weak World *_world;
}

-(void)CreateSimple;
-(void)CreateBlocky;
-(void)CreateModern;
-(void)CreateTower;
  
-(float)ConstructWallWithX:(int) start_x Y:(int)start_y Z:(int) start_z
                       direction:(int) direction length:(int) length height:(int) height 
                       windowGroups:(GLulong) wgroup UVStart:(float) uvStart blankCorners:(BOOL) blankCorners;

-(void)ConstructSpikeWithLeft:(int) left right:(int) right front:(int) front back:(int) back bottom:(int) bottom top:(int) top;
-(void)ConstructCubeWithLeft:(int)  left right:(int) right front:(int) front back:(int) back bottom:(int) bottom top:(int) top;
-(void)ConstructCubeWithFloatLeft:(float)  left right:(float) right front:(float) front back:(float) back bottom:(float) bottom top:(float) top;
-(void)ConstructRoofWithLeft:(float)  left right:(float) right front:(float) front back:(float) back bottom:(float) bottom;

-(id)initWithType:(BuildingType) type x:(int) x y:(int) y height:(int) height width:(int) width depth:(int) depth seed:(int) seed color:(GLrgba) color world:(World*) world;
+(id)buildingWithType:(BuildingType) type x:(int) x y:(int) y height:(int) height width:(int) width depth:(int) depth seed:(int) seed color:(GLrgba) color world:(World*) world;

@end

