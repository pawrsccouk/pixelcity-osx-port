/*-----------------------------------------------------------------------------

  glVector3.cpp

  2006 Shamus Young

-------------------------------------------------------------------------------

  Functions for dealing with 3d vectors.

-----------------------------------------------------------------------------*/

#import <float.h>
#import <math.h>
#import <OpenGL/gl.h>

#import "macro.h"
#import "mathx.h"
#import "glTypes.h"

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector glVectorReflect (GLvector3 ray, GLvector3 normal)
{

  float       dot;

  dot = glVectorDotProduct (ray, normal);
  return ray - (normal * (2.0f * dot));

}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector3 glVector (float x, float y, float z)
{

  GLvector3 result;

  result.x = x;
  result.y = y;
  result.z = z;
  return result;

}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector3 glVectorInterpolate (GLvector3 v1, GLvector3 v2, float scalar)
{

  GLvector3 result;

  result.x = MathInterpolate (v1.x, v2.x, scalar);
  result.y = MathInterpolate (v1.y, v2.y, scalar);
  result.z = MathInterpolate (v1.z, v2.z, scalar);
  return result;

}  

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

float GLvector3::Length() const
{
  return (float)sqrt (x * x + y * y + z * z);
}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

float glVectorDotProduct (GLvector3 v1, GLvector3 v2)
{

  return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;

}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector3 glVectorCrossProduct (GLvector3 v1, GLvector3 v2)
{

  GLvector3 result;
  
  result.x = v1.y * v2.z - v2.y * v1.z;
  result.y = v1.z * v2.x - v2.z * v1.x;
  result.z = v1.x * v2.y - v2.x * v1.y;
  return result;

}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector3 glVectorInvert (GLvector3 v)
{

  v.x *= -v.x;
  v.y *= -v.y;
  v.z *= -v.z;
  return v;

}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector3 glVectorScale (GLvector3 v, float scale)
{

  v.x *= scale;
  v.y *= scale;
  v.z *= scale;
  return v;

}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector3 glVectorNormalize (GLvector3 v)
{
  float length = v.Length();
  return (length < 0.000001f) ? v : glVectorScale(v, 1.0f / length);
}

/*-----------------------------------------------------------------------------
+                           
-----------------------------------------------------------------------------*/

GLvector::GLvector()
:x(0.0f), y(0.0f), z(0.0f)
{
}

std::ostream &GLvector::operator<<(std::ostream &os) const
{
    return os << "[GLvector X=" << x << ", Y=" << y << ", Z=" << z << "]";
}

GLvector GLvector::operator+ (const GLvector& c) const
{
  return glVector (x + c.x, y + c.y, z + c.z);
}

GLvector GLvector::operator+ (const float& c) const
{
  return glVector (x + c, y + c, z + c);
}

//void GLvector::operator+= (const GLvector& c)
//{
//  x += c.x;
//  y += c.y;
//  z += c.z;
//}
//
//void GLvector::operator+= (const float& c)
//{
//  x += c;
//  y += c;
//  z += c;
//}

GLvector GLvector::operator- (const GLvector& c) const
{
  return glVector (x - c.x, y - c.y, z - c.z);
}

GLvector GLvector::operator- (const float& c) const
{
  return glVector (x - c, y - c, z - c);
}

//void GLvector::operator-= (const GLvector& c)
//{
//  x -= c.x;
//  y -= c.y;
//  z -= c.z;
//}
//
//void GLvector::operator-= (const float& c)
//{
//  x -= c;
//  y -= c;
//  z -= c;
//}

GLvector GLvector::operator* (const GLvector& c) const
{
  return glVector (x * c.x, y * c.y, z * c.z);
}

GLvector GLvector::operator* (const float& c) const
{
  return glVector (x * c, y * c, z * c);
}

//void GLvector::operator*= (const GLvector& c)
//{
//  x *= c.x;
//  y *= c.y;
//  z *= c.z;
//}
//
//void GLvector::operator*= (const float& c)
//{
//  x *= c;
//  y *= c;
//  z *= c;
//}

GLvector GLvector::operator/ (const GLvector& c) const
{
  return glVector (x / c.x, y / c.y, z / c.z);
}

GLvector GLvector::operator/ (const float& c) const
{
  return glVector (x / c, y / c, z / c);
}

//void GLvector::operator/= (const GLvector& c)
//{
//  x /= c.x;
//  y /= c.y;
//  z /= c.z;
//}
//
//void GLvector::operator/= (const float& c)
//{
//  x /= c;
//  y /= c;
//  z /= c;
//}

bool GLvector::operator== (const GLvector& c) const
{
  return (x == c.x && y == c.y && z == c.z);
}

