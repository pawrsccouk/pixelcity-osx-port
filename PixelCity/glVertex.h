//
//  glVertex.h
//  PixelCity
//
//  Created by Patrick Wallace on 10/02/2013.
//  Copyright (c) 2013 Patrick Wallace. All rights reserved.
//

#ifndef PixelCity_glVertex_h
#define PixelCity_glVertex_h


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
    
    
    void glVertex3() const;   // Call glVertex3f with the current position.
    void glTexCoord2() const;   // Call glTexCoord3f with the current uv.
};
inline std::ostream &operator<<(std::ostream &os, const GLvertex &v) { return v.operator<<(os); }

inline void GLvertex::glVertex3() const { position.glVertex3(); }
inline void GLvertex::glTexCoord2() const { uv.glTexCoord2(); }

#endif
