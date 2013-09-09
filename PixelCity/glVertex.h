//
//  glVertex.h
//  PixelCity
//
//  2009 Shamus Young
//  Modified 2013 by Patrick A Wallace. If you find any bugs, assume they are mine.
//  Released under the GNU GPL v3. See file COPYING for details.


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
    
    void apply() const;       // Call glTexCoord3 on uv glVertex3 on position and glColor4 on color.
    void glVertex3() const;   // Call glVertex3f with the current position.
    void glTexCoord2() const;   // Call glTexCoord3f with the current uv.
};
inline std::ostream &operator<<(std::ostream &os, const GLvertex &v) { return v.operator<<(os); }

inline void GLvertex::glVertex3() const { position.glVertex3(); }
inline void GLvertex::glTexCoord2() const { uv.glTexCoord2(); }

