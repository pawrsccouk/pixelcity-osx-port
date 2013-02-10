//
//  glVertex.h
//  PixelCity
//
//  Created by Patrick Wallace on 10/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#ifndef PixelCity_glVertex_h
#define PixelCity_glVertex_h

#include "glTypes.h"
#include "GLrgba.h"

struct GLvertex
{
    GLvector3   position;
    GLvector2   uv;
    GLrgba      color;
    int         bone;
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const GLvertex &v) { return v.operator<<(os); }

#endif
