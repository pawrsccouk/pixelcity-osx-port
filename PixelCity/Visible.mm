/*-----------------------------------------------------------------------------

  Visible.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  This module runs the visibility grid, a 2-dimensional array that aids in
  culling objects during rendering. 

  There are many ways this could be refined or sped up, although tests indicate
  it's not a huge drain on performance.

-----------------------------------------------------------------------------*/



#import "Model.h"
#import "camera.h"
#import "visible.h"
#import "world.h"
#import "win.h"

static bool          vis_grid[GRID_SIZE][GRID_SIZE];

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

bool Visible (GLvector pos)
{

  return vis_grid[WORLD_TO_GRID(pos.x)][WORLD_TO_GRID(pos.z)];

}


/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

bool Visible (int x, int z)
{

  return vis_grid[x][z];

}



/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

void VisibleUpdate (void)
{    
        //Clear the visibility table
    memset(vis_grid, 0, sizeof (vis_grid));
    
        //Calculate which cell the camera is in
    GLvector angle = CameraAngle(), position = CameraPosition();
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
            vis_grid[x][y] = true;
        }
    }
        //Doesn't matter where we are facing, objects in current cell are always visible
    vis_grid[grid_x][grid_z] = true;
    
        //Here, we look at the angle from the current camera position to the cell on the grid, and how much that angle deviates from the current view angle.
    for (int x = 0; x < GRID_SIZE; x++) {
        for (int y = 0; y < GRID_SIZE; y++) {
                //if we marked it visible earlier, skip all this math
            if (vis_grid[x][y])
                continue;
            
                //if the camera is to the left of this cell, use the left edge
            float target_x = (grid_x < x) ? (float)x * GRID_RESOLUTION : (float)(x + 1) * GRID_RESOLUTION;
            float target_z = (grid_z < y) ? (float)y * GRID_RESOLUTION : (float)(y + 1) * GRID_RESOLUTION;
            float angle_to = 180 - MathAngle2(target_x, target_z, position.x, position.z);
            
                //Store how many degrees the cell is to the 
            float angle_diff = (float)fabs (MathAngleDifference (angle.y, angle_to));
            vis_grid[x][y] = angle_diff < 45;
        }
    }
}
  
