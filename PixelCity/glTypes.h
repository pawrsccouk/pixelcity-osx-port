#ifndef glTYPES
#define glTYPES

#import <OpenGL/OpenGL.h>
//static const int GL_CLAMP_TO_EDGE = 0x812F;

#import <iostream>


#define OPERATORS(type)                       \
  type();                                     \
  type    operator+  (const type& c)  const;  \
  type    operator+  (const float& c) const;  \
  type    operator-  (const type& c)  const;  \
  type    operator-  (const float& c) const;  \
  type    operator*  (const type& c)  const;  \
  type    operator*  (const float& c) const;  \
  type    operator/  (const type& c)  const;  \
  type    operator/  (const float& c) const;  \
  bool    operator== (const type& c)  const;  \
  std::ostream &operator<<(std::ostream &os) const;


//  void    operator/= (const type& c);   \
//  void    operator/= (const float& c);  \
//  void    operator*= (const type& c);   \
//  void    operator*= (const float& c);  \
//  void    operator-= (const type& c);   \
//  void    operator-= (const float& c);  \
//  void    operator+= (const type& c);   \
//  void    operator+= (const float& c);  \

typedef struct GLvector
{
  float       x;
  float       y;
  float       z;
  OPERATORS(GLvector);
  GLvector(float xx, float yy, float zz) : x(xx), y(yy), z(zz) {}
  float Length() const;
} GLvector, GLvector3;

inline std::ostream &operator<<(std::ostream &os, const GLvector &v) { return v.operator<<(os); }


struct GLvector2
{
  float       x;
  float       y;
    GLvector2(float x, float y) : x(x), y(y) {}
    float Length() const;
    OPERATORS(GLvector2);
};
inline std::ostream &operator<<(std::ostream &os, const GLvector2 &v) { return v.operator<<(os); }


struct GLbbox
{
  GLvector3   min;
  GLvector3   max;
};

struct GLmatrix
{
  float elements[4][4];
};

struct GLquat
{
    float       x;
    float       y;
    float       z;
    float       w;
};


GLbbox    glBboxClear (void);
GLbbox    glBboxContainPoint (GLbbox box, GLvector point);
bool      glBboxTestPoint (GLbbox box, GLvector point);
GLmatrix  glMatrixIdentity (void);
void      glMatrixElementsSet (GLmatrix* m, float* in);
GLmatrix  glMatrixMultiply (GLmatrix a, GLmatrix b);
GLvector  glMatrixTransformPoint (GLmatrix m, GLvector in);
GLmatrix  glMatrixTranslate (GLmatrix m, GLvector in);
GLmatrix  glMatrixRotate (GLmatrix m, float theta, float x, float y, float z);
GLvector  glMatrixToEuler (GLmatrix mat, int order);

GLquat    glQuat (float x, float y, float z, float w);
GLvector  glQuatToEuler (GLquat q, int order);

GLvector  glVector (float x, float y, float z);
GLvector  glVectorCrossProduct (GLvector v1, GLvector v2);
float     glVectorDotProduct (GLvector v1, GLvector v2);
void      glVectorGl (GLvector v);
GLvector  glVectorInterpolate (GLvector v1, GLvector v2, float scalar);
//float     glVectorLength (GLvector v);
GLvector  glVectorNormalize (GLvector v);
GLvector  glVectorReflect (GLvector3 ray, GLvector3 normal);
inline GLvector glVector(int x, int y, int z) { return glVector(float(z), float(y), float(z)); }

GLvector2 glVector (float x, float y);
//GLvector2 glVectorAdd (GLvector2 val1, GLvector2 val2);
//GLvector2 glVectorSubtract (GLvector2 val1, GLvector2 val2);
GLvector2 glVectorNormalize (GLvector2 v);
GLvector2 glVectorInterpolate (GLvector2 v1, GLvector2 v2, float scalar);
GLvector2 glVectorSinCos (float angle);
//float     glVectorLength (GLvector2 v);
inline GLvector2 glVector(int x, int y) { return glVector(float(x), float(y)); }

#endif

