//
//  glVertex.h
//  PixelCity
//
//  Created by Patrick Wallace on 10/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#ifndef PixelCity_glVertex_h
#define PixelCity_glVertex_h

#import "glTypes.h"
#import "GLrgba.h"

struct GLvertex
{
    GLvertex();
    GLvertex(const GLvector3 &position, const GLvector2 &uv, const GLrgba &color, int bone = 0);
    GLvertex(const GLvector3 &position, const GLvector2 &uv);
    
    GLvector3   position;
    GLvector2   uv;
    GLrgba      color;
    int         bone;
    std::ostream &operator<<(std::ostream &os) const;
};
inline std::ostream &operator<<(std::ostream &os, const GLvertex &v) { return v.operator<<(os); }

#endif
