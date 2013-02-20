
static const float DEGREES_TO_RADIANS   =    0.017453292F;
static const float RADIANS_TO_DEGREES   =    57.29577951F;
static const double PI                  =    3.1415926535;
static const double PI2                 =    PI*PI;
static const float  GRAVITY             =     9.5f;

#ifdef __cplusplus
extern "C" {
#endif

float MathAngle1 (float angle);
float MathAngle2 (float x1, float y1, float x2, float y2);

float MathAngleDifference (float a1, float a2);
float MathAverage (float n1, float n2);
float MathInterpolate (float n1, float n2, float delta);
float MathLine_distance (float x1, float y1, float x2, float y2, float px, float py);
float MathDistance (float x1, float y1, float x2, float y2);
float MathDistance2 (float x1, float y1, float x2, float y2);
float MathSmoothStep (float val, float a, float b);
float MathScalarCurve (float val);

#ifdef __cplusplus
}
#endif

