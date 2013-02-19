/*-----------------------------------------------------------------------------

  Car.cpp
  2009 Shamus Young

-------------------------------------------------------------------------------
  This creates the little two-triangle cars and moves them around the map.
-----------------------------------------------------------------------------*/

#import "Model.h"
#import "car.h"
#import "building.h"
#import "mesh.h"
#import "render.h"
#import "texture.h"
#import "visible.h"
#import "win.h"
#import "World.h"
#import "camera.h"

@interface Car : NSObject
{
    GLvector _position, _drivePosition;
    BOOL     _ready, _front;
    RoadDirection _direction;
    int      _drive_angle,  _change, _stuck;
    unsigned int _row, _col;
    float    _speed, _max_speed;
}

-(void) Render;
-(void) Update;
-(void) Park;

@end 

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


static const int DEAD_ZONE = 200, STUCK_TIME = 230, UPDATE_INTERVAL = 50; //milliseconds
static const float MOVEMENT_SPEED = 0.61f,  CAR_SIZE = 3.0f;

static GLvector direction[] = 
{
  GLvector( 0.0f, 0.0f, -1.0f),
  GLvector( 1.0f, 0.0f,  0.0f),
  GLvector( 0.0f, 0.0f,  1.0f),
  GLvector(-1.0f, 0.0f,  0.0f),
};

static const int dangles[] = { 0, 90, 180, 270 };
static GLvector2 angles[360];
static bool    angles_done;

static NSMutableArray *all_cars = [NSMutableArray array];

static int     count;
static unsigned char carmap[WORLD_SIZE][WORLD_SIZE];
static unsigned long next_update;

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark - Global Interface

size_t CarCount ()
{
  return count;
}

void CarAdd()
{
    [all_cars addObject:[[Car alloc] init]];
    count++;
}


void CarClear ()
{
    for(Car *car in all_cars)
        [car Park];
    memset(carmap, 0, sizeof(carmap));
    count = 0;
}


void CarRender ()
{
  if (!angles_done) {
    for (int i = 0 ;i < 360; i++) {
      angles[i].x = cosf ((float)i * DEGREES_TO_RADIANS) * CAR_SIZE;
      angles[i].y = sinf ((float)i * DEGREES_TO_RADIANS) * CAR_SIZE;
    }
  }
  pwDepthMask (GL_FALSE);
  pwEnable (GL_BLEND);
  pwDisable (GL_CULL_FACE);
  pwBlendFunc (GL_ONE, GL_ONE);
  pwBindTexture (GL_TEXTURE_2D, 0);
  pwBindTexture(GL_TEXTURE_2D, TextureId (TEXTURE_HEADLIGHT));
  for(Car *car in all_cars)
      [car Render];
  pwDepthMask (GL_TRUE);
}



void CarUpdate ()
{
    if (!TextureReady () || !EntityReady ())
        return;
    unsigned long now = GetTickCount ();
    if (next_update > now)
        return;
    next_update = now + UPDATE_INTERVAL;
    for(Car *car in all_cars)
        [car Update];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


@implementation Car


-(id)init
{
    self = [super init];
    if(self)
        _ready = false;
    return self;
}

-(void) Park { _ready = false; }

-(BOOL) PlaceOnMap
{
    NSAssert1(!_ready, @"Car %@ is marked as ready in PlaceOnMap.", self);
        //if the car isn't ready, we need to place it somewhere on the map
    _row = DEAD_ZONE + RandomIntR(WORLD_SIZE - DEAD_ZONE * 2);
    _col = DEAD_ZONE + RandomIntR(WORLD_SIZE - DEAD_ZONE * 2);
    
    if(   (carmap[_row][_col] > 0)                     //if there is already a car here, forget it.
       || (! (WorldCell (_row, _col) & CLAIM_ROAD))    //if this spot is not a road, forget it
       || (! Visible(glVector(float(_row), 0.0f, float(_col)))) )
        return NO;
    
        //good spot. place the car
    _position = glVector(float(_row), 0.1f, float(_col));
    _drivePosition = _position;
    _ready = true;
    
    _direction = directionFromLane(_row, _col);
    
    _drive_angle = dangles[_direction];
    _max_speed   = float(4 + RandomLongR(6)) / 10.0f;
    _speed       = 0.0f;
    _change      = 3;
    _stuck       = 0;
    carmap[_row][_col]++;
    return YES;
}

    // If the car is not ready (because it's not been placed at all, or it's placing was invalid and it was removed from the board)
    // Then place it at random on the board. Otherwise, check if it is in an invalid position or is stuck and if so mark it not ready
    // and remove it. If it is still on the board after all this, then move it in whatever direction it was facing.
-(void) Update
{
        //If the car isn't ready, place it on the map and get it moving
    GLvector old_pos, camera = CameraPosition();
    if (!_ready)
        if(! [self PlaceOnMap])
            return;     // The place failed. This car slot will be blank.
    
    NSAssert3(carmap[_row][_col] == 0 || carmap[_row][_col] == 1,
              @"Car at position (%d,%d) has %d on the board", _row, _col, carmap[_row][_col]);
    
        //take the car off the map and move it
    carmap[_row][_col]--;
    old_pos = _position;
    _speed += _max_speed * 0.05f;
    _speed = MIN(_speed, _max_speed);
    _position = _position + (direction[_direction] * MOVEMENT_SPEED * _speed);
    
        // Check if the car is out of range, or some other reason to hide it for this iteration.
    if(shouldRemoveCar(_row, _col, _position, camera, _stuck)) {
        _ready = false;
        return;
    }
    
        //Check the new position and make sure its not in another car
    int new_row = (int)_position.x, new_col = (int)_position.z;
    if (new_row != _row || new_col != _col) {
           // see if the new position places us on top of another car.
           // If so, then undo any move and increment the stuck counter. When this gets too big, the car will be removed next update.
        if (carmap[new_row][new_col]) { 
            _position = old_pos;
            _speed = 0.0f;
            _stuck++;
        } else {
            _row = new_row;
            _col = new_col;
            _change--;
            _stuck = 0;
            _front = facingCamera(_direction, camera, _position);
        }
    }
    _drivePosition = (_drivePosition + _position) / 2.0f;
        //place the car back on the map
    carmap[_row][_col]++;
}


-(void) Render
{
	if (!_ready || !Visible (_drivePosition))
		return;

	int angle = (360 - int(MathAngle2(_position.x, _position.z, _drivePosition.x, _drivePosition.z))) % 360;
	int turn = int(MathAngleDifference(_drive_angle, angle));
	_drive_angle += SIGN(turn);

	GLvector pos = _drivePosition + GLvector(0.5f, 0.0f, 0.5f);
	GLrgba color = (_front) ? GLrgba(1.0f, 1.0f, 0.8f) : GLrgba(0.5f, 0.2f, 0.0f);		
	float top = _front ? CAR_SIZE : 0.0f;
    pwBegin(GL_QUADS);
    @try {
        GLvertex(GLvector(pos.x + angles[angle].x, -CAR_SIZE, pos.z + angles[angle].y), GLvector2(0, 0), color).apply();
        GLvertex(GLvector(pos.x - angles[angle].x, -CAR_SIZE, pos.z - angles[angle].y), GLvector2(1, 0), color).apply();
        GLvertex(GLvector(pos.x - angles[angle].x,  top     , pos.z - angles[angle].y), GLvector2(1, 1), color).apply();
        GLvertex(GLvector(pos.x + angles[angle].x,  top     , pos.z + angles[angle].y), GLvector2(0, 1), color).apply();
    }
    @finally { pwEnd(); }
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark - Support functions

    // Identify the direction of the car by finding out which lane it is in.
static RoadDirection directionFromLane(int row, int col)
{
    if(WorldCell(row, col) & MAP_ROAD_NORTH)  return NORTH;
    if(WorldCell(row, col) & MAP_ROAD_EAST )  return EAST;
    if(WorldCell(row, col) & MAP_ROAD_SOUTH)  return SOUTH;
    if(WorldCell(row, col) & MAP_ROAD_WEST )  return WEST;
    assert(false);
    return NORTH;
}

    // Returns true if the car at <position> facing <direction> is looking at the camera or away from it.
static BOOL facingCamera(RoadDirection direction, const GLvector &camera, const GLvector &position)
{
    assert(direction == NORTH || direction == SOUTH || direction == EAST || direction == WEST);
    return (direction == NORTH) ? (camera.z < position.z)
        :  (direction == SOUTH) ? (camera.z > position.z)
        :  (direction == EAST ) ? (camera.x > position.x)
        :                         (camera.x < position.x);
}

static BOOL shouldRemoveCar(float row, float col, const GLvector &position, const GLvector &camera, int stuck)
{
    // Remove if: the car has moved out of view, the car is far away, or the car gets too close to the edge of the map.
    // We use manhattan units because buildings almost always block views of cars on the diagonal.
    return ((  ! Visible(glVector(row, 0.0f, col)))
       || (fabs(camera.x - position.x) + fabs(camera.z - position.z) > RenderFogDistance())
       || (position.x < DEAD_ZONE || position.x > (WORLD_SIZE - DEAD_ZONE))
       || (position.z < DEAD_ZONE || position.z > (WORLD_SIZE - DEAD_ZONE))
       || (stuck >= STUCK_TIME) );
}





@end


