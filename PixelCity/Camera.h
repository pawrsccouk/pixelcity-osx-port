
GLvector CameraAngle (void);
void  CameraAngleSet (const GLvector &new_angle);
GLvector CameraPosition (void);
void  CameraPositionSet (const GLvector &new_pos);

#ifdef __cplusplus
extern "C" {
#endif

void  CameraAutoToggle ();
float CameraDistance (void);
void  CameraDistanceSet (float new_distance);
void  CameraInit (void);
void  CameraNextBehavior (void);
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
