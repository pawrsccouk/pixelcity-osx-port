//
//  glTypes.cpp
//  PixelCity
//
//  Created by Patrick Wallace on 09/02/2013.
//
//
#import <iostream>
#import "glVertex.h"

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