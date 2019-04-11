/*-----------------------------------------------------------------------------

  Camera.cpp

  2009 Shamus Young
  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
  Released under the GNU GPL v3. See file COPYING for details.

-------------------------------------------------------------------------------

  This tracks the position and oritentation of the camera. In screensaver 
  mode, it moves the camera around the world in order to create dramatic 
  views of the hot zone.  

-----------------------------------------------------------------------------*/

#import "Model.h"
#import "Ini.h"
#import "World.h"
#import "Visible.h"
#import "Camera.h"
#import "Win.h"
#import "World.h"

enum
{
  CAMERA_FLYCAM1,
  CAMERA_ORBIT_INWARD,
  CAMERA_ORBIT_OUTWARD,
  CAMERA_ORBIT_ELLIPTICAL,
  CAMERA_FLYCAM2,
  CAMERA_SPEED,
  CAMERA_SPIN,
  CAMERA_FLYCAM3,
  CAMERA_MODES
};

//static const float EYE_HEIGHT  = 2.0f;
static const int MAX_PITCH     = 85,
                 FLYCAM_CIRCUT = 60000,
                 FLYCAM_CIRCUT_HALF     = (FLYCAM_CIRCUT / 2),
                 FLYCAM_LEG             = (FLYCAM_CIRCUT / 4),
				 ONE_SECOND = 1000;
// static const int CAMERA_CHANGE_INTERVAL = 15,
//                  CAMERA_CYCLE_LENGTH    = (CAMERA_MODES * CAMERA_CHANGE_INTERVAL);

@interface Camera ()
{
    GLvector _auto_angle, _position, _auto_position;
    BOOL     _cam_auto;
    float    _tracker;
    int      _camera_behavior;
    GLulong  _last_update, _last_move;
}
@end


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

@implementation Camera
@synthesize angle = _angle, movement = _movement;

static GLvector flycam_position (GLulong t, World *world)
{
  GLvector    start, end;
  GLbbox      hot_zone = world.hotZone;
  GLulong t2 = t % FLYCAM_CIRCUT;
  switch(t2 / FLYCAM_LEG) {
  case 0:
    start = glVector (hot_zone.min.x, 25.0f, hot_zone.min.z);
    end   = glVector (hot_zone.min.x, 60.0f, hot_zone.max.z);
    break;
  case 1:
    start = glVector (hot_zone.min.x, 60.0f, hot_zone.max.z);
    end   = glVector (hot_zone.max.x, 25.0f, hot_zone.max.z);
    break;
  case 2:
    start = glVector (hot_zone.max.x, 25.0f, hot_zone.max.z);
    end   = glVector (hot_zone.max.x, 60.0f, hot_zone.min.z);
    break;
  case 3:
    start = glVector (hot_zone.max.x, 60.0f, hot_zone.min.z);
    end   = glVector (hot_zone.min.x, 25.0f, hot_zone.min.z);
    break;
  }
  return glVectorInterpolate (start, end, MathScalarCurve(float(t2 % FLYCAM_LEG) / FLYCAM_LEG));
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) doAutoCam
{
    GLulong now = GetTickCount ();
    World *world = self.world;
    
    GLulong elapsed = now - _last_update;
    elapsed = std::min(elapsed, 50ul); //limit to 1/20th second worth of time
    if (elapsed == 0)
        return;
    
    _last_update = now;
    
#if SCREENSAVER
    int behavior = (time(NULL) % CAMERA_CYCLE_LENGTH) / CAMERA_CHANGE_INTERVAL;
#else
    int behavior = _camera_behavior;
#endif

    _tracker += (float)elapsed / 300.0f;
    GLvector  target;
    switch (behavior) {
        case CAMERA_ORBIT_INWARD:
            _auto_position.x = WORLD_HALF + sinf (_tracker * DEGREES_TO_RADIANS) * 150.0f;
            _auto_position.y = 60.0f;
            _auto_position.z = WORLD_HALF + cosf (_tracker * DEGREES_TO_RADIANS) * 150.0f;
            target = glVector (WORLD_HALF, 40, WORLD_HALF);
            break;
            
        case CAMERA_ORBIT_OUTWARD:
            _auto_position.x = WORLD_HALF + sinf (_tracker * DEGREES_TO_RADIANS) * 250.0f;
            _auto_position.y = 60.0f;
            _auto_position.z = WORLD_HALF + cosf (_tracker * DEGREES_TO_RADIANS) * 250.0f;
            target = glVector (WORLD_HALF, 30, WORLD_HALF);
            break;
            
        case CAMERA_ORBIT_ELLIPTICAL: {
            float dist = 150.0f + sinf (_tracker * DEGREES_TO_RADIANS / 1.1f) * 50;
            _auto_position.x = WORLD_HALF + sinf (_tracker * DEGREES_TO_RADIANS) * dist;
            _auto_position.y = 60.0f;
            _auto_position.z = WORLD_HALF + cosf (_tracker * DEGREES_TO_RADIANS) * dist;
            target = glVector (WORLD_HALF, 50, WORLD_HALF);
        }
            break;
            
        case CAMERA_FLYCAM1:
        case CAMERA_FLYCAM2:
        case CAMERA_FLYCAM3:
            _auto_position = (flycam_position (now, world) + flycam_position(now + 4000, world)) / 2.0f;
            target = flycam_position(now + FLYCAM_CIRCUT_HALF - ONE_SECOND * 3, world);
            break;
            
        case CAMERA_SPEED:
            _auto_position = (flycam_position(now, world) + flycam_position(now + 500, world)) / 2.0f;
            target = flycam_position(now + ONE_SECOND * 5, world);
            _auto_position.y /= 2;
            target.y /= 2;
            break;
            
        case CAMERA_SPIN:
        default:
            target.x = WORLD_HALF + sinf (_tracker * DEGREES_TO_RADIANS) * 300.0f;
            target.y = 30.0f;
            target.z = WORLD_HALF + cosf (_tracker * DEGREES_TO_RADIANS) * 300.0f;
            _auto_position.x = WORLD_HALF + sinf (_tracker * DEGREES_TO_RADIANS) * 50.0f;
            _auto_position.y = 60.0f;
            _auto_position.z = WORLD_HALF + cosf (_tracker * DEGREES_TO_RADIANS) * 50.0f;
    }
    float dist = MathDistance (_auto_position.x, _auto_position.z, target.x, target.z);
    _auto_angle.y = MathAngle1 (-MathAngle2 (_auto_position.x, _auto_position.z, target.x, target.z));
    _auto_angle.x = 90.0f + MathAngle2 (0, _auto_position.y, dist, target.y);
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) autoToggle
{
    _cam_auto = !_cam_auto;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) nextBehavior
{
    _camera_behavior = (_camera_behavior + 1) % CAMERA_MODES;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) yaw:(float)delta
{
    _angle.y -= delta;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) pitch:(float)delta
{
    _angle.x -= delta;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) pan:(float) delta
{
  _position.x -=  float(cos(-_angle.y * DEGREES_TO_RADIANS) / 10.0f) * delta;
  _position.z -= -float(sin(-_angle.y * DEGREES_TO_RADIANS) / 10.0f) * delta;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) forward:(float) delta
{
  _position.x -= float(sin (-_angle.y * DEGREES_TO_RADIANS)) / 10.0f * delta;
  _position.z -= float(cos (-_angle.y * DEGREES_TO_RADIANS)) / 10.0f * delta;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) vertical:(float) val
{
  _movement.y += val;
  _last_move = GetTickCount ();
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) lateral:(float) val
{
  _movement.x += val;
  _last_move = GetTickCount ();
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) medial:(float)val
{
  _movement.z += val;
  _last_move = GetTickCount ();
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
-(GLvector) position
{
    return _cam_auto ? _auto_position : _position;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void) setPosition:(GLvector) position
{
    _position = position;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void)reset
{
    _position = GLvector(WORLD_HALF, 50.0f, WORLD_HALF);
    _angle    = GLvector(0, 0, 0);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(GLvector)angle
{
  return _cam_auto ? _auto_angle : _angle;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void)setAngle:(GLvector) newAngle
{
  _angle = GLvector(CLAMP(newAngle.x, -80.0f, 80.0f), newAngle.y, newAngle.z);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(id)initWithWorld:(World *)world
{
    self = [super init];
    if(self) {
        _cam_auto = YES;
        _movement = GLvector(0, 0, 0);
        _world   = world;
        [self reset];
    }
    return self;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

-(void)update
{	
    [self pan:_movement.x];
    [self forward:_movement.z];
    _position = GLvector(_position.x, _position.y + _movement.y / 10.0f, _position.z);
    _movement = _movement * ((GetTickCount () - _last_move > 1000) ? 0.9f : 0.99f);

    if (SCREENSAVER)
        _cam_auto = true;

    if (_cam_auto)
        [self doAutoCam];

    if (_angle.y < 0.0f)
        _angle.y = 360.0f - float(fmod(fabs(_angle.y), 360.0f));
    _angle.y = float(fmod(_angle.y, 360.0f));
    _angle.x = CLAMP<float>(_angle.x, -MAX_PITCH, MAX_PITCH);
}

@end



