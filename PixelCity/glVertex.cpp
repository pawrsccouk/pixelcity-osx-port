//
//  glTypes.cpp
//  PixelCity
//
//  2009 Shamus Young
//  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
//  Released under the GNU GPL v3. See file COPYING for details.

#import "Model.h"

GLvertex::GLvertex()
: position(glVector(0.0f, 0.0f, 0.0f)), uv(glVector(0.0f, 0.0f)), color(GLrgba()), bone(0)
{}

GLvertex::GLvertex(const GLvector3 &position, const GLvector2 &uv, const GLrgba &color, int bone)
: position(position), uv(uv), color(color), bone(bone)
{}

GLvertex::GLvertex(const GLvector3 &position, const GLvector2 &uv)
: position(position), uv(uv), color(GLrgba()), bone(0)
{
}


std::ostream &GLvertex::operator<<(std::ostream &os) const
{
    return os << "[GLvertex POSITION=" << position << ", UV=" << uv << ", COLOR=" << color << ", BONE=" << bone << "]";
}

void GLvertex::apply() const
{
    color.glColor3();
    uv.glTexCoord2();
    position.glVertex3();
}

