 // 2009 Shamus Young
 // Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
 // Released under the GNU GPL v3. See file COPYING for details.

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

typedef struct GLvector
{
  float       x;
  float       y;
  float       z;
  OPERATORS(GLvector);
  GLvector(float xx, float yy, float zz) : x(xx), y(yy), z(zz) {}

  float Length() const;

  void glVertex3() const;    // call glVertex3 on this vector.

} GLvector, GLvector3;

inline std::ostream &operator<<(std::ostream &os, const GLvector &v) { return v.operator<<(os); }


struct GLvector2
{
    float x, y;
    GLvector2(float x, float y) : x(x), y(y) {}
    float Length() const;
    void glTexCoord2() const;
    OPERATORS(GLvector2);
};
inline std::ostream &operator<<(std::ostream &os, const GLvector2 &v) { return v.operator<<(os); }


struct GLbbox
{
  GLvector3 min, max;
};

GLbbox bboxWithCorners(const GLvector &topLeftFront, const GLvector &bottomRightBack);

GLbbox    glBboxClear (void);
GLbbox    glBboxContainPoint (GLbbox box, GLvector point);
bool      glBboxTestPoint (GLbbox box, GLvector point);

GLvector  glVector (float x, float y, float z);
GLvector  glVectorCrossProduct (GLvector v1, GLvector v2);
float     glVectorDotProduct (GLvector v1, GLvector v2);
void      glVectorGl (GLvector v);
GLvector  glVectorInterpolate (GLvector v1, GLvector v2, float scalar);
GLvector  glVectorNormalize (GLvector v);
GLvector  glVectorReflect (GLvector3 ray, GLvector3 normal);
inline GLvector glVector(int x, int y, int z) { return glVector(float(z), float(y), float(z)); }

GLvector2 glVector (float x, float y);
GLvector2 glVectorNormalize (GLvector2 v);
GLvector2 glVectorInterpolate (GLvector2 v1, GLvector2 v2, float scalar);
GLvector2 glVectorSinCos (float angle);
inline GLvector2 glVector(int x, int y) { return glVector(float(x), float(y)); }


