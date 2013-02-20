/*-----------------------------------------------------------------------------

  glRgba.cpp

  2009 Shamus Young

-------------------------------------------------------------------------------

  Functions for dealing with RGBA color values.

-----------------------------------------------------------------------------*/


#import "Model.h"


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba glRgbaFromHsl (float h, float sl, float l)
{
  float r = l, g = l, b = l;
  float v = (l <= 0.5f) ? (l * (1.0f + sl)) : (l + sl - l * sl);
  if (v > 0)  {   
    float m = l + l - v, sv = (v - m) / v;
    h *= 6.0f;
    int sextant = (int)h;
    float fract = h - sextant, vsf = v * sv * fract;
    float mid1 = m + vsf, mid2 = v - vsf;
    switch (sextant) {
    case 0:      r = v;    g = mid1; b = m;     break;
    case 1:      r = mid2; g = v;    b = m;     break;
    case 2:      r = m;    g = v;    b = mid1;  break;
    case 3:      r = m;    g = mid2; b = v;     break;
    case 4:      r = mid1; g = m;    b = v;     break;
    case 5:      r = v;    g = m;    b = mid2;  break;
    }
  }
  return GLrgba(r, g, b);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba glRgbaInterpolate (GLrgba c1, GLrgba c2, float delta)
{
  return GLrgba(MathInterpolate (c1.red()  , c2.red()  , delta),    // R
                MathInterpolate (c1.green(), c2.green(), delta),    // G
                MathInterpolate (c1.blue() , c2.blue() , delta),    // B
                MathInterpolate (c1.alpha(), c2.alpha(), delta));   // A
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba glRgbaAdd (GLrgba c1, GLrgba c2)
{
  return GLrgba(c1.red() + c2.red(), c1.green() + c2.green(), c1.blue() + c2.blue());
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba glRgbaSubtract (GLrgba c1, GLrgba c2)
{
  return GLrgba(c1.red() - c2.red(), c1.green() - c2.green(), c1.blue() - c2.blue());
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba glRgbaMultiply (GLrgba c1, GLrgba c2)
{
  return GLrgba(c1.red() * c2.red(), c1.green() * c2.green(), c1.blue() * c2.blue());
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba glRgbaScale (GLrgba c, float scale)
{
    return GLrgba(c.red() * scale, c.green() * scale, c.blue() * scale);
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba::GLrgba(char* string)
: _alpha(1.0f)
{
    char buffer[10], *pound = NULL;
    if ((pound = strchr (buffer, '#')))
        pound[0] = ' ';
    
    GLuint color = 0;
    if (sscanf (string, "%x", &color) != 1)
        _red = _green = _blue = 0.0f;
    else {
        _red   = float(GetRValue(color)) / 255.0f;
        _green = float(GetGValue(color)) / 255.0f;
        _blue  = float(GetBValue(color)) / 255.0f;
    }
}

GLrgba::GLrgba(const GLrgba &rhs)
: _red(rhs.red()), _green(rhs.green()), _blue(rhs.blue()), _alpha(rhs.alpha())
{
}

GLrgba &GLrgba::operator=(const GLrgba &rhs)
{
    if(this != &rhs) {
        _red   = rhs.red();
        _green = rhs.green();
        _blue  = rhs.blue();
        _alpha = rhs.alpha();
    }
    return *this;
}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba::GLrgba(int red, int green, int blue)
: _red(float(red) / 255.0f), _green(float(green) / 255.0f), _blue(float(blue) / 255.0f), _alpha(1.0f)
{
}


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba::GLrgba(GLlong c)
: _red  (float(GetRValue(c)) / 255.0f),
  _green(float(GetGValue(c)) / 255.0f),
  _blue (float(GetBValue(c)) / 255.0f),
  _alpha(1.0f)
{}

/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/

GLrgba::GLrgba(float luminance)
: _red(luminance), _green(luminance), _blue(luminance), _alpha(1.0f)
{}

//Takes the given index and returns a "random" color unique for that index. 512 Unique values: #0 and #512 will be the same, as will #1 and #513, etc
//Useful for visual debugging in some situations.
GLrgba glRgbaUnique (int i)
{
  float red   = 0.4f + ((i & 1) ? 0.2f : 0.0f) + ((i &  8) ? 0.3f : 0.0f) - ((i &  64) ? 0.3f : 0.0f);
  float green = 0.4f + ((i & 2) ? 0.2f : 0.0f) + ((i & 32) ? 0.3f : 0.0f) - ((i & 128) ? 0.3f : 0.0f);
  float blue  = 0.4f + ((i & 4) ? 0.2f : 0.0f) + ((i & 16) ? 0.3f : 0.0f) - ((i & 256) ? 0.3f : 0.0f);
  return GLrgba(red, green, blue, 1.0f);
}

GLrgba::GLrgba()
:_red(0.0f), _green(0.0f), _blue(0.0f), _alpha(0.0f)
{}

GLrgba::GLrgba(float red, float green, float blue, float alpha)
:_red(red), _green(green), _blue(blue), _alpha(alpha)
{}

using std::ostream;
ostream& GLrgba::operator<<(ostream &os) const
{
    return os << "[GLrgba A=" << alpha() << ", R=" << red() << ", G=" << green() << ", B=" << blue() << "]";
}

//  + operator                          

GLrgba GLrgba::operator+ (const GLrgba& c) const
{
  return GLrgba(red() + c.red(), green() + c.green(), blue() + c.blue(), alpha());
}

GLrgba GLrgba::operator+ (const float& c) const
{
  return GLrgba(red() + c, green() + c, blue() + c, alpha());
} 


//  - operator                          

GLrgba GLrgba::operator- (const GLrgba& c) const
{
  return GLrgba(red() - c.red(), green() - c.green(), blue() - c.blue());
}

GLrgba GLrgba::operator- (const float& c) const
{
  return GLrgba(red() - c, green() - c, blue() - c, alpha());
}

//  * operator

GLrgba GLrgba::operator* (const GLrgba& c) const
{
  return GLrgba(red() * c.red(), green() * c.green(), blue() * c.blue());
}

GLrgba GLrgba::operator* (const float& c) const
{
  return GLrgba(red() * c, green() * c, blue() * c, alpha());
}


//  / operator                          

GLrgba GLrgba::operator/ (const GLrgba& c) const
{
  return GLrgba(red() / c.red(), green() / c.green(), blue() / c.blue());
}

GLrgba GLrgba::operator/ (const float& c) const
{
  return GLrgba(red() / c, green() / c, blue() / c, alpha());
}

bool GLrgba::operator==(const GLrgba& c) const
{
  return (red() == c.red() && green() == c.green() && blue() == c.blue());
}

void GLrgba::copyRGB(float output[3]) const
{
    output[0] = red();
    output[1] = green();
    output[2] = blue();
}

void GLrgba::copyRGBA(float output[4]) const
{
    copyRGB(output); // 0=R, 1=G, 2=B
    output[3] = alpha();
}

GLrgba GLrgba::colorWithAlpha(float newAlpha) const { return GLrgba(red(), green(), blue(), newAlpha); }

    //Random SATURATED color
GLrgba RANDOM_COLOR(void)
{
    return glRgbaFromHsl(float(RandomIntR(255))/255.0f, 1.0f, 0.75f);
}

void GLrgba::glColor4() const
{
    glColor4f(red(), green(), blue(), alpha());
}

void GLrgba::glColor3() const
{
    glColor3f(red(), green(), blue());
}

