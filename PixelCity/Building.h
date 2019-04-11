// 2009 Shamus Young
// Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
// Released under the GNU GPL v3. See file COPYING for details.

#import "Entity.h"
#import "glRgba.h"
#import "Win.h"

enum BuildingType
{
  BUILDING_SIMPLE,
  BUILDING_BLOCKY,
  BUILDING_MODERN,
  BUILDING_TOWER
};

@class Mesh, World;

@interface Building : Entity
  
-(float)constructWallWithPosition:(const GLvector3 &) position
                        direction:(RoadDirection) direction
                           length:(int) length
                           height:(int) height
                     windowGroups:(GLulong) wgroup
                          UVStart:(float)   uvStart
                     blankCorners:(BOOL)    blankCorners;

-(void)ConstructSpikeWithLeft:(int) left
                        right:(int) right
                        front:(int) front
                         back:(int) back
                       bottom:(int) bottom
                          top:(int) top;

-(void)ConstructCubeWithLeft:(int) left
                       right:(int) right
                       front:(int) front
                        back:(int) back
                      bottom:(int) bottom
                         top:(int) top;

-(void)ConstructCubeWithFloatLeft:(float) left
                            right:(float) right
                            front:(float) front
                             back:(float) back
                           bottom:(float) bottom
                              top:(float) top;

-(void)ConstructRoofWithLeft:(float) left
                       right:(float) right
                       front:(float) front
                        back:(float) back
                      bottom:(float) bottom;

-(id)initWithType:(BuildingType) type
                x:(int) x
                y:(int) y
           height:(int) height
            width:(int) width
            depth:(int) depth
             seed:(int) seed
            color:(const GLrgba &) color
        trimColor:(const GLrgba &) trimColor
            world:(World*) world;

+(id)buildingWithType:(BuildingType) type
                    x:(int) x
                    y:(int) y
               height:(int) height
                width:(int) width
                depth:(int) depth
                 seed:(int) seed
                color:(const GLrgba &) color
            trimColor:(const GLrgba &) trimColor
                world:(World*) world;

+(id)buildingWithType:(BuildingType) type
                    x:(int) x
                    y:(int) y
               height:(int) height
                width:(int) width
                depth:(int) depth
                 seed:(int) seed
                color:(const GLrgba &) color
                world:(World*) world;

@end

