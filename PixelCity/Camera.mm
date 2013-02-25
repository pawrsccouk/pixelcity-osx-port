/*-----------------------------------------------------------------------------

  Camera.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  This tracks the position and oritentation of the camera. In screensaver 
  mode, it moves the camera around the world in order to create dramatic 
  views of the hot zone.  

-----------------------------------------------------------------------------*/

#import "Model.h"
#import "ini.h"
#import "world.h"
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

static const float EYE_HEIGHT  = 2.0f;
static const int MAX_PITCH     = 85,
                 FLYCAM_CIRCUT = 60000,
                 FLYCAM_CIRCUT_HALF     = (FLYCAM_CIRCUT / 2),
                 FLYCAM_LEG             = (FLYCAM_CIRCUT / 4),
                 ONE_SECOND = 1000,
                 CAMERA_CHANGE_INTERVAL = 15,
                 CAMERA_CYCLE_LENGTH    = (CAMERA_MODES * CAMERA_CHANGE_INTERVAL);

static GLvector angle, position, auto_angle, auto_position;
//static float    distance;
static GLvector movement /* = {0.0f, 0.0f, 0.0f}*/;
static bool     cam_auto = true;	// PAW: hit 'C' to turn off.
static float    tracker;
static int      camera_behavior;
static GLulong last_update, last_move;

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

static GLvector flycam_position (GLulong t, World *world)
{
  GLulong   leg;
  float       delta;
  GLvector    start, end;
  GLbbox      hot_zone;

  hot_zone = world.hotZone;
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

static void do_auto_cam (World *world)
{
    GLulong now = GetTickCount ();
    GLulong elapsed = now - last_update;
    elapsed = std::min(elapsed, 50ul); //limit to 1/20th second worth of time
    if (elapsed == 0)
        return;
    
    last_update = now;
    
#if SCREENSAVER
    int behavior = (time(NULL) % CAMERA_CYCLE_LENGTH) / CAMERA_CHANGE_INTERVAL;
#else
    int behavior = camera_behavior;
#endif

    tracker += (float)elapsed / 300.0f;
    GLvector  target;
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
            
        case CAMERA_ORBIT_ELLIPTICAL: {
            float dist = 150.0f + sinf (tracker * DEGREES_TO_RADIANS / 1.1f) * 50;
            auto_position.x = WORLD_HALF + sinf (tracker * DEGREES_TO_RADIANS) * dist;
            auto_position.y = 60.0f;
            auto_position.z = WORLD_HALF + cosf (tracker * DEGREES_TO_RADIANS) * dist;
            target = glVector (WORLD_HALF, 50, WORLD_HALF);
        }
            break;
            
        case CAMERA_FLYCAM1:
        case CAMERA_FLYCAM2:
        case CAMERA_FLYCAM3:
            auto_position = (flycam_position (now, world) + flycam_position(now + 4000, world)) / 2.0f;
            target = flycam_position(now + FLYCAM_CIRCUT_HALF - ONE_SECOND * 3, world);
            break;
            
        case CAMERA_SPEED:
            auto_position = (flycam_position(now, world) + flycam_position(now + 500, world)) / 2.0f;
            target = flycam_position(now + ONE_SECOND * 5, world);
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
    float dist = MathDistance (auto_position.x, auto_position.z, target.x, target.z);
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

GLvector CameraPosition (void)
{
    return cam_auto ? auto_position : position;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraPositionSet (const GLvector &new_pos)
{
  position = new_pos;
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

GLvector CameraAngle (void)
{
  return cam_auto ? auto_angle : angle;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraAngleSet (const GLvector &newAngle)
{
  angle = newAngle;
  angle.x = CLAMP(angle.x, -80.0f, 80.0f);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraInit (void)		
{
	CameraReset();
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

void CameraUpdate (World *world)
{
	DebugLog("Camera Update: Movement = (%lf, %lf)", movement.x, movement.y);
	
    CameraPan (movement.x);
    CameraForward (movement.z);
    position.y += movement.y / 10.0f;
    movement = movement * ((GetTickCount () - last_move > 1000) ? 0.9f : 0.99f);

    if (SCREENSAVER)
        cam_auto = true;

    if (cam_auto)
        do_auto_cam(world);

    if (angle.y < 0.0f)
        angle.y = 360.0f - float(fmod(fabs(angle.y), 360.0f));
    angle.y = float(fmod(angle.y, 360.0f));
    angle.x = CLAMP<float>(angle.x, -MAX_PITCH, MAX_PITCH);
}


