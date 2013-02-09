//
//  glTypes.cpp
//  PixelCity
//
//  Created by Patrick Wallace on 09/02/2013.
//
//
#include <iostream>
#include "glTypes.h"

std::ostream &GLvertex::operator<<(std::ostream &os) const
{
    return os << "[GLvertex POSITION=" << position << ", UV=" << uv << ", COLOR=" << color << ", BONE=" << bone << "]";
}