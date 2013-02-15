/*-----------------------------------------------------------------------------

  Vector2.cpp

  2006 Shamus Young

-------------------------------------------------------------------------------

  Functions for dealing with 2d (usually texture mapping) values.

-----------------------------------------------------------------------------*/

#import <float.h>
#import <math.h>
#import <OpenGL/gl.h>

#import "glTypes.h"
#import "mathx.h"
#import "macro.h"

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector2 glVectorNormalize (const GLvector2 &v)
{
  float length = v.Length();
  return (length < 0.000001f) ? v : v * (1.0f / length);
}

/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

float GLvector2::Length() const
{
    return (float)sqrt (x * x + y * y);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLvector2 glVectorSinCos(float a)
{
    a *= DEGREES_TO_RADIANS;
    return GLvector2(sinf (a), cosf (a));
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLvector2 glVector(float x, float y)
{
  return GLvector2(x,y);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

//GLvector2 glVectorAdd (GLvector2 val1, GLvector2 val2)
//{
//  GLvector2      result;
//
//  result.x = val1.x + val2.x;
//  result.y = val1.y + val2.y;
//  return result;
//}


/*-----------------------------------------------------------------------------
                           
-----------------------------------------------------------------------------*/

GLvector2 glVectorInterpolate (GLvector2 v1, GLvector2 v2, float scalar)
{
  return GLvector2( MathInterpolate (v1.x, v2.x, scalar),
                    MathInterpolate (v1.y, v2.y, scalar) );
}  

/*-----------------------------------------------------------------------------

-----------------------------------------------------------------------------*/

//GLvector2 glVectorSubtract (GLvector2 val1, GLvector2 val2)
//{
//
//  GLvector2      result;
//
//  result.x = val1.x - val2.x;
//  result.y = val1.y - val2.y;
//  return result;
//
//}

/*-----------------------------------------------------------------------------
+                           
-----------------------------------------------------------------------------*/

GLvector2::GLvector2()
:x(0.0f), y(0.0f)
{
}

std::ostream &GLvector2::operator<<(std::ostream &os) const
{
    return os << "[GLVECTOR2 X=" << x << ", Y=" << y << "]";
}

GLvector2 GLvector2::operator+ (const GLvector2& c) const
{
  return glVector (x + c.x, y + c.y);
}

GLvector2 GLvector2::operator+ (const float& c) const
{
  return glVector (x + c, y + c);
}

//void GLvector2::operator+= (const GLvector2& c)
//{
//  x += c.x;
//  y += c.y;
//}
//
//void GLvector2::operator+= (const float& c)
//{
//  x += c;
//  y += c;
//}

GLvector2 GLvector2::operator- (const GLvector2& c) const
{
  return glVector (x - c.x, y - c.y);
}

GLvector2 GLvector2::operator- (const float& c) const
{
  return glVector (x - c, y - c);
}

//void GLvector2::operator-= (const GLvector2& c)
//{
//  x -= c.x;
//  y -= c.y;
//}
//
//void GLvector2::operator-= (const float& c)
//{
//  x -= c;
//  y -= c;
//}

GLvector2 GLvector2::operator* (const GLvector2& c) const
{
  return glVector (x * c.x, y * c.y);
}

GLvector2 GLvector2::operator* (const float& c) const
{
  return glVector (x * c, y * c);
}

//void GLvector2::operator*= (const GLvector2& c)
//{
//  x *= c.x;
//  y *= c.y;
//}
//
//void GLvector2::operator*= (const float& c)
//{
//  x *= c;
//  y *= c;
//}

GLvector2 GLvector2::operator/ (const GLvector2& c) const
{
  return glVector (x / c.x, y / c.y);
}

GLvector2 GLvector2::operator/ (const float& c) const
{
  return glVector (x / c, y / c);
}

//void GLvector2::operator/= (const GLvector2& c)
//{
//  x /= c.x;
//  y /= c.y;
//}
//
//void GLvector2::operator/= (const float& c)
//{
//  x /= c;
//  y /= c;
//}

bool GLvector2::operator== (const GLvector2& c) const
{
  return (x == c.x && y == c.y);
}


