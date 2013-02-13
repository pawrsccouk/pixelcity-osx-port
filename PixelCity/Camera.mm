/*-----------------------------------------------------------------------------

  Camera.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  This tracks the position and oritentation of the camera. In screensaver 
  mode, it moves the camera around the world in order to create dramatic 
  views of the hot zone.  

-----------------------------------------------------------------------------*/

#define EYE_HEIGHT              2.0f
#define MAX_PITCH               85
#define FLYCAM_CIRCUT           60000
#define FLYCAM_CIRCUT_HALF      (FLYCAM_CIRCUT / 2)
#define FLYCAM_LEG              (FLYCAM_CIRCUT / 4)
#define ONE_SECOND              1000
#define CAMERA_CHANGE_INTERVAL  15
#define CAMERA_CYCLE_LENGTH     (CAMERA_MODES*CAMERA_CHANGE_INTERVAL)

#import <math.h>
#import <time.h>
#import <stdio.h>

#import "glTypes.h"
#import "ini.h"
#import "macro.h"
#import "mathx.h"
#import "world.h"
#import "win.h"
#import "Camera.h"


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

static GLvector angle, position, auto_angle, auto_position;
//static float    distance;
static GLvector movement /* = {0.0f, 0.0f, 0.0f}*/;
static bool     cam_auto = true;	// PAW: hit 'C' to turn off.
static float    tracker;
static int      camera_behavior;
static unsigned long last_update, last_move;

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static GLvector flycam_position (unsigned long t)
{
  unsigned long   leg;
  float       delta;
  GLvector    start, end;
  GLbbox      hot_zone;

  hot_zone = WorldHotZone ();
  t %= FLYCAM_CIRCUT; 
  leg = t / FLYCAM_LEG;
  delta = (float)(t % FLYCAM_LEG) / FLYCAM_LEG;
  switch (leg) {
  case 0:
    start = glVector (hot_zone.min.x, 25.0f, hot_zone.min.z);
    end = glVector (hot_zone.min.x, 60.0f, hot_zone.max.z);
    break;
  case 1:
    start = glVector (hot_zone.min.x, 60.0f, hot_zone.max.z);
    end = glVector (hot_zone.max.x, 25.0f, hot_zone.max.z);
    break;
  case 2:
    start = glVector (hot_zone.max.x, 25.0f, hot_zone.max.z);
    end = glVector (hot_zone.max.x, 60.0f, hot_zone.min.z);
    break;
  case 3:
    start = glVector (hot_zone.max.x, 60.0f, hot_zone.min.z);
    end = glVector (hot_zone.min.x, 25.0f, hot_zone.min.z);
    break;
  }
  delta = MathScalarCurve (delta);
  return glVectorInterpolate (start, end, delta);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static void do_auto_cam ()
{

  float     dist;
  unsigned  t;
  unsigned long  now, elapsed;
  int       behavior; 
  GLvector  target;

  now = GetTickCount ();
  elapsed = now - last_update;
  elapsed = std::min(elapsed, 50ul); //limit to 1/20th second worth of time
  if (elapsed == 0)
    return;
  last_update = now;
  t = time (NULL) % CAMERA_CYCLE_LENGTH;
#if SCREENSAVER
  behavior = t / CAMERA_CHANGE_INTERVAL;
#else
  behavior = camera_behavior;
#endif
  tracker += (float)elapsed / 300.0f;
  //behavior = CAMERA_FLYCAM1; 
  switch (behavior) {
  case CAMERA_ORBIT_INWARD:
    auto_position.x = WORLD_HALF + sinf (tracker * DEGREES_TO_RADIANS) * 150.0f;
    auto_position.y = 60.0f;
    auto_position.z = WORLD_HALF + cosf (tracker * DEGREES_TO_RADIANS) * 150.0f;
    target = glVector (WORLD_HALF, 40, WORLD_HALF);
    break;
  case CAMERA_ORBIT_OUTWARD:
    auto_position.x = WORLD_HALF + sinf (tracker * DEGREES_TO_RADIANS) * 250.0f;
    auto_position.y = 60.0f;
    auto_position.z = WORLD_HALF + cosf (tracker * DEGREES_TO_RADIANS) * 250.0f;
    target = glVector (WORLD_HALF, 30, WORLD_HALF);
    break;
  case CAMERA_ORBIT_ELLIPTICAL:
    dist = 150.0f + sinf (tracker * DEGREES_TO_RADIANS / 1.1f) * 50;
    auto_position.x = WORLD_HALF + sinf (tracker * DEGREES_TO_RADIANS) * dist;
    auto_position.y = 60.0f;
    auto_position.z = WORLD_HALF + cosf (tracker * DEGREES_TO_RADIANS) * dist;
    target = glVector (WORLD_HALF, 50, WORLD_HALF);
    break;
  case CAMERA_FLYCAM1:
  case CAMERA_FLYCAM2:
  case CAMERA_FLYCAM3:
    auto_position = (flycam_position (now) + flycam_position (now + 4000)) / 2.0f;
    target = flycam_position (now + FLYCAM_CIRCUT_HALF - ONE_SECOND * 3);
    break;
  case CAMERA_SPEED:
    auto_position = (flycam_position (now) + flycam_position (now + 500)) / 2.0f;
    target = flycam_position (now + ONE_SECOND * 5);
    auto_position.y /= 2;
    target.y /= 2;
    break;
  case CAMERA_SPIN:
  default:  
    target.x = WORLD_HALF + sinf (tracker * DEGREES_TO_RADIANS) * 300.0f;
    target.y = 30.0f;
    target.z = WORLD_HALF + cosf (tracker * DEGREES_TO_RADIANS) * 300.0f;
    auto_position.x = WORLD_HALF + sinf (tracker * DEGREES_TO_RADIANS) * 50.0f;
    auto_position.y = 60.0f;
    auto_position.z = WORLD_HALF + cosf (tracker * DEGREES_TO_RADIANS) * 50.0f;
  }
  dist = MathDistance (auto_position.x, auto_position.z, target.x, target.z);
  auto_angle.y = MathAngle1 (-MathAngle2 (auto_position.x, auto_position.z, target.x, target.z));
  auto_angle.x = 90.0f + MathAngle2 (0, auto_position.y, dist, target.y);

}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraAutoToggle ()
{
  cam_auto = !cam_auto;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraNextBehavior ()
{

  camera_behavior++;
  camera_behavior %= CAMERA_MODES;

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraYaw (float delta)
{

  angle.y -= delta;

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraPitch (float delta)
{

  angle.x -= delta;

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraPan (float delta)
{

  float           move_x, move_y;

  move_x = (float)sin (-angle.y * DEGREES_TO_RADIANS) / 10.0f;
  move_y = (float)cos (-angle.y * DEGREES_TO_RADIANS) / 10.0f;
  position.x -= move_y * delta;
  position.z -= -move_x * delta;

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraForward (float delta)
{

  float           move_x, move_y;

  move_y = (float)sin (-angle.y * DEGREES_TO_RADIANS) / 10.0f;
  move_x = (float)cos (-angle.y * DEGREES_TO_RADIANS) / 10.0f;
  position.x -= move_y * delta;
  position.z -= move_x * delta;

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraVertical (float val)
{

  movement.y += val;
  last_move = GetTickCount ();

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraLateral (float val)
{

  movement.x += val;
  last_move = GetTickCount ();

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraMedial (float val)
{

  movement.z += val;
  last_move = GetTickCount ();

}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

Vector *CameraPosition (void)
{
    GLvector &pos = cam_auto ? auto_position : position;
    return [Vector vectorWithX:pos.x Y:pos.y Z:pos.z];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraPositionSet (Vector *new_pos)
{
  position = GLvector(new_pos.x, new_pos.y, new_pos.z);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraReset ()		
{

  position.y = 50.0f;
  position.x = WORLD_HALF;
  position.z = WORLD_HALF;
  angle.x = 0.0f;
  angle.y = 0.0f;
  angle.z = 0.0f;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

Vector *CameraAngle (void)
{
  GLvector &a = cam_auto ? auto_angle : angle;
  return [Vector vectorWithX:a.x Y:a.y Z:a.z];
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraAngleSet (Vector *newAngle)
{
  angle = GLvector(newAngle.x, newAngle.y, newAngle.z);
  angle.x = CLAMP(angle.x, -80.0f, 80.0f);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraInit (void)		
{
	CameraReset();
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraUpdate (void)		
{
	DebugLog("Camera Update: Movement = (%lf, %lf)", movement.x, movement.y);
	
    CameraPan (movement.x);
    CameraForward (movement.z);
    position.y += movement.y / 10.0f;
    movement *= (GetTickCount () - last_move > 1000) ? 0.9f : 0.99f;

    if (SCREENSAVER)
        cam_auto = true;

    if (cam_auto)
        do_auto_cam ();

    if (angle.y < 0.0f)
        angle.y = 360.0f - float(fmod(fabs(angle.y), 360.0f));
    angle.y = float(fmod(angle.y, 360.0f));
    angle.x = CLAMP<float>(angle.x, -MAX_PITCH, MAX_PITCH);
}


