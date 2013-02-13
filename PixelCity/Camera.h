#import "glTypesObjC.h"

#ifdef __cplusplus
extern "C" {
#endif

Vector *CameraAngle (void);
void  CameraAngleSet (Vector *new_angle);
void  CameraAutoToggle ();
float CameraDistance (void);
void  CameraDistanceSet (float new_distance);
void  CameraInit (void);
void  CameraNextBehavior (void);
Vector *CameraPosition (void);
void  CameraPositionSet (Vector *new_pos);
void  CameraReset ();
void  CameraUpdate (void);	
void  CameraTerm (void);

void  CameraForward (float delta);
void  CameraPan (float delta_x);
void  CameraPitch (float delta_y);
void  CameraYaw (float delta_x);
void  CameraVertical (float val);
void  CameraLateral (float val);
void  CameraMedial (float val);

#ifdef __cplusplus
}
#endif
