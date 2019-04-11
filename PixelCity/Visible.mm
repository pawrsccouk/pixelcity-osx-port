/*-----------------------------------------------------------------------------

  Visible.cpp

  2009 Shamus Young
  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
  Released under the GNU GPL v3. See file COPYING for details.

-------------------------------------------------------------------------------

  This module runs the visibility grid, a 2-dimensional array that aids in
  culling objects during rendering. 

  There are many ways this could be refined or sped up, although tests indicate
  it's not a huge drain on performance.

-----------------------------------------------------------------------------*/



#import "Model.h"
#import "Camera.h"
#import "Visible.h"
#import "World.h"
#import "Win.h"

@interface VisibilityGrid ()
{
    BOOL _vis_grid[GRID_SIZE][GRID_SIZE];
}
@end


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

@implementation VisibilityGrid
@synthesize world = _world;

- (id)initWithWorld:(World *)world
{
    self = [super init];
    if (self) {
        _world = world;
    }
    return self;
}

-(BOOL)visibleAtPosition:(const GLvector &) pos
{
  return _vis_grid[WORLD_TO_GRID(pos.x)][WORLD_TO_GRID(pos.z)];
}


-(BOOL)visibleAtX:(int)x Z:(int)z
{
  return _vis_grid[x][z];
}

-(void)update
{
        //Clear the visibility table
    memset(_vis_grid, 0, sizeof(_vis_grid));
    
        //Calculate which cell the camera is in
    Camera *camera = self.world.camera;
    GLvector angle = camera.angle, position = camera.position;
    int grid_x = WORLD_TO_GRID(position.x), grid_z = WORLD_TO_GRID(position.z);
    
        //Cells directly adjactent to the camera might technically fall out of the fov,
        //but still have a few objects poking into screenspace when looking up or down.
        //Rather than obsess over sorting those objects properly, it's more efficient to just mark them visible.
    int left = 3, right = 3, front = 3, back = 3;
    if (angle.y < 45.0f  || angle.y > 315.0f)  front = 0;  //Looking north, can't see south.
    if (angle.y > 135.0f && angle.y < 225.0f)  back  = 0;  //Looking south, can't see north
    if (angle.y > 45.0f  && angle.y < 135.0f)  left  = 0;  //Looking east , can't see west
    if (angle.y > 225.0f && angle.y < 315.0f)  right = 0;  //Looking west , can't see east
    
        //Now mark the block around us the might be visible
    for (int x = grid_x - left; x <= grid_x + right; x++) {
        if (x < 0 || x >= GRID_SIZE) //just in case the camera leaves the world map
            continue;
        for (int y = grid_z - back; y <= grid_z + front; y++) {
            if (y < 0 || y >= GRID_SIZE) //just in case the camera leaves the world map
                continue;
            _vis_grid[x][y] = true;
        }
    }
        //Doesn't matter where we are facing, objects in current cell are always visible
    _vis_grid[grid_x][grid_z] = true;
    
        //Here, we look at the angle from the current camera position to the cell on the grid, and how much that angle deviates from the current view angle.
    for (int x = 0; x < GRID_SIZE; x++) {
        for (int y = 0; y < GRID_SIZE; y++) {
                //if we marked it visible earlier, skip all this math
            if (_vis_grid[x][y])
                continue;
            
                //if the camera is to the left of this cell, use the left edge
            float target_x = (grid_x < x) ? float(x) * GRID_RESOLUTION : float(x + 1) * GRID_RESOLUTION;
            float target_z = (grid_z < y) ? float(y) * GRID_RESOLUTION : float(y + 1) * GRID_RESOLUTION;
            float angle_to = 180 - MathAngle2(target_x, target_z, position.x, position.z);
            
                //Store how many degrees the cell is to the 
            float angle_diff = (float)fabs (MathAngleDifference (angle.y, angle_to));
            _vis_grid[x][y] = angle_diff < 45;
        }
    }
}

@end

