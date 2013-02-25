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

typedef BOOL CarMap[WORLD_SIZE][WORLD_SIZE];
typedef GLvector2 AngleMap[360];
@interface Cars ()
{
    NSArray *_cars;
    CarMap   _carmap;
    AngleMap _angles;
    BOOL     _anglesDone;
    GLulong  _nextUpdate;
}

-(id)initWithWorld:(World*)world;

-(BOOL) spaceAtRow:   (GLint) row column:(GLint) column;
-(BOOL) carAtRow:     (GLint) row column:(GLint) column;
-(void) setSpaceAtRow:(GLint) row column:(GLint) column;
-(void) setCarAtRow:  (GLint) row column:(GLint) column;

-(GLvector2) angleAt:(GLint) pos;
-(void)setAngle:(GLvector2) angle atIndex:(GLint) pos;

@end

@interface Car : NSObject
{
    GLvector _position, _drivePosition;
    BOOL     _ready, _front;
    RoadDirection _direction;
    int      _drive_angle,  _change, _stuck;
    GLuint   _row, _col;
    float    _speed, _max_speed;
    
    __weak Cars *_parent;
    __weak World *_world;
}

-(id) initWithParent:(Cars*)parent world:(World*) world;
-(void) render;
-(void) update;
-(void) park;

@end 

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/


static const int DEAD_ZONE = 200, STUCK_TIME = 230, UPDATE_INTERVAL = 50; //milliseconds
static const float MOVEMENT_SPEED = 0.61f,  CAR_SIZE = 3.0f;
static const int CARS = 500;    //Controls the density of cars.
static const int dangles[] = { 0, 90, 180, 270 };
static const GLvector directions[] = {
    GLvector( 0.0f, 0.0f, -1.0f),
    GLvector( 1.0f, 0.0f,  0.0f),
    GLvector( 0.0f, 0.0f,  1.0f),
    GLvector(-1.0f, 0.0f,  0.0f)
};

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark - Global Interface

@implementation Cars
@synthesize count = _count, world = _world;


-(id)initWithWorld:(World *)world
{
    self = [super init];
    if(self) {
        _count = 0;
        memset(_carmap, 0, sizeof(_carmap));
        _cars = nil;
        _world = world;
        [self populate];
    }
    return self;
}

-(NSUInteger) count
{
  return _count;
}

-(void) populate
{
    NSMutableArray *allCars = [[NSMutableArray alloc] initWithCapacity:CARS];
    for(int i = 0; i < CARS; i++) {
        [allCars addObject:[[Car alloc] initWithParent:self world:_world]];
        _count++;
    }
    _cars = allCars;
}


-(void) clear
{
    for(Car *car in _cars)
        [car park];
    memset(_carmap, 0, sizeof(_carmap));
    _count = 0;
}


-(void) render
{
  if (! _anglesDone) {
    for (int i = 0 ;i < 360; i++) {
      _angles[i].x = cosf ((float)i * DEGREES_TO_RADIANS) * CAR_SIZE;
      _angles[i].y = sinf ((float)i * DEGREES_TO_RADIANS) * CAR_SIZE;
    }
  }
  pwDepthMask (GL_FALSE);
  pwEnable (GL_BLEND);
  pwDisable (GL_CULL_FACE);
  pwBlendFunc (GL_ONE, GL_ONE);
  pwBindTexture (GL_TEXTURE_2D, 0);
  pwBindTexture(GL_TEXTURE_2D, TextureId (TEXTURE_HEADLIGHT));
  for(Car *car in _cars)
      [car render];
  pwDepthMask (GL_TRUE);
}



-(void) update
{
    if (!TextureReady () || ! self.world.entities.ready)
        return;
    GLulong now = GetTickCount ();
    if (_nextUpdate > now)
        return;
    _nextUpdate = now + UPDATE_INTERVAL;
    for(Car *car in _cars)
        [car update];
}

-(BOOL)spaceAtRow:   (GLint)row column:(GLint)column  { return ! _carmap[row][column]; }
-(BOOL)carAtRow:     (GLint)row column:(GLint)column  { return   _carmap[row][column]; }
-(void)setCarAtRow:  (GLint)row column:(GLint)column { _carmap[row][column] = YES; }
-(void)setSpaceAtRow:(GLint)row column:(GLint)column { _carmap[row][column] = NO;  }

-(GLvector2)angleAt:(GLint)pos { return _angles[pos]; }
-(void)setAngle:(GLvector2) angle atIndex:(GLint)pos { _angles[pos] = angle; }

@end

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

@implementation Car


-(id)initWithParent:(Cars *)parent world:(World*)world
{
    self = [super init];
    if(self) {
        _ready = false;
        _parent = parent;
        _world  = world;
    }
    return self;
}

-(void) park { _ready = false; }

-(BOOL) placeOnMap
{
    NSAssert1(!_ready, @"Car %@ is marked as ready in PlaceOnMap.", self);
        //if the car isn't ready, we need to place it somewhere on the map
    _row = DEAD_ZONE + RandomIntR(WORLD_SIZE - DEAD_ZONE * 2);
    _col = DEAD_ZONE + RandomIntR(WORLD_SIZE - DEAD_ZONE * 2);
    
    if([_parent carAtRow:_row column:_col]             //if there is already a car here, forget it.
       || (! ([_world cellAtRow:_row column:_col] & CLAIM_ROAD))    //if this spot is not a road, forget it
       || (! Visible(glVector(float(_row), 0.0f, float(_col)))) )
        return NO;
    
        //good spot. place the car
    _position = glVector(float(_row), 0.1f, float(_col));
    _drivePosition = _position;
    _ready = true;
    
    _direction = directionFromLane(_world, _row, _col);
    
    _drive_angle = dangles[_direction];
    _max_speed   = float(4 + RandomLongR(6)) / 10.0f;
    _speed       = 0.0f;
    _change      = 3;
    _stuck       = 0;
    [_parent setCarAtRow:_row column:_col];
    return YES;
}

    // If the car is not ready (because it's not been placed at all, or it's placing was invalid and it was removed from the board)
    // Then place it at random on the board. Otherwise, check if it is in an invalid position or is stuck and if so mark it not ready
    // and remove it. If it is still on the board after all this, then move it in whatever direction it was facing.
-(void) update
{
        //If the car isn't ready, place it on the map and get it moving
    GLvector old_pos, camera = CameraPosition();
    if (!_ready)
        if(! [self placeOnMap])
            return;     // The place failed. This car slot will be blank.

        //take the car off the map and move it
    [_parent setSpaceAtRow:_row column:_col];
    old_pos = _position;
    _speed += _max_speed * 0.05f;
    _speed = MIN(_speed, _max_speed);
    _position = _position + (directions[_direction] * MOVEMENT_SPEED * _speed);
    
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
        if ([_parent carAtRow:new_row column:new_col]) {
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
    [_parent setCarAtRow:_row column:_col];    //place the car back on the map
}


-(void) render
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
        GLvertex(GLvector(pos.x + [_parent angleAt:angle].x, -CAR_SIZE, pos.z + [_parent angleAt:angle].y), GLvector2(0, 0), color).apply();
        GLvertex(GLvector(pos.x - [_parent angleAt:angle].x, -CAR_SIZE, pos.z - [_parent angleAt:angle].y), GLvector2(1, 0), color).apply();
        GLvertex(GLvector(pos.x - [_parent angleAt:angle].x,  top     , pos.z - [_parent angleAt:angle].y), GLvector2(1, 1), color).apply();
        GLvertex(GLvector(pos.x + [_parent angleAt:angle].x,  top     , pos.z + [_parent angleAt:angle].y), GLvector2(0, 1), color).apply();
    }
    @finally { pwEnd(); }
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
#pragma mark - Support functions

    // Identify the direction of the car by finding out which lane it is in.
static RoadDirection directionFromLane(World *world, int row, int col)
{
    if([world cellAtRow:row column:col] & MAP_ROAD_NORTH)  return NORTH;
    if([world cellAtRow:row column:col] & MAP_ROAD_EAST )  return EAST;
    if([world cellAtRow:row column:col] & MAP_ROAD_SOUTH)  return SOUTH;
    if([world cellAtRow:row column:col] & MAP_ROAD_WEST )  return WEST;
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


