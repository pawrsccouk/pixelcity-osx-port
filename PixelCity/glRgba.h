//
//  glRGBA.h
//  PixelCity
//
//  Created by Patrick Wallace on 10/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#ifndef PixelCity_glRGBA_h
#define PixelCity_glRGBA_h

class GLrgba
{
    float _red, _green, _blue, _alpha;
public:
    GLrgba();
    GLrgba(float red, float green, float blue, float alpha = 1.0f);
    
    explicit GLrgba(char* string);
    explicit GLrgba(float luminance);
    explicit GLrgba(GLlong c);
    GLrgba(int red, int green, int blue);

    GLrgba(const GLrgba &rhs);
    GLrgba &operator=(const GLrgba &rhs);

    float red  () const { return _red;   }
    float green() const { return _green; }
    float blue () const { return _blue;  }
    float alpha() const { return _alpha; }

    GLrgba operator+  (const GLrgba& c) const;
    GLrgba operator+  (const float& c) const;
    GLrgba operator-  (const GLrgba& c) const;
    GLrgba operator-  (const float& c) const;
    GLrgba operator*  (const GLrgba& c) const;
    GLrgba operator*  (const float& c)  const;
    GLrgba operator/  (const GLrgba& c) const;
    GLrgba operator/  (const float& c)  const;

    bool    operator== (const GLrgba& c) const;
    std::ostream &operator<<(std::ostream &os) const;
    
        // Populate the array with the colour values sutable for passing to glColor3fv or glColor4fv
    void copyRGB (float output[3]) const;
    void copyRGBA(float output[4]) const;

        // Return a colour which is a copy of this one, but with the specified alpha value. Defaults to fully opaque.
    GLrgba colorWithAlpha(float newAlpha = 1.0f) const;
    
        // Set the current color to this color
    void glColor3() const;   // R, G, B
    void glColor4() const;   // R, G, B, A
};

inline std::ostream &operator<<(std::ostream &os, const GLrgba &v) { return v.operator<<(os); }

    //Random SATURATED color
GLrgba RANDOM_COLOR(void);


GLrgba    glRgbaAdd (GLrgba c1, GLrgba c2);
GLrgba    glRgbaSubtract (GLrgba c1, GLrgba c2);
GLrgba    glRgbaInterpolate (GLrgba c1, GLrgba c2, float delta);
GLrgba    glRgbaScale (GLrgba c, float scale);
GLrgba    glRgbaMultiply (GLrgba c1, GLrgba c2);
GLrgba    glRgbaUnique (int i);
GLrgba    glRgbaFromHsl (float h, float s, float l);

    // Calls glColor3fv and glColor4fv with the RGB/A values in color.
//void glColor3(const GLrgba &color);
//void glColor4(const GLrgba &color);

#endif
